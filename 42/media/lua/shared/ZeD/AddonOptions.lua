-- ZeD-UI/42/media/lua/shared/ZeD/AddonOptions.lua
-- ============================================================================
-- AN ADD-ON'S OPTIONS ON ZeD SETUP (Nov 15 2026, add-on hooks: a public hook
-- for other mods). Shared; only a list of what add-ons asked for. Pure ASCII.
--
-- An add-on makes its options with PZAPI.ModOptions as any mod does (they stay
-- on the Mods page, as every mod's do), then asks ZeD to show them as a group
-- of their own on ZeD setup, the Options window's first page, drawn with ZeD's
-- own controls:
--
--     ZeD.Options.addGroup {
--         owner = "MyAddon",                -- the add-on's PZAPI.ModOptions id
--         title = "UI_MyAddon_Group",       -- a translation key, or plain words
--         after = "UI_ZeD_Options_ZedWindows",  -- optional: the ZeD group it follows
--         rows  = {                         -- the row shape of G.ZED_GROUPS
--             { "sizes", "onoff" },
--             { "newItems", "radio", short = { "UI_MyAddon_A", "UI_MyAddon_B" } },
--             { "mark", "onoff", needs = "sizes", needsWhy = "UI_MyAddon_NeedsSizes" },
--         },
--     }
--
--   returns true when the group was taken, false (and one log line) when the
--   call itself is unusable (no owner, no rows).
--
-- Where it goes: after the ZeD group whose title key is `after` (the keys are
-- in ZeD_MainMenuOptionGroups.lua's G.ZED_GROUPS); without `after`, or with a
-- key ZeD has no group for, just before the Trouble group. Groups with the same
-- place keep the order they were added in. The same owner and title added
-- again replaces the earlier one (so a reloaded file does not show it twice).
--
-- Each row: { option id, style, under =, short =, needs =, needsNot =,
-- needsWhy =, showIf =, nameKey =, tipKey =, default = }.
--   style      "radio", "onoff" (item 1 Off, item 2 On), "scale" (a stepped
--              slider, its readout the item's words) or nil (the pop-up menu).
--              ("swatch" is ZeD's accent wells and means nothing for an add-on.)
--   under      the line under the name (a translation key or plain words)
--   short      shorter words for the choices, by item (translation keys)
--   needs      another option id of the SAME add-on: this row dims while that
--              one is not item 2 (On); needsNot dims it while that one is On;
--              needsWhy is the help band's words while dimmed (a key)
--   showIf     another option id of the SAME add-on: this row is not shown at
--              all while that one is not item 2 (On) (quieter than a dimmed
--              row: Restock while Loadouts is off). The page rebuilds when the
--              switch is flipped, Apply or not.
--   nameKey    the name read through ZeD.tr each frame (else the name the
--              option was made with, as the Mods page shows it)
--   tipKey     the help band's words through ZeD.tr (else the option's own
--              tooltip as it was passed to ModOptions)
--   default    the item Reset to defaults goes back to (else the item the
--              option started on before the saved values were read, which
--              ZeD.ModOptionsOwners notes for every mod)
-- Only combo boxes (addComboBox) take a style and a default, as ZeD's own
-- options; any other kind of option shows as it does on the Mods page.
--
-- The group can be added at any time: before the options screen is built (an
-- add-on's file loading before or after ZeD's) or while it is open (it shows
-- within a moment). An owner or option id ZeD cannot find is logged once and
-- left out; nothing throws.
--
-- ZeD.Options.VERSION: 1. An add-on checks it before calling:
--     if ZeD and ZeD.Options and (ZeD.Options.VERSION or 0) >= 1 then ... end
--
-- (1.0, Nov 23 2026) Two more, for an add-on whose switches sit among ZeD's own:
--
--   ZeD.Options.addRows { owner =, into =, afterRow =, rows = { ... } }
--     its rows inside one of ZeD's groups instead of a group of their own:
--     into = the ZeD group's title key ("UI_ZeD_Options_ZedAdditions"), afterRow =
--     the option id of ZeD's row they follow (none, or one not in that group: the
--     group's end). The rows have the shape above. owner may be "ZeD_UI" for an
--     option ZeD itself makes for the add-on.
--
--   ZeD.Options.joinPreset { owner =, id =, presets = { v1, v2, v3 }, wasOn = item }
--     the option becomes one of ZeD's additions: the Additions preset (1 Vanilla,
--     2 Vanilla Plus, 3 Vanilla Accessible) sets it to presets[i] (nil: that
--     preset leaves it as it is and does not look at it), a change to it makes the
--     preset read Custom, Lite and ZeD setup's Defaults put it to presets[1].
--     wasOn: a player who had ZeD's options saved before this option existed (no
--     line for it in ModOptions.ini) starts on this item instead of the default
--     ("start on for existing players"). Join at file load, as the option is made.
--     ZeD.Settings.savedValue(owner, id) reads a saved value from ModOptions.ini
--     as the game started (an add-on carrying a value ZeD saved under its own
--     owner before the option moved: ZeD.Settings.savedValue("ZeD_UI", "loadouts")).
-- ============================================================================

-- Reload-safe: loading this file twice keeps what was added (an add-on that
-- registered before a reload would otherwise lose its group)
ZeD = ZeD or {}
ZeD.Options = ZeD.Options or {}
local O = ZeD.Options
O.VERSION = 1
O.groups = O.groups or {}    -- the groups added, in the order they came: { owner, title, after, rows }
O.rev = O.rev or 0           -- goes up by one with every group added (the options window rebuilds its rows when it changes)
O.logged = O.logged or {}    -- the log lines already printed, by their key (each problem is told once)

--- Print one line to the console log, once for each key (the setup page is rebuilt every
--- two seconds; a missing option would otherwise fill the log).
function O.logOnce(key, msg)
    if O.logged[key] then return end
    O.logged[key] = true
    print("[ZeD] Options: " .. tostring(msg))
end

O.rowAdds = O.rowAdds or {}       -- addRows' entries: { owner, into, afterRow, rows }
O.presetJoins = O.presetJoins or {}   -- joinPreset's entries, in the order they came

--- Put an add-on's rows inside one of ZeD's groups (the header above).
function O.addRows(spec, more)
    if spec == O then spec = more end
    if type(spec) ~= "table" or type(spec.owner) ~= "string" or type(spec.into) ~= "string" or type(spec.rows) ~= "table" then
        O.logOnce("addRows:bad", "addRows needs { owner =, into =, rows = }: left out")
        return false
    end
    local rows = {}
    for _, e in ipairs(spec.rows) do
        if type(e) == "table" and type(e[1]) == "string" and e[1] ~= "" then rows[#rows + 1] = e end
    end
    local a = { owner = spec.owner, into = spec.into, afterRow = spec.afterRow, rows = rows }
    -- the same owner, group and place again: replace it
    local at = nil
    for i, old in ipairs(O.rowAdds) do
        if old.owner == a.owner and old.into == a.into and old.afterRow == a.afterRow then at = i end
    end
    if at then O.rowAdds[at] = a else O.rowAdds[#O.rowAdds + 1] = a end
    O.rev = O.rev + 1
    return true
end

--- An option joins ZeD's additions and their presets (the header above). Settings.lua takes it at once when it
--- has loaded, else when it loads.
function O.joinPreset(spec, more)
    if spec == O then spec = more end
    if type(spec) ~= "table" or type(spec.owner) ~= "string" or type(spec.id) ~= "string" then
        O.logOnce("joinPreset:bad", "joinPreset needs { owner =, id = }: left out")
        return false
    end
    for i, old in ipairs(O.presetJoins) do
        if old.owner == spec.owner and old.id == spec.id then table.remove(O.presetJoins, i); break end
    end
    O.presetJoins[#O.presetJoins + 1] = spec
    if ZeD.Settings and ZeD.Settings.joinAddition then ZeD.Settings.joinAddition(spec) end
    O.rev = O.rev + 1
    return true
end

--- Add (or replace) an add-on's group on ZeD setup. The header above has the fields.
function O.addGroup(spec, more)
    -- (called as ZeD.Options:addGroup{...} with a colon, Lua passes the table itself first: take the second)
    if spec == O then spec = more end
    if type(spec) ~= "table" then
        O.logOnce("addGroup:notable", "addGroup needs a table { owner =, title =, rows = }")
        return false
    end
    local owner = spec.owner
    if type(owner) ~= "string" or owner == "" then
        O.logOnce("addGroup:noowner", "addGroup without an owner (the add-on's ModOptions id) was left out")
        return false
    end
    if type(spec.rows) ~= "table" then
        O.logOnce("addGroup:norows:" .. owner, "addGroup from " .. owner .. " has no rows: left out")
        return false
    end
    -- the title: what the add-on gave, else its owner id (a header with no words would read as a gap)
    local title = spec.title
    if type(title) ~= "string" or title == "" then title = owner end
    -- the rows: only well-formed ones ({ "option id", ... }); a bad one is told once and skipped
    local rows = {}
    for i, e in ipairs(spec.rows) do
        if type(e) == "table" and type(e[1]) == "string" and e[1] ~= "" then
            rows[#rows + 1] = e
        else
            O.logOnce("addGroup:badrow:" .. owner .. ":" .. i, owner .. ": row " .. i .. " has no option id: skipped")
        end
    end
    local g = { owner = owner, title = title, after = spec.after, rows = rows }
    -- the same owner and title again: replace it where it stands (keeps its place in the order)
    local at = nil
    for i, old in ipairs(O.groups) do
        if old.owner == owner and old.title == title then at = i end
    end
    if at then O.groups[at] = g else O.groups[#O.groups + 1] = g end
    O.rev = O.rev + 1
    return true
end
