# Java Deep Dive — Language Internals for Game Engine Reading

## Table of Contents
1. Inner Classes and Anonymous Classes
2. Enums
3. Annotations
4. Exception Hierarchy
5. Keyword Matrix
6. JVM Memory Basics
7. Common PZ Java Patterns

---

## 1. Inner Classes and Anonymous Classes

Decompiled PZ source is full of these. Knowing how to read them is essential.

### Static Inner Classes

```java
public class IsoGameCharacter {
    // Accessed as IsoGameCharacter.XP
    public static class XP {
        private HashMap<Perks, Float> xpMap;
        public float getXP(Perks perk) { ... }
    }
}
```
File name in decompiled output: `IsoGameCharacter$XP.java`
No reference to enclosing instance — behaves like a top-level class namespaced inside another.

### Instance Inner Classes

```java
public class IsoGameCharacter {
    // Has implicit reference to enclosing IsoGameCharacter
    public class PerkInfo {
        public Perks perk;
        public int level;
        // Can access IsoGameCharacter.this.health etc.
    }
}
```
Carries a hidden `this$0` reference to the outer instance. In decompiled code you'll see constructor parameters like `IsoGameCharacter this$0`.

### Anonymous Classes

```java
// In source:
button.addListener(new ActionListener() {
    public void actionPerformed(ActionEvent e) {
        doSomething();
    }
});

// In decompiled output: IsoSomething$1.java, IsoSomething$2.java, etc.
```
Anonymous classes become numbered inner classes. `$1` is the first anonymous class in the file, `$2` the second, etc. They capture local variables from the enclosing scope (must be `final` or effectively final).

### Lambda Expressions (Java 8+)

```java
list.sort((a, b) -> a.getName().compareTo(b.getName()));
```
PZ uses Java 17 — lambdas appear frequently. In decompiled output they may appear as lambda methods (`lambda$methodName$0`) or as anonymous inner classes depending on the decompiler.

---

## 2. Enums

PZ uses enums extensively — `BodyPartType`, `Perks`, `MoodleType`, `SpriteType`, etc.

```java
public enum BodyPartType {
    Hand_L, Hand_R, ForeArm_L, ForeArm_R,
    UpperArm_L, UpperArm_R, Torso_Upper, Torso_Lower,
    Head, Neck, Groin, UpperLeg_L, UpperLeg_R,
    LowerLeg_L, LowerLeg_R, Foot_L, Foot_R;

    // Enums can have methods
    public boolean isUpperBody() { ... }
}
```

In Kahlua2, enums are converted to/from Lua strings via `KahluaEnumConverter`:
```lua
-- Lua side:
local part = player:getBodyDamage():getBodyPart(BodyPartType.Hand_L)
-- BodyPartType.Hand_L is a Java enum value exposed as a global table
```

### Enum with Fields

```java
public enum Perks {
    Cooking("Cooking", 1, true),
    Farming("Farming", 1, true),
    // ...
    ;
    private String name;
    private int startLevel;
    private boolean passive;

    Perks(String name, int startLevel, boolean passive) { ... }
    public String getName() { return name; }
}
```

---

## 3. Annotations

Annotations you'll encounter in PZ decompiled source:

| Annotation | Meaning |
|---|---|
| `@Override` | Method overrides parent — compiler verification |
| `@Deprecated` | Marked for removal — avoid using |
| `@SuppressWarnings` | Suppress compiler warnings |
| `@FunctionalInterface` | Interface with single abstract method (lambda target) |
| `@LuaMethod` | Kahlua2: expose to Lua |
| `@LuaConstructor` | Kahlua2: expose constructor as Lua function |

Annotations are metadata only — they don't change runtime behavior unless something reads them (like the Kahlua2 exposer reads `@LuaMethod`).

---

## 4. Exception Hierarchy

```
Throwable
  ├── Error (JVM-level, don't catch)
  │     ├── OutOfMemoryError
  │     ├── StackOverflowError
  │     └── ...
  └── Exception
        ├── RuntimeException (unchecked — no forced catch)
        │     ├── NullPointerException
        │     ├── IndexOutOfBoundsException
        │     ├── ClassCastException
        │     ├── IllegalArgumentException
        │     ├── IllegalStateException
        │     ├── ConcurrentModificationException
        │     └── NumberFormatException
        └── Checked exceptions (must catch or declare)
              ├── IOException
              ├── FileNotFoundException
              └── ...
```

**For PZ modding**: Most errors crossing the Kahlua2 bridge are `RuntimeException` subclasses. Lua's `pcall` catches them and returns the Java exception as the fourth return value.

Common PZ stack trace patterns:
- `NullPointerException` → a getter returned null and you called a method on it
- `ClassCastException` → wrong argument type passed through the bridge
- `ConcurrentModificationException` → iterating a collection while modifying it
- `StackOverflowError` → infinite recursion (possibly circular `__index` chain)

---

## 5. Keyword Matrix

| Keyword | On class | On method | On field | On variable |
|---|---|---|---|---|
| `public` | Visible everywhere | Lua-callable | NOT Lua-accessible | — |
| `private` | Enclosing file only | Not Lua-callable | Not accessible | — |
| `protected` | Package + subclasses | Not Lua-callable | Not accessible | — |
| `static` | No instance needed | Global function candidate | Class-level | — |
| `final` | Can't extend | Can't override | Constant after init | Effectively final |
| `abstract` | Can't instantiate | Must implement in subclass | — | — |
| `synchronized` | — | Thread-safe call | — | — |
| `volatile` | — | — | Thread-visible writes | — |
| `transient` | — | — | Skip serialization | — |
| `native` | — | JNI implementation | — | — |

**Key for modding**: `public` methods = Lua-callable. Everything else = invisible to Lua. `final` class = can't subclass (IsoPlayer is final — you can't extend it in Java). `static` methods = good candidates for global Lua functions.

---

## 6. JVM Memory Basics

### Heap vs Stack

- **Heap**: Where objects live. Garbage-collected. Shared across threads.
- **Stack**: Method call frames, local variables, primitive values. Per-thread. Auto-cleaned on method return.

### Garbage Collection

Java's GC handles all memory management. PZ objects (IsoPlayer, InventoryItem, etc.) are GC'd when nothing references them. From Lua's perspective through Kahlua2, holding a reference to a Java object prevents its GC — the Lua variable keeps the Java object alive.

**Gotcha**: If you store a Java object reference in a Lua table and the game removes that object (player dies, item destroyed), the Java object may be in an invalid state but NOT null from Lua's perspective. Always check validity: `player:isDead()`, `item:getContainer() ~= nil`, etc.

### Boxing

Java primitives (`int`, `float`, `boolean`) are boxed to objects (`Integer`, `Float`, `Boolean`) when passing through Kahlua2. This adds memory overhead — every number is a `Double` object (16 bytes vs 8 bytes for a raw double). Not something modders control, but explains why Lua-heavy code uses more memory than equivalent Java.

---

## 7. Common PZ Java Patterns

### Singleton
```java
public class IsoWorld {
    private static IsoWorld instance;
    public static IsoWorld getInstance() { return instance; }
}
// Lua: getWorld() — exposed as global function
```

### Static Factory
```java
public class InventoryItemFactory {
    public static InventoryItem CreateItem(String type) {
        // Reads script definition, creates appropriate subclass
    }
}
// Lua: instanceItem("Base.Axe")
```

### Type Check Pattern
```java
if (item instanceof Food) {
    Food food = (Food) item;
    food.setCooked(true);
}
// Lua: if instanceof(item, "Food") then ... end
// Or: if item:IsFood() then ... end
```

### Null Check Chain
```java
IsoGridSquare sq = player.getCurrentSquare();
if (sq != null) {
    IsoRoom room = sq.getRoom();
    if (room != null) {
        IsoBuilding building = room.getBuilding();
        // ...
    }
}
// Lua equivalent:
-- local sq = player:getCurrentSquare()
-- if sq then
--     local room = sq:getRoom()
--     if room then ...
```

### ArrayList Iteration
```java
ArrayList<InventoryItem> items = container.getItems();
for (int i = 0; i < items.size(); i++) {
    InventoryItem item = items.get(i);
    // ...
}
// Lua: ArrayList becomes iterable via Kahlua2
-- local items = container:getItems()
-- for i = 0, items:size() - 1 do  -- Java is 0-indexed!
--     local item = items:get(i)
-- end
```

**Critical note**: Java collections are 0-indexed. Lua tables are 1-indexed. When iterating Java `ArrayList` from Lua, use `0` to `size()-1`, not `1` to `size()`.
