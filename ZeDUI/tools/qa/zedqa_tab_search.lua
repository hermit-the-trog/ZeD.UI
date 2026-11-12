-- ZeDUI/tools/qa/zedqa_tab_search.lua  (Nov 11 2026, Build): the Find field on the Character window's Skills and
-- Equipment tabs, in game. QA save only (Saves/Sandbox/ZeD-QA), the deep-run character (worn clothes, gloves, boots,
-- a weapon in hand). Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go, grep console.txt for "ZEDQA ts". PASS / FAIL
-- lines, ending DONE. Screenshots/zqa_ts_*.png: take the set at 4K 1.75x, then again at the Deck size (1280x800,
-- Auto scale, Normal and Large text; the script does not resize).
--   1  Skills: the field in the heading's right; "bla" dims the rest in place (rows still there), the count shows
--   2  "combat": both combat groups whole (a group name keeps its group); "cook": Cooking and its books
--   3  "piloting": the empty result with Clear; Clear (the mouse's route) empties the field, every row back
--   4  Equipment: its own empty field (the Skills text kept); "hand": slot words match, the Defense block hides;
--      "foot": the "covers Left Foot, Right Foot" line; the Doll view: the rest dimmed, the matches keep their picture
--   5  back on Skills: its text is still there; the Equipment text still there on the way back
--   6  the controller: the field is a stop; A opens the pad keyboard; Accept (RT's route) lands the hand on the first
--      match; X on the field clears; with Skill Recovery Journal and a Bound Journal, Up from the top rows reaches
--      the Transcribe key, Up again the field
--   7  the window closed and opened: both fields empty
local function say(s) print("ZEDQA ts " .. tostring(s)) end
local fails = 0
local function check(ok, what, extra) if not ok then fails = fails + 1 end; say((ok and "PASS " or "FAIL ") .. what .. (extra ~= nil and (" | " .. tostring(extra)) or "")) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ts_" .. n .. ".png") end) end
local Focus, Det = ZeD.Input.Focus, ZeD.Input.Detector
local CWm, TF = ZeD_CharacterWindow, ZeD.TabFind
local function W() return CWm.getWindow() end

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

local function field(tab) local w = W(); return w and w._findFields and w._findFields[tab] end
local function typeIn(tab, text) local f = field(tab); if f then f.input:setText(text) end end
local function tabTo(id) local w = W(); w._activeTab = id; w._drawerMode = "tab"; w._drawerOpen = true end
local function ringEl(id)
    for _, z in ipairs(W()._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if e.id == id then return e, z end end
    end
end
local function focusedEl()
    local el = Focus.getFocusedElement and Focus.getFocusedElement(W())
    return el
end
local function count(tab) local c = W()._findCount; return c and c[tab] end

-- 1  Skills
add(300, function()
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
end)
add(1500, function()
    tabTo("skills")
end)
add(1000, function()
    local f = field("skills")
    check(f and f:isVisible(), "Skills: the Find field shows in the heading")
    local r = TF.rect(W(), "skills")
    check(r and r.x > W()._skillsGridZone.x + W()._skillsGridZone.w, "Skills: the disclosure stops short of the field")
    shot("1_skills_idle")
    typeIn("skills", "bla")
end)
add(800, function()
    local c = count("skills")
    check(c and c.shown >= 1 and c.shown < c.total, "Skills 'bla': some kept, the rest dimmed", c and (c.shown .. " of " .. c.total))
    check(#(W()._skillRowZones or {}) == (c and c.total or -1), "Skills 'bla': no row hidden", #(W()._skillRowZones or {}))
    shot("2_skills_bla")
    typeIn("skills", "combat")
end)
add(800, function()
    local c = count("skills")
    local g = 0
    for _, v in pairs(c and c.groupHit or {}) do if v then g = g + 1 end end
    check(g >= 1, "Skills 'combat': a group name matched, its skills all kept", g)
    shot("3_skills_combat")
    typeIn("skills", "cook")
end)
add(800, function()
    local c = count("skills")
    local anyBook = false
    for _, v in pairs(c and c.train or {}) do if v then anyBook = true end end
    check(c and c.shown >= 1 and anyBook, "Skills 'cook': Cooking and its books kept", c and c.shown)
    shot("4_skills_cook")
    typeIn("skills", "piloting")
end)
-- 3  nothing matches
add(800, function()
    local c = count("skills")
    check(c and c.shown == 0, "Skills 'piloting': nothing matches")
    local b = W()._findClearBtn and W()._findClearBtn.skills
    check(b and b.live, "Skills 'piloting': the empty result's Clear shows")
    shot("5_skills_none")
    if b then TF.onClick(W(), b.x + 2, b.y + 2) end
end)
add(800, function()
    check(TF.text(W(), "skills") == "" and field("skills"):getText() == "", "Clear empties the field")
    check(not W()._findSkills, "after Clear: nothing dimmed")
    typeIn("skills", "bla")
end)

-- 4  Equipment
add(800, function() tabTo("equip"); ZeD.EquipDoll.setView("list") end)
add(1200, function()
    local f = field("equip")
    check(f and f:isVisible() and f:getText() == "", "Equipment: its own field, empty")
    check(not field("skills"):isVisible() and TF.text(W(), "skills") == "bla", "the Skills field hides, its text kept")
    shot("6_equip_idle")
    typeIn("equip", "hand")
end)
add(800, function()
    local c = count("equip")
    check(c and c.shown >= 1, "Equipment 'hand': slot words match (Hands, Primary / Secondary Hand)", c and (c.shown .. " of " .. c.worn))
    check(W()._equipDefHidden == true, "Equipment 'hand': the Defense block hides")
    shot("7_equip_hand")
    typeIn("equip", "foot")
end)
add(800, function()
    local c = count("equip")
    local cov = 0
    for _ in pairs(c and c.covers or {}) do cov = cov + 1 end
    check(cov >= 1, "Equipment 'foot': a 'covers ...' line under the socks or shoes", cov)
    shot("8_equip_foot")
    ZeD.EquipDoll.setView("doll")
end)
add(1200, function()
    local c = W()._findEquip
    check(c and c.view == "doll" and c.res.shown >= 1, "Doll 'foot': the matching boxes keep their picture, the rest dim",
        c and c.res and c.res.shown)
    shot("9_doll_foot")
    ZeD.EquipDoll.setView("list")
    typeIn("equip", "")
end)
add(800, function()
    check(W()._equipDefHidden == false, "Equipment cleared: the Defense block is back")
    typeIn("equip", "jean")
    tabTo("skills")
end)

-- 5  each tab keeps its text
add(1000, function()
    check(field("skills"):isVisible() and field("skills"):getText() == "bla", "back on Skills: its text still there")
    check(TF.text(W(), "equip") == "jean", "the Equipment text kept while away")
end)

-- 6  the controller
add(300, function()
    Det.setLockedMode(Det.MODE_GAMEPAD)
end)
add(800, function()
    local el, z = ringEl("skills:find")
    check(el ~= nil, "the field is a stop in the tab's zone")
    if el then
        el.onActivate(W(), el)
    end
end)
add(800, function()
    local KB = ZeD.Keyboard
    check(KB and KB.isVisible(), "A on the field: the pad keyboard opens")
    shot("10_pad_keyboard")
    if KB and KB.instance then
        field("skills").input:setText("carp")
        KB.instance:accept()   -- (what RT does)
    end
end)
add(800, function()
    local el = focusedEl()
    check(el and el.skillName == "Carpentry", "RT: the hand lands on the first match", el and el.id)
    shot("11_pad_landed")
    local f = ringEl("skills:find")
    if f then f.onContextMenu(W(), f) end   -- (X on the field)
end)
add(800, function()
    check(TF.text(W(), "skills") == "", "X on the field clears")
    local el = focusedEl()
    check(el and el.findField, "after X: the hand on the field", el and el.id)
    -- the Transcribe key (only with Skill Recovery Journal on and a Bound Journal carried)
    local key = nil
    for _, z in ipairs(W()._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if e.skillsStopId then key = e end end
    end
    if key then
        local top = nil
        for _, z in ipairs(W()._focusRing or {}) do
            for _, e in ipairs(z.elements or {}) do if e.skillName and e._findUpTo then top = e end end
        end
        check(top ~= nil and top._findUpTo == key.id, "Up from a top row goes to the Transcribe key")
        check(key._findUpTo == "skills:find", "Up from the Transcribe key goes to the field")
    else
        say("SKIP the Transcribe key's order: no Bound Journal (or the mod is off)")
    end
    Det.setLockedMode(nil)
end)

-- 7  closed and opened
add(500, function() CWm.toggleBothPaired(0) end)
add(1500, function() CWm.toggleBothPaired(0) end)
add(1500, function()
    tabTo("skills")
    check(TF.text(W(), "skills") == "" and TF.text(W(), "equip") == "", "a reopened window: both fields empty")
end)
add(800, function()
    local f = field("skills")
    check(f and f:getText() == "", "a reopened window: the field shows empty")
    shot("12_reopened")
    CWm.toggleBothPaired(0)
    say("fails " .. fails)
    say("DONE")
end)

local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
