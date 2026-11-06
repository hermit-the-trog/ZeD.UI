DRAFT for the director to post. Not sent. Reproduced by QA on the game with no mods (the log: ZeDUI/qa/pool_repro_20261105.txt).

----

# [42.22.1] A Lua call that matches no Java overload corrupts Kahlua's argument pool: later actions fail with "Cannot assign field callFrame because a is null"

**Version:** 42.22.1 (71e8410c42)
**Mods:** none. Reproduced on the unmodded game, in debug mode.
**Single player or multiplayer:** seen in single player; the code is shared
**New or existing save:** either
**Severity:** a Lua error that a script catches and carries on from can break unrelated actions later, for the rest of the session. Players see the failure far from its cause, with a stack that points at innocent code.

## What happens

When Lua calls an overloaded Java method with arguments that match none of its overloads, and that error is caught by `pcall`, the same `MethodArguments` object ends up in the pool twice. Later, an outer Java call and a nested Java call with the same parameter count are handed the same object. The nested call releases it, the outer call's return values are then null, and it fails:

    java.lang.NullPointerException: Cannot assign field "callFrame" because "a" is null
        at ReturnValues.put(ReturnValues.java:61)
        at LuaJavaInvoker.call(LuaJavaInvoker.java:185)

We saw it at `ISBaseTimedAction.begin` (line 88, `StartAction`), so the timed action never starts, and in `ISCharacterScreen.onTrimBeard`. We also saw it on quitting to the menu, in nested `require` calls while `IngameState.exit` reloads Lua, at `ISDropCorpseIntoContainer.lua`, `corpseStorageCheck.lua` line 9 and `Foraging/Categories/Ammo.lua`.

Nothing is logged at the moment of the damage, because the `pcall` swallows the error. The stack traces show only the later victims.

## Cause

In `se.krka.kahlua.integration.expose.MultiLuaJavaInvoker.call(LuaCallFrame, int)`, line numbers from the 42.22.1 class file:

- The last loop tries each remaining overload. A candidate that fails `isValid()` is released, line 104: `MethodArguments.put(args)`. The local `args` still points at it.
- After the loop, lines 108 to 110 run `if (args != null) { args.assertValid(); MethodArguments.put(args); }`.
- `MethodArguments.put` had already reset that object: `valid = true`, `failure = null`. So `assertValid()` passes when it should report the failure, and the second `put` adds the same object to the pool again.
- Line 113 then throws "No implementation found for function: ...", which a `pcall` catches.

The next two `MethodArguments.get(n)` calls of that size return the same object.

The check behind `DebugOptions.instance.checks.objectPoolContains` looks as though it would catch this at the second `put`, with "object pool already contains object". We haven't tested that.

## Steps to reproduce

1. Start a game with no mods, in debug mode. Give the character a beard and a razor in the main inventory.
2. Run this once from the Lua console. Any item works. `hasTag` has two one-parameter overloads, and neither takes a string:

       local item = getPlayer():getInventory():getItems():get(0)
       print(pcall(function() return item:hasTag("not a tag") end))

   It prints false and "No implementation found for function: hasTag(...)". Nothing else looks wrong.
3. Trim the beard: `ISCharacterScreen.onTrimBeard(getPlayer(), "Goatee")`.

**Expected:** the action starts with no error, as it does when step 2 is skipped. The failed call only affects the code that made it.
**Actual:** `onTrimBeard` throws the callFrame exception above.

## Suggested fix

Clear the local after the release in the loop, or release only at the end, so each object is put back exactly once. If the intent of `assertValid()` at line 109 is to report the failure, it needs to run before the object is released, because `put` resets `valid` and `failure`.

Any overload mismatch inside a `pcall` can trigger this, which makes it easy to hit: scripts that try several argument forms to stay working across game versions do exactly that.
