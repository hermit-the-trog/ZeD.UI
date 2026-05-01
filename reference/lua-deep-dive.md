# Lua Deep Dive — Language Internals

## Table of Contents
1. Table Memory Layout
2. Metatables Advanced
3. Weak Tables
4. String Internals and Pattern Reference
5. Standard Library Complete Reference
6. Performance and Memory
7. Common Idioms

---

## 1. Table Memory Layout

Lua tables have two parts internally:
- **Array part**: Contiguous integer keys starting from 1. Stored as a C array — O(1) access.
- **Hash part**: Everything else (string keys, non-contiguous integers, mixed types). Hash table with open addressing.

Lua resizes both parts dynamically. When the array or hash fills up, Lua allocates a new block (power of 2 size) and rehashes. This is expensive — pre-allocating avoids it:

```lua
-- Bad: grows incrementally (many rehashes)
local t = {}
for i = 1, 10000 do t[i] = 0 end

-- Better: Lua pre-sizes from constructor
local t = {0,0,0,0,0,0,0,0,0,0} -- only 10, but illustrates the idea
-- For large tables, there's no built-in pre-allocation in standard Lua
-- Kahlua2's ConcurrentHashMap handles this differently anyway
```

**Key rule**: Contiguous integer keys from 1..n use the fast array path. Gaps break this. `t[1], t[2], t[4]` (missing 3) may push keys into the hash part.

### The # Operator

`#t` returns a "border" — an integer n where `t[n] ~= nil` and `t[n+1] == nil`. If there are multiple borders (holes), `#` can return any of them. Only trust `#` on proper sequences (no holes).

```lua
local t = {1, 2, nil, 4}
-- #t is UNDEFINED behavior. Could be 2 or 4.
-- For safety: track length explicitly or use table.pack/table.unpack
```

---

## 2. Metatables Advanced

### __index as Function vs Table

```lua
-- Table __index: simple prototype chain (fast, direct lookup)
setmetatable(child, {__index = parent})

-- Function __index: computed properties (flexible, slower)
setmetatable(obj, {
    __index = function(self, key)
        -- Can compute, delegate, cache, log, etc.
        return someComputation(key)
    end
})
```

**Performance**: Table `__index` is a single rawget on the parent. Function `__index` is a function call with frame push/pop. In hot loops, table form is measurably faster.

### __newindex for Change Tracking

```lua
local function watchedTable(onChange)
    local data = {}
    return setmetatable({}, {
        __index = data,
        __newindex = function(self, key, value)
            local old = data[key]
            data[key] = value
            if old ~= value then
                onChange(key, old, value)
            end
        end,
    })
end

local config = watchedTable(function(k, old, new)
    print(k .. " changed: " .. tostring(old) .. " → " .. tostring(new))
end)
config.debug = true  -- prints: "debug changed: nil → true"
```

This is the foundation of reactive UI — detect when data changes and propagate updates.

### Read-Only Tables

```lua
local function readOnly(t)
    return setmetatable({}, {
        __index = t,
        __newindex = function()
            error("attempt to modify read-only table", 2)
        end,
    })
end

local constants = readOnly({MAX_HEALTH = 100, MIN_DAMAGE = 1})
print(constants.MAX_HEALTH)  -- 100
constants.MAX_HEALTH = 200   -- ERROR
```

### __call (Callable Tables)

```lua
local Color = {}
Color.__index = Color
Color.__call = function(self, r, g, b, a)
    return setmetatable({r=r, g=g, b=b, a=a or 1}, Color)
end

setmetatable(Color, Color)

local red = Color(1, 0, 0)    -- Works because Color is callable
local blue = Color(0, 0, 1)
```

PZ's PZAPI uses this: `UI.Panel { width=300, height=200 }` — `UI.Panel` is a callable table.

### Metatable Inheritance Chain Construction

```lua
local function class(parent)
    local cls = setmetatable({}, {__index = parent})
    cls.__index = cls
    cls.new = function(self, ...)
        local instance = setmetatable({}, self)
        if instance.init then instance:init(...) end
        return instance
    end
    return cls
end

local Animal = class()
function Animal:init(name) self.name = name end
function Animal:speak() return "..." end

local Dog = class(Animal)
function Dog:speak() return "woof" end

local rex = Dog:new("Rex")
print(rex:speak())  -- "woof"
print(rex.name)     -- "Rex" (inherited init set it)
```

---

## 3. Weak Tables

**Note**: Kahlua2 does NOT support weak tables (`__mode` is silently ignored). This section is for general Lua knowledge.

In standard Lua, setting `__mode` on a metatable makes keys and/or values weak (not preventing garbage collection):

```lua
-- Weak values: entries vanish when value is GC'd
local cache = setmetatable({}, {__mode = "v"})

-- Weak keys: entries vanish when key is GC'd
local metadata = setmetatable({}, {__mode = "k"})

-- Both weak
local ephemeral = setmetatable({}, {__mode = "kv"})
```

Since Kahlua2 ignores this, alternative cleanup strategies for game modding:
- Manual cleanup in `onRemove`/`onDestroy` callbacks
- Periodic sweep in `OnTick` handler
- Reference counting

---

## 4. String Internals and Pattern Reference

### Lua Strings

Strings are immutable and interned in standard Lua (NOT in Kahlua2 — interning was removed). Comparison is by value. Concatenation with `..` creates a new string every time.

```lua
-- Bad: O(n²) string building
local s = ""
for i = 1, 1000 do
    s = s .. "item" .. i .. ","  -- 1000 new strings created
end

-- Good: O(n) with table.concat
local parts = {}
for i = 1, 1000 do
    parts[#parts + 1] = "item" .. i
end
local s = table.concat(parts, ",")
```

### Complete Pattern Reference

**Character classes:**
| Class | Matches | Complement |
|---|---|---|
| `%a` | Letters | `%A` |
| `%d` | Digits | `%D` |
| `%w` | Alphanumeric | `%W` |
| `%s` | Whitespace | `%S` |
| `%l` | Lowercase | `%L` |
| `%u` | Uppercase | `%U` |
| `%p` | Punctuation | `%P` |
| `%c` | Control chars | `%C` |
| `.` | Any character | — |
| `%%` | Literal `%` | — |

**Quantifiers:**
| Quantifier | Meaning |
|---|---|
| `*` | 0 or more (greedy) |
| `+` | 1 or more (greedy) |
| `-` | 0 or more (lazy) |
| `?` | 0 or 1 |

**Key functions:**
```lua
string.find(s, pattern, init, plain)    -- returns start, end indices
string.match(s, pattern)                -- returns captures
string.gmatch(s, pattern)              -- iterator over matches
string.gsub(s, pattern, repl, n)       -- substitute matches
string.format(fmt, ...)                -- printf-style formatting
string.sub(s, i, j)                    -- substring
string.rep(s, n)                       -- repeat
string.reverse(s)                      -- reverse
string.upper(s) / string.lower(s)     -- case
string.byte(s, i) / string.char(n)    -- char ↔ byte
string.len(s)                          -- length (same as #s)
```

---

## 5. Standard Library Complete Reference

### table.*
```lua
table.insert(t, pos, value)  -- insert at position (shifts others)
table.insert(t, value)       -- append (fastest)
table.remove(t, pos)         -- remove at position (shifts others)
table.sort(t, comp)          -- in-place sort, comp(a,b) returns true if a < b
table.concat(t, sep, i, j)  -- join array elements with separator
-- Lua 5.2+: table.pack, table.unpack (not in Lua 5.1/Kahlua2)
-- Use unpack() instead (global function in 5.1)
```

### math.*
```lua
math.floor(x)    math.ceil(x)     math.abs(x)
math.max(...)    math.min(...)    math.sqrt(x)
math.sin(x)      math.cos(x)      math.tan(x)
math.random()    math.random(n)   math.random(m, n)
math.randomseed(x)
math.pi          math.huge        -- constants
math.log(x)      math.exp(x)      math.pow(x, y)
math.fmod(x, y)  math.modf(x)     -- integer and fractional parts
```

### Global functions
```lua
type(v)              -- "nil","number","string","boolean","table","function","userdata"
tostring(v)          -- convert to string
tonumber(s, base)    -- convert to number
select(n, ...)       -- select nth arg or "#" for count
unpack(t, i, j)      -- table to multiple values
rawget(t, k)         -- bypass __index
rawset(t, k, v)      -- bypass __newindex
rawequal(a, b)       -- bypass __eq
setmetatable(t, mt)  -- set metatable
getmetatable(t)      -- get metatable
pcall(f, ...)        -- protected call
xpcall(f, handler)   -- protected call with error handler
error(msg, level)    -- throw error
assert(v, msg)       -- error if v is falsy
print(...)           -- debug output
```

---

## 6. Performance and Memory

### Hot Path Rules

1. **Local > Global**: Every global access is a hash lookup on `_G`. Localize at file scope:
   ```lua
   local math_floor = math.floor
   local getMouseX = getMouseX  -- PZ global
   ```

2. **Avoid allocation in render/update**: `prerender()` and `render()` run 60x/second. Don't create tables, closures, or strings there unless necessary.

3. **Cache metatable lookups**: `obj:method()` traverses `__index` each time. For hot loops:
   ```lua
   local method = obj.method  -- resolve once
   for i = 1, 1000 do method(obj, i) end
   ```

4. **String keys faster than computed keys**: `t.name` is slightly faster than `t["name"]` (compiler optimization in some Lua implementations; in Kahlua2 they're equivalent).

5. **Reuse tables**: Instead of creating new tables each frame, clear and reuse:
   ```lua
   local tempTable = {}
   function getResults()
       for k in pairs(tempTable) do tempTable[k] = nil end  -- wipe
       -- fill tempTable with results
       return tempTable
   end
   ```

### Memory Patterns

- Tables: ~40 bytes base + per-slot overhead
- Closures: ~32 bytes + upvalue storage
- Strings: length + overhead (NOT interned in Kahlua2)
- Numbers: 8 bytes (boxed Double in Kahlua2 — more than C Lua's unboxed double)
- Userdata (Java objects): only a reference from Lua's perspective; Java handles the real memory

---

## 7. Common Idioms

```lua
-- Default values
local x = value or defaultValue

-- Boolean coercion (only nil and false are falsy)
if obj then ... end  -- true for 0, "", empty table

-- Ternary (Lua doesn't have ?:)
local result = condition and valueIfTrue or valueIfFalse
-- CAUTION: fails if valueIfTrue is false or nil

-- Safe ternary
local result = condition and {valueIfTrue} or {valueIfFalse}
result = result[1]

-- Swap
a, b = b, a

-- Multiple return
function divmod(a, b) return math.floor(a/b), a % b end
local q, r = divmod(17, 5)

-- Variadic functions
function log(level, ...)
    local args = {...}
    -- or: local n = select("#", ...)
end

-- String interpolation (Lua doesn't have it natively)
local msg = string.format("Player %s has %d HP", name, health)

-- Nil-safe chaining (no ?. operator in Lua)
local health = player and player:getBodyDamage() and player:getBodyDamage():getOverallBodyHealth()
```
