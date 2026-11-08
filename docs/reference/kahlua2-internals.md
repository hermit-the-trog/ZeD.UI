# Kahlua2 Internals — Deep Dive

## Table of Contents
1. KahluaThread Execution Model
2. Coroutine Mechanics
3. Platform Abstraction
4. Converter System
5. Standard Libraries
6. Compilation Pipeline

---

## 1. KahluaThread Execution Model

KahluaThread (~1,255 lines) is the entire VM. One class, one main loop, 38 opcodes.

### The Main Loop

`luaMainloop()` is a `while(true)` loop that:
1. Reads the next 32-bit instruction from the current `LuaCallFrame`'s `Prototype.code[]`
2. Extracts opcode (6 bits), A (8 bits), B (9 bits), C (9 bits) fields
3. Switches over the opcode
4. Executes the operation against `callFrame.objectStack[]`

The instruction format is standard Lua 5.1 binary. Files compiled by C `luac` work directly — Kahlua doesn't have its own bytecode format.

### Call Dispatch

`call(int nArguments)` checks the callable type:

```java
Object callable = objectStack[callBase];
if (callable instanceof LuaClosure) {
    // Push new LuaCallFrame, enter luaMainloop()
    LuaClosure closure = (LuaClosure) callable;
    LuaCallFrame frame = currentCoroutine.pushNewCallFrame(closure, ...);
    // luaMainloop() picks up from the new frame
} else if (callable instanceof JavaFunction) {
    // callJava() — creates temporary frame, invokes JavaFunction.call()
    callJava((JavaFunction) callable, callFrame, callBase, nArguments);
}
```

`callJava()` pushes a frame, calls `JavaFunction.call(callFrame, nArguments)`, and the return int tells how many values were pushed as returns.

### Table Operations

`tableGet(Object table, Object key)` — the __index resolution path:

```
1. If table is KahluaTable:
   rawget(key) → if non-null, return it
   → else get metatable, look for __index
2. If table is any other Java object:
   → getMetaOp(table, "__index") → resolves class metatable
3. __index is a KahluaTable → recursive tableGet(indexTable, key)
   __index is a JavaFunction → call it with (table, key)
4. Recursion capped at MAX_INDEX_RECURSION
```

This is how `player:getHealth()` resolves: `player` is a Java `IsoPlayer` → class metatable → `__index` → indexTable → `"getHealth"` → `LuaJavaInvoker`.

`tableSet(Object table, Object key, Object value)` mirrors this with `__newindex`.

### Error Handling

Lua errors throw `RuntimeException`. `pcall` wraps in try/catch:

```java
try {
    call(nArgs);
    return 1; // success
} catch (RuntimeException e) {
    // Push (false, message, stacktrace, exception) onto stack
    return 4;
}
```

PZ error logs always show this four-value pattern. The Java exception object is the fourth return — modders can catch it with `select(4, pcall(...))`.

### Stack Management

Each `Coroutine` owns:
- `Object[] objectStack` — the value stack (dynamic size, grows as needed)
- `LuaCallFrame[] callFrameStack` — call frames (each tracks PC, base index, closure, etc.)

`LuaCallFrame` fields:
- `closure` — the `LuaClosure` being executed (null for Java calls)
- `localBase` — index into objectStack where this frame's locals start
- `returnBase` — where return values should be placed
- `pc` — program counter into `closure.prototype.code[]`
- `nArguments` — argument count

---

## 2. Coroutine Mechanics

Kahlua2 coroutines are pure stackful continuations — they do NOT use Java threads. This is a deliberate design choice for J2ME compatibility and reduced overhead.

Each `Coroutine` object owns its own value stack and call frame stack. When `coroutine.resume()` fires:
1. `KahluaThread.currentCoroutine` is swapped to the target coroutine
2. `luaMainloop()` continues execution using the target's stacks
3. The calling coroutine's state is preserved in its own stacks

When `coroutine.yield()` fires:
1. Execution state is saved in the current call frame
2. `currentCoroutine` swaps back to the parent
3. Yield values are pushed onto the parent's stack

**Critical limitation:** Coroutines cannot yield across Java call boundaries. If a Lua coroutine calls a Java function that calls back into Lua, the inner Lua code cannot yield — the Java frame on the call stack has no mechanism to save/restore. This affects PZ modders using coroutines in hooks that cross Java boundaries.

---

## 3. Platform Abstraction

```java
public interface Platform {
    double pow(double x, double y);
    KahluaTable newTable();
    KahluaTable newEnvironment();
}
```

`J2SEPlatform` (singleton):
- `newTable()` → `KahluaTableImpl` backed by `ConcurrentHashMap<Object, Object>`
- `newEnvironment()` → creates table, installs standard libraries
- `pow()` → delegates to `Math.pow()`

The `ConcurrentHashMap` backing is significant for PZ's multi-threaded architecture. Multiple `KahluaThread` instances sharing one global environment get thread-safe table operations without explicit locking. This is how PZ handles its server/client thread separation.

`CLDC11Platform` (J2ME) uses `Hashtable` instead — irrelevant for PZ but explains some Kahlua2 design decisions.

---

## 4. Converter System

`KahluaConverterManager` handles bidirectional Java↔Lua type conversion:

### Built-in Converters

- `KahluaNumberConverter` — `int/long/float/short/byte` → `Double` (Lua numbers are always doubles)
- `KahluaEnumConverter` — Java enums ↔ Lua strings (enum name)
- `KahluaTableConverter` — Java Maps/Lists ↔ `KahluaTable`

### Converter Chain

When `LuaJavaInvoker.call()` processes arguments:
1. Extracts raw Lua values from the call frame
2. For each parameter, calls `converterManager.fromLuaToJava(luaValue, targetJavaType)`
3. Converter walks the registered converter list until one matches
4. If no converter matches, the value passes through unchanged (works for Java objects that are already the correct type)

Return path: `converterManager.fromJavaToLua(javaReturnValue)` — Java `int` → `Double`, etc.

### Custom Converters

PZ registers additional converters for game-specific types. The pattern:

```java
converterManager.addLuaConverter(new LuaConverter() {
    public Object fromLuaToJava(Object luaValue, Class<?> targetType) {
        if (targetType == SomeType.class && luaValue instanceof String) {
            return SomeType.valueOf((String) luaValue);
        }
        return null; // pass to next converter
    }
});
```

---

## 5. Standard Libraries

Kahlua2 installs these Lua standard libraries:

| Library | Kahlua2 Class | Notes |
|---|---|---|
| base | `BaseLib` | `print`, `type`, `tostring`, `tonumber`, `pcall`, `error`, `select`, `unpack`, `rawget/set`, `setmetatable/getmetatable`, `pairs`, `ipairs` |
| string | `StringLib` | Standard Lua string ops. UTF-16 backed, not byte-string |
| table | `TableLib` | `table.insert`, `table.remove`, `table.sort`, `table.concat` |
| math | `MathLib` | Standard math. All operations on `Double` |
| coroutine | `CoroutineLib` | `coroutine.create/resume/yield/status/wrap` |
| os | `OsLib` | Minimal: `os.time()`, `os.clock()` only |
| random | `RandomLib` | Kahlua extension (not standard Lua) |

**Not included:** `io`, `debug`, `package` (Lua's module system). PZ implements its own `require` mechanism for loading Lua files.

### Notable Behavior Differences from C Lua

- `pairs()` uses `KahluaTableIterator`, not `next()` — iteration order may differ from C Lua
- `string.format()` is Java's `String.format()` under the hood — some edge cases differ
- `math.random()` uses Kahlua's `RandomLib` with Java's `Random` — seed behavior differs
- No `string.dump()` (would need to serialize `Prototype` objects)
- `pcall` returns 4 values on error instead of 2 (adds stacktrace and Java exception)

---

## 6. Compilation Pipeline

Kahlua2 includes a Lua 5.1 compiler (forked from LuaJ's compiler, rewritten for Kahlua):

```
Lua source text
  → LexState (lexer/tokenizer)
    → FuncState (parser, builds Prototype)
      → Prototype (bytecode + constants + debug info)
        → LuaClosure (wraps Prototype + upvalues + environment)
```

`Prototype` contains:
- `int[] code` — bytecode instructions (standard Lua 5.1 format)
- `Object[] constants` — number/string literals referenced by instructions
- `Prototype[] prototypes` — nested function definitions
- `int[] lines` — line number mapping for debug
- `int maxStacksize`, `numParams`, `isVararg`

The compiler runs at Lua `dofile()`/`loadstring()` time. PZ pre-compiles some core Lua files but most mod Lua compiles on load.

### Loading Lua Files in PZ

PZ's loading pipeline: `LuaManager.LoadDir()` → walks directory → `LuaManager.RunLua()` → reads file → Kahlua2 compiler → `LuaClosure` → `KahluaThread.pcall()`. The load order is deterministic within directories but mods can specify dependencies via `mod.info`.
