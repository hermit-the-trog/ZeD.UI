-- ZeDUI/tools/qa/et_calls.lua  (Nov 25 2026, QA; tag et_calls): the director's 9 design calls for the Character
-- window's Equipment and Thermal tabs, as Build merged them (737da749a), each checked in the running game, by the mouse
-- and by the pad, at whatever screen size the runner uses. Run after zedqa_prelude.lua and rt_kit.lua (et_calls.txt).
-- grep "ZEDQA et_calls". Built the way lv_calls.lua, eq_tab.lua and th_tab.lua are (their helpers copied: each script
-- stands alone). Build's own unit sim for the same calls is et_calls_sim.lua (outside the game); this one runs against
-- real items and the real UI.
--
-- How it reads the tabs: the Thermal tab's draw pieces are wrapped for the thermal cases (th_tab's way: _renderHeader,
-- Atoms.drawSegFill, _renderCardGrid, Molecules.drawStatBarRow, _renderPicked, TabFill.block / row), so a check reads
-- what was DRAWN that frame; the Equipment drawer's drawText and drawTextureScaledAspect are wrapped for a few frames
-- where a check needs the words, colours and alphas drawn. The core is held through the game's TEMPERATURE stat every
-- player update (th_tab's hold), god mode off for the thermal cases (it keeps the moodles off) with hg_fit's guard on
-- every tick, intoxication held at 0 (drunk, the game holds Hypothermia 1 back). The expected values come from the
-- game's own API (moodle levels, the thermoregulator's node getters, getBodyLocation / canBeEquipped, HandWeapon,
-- isTwoHandWeapon, the hands, the hotbar); where a ZeD helper is the thing under test it is also compared to the game.
-- No controller is plugged into the QA PC: for the pad ZeD's input mode is locked to the controller and the presses go
-- through FocusManager's QA hook and its own dispatch (eq_tab's way); ZeD's menu is walked by its own joypad handlers.
-- A drop on the doll is handed to the doll's drop taker with the pointer answered over the box (eq_tab 5d's way).
--
-- Checks (case: what it asserts; PASS / FAIL with the values, SKIP only where the game cannot stage it, said why):
--   setup   both windows' pieces loaded; what is found recorded
--   1 core  the core held at 24.5, 25.5, 29.5, 30.5, 34.5, 35.5, 36.2, 36.8, 37.3, 37.8, 39.2 and 39.9 C until the
--           moodles settle: the meter drawn (lit count, colour) is Build's look for the GAME's moodle level (Hypothermia
--           4..1 lit 1..4, none 5, Hyperthermia 1..4 lit 7..10; Hypo 1 tempCool, Hypo 2-4 tempCold, Hyper 1 tempWarm,
--           Hyper 2-4 tempHot); green exactly when both moodles are 0; each level reached its own lit count; NOTE where
--           ZeD's coreLevel and the game's moodle differ; NOTE the game's cap at 40.0 C (Hyperthermia 3-4 unreachable)
--           and coreLevel / coreLook checked as plain calls at 40.5 and 41.5; pictures et_calls_core_<level>_<theme>_<w>x<h>
--           at Hypo 2, Hypo 1, none, Hyper 1, Hyper 2 in Dark, Light and High contrast (the meter takes each theme's token)
--   2 wet   the Wetness view with the body and garments held at 0, 0.10, 0.20, 0.50, 0.80 and 0.95: the figure's part,
--           its grid cell and both wetness rows of the picked block take the WET step's colour of the game's value (cuts
--           0.15 / 0.40 / 0.70 / 0.90: tempNorm, half way to tempCool, tempCool, half way to tempCold, tempCold); never
--           the hot red when soaked; ZeD's wetColor agrees with the step; pictures et_calls_wet_<dry|damp|soaked>_<theme>
--   3 unit  the views Body response, Blood vessels, Shivering, Insulation, Wind resistance and Wetness: for Upper Torso,
--           Head, Left Hand and Right Foot the grid cell and the picked block's row read the same "NN%", the game's UI
--           getter x 100; Skin temperature keeps degrees in both, in C and then in F (the display option switched)
--   4 word  at 0, 0.10, 0.20, 0.50, 0.80 and 0.95 the body wetness row's word is IGUI_Temp_Dry, Moodles_Wet_lvl1..4 by the
--           step (the clothing row by its own value); NOTE where the body's WET moodle differs from the part's step
--   5 wear  the character's clothes set aside (belt-givers and bags kept on), a spare hat, gloves, jacket, knife and
--           hammer carried, and a bag holding a second hat and a second knife. List: an empty row pressed and released
--           (HAT, GLV, OUT, PRI, SEC) opens the list of what fits: ZeD.EquipmentTab.lastWearMenu.key and .n, n the count
--           of fitting things carried (one per name, none on) worked out here from getBodyLocation / canBeEquipped and
--           HandWeapon; the menu's lines match; a pick wears it or puts the weapon in that hand; the hood rule (a hat on
--           a raised hood keeps the hoodie on); a slot nothing fits: n 0 and one grayed IGUI_None line. Doll: Head,
--           Outer, Main and Off the same. Pad: A on equipslot:<type> opens the same list, the D-pad walks it, A picks,
--           the focus back on the slot; B shuts it, the focus back on the slot. Double-click (two clicks inside
--           DOUBLE_MS): a worn list row and a doll box take it off (lastTakeOff set, no card after 0.4 s); a filled belt
--           row (the list) and a belt box (the doll) detach it. A single click opens the card only after DOUBLE_MS.
--           Pictures et_calls_wearmenu_list_<w>x<h>, et_calls_wearmenu_doll_<w>x<h>
--   6 belt  Held and Belt folded: every belt slot, filled and empty, has its row, as many as the hotbar's availableSlot
--   7 both  a two-handed weapon in both hands: the list's SEC row keeps it as bothHands and draws "<name> (both hands)"
--           dimmed with its icon at alpha 0.4; the doll's data.offBoth is set and its Off box draws the icon at 0.35;
--           with a one-handed weapon none of that. Pictures et_calls_bothhands_<list|doll>_<theme>_<w>x<h>
--   8 card  the game's rule (Build 5b73df5b0): a one-handed knife in the main hand shows UNEQUIP, OFF HAND, DROP, MORE;
--           OFF HAND moves it to the off hand (then UNEQUIP, DROP, MORE); a two-handed weapon in the main hand only shows
--           UNEQUIP, OFF HAND, TWO HANDS, DROP, MORE and TWO HANDS puts it in both (then UNEQUIP, OFF HAND, DROP, MORE);
--           by the mouse and by the pad; the fit passes use the two-handed weapon's five buttons; the 480 card and the 220 card at the text size found and
--           in Large text: every button inside the back bar, none over another or the close key; on the 220 card the
--           hand buttons sit before MORE or in More's menu. Pictures et_calls_card<480|220>_<textsize>_<w>x<h>
--   9 drop  a drop on the doll: a one-handed weapon on Main is the primary, a weapon on Off the secondary, a two-handed
--           weapon on Main takes both hands, an apple or a hat on a hand box does nothing and nothing is lost
--   each case no Lua error over it (and the Thermal tab's own error log); put back exactly
-- Puts back: the core (held at the found TEMPERATURE until it is back), the stats, the body's, its parts' and the
-- garments' wetness; god mode, invincible and the game speed; the clothes worn in their order, the hands, the belt's
-- own things on their slots (a slot lent given back); every thing the test made, and what the game made from them,
-- removed; the display unit, the theme, the text size, the Equip view (List / Doll), its folds and columns, the Thermal
-- view, pick and folds, the window's width cap and layout; the input lock and the pad focus; the pointer; the windows
-- and the tab; the character where he stood.
if not RT then print("ZEDQA et_calls ERR rt_kit.lua did not run first"); print("ZEDQA et_calls DONE"); return end
local Q = RT.make("et_calls")
Q.maxMs = 1500000                    -- (the runner gives this script 1800 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, madeSet = {}, caseMade = {}, keptSet = {}, sp = {},
            errs = 0, shots = {}, rec = {}, renders = 0, tabErrs = 0, live = false, keeping = false, t0 = getTimestampMs() }
S.F = RT.focus()

-- ===================================================================== constants
function S.set(t) local s = {}; for _, v in ipairs(t) do s[v] = true end; return s end
S.KIND = {
    hat = { "Base.Hat_Beany", "Base.Hat_BaseballCap" }, hat2 = { "Base.Hat_BaseballCap", "Base.Hat_Beany" },
    gloves = { "Base.Gloves_LeatherGloves" }, jacket = { "Base.Jacket_Black", "Base.Jacket_Padded" },
    knife = { "Base.HuntingKnife", "Base.KitchenKnife" }, hammer = { "Base.Hammer" },
    two = { "Base.Sledgehammer", "Base.Axe", "Base.WoodAxe", "Base.Shovel" },
    bag = { "Base.Bag_Schoolbag" }, hoodieUp = { "Base.HoodieUP_WhiteTINT" }, apple = { "Base.Apple" },
}
S.THEMES = { { key = "dark", word = "Dark" }, { key = "light", word = "Light" }, { key = "hicon", word = "High contrast" } }
S.GROUPS = { "head", "torso", "arms", "legs", "held" }
S.PARTS = {
    { bp = "Head", name = "Head" }, { bp = "Neck", name = "Neck" }, { bp = "Torso_Upper", name = "Upper Torso" },
    { bp = "Torso_Lower", name = "Lower Torso" }, { bp = "Groin", name = "Groin" },
    { bp = "UpperArm_L", name = "Left Upper Arm" }, { bp = "UpperArm_R", name = "Right Upper Arm" },
    { bp = "ForeArm_L", name = "Left Forearm" }, { bp = "ForeArm_R", name = "Right Forearm" },
    { bp = "Hand_L", name = "Left Hand" }, { bp = "Hand_R", name = "Right Hand" },
    { bp = "UpperLeg_L", name = "Left Upper Leg" }, { bp = "UpperLeg_R", name = "Right Upper Leg" },
    { bp = "LowerLeg_L", name = "Left Lower Leg" }, { bp = "LowerLeg_R", name = "Right Lower Leg" },
    { bp = "Foot_L", name = "Left Foot" }, { bp = "Foot_R", name = "Right Foot" },
}
-- the seven views in ThermalTab's order, their UI getters (the picked block's rows 1..7 read the same getters)
S.VIEWS = {
    { id = "skinTemp", ui = "getSkinCelciusUI" }, { id = "response", ui = "getBodyResponseUI" },
    { id = "vessels", ui = "getPrimaryDeltaUI" }, { id = "shiver", ui = "getSecondaryDeltaUI" },
    { id = "insul", ui = "getInsulationUI" }, { id = "wind", ui = "getWindresistUI" }, { id = "wetness", ui = "getBodyWetnessUI" },
}
S.PCT_PARTS = { "Upper Torso", "Head", "Left Hand", "Right Foot" }
S.WPART = "Upper Torso"
-- the core points (shot: a picture tag at that point)
S.CORES = { { c = 24.5 }, { c = 25.5 }, { c = 29.5 }, { c = 30.5 }, { c = 34.5, shot = "hypo2" }, { c = 35.5 },
            { c = 36.2, shot = "hypo1" }, { c = 36.8, shot = "none" }, { c = 37.3 }, { c = 37.8, shot = "hyper1" },
            { c = 39.2, shot = "hyper2" }, { c = 39.9 } }
-- Build's table: the meter's lit segments by moodle level (Hypothermia negative)
S.CORE_LIT = { [-4] = 1, [-3] = 2, [-2] = 3, [-1] = 4, [0] = 5, [1] = 7, [2] = 8, [3] = 9, [4] = 10 }
S.WET_CUTS = { 0.15, 0.40, 0.70, 0.90 }
S.WETS = { { v = 0, lab = "dry", key = "IGUI_Temp_Dry", shot = "dry" }, { v = 0.10, lab = "0.10", key = "IGUI_Temp_Dry" },
           { v = 0.20, lab = "0.20", key = "Moodles_Wet_lvl1", shot = "damp" }, { v = 0.50, lab = "0.50", key = "Moodles_Wet_lvl2" },
           { v = 0.80, lab = "0.80", key = "Moodles_Wet_lvl3" }, { v = 0.95, lab = "0.95", key = "Moodles_Wet_lvl4", shot = "soaked" } }
-- where each body location shows (the game's location ids, lower case, no underscores): the list's rows ...
S.OUT_LOCS = { "jacket", "jacketdown", "jacketbulky", "jacketsuit", "boilersuit", "fullsuit", "fulltop", "bathrobe", "fullrobe",
               "bodycostume", "sweater", "jersey", "sweaterhat", "jackethat", "jackethatbulky" }
S.LIST_LOCS = {
    HAT = S.set({ "hat", "fullhat", "fullsuithead", "fullsuitheadscba" }), EYE = S.set({ "eyes", "lefteye", "righteye" }),
    MSK = S.set({ "mask", "maskeyes", "maskfull" }), EAR = S.set({ "ears", "eartop", "nose" }), OUT = S.set(S.OUT_LOCS),
    GLV = S.set({ "hands", "handsleft", "handsright" }), WCH = S.set({ "leftwrist", "rightwrist" }),
    ARM = S.set({ "leftarm", "rightarm", "forearmleft", "forearmright", "elbowleft", "elbowright" }),
    SHD = S.set({ "shoulderpadleft", "shoulderpadright", "sportshoulderpad", "sportshoulderpadontop" }),
    KNE = S.set({ "kneeleft", "kneeright", "calfleft", "calfright", "calflefttexture", "calfrighttexture", "thighleft", "thighright",
                  "gaiterleft", "gaiterright" }),
}
-- ... and the doll's big boxes (fold: the small slots' places that come back to the box with the bands folded)
S.DOLL_LOCS = {
    head = { big = S.set({ "hat", "fullhat", "fullsuithead", "fullsuitheadscba", "mask", "maskeyes", "maskfull" }), fold = S.set({ "ears", "eartop", "nose" }) },
    eyes = { big = S.set({ "eyes", "lefteye", "righteye" }), fold = {} },
    outer = { big = S.set({ "jacket", "jacketdown", "jacketbulky", "jacketsuit", "boilersuit", "fullsuit", "fulltop", "bathrobe", "fullrobe",
                            "bodycostume", "sweater", "jersey", "torsoextravest", "torsoextravestbullet", "cuirass", "sweaterhat", "jackethat",
                            "jackethatbulky", "vesttexture" }), fold = S.set({ "shoulderholster" }) },
}
S.NONE_LIST = { "MSK", "SHD", "EYE", "ARM", "KNE", "EAR", "WCH" }
S.NONE_DOLL = { "doll:eyes" }
-- (the game's rule, fixed by Build 5b73df5b0: TWO HANDS only for isTwoHandWeapon or RequiresEquippedBothHands; OFF HAND while in the main hand)
S.HANDVERBS = { main = { "UNEQUIP", "OFF HAND", "DROP", "MORE" }, off = { "UNEQUIP", "DROP", "MORE" },
                twomain = { "UNEQUIP", "OFF HAND", "TWO HANDS", "DROP", "MORE" },
                both = { "UNEQUIP", "OFF HAND", "DROP", "MORE" } }
S.STATE_VERBWORD = { main = "in the main hand", off = "in the off hand", twomain = "in the main hand (a two-handed weapon)", both = "in both hands" }
S.STATE_WORD = { main = "in the main hand", off = "in the off hand", both = "in both hands", none = "in no hand" }
S.DROPS = {
    { k = "knife", box = "main", want = "pri", lab = "a one-handed weapon dropped on the Main box goes to the main hand" },
    { k = "hammer", box = "off", want = "sec", lab = "a weapon dropped on the Off box goes to the off hand" },
    { k = "two", box = "main", want = "both", lab = "a two-handed weapon dropped on the Main box takes both hands" },
    { k = "apple", box = "main", want = "none", lab = "an apple (no weapon) dropped on the Main box does nothing, nothing lost" },
    { k = "hat", box = "off", want = "none", lab = "a hat (no weapon) dropped on the Off box does nothing, nothing lost" },
}

-- ===================================================================== small helpers (lv_calls', eq_tab's, th_tab's)
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.note(s) Q.say("NOTE " .. tostring(s)) end
function S.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function S.wait(n, max, cond, fn)
    Q.waitFor(n, max, function() if S.dead then return true end; return cond() end,
        function(ok) if S.dead then return end; fn(ok) end)
end
function S.noop() end
function S.waitIdle(n) Q.step(n, function() end) end
function S.n1(v) local x = tonumber(v); if x == nil then return "?" end; return string.format("%.1f", x) end
function S.n2(v) local x = tonumber(v); if x == nil then return "?" end; return string.format("%.2f", x) end
function S.num(s)
    if s == nil then return nil end
    local m = string.match(tostring(s), "%-?%d+%.?%d*")
    return m and tonumber(m) or nil
end
function S.inList(list, x) for _, v in ipairs(list or {}) do if v == x then return true end end; return false end
function S.idsText(t) local o = {}; for _, v in ipairs(t or {}) do o[#o + 1] = tostring(v) end; return (#o > 0) and table.concat(o, ", ") or "none" end
function S.near(a, b, e) return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= (e or 0.002) end
function S.sameC(a, b) return a ~= nil and b ~= nil and S.near(a.r, b.r) and S.near(a.g, b.g) and S.near(a.b, b.b) end
function S.cText(c) return c and string.format("%.2f,%.2f,%.2f", c.r or -1, c.g or -1, c.b or -1) or "none" end
function S.clamp01(v) v = tonumber(v) or 0; if v < 0 then return 0 end; if v > 1 then return 1 end; return v end
function S.copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = v end
    return o
end
function S.screen()
    local w, h = 0, 0
    pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end)
    return math.floor(w), math.floor(h)
end
function S.sizeTag() local w, h = S.screen(); return w .. "x" .. h end
function S.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function S.setOpt(o, v) if o and v ~= nil then pcall(function() o:setValue(v) end) end end
function S.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function S.instant(on) pcall(function() S.p:setTimedActionInstantCheat(on and true or false) end) end
function S.speed(n)
    if n == nil then return end
    local f = ZEDQA_SPEED or setGameSpeed
    if f then pcall(f, n) end
end
function S.gameSpeed() local v = nil; pcall(function() v = getGameSpeed() end); return v end
function S.goTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z)
    end)
end
function S.withGlobals(over, fn)
    local was = {}
    for k, v in pairs(over) do was[k] = _G[k]; _G[k] = v end
    local ok, err = pcall(fn)
    for k, v in pairs(was) do _G[k] = v end
    return ok, err
end
function S.withFields(list, fn)
    local saved = {}
    for _, e in ipairs(list) do saved[#saved + 1] = { e[1], e[2], rawget(e[1], e[2]) }; e[1][e[2]] = e[3] end
    local ok, err = pcall(fn)
    for i = #saved, 1, -1 do local s = saved[i]; s[1][s[2]] = s[3] end
    return ok, err
end
function S.findField(el, key, depth)
    if type(el) ~= "table" or depth > 8 then return nil end
    if el[key] ~= nil then return el[key] end
    for _, ch in pairs(el.children or {}) do
        local r = S.findField(ch, key, depth + 1)
        if r ~= nil then return r end
    end
    return nil
end
function S.textMatch(s, exp)
    s, exp = tostring(s), tostring(exp)
    if s == exp then return true end
    if #s > 3 and string.sub(s, -3) == "..." then return string.sub(exp, 1, #s - 3) == string.sub(s, 1, #s - 3) end
    return false
end

-- ===================================================================== things (lv_calls' and eq_tab's)
function S.list(inv)
    local out = {}
    if inv == nil then return out end
    pcall(function()
        local it = inv:getItems()
        for i = 0, it:size() - 1 do out[#out + 1] = it:get(i) end
    end)
    return out
end
function S.inv() return S.p:getInventory() end
function S.where(it) local c = nil; if it then pcall(function() c = it:getContainer() end) end; return c end
function S.ft(it) local s = "?"; if it then pcall(function() s = tostring(it:getFullType()) end) end; return s end
function S.nm(it) local s = "nothing"; if it then pcall(function() s = tostring(it:getDisplayName()) end) end; return s end
function S.onFloor(it) local wo = nil; if it then pcall(function() wo = it:getWorldItem() end) end; return wo ~= nil end
function S.queueLen()
    local q = nil
    pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end)
    return (q and q.queue and #q.queue) or 0
end
function S.queueEmpty() return S.queueLen() == 0 end
function S.settled(k)
    local st = { n = 0 }
    return function()
        if S.queueEmpty() then st.n = st.n + 1 else st.n = 0 end
        return st.n >= (k or 8)
    end
end
function S.known(ft)
    local ok = false
    if ft then pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end) end
    return ok
end
function S.firstKnown(list) for _, ft in ipairs(list or {}) do if S.known(ft) then return ft end end; return nil end
function S.kind(k) return S.firstKnown(S.KIND[k]) end
function S.normLoc(loc)
    local ls = string.lower(tostring(loc))
    local c = string.find(ls, ":", 1, true)
    if c then ls = string.sub(ls, c + 1) end
    return (string.gsub(ls, "_", ""))
end
function S.loose(it)
    if not it then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() S.p:removeWornItem(it) end)
    pcall(function()
        local hb = getPlayerHotbar(S.pn)
        if hb and hb:isInHotbar(it) then hb:removeItem(it, false) end
    end)
    pcall(function()
        if (it:getAttachedSlot() or -1) > -1 then
            S.p:removeAttachedItem(it)
            it:setAttachedSlot(-1)
            it:setAttachedSlotType(nil)
            it:setAttachedToModel(nil)
        end
    end)
end
function S.removeItem(it)
    if not it then return end
    S.loose(it)
    pcall(function()
        local wo = it:getWorldItem()
        if wo then
            local sq = wo:getSquare()
            if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            pcall(function() it:setWorldItem(nil) end)
        end
    end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
function S.put(it, inv)
    if not (it and inv) then return end
    if S.where(it) == inv and not S.onFloor(it) then return end
    S.removeItem(it)
    pcall(function() inv:AddItem(it) end)
end
-- a thing the test made: the whole run's (keep) or the case's
function S.mark(it, keep)
    if not it then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.made[#S.made + 1] = it
    S.madeSet[it] = true
    if not keep then S.caseMade[#S.caseMade + 1] = it end
    return it
end
function S.give(ft, keep) if not ft then return nil end; local it = RT.give(ft); return S.mark(it, keep) end
function S.make(k) return S.give(S.kind(k)) end
-- a spare with a name of its own (the lists pick by name, one per name)
function S.named(it, name)
    if not it then return nil end
    pcall(function() it:setName(name) end)
    pcall(function() it:setCustomName(true) end)
    return it
end
function S.addTo(inv, ft)
    local it = nil
    if inv and ft then pcall(function() it = inv:AddItem(ft) end) end
    return S.mark(it, true)
end

-- ===================================================================== the clothes and the hands (eq_tab's)
function S.wornList()
    local out = {}
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do
            local w = wi:get(i)
            out[#out + 1] = { loc = w:getLocation(), item = w:getItem() }
        end
    end)
    return out
end
function S.wornSet() local set = {}; for _, e in ipairs(S.wornList()) do set[e.item] = true end; return set end
function S.isWorn(it)
    if not it then return false end
    local w = false
    pcall(function() w = S.p:isEquippedClothing(it) end)
    return w and true or false
end
function S.isClothing(it) local ok = false; if it then pcall(function() ok = instanceof(it, "Clothing") end) end; return ok end
function S.wornClothes() local out = {}; for _, e in ipairs(S.wornList()) do if S.isClothing(e.item) then out[#out + 1] = e.item end end; return out end
function S.locOf(it)
    local loc = nil
    pcall(function() loc = it:getBodyLocation() end)
    if loc == nil or tostring(loc) == "" then loc = nil; pcall(function() loc = it:canBeEquipped() end) end
    if loc ~= nil and tostring(loc) == "" then loc = nil end
    return loc
end
function S.wearIt(it)
    if not it then return false end
    local loc = S.locOf(it)
    if loc then pcall(function() S.p:setWornItem(loc, it) end) end
    return S.isWorn(it)
end
function S.unwear(it)
    if not it then return end
    pcall(function() S.p:removeWornItem(it) end)
    if S.isWorn(it) then pcall(function() S.p:removeWornItem(it, false) end) end
end
-- a worn thing kept on for the run: it gives belt slots, or it is a bag
function S.keeps(it)
    local k = false
    pcall(function() local ap = it:getAttachmentsProvided(); k = ap ~= nil and ap:size() > 0 end)
    if not k then pcall(function() k = it:IsInventoryContainer() == true end) end
    return k
end
function S.keptBack()
    for _, e in ipairs(S.found.kept or {}) do
        if not S.isWorn(e.item) and S.where(e.item) == S.inv() then pcall(function() S.p:setWornItem(e.loc, e.item) end) end
    end
end
function S.eqDirty()
    local w = RT.cw()
    if not w then return end
    w._equipCache = nil
    w._equipProtCache = nil
    w._equipDollTimer = 99
    w._equipDollStale = true
end
function S.wornEvent()
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
    pcall(function() S.p:resetModelNextFrame() end)
    S.eqDirty()
end
function S.clothesChanged() pcall(function() triggerEvent("OnClothingUpdated", S.p) end); pcall(function() S.p:resetModelNextFrame() end) end
function S.wornOfType(prefix)
    local out = {}
    for _, e in ipairs(S.wornList()) do
        local ft = S.ft(e.item)
        if string.sub(ft, 1, #prefix) == prefix then out[#out + 1] = ft end
    end
    return out
end
function S.handsSet(p, s)
    pcall(function() S.p:setPrimaryHandItem(p) end)
    pcall(function() S.p:setSecondaryHandItem(s) end)
    S.eqDirty()
end
function S.handState(it)
    local p, s = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    if p == it and s == it then return "both" elseif p == it then return "main" elseif s == it then return "off" end
    return "none"
end
-- what the game made from the test's things (a lowered hoodie): anything new in the main inventory the test did not make
function S.sweepNew()
    local f = S.found
    if not f.inv0 then return end
    for _, it in ipairs(S.list(S.inv())) do
        if not f.inv0[it] and not S.madeSet[it] then S.removeItem(it) end
    end
end

-- ===================================================================== the belt (eq_tab's)
function S.hb() local hb = nil; pcall(function() hb = getPlayerHotbar(S.pn) end); return hb end
function S.bslots() local s = nil; pcall(function() s = ZeD.Belt.slots(S.pn) end); return s or {} end
function S.slotOf(it) local s = -1; if it then pcall(function() s = it:getAttachedSlot() end) end; return s or -1 end
function S.hbSnap()
    local out = {}
    local hb = S.hb()
    for i, it in pairs((hb and hb.attachedItems) or {}) do
        local st, model = nil, nil
        pcall(function() st = hb.availableSlot[i].slotType end)
        pcall(function() model = it:getAttachedToModel() end)
        out[#out + 1] = { item = it, i = i, slotType = st, model = model }
    end
    return out
end
function S.hbBack()
    local hb = S.hb()
    if not hb then return end
    pcall(function() hb:refresh() end)
    for _, e in ipairs(S.found.hb or {}) do
        local on = false
        pcall(function() on = hb:isInHotbar(e.item) end)
        if not on and S.where(e.item) == S.inv() and e.slotType then
            local i = nil
            pcall(function() i = hb:getThisSlotIndex(e.slotType) end)
            local slot = i and hb.availableSlot and hb.availableSlot[i]
            if slot then
                local model = nil
                pcall(function() model = slot.def.attachments[e.item:getAttachmentType()] end)
                model = model or e.model
                pcall(function() hb:attachItem(e.item, model, i, slot.def, false) end)
            end
        end
    end
end
function S.emptyFor(it)
    if not it then return nil end
    local hb = S.hb()
    for _, s in ipairs(S.bslots()) do
        local fits = false
        pcall(function() fits = ZeD.Belt.fits(hb, s.i, it) end)
        if not s.item and fits then return s.i end
    end
    return nil
end
-- the first empty slot that takes it, else a slot lent for the case (its own thing off into the bag, hbBack at the clean)
function S.emptyOrLend(it, what)
    local i = S.emptyFor(it)
    if i or not it then return i end
    local hb = S.hb()
    if not (hb and hb.availableSlot and hb.attachedItems) then return nil end
    for j, slot in pairs(hb.availableSlot) do
        local old = hb.attachedItems[j]
        local okA, can = pcall(function() return hb:canBeAttached(slot, it) end)
        if old and old ~= it and okA and can then
            pcall(function() hb:removeItem(old, false) end)
            pcall(function() hb:refresh() end)
            local on = true
            pcall(function() on = hb:isInHotbar(old) end)
            if not on then
                S.note(tostring(what) .. ": belt slot " .. tostring(j) .. " lent for the case (its " .. S.nm(old) .. " off into the bag, back at the end)")
                return j
            end
        end
    end
    return nil
end

-- ===================================================================== the menu (lv_calls')
function S.menu()
    local m = nil
    pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end)
    return m
end
function S.menuUp()
    if S.menu() then return true end
    local up = false
    pcall(function() local c = getPlayerContextMenu(S.pn); up = c ~= nil and c:getIsVisible() and #(c.options or {}) > 0 end)
    return up and true or false
end
function S.closeMenu()
    local m = S.menu()
    if m then pcall(function() m:close() end) end
    pcall(function() local v = getPlayerContextMenu(S.pn); if v then v:hideAndChildren() end end)
end
function S.same(a, b) return a == b or string.lower(tostring(a)) == string.lower(tostring(b)) end
function S.pick(m, names)
    if not m then return false, "no menu" end
    if m._levels then
        for depth, nm in ipairs(names) do
            local lv = m._levels[depth]
            if not lv then return false, "no level " .. depth end
            local ri = nil
            for k, r in ipairs(lv.rows or {}) do if r.def and not ri and S.same(r.def.name, nm) then ri = k end end
            if not ri then return false, "no row " .. tostring(nm) end
            lv.sel = ri
            m:confirm(depth)
        end
        return true, "picked"
    end
    for _, nm in ipairs(names) do
        local items = m._ctx.items or m:_currentItems()
        local idx = nil
        for i, d in ipairs(items) do if not idx and d and S.same(d.name, nm) then idx = i end end
        if not idx then return false, "no cell " .. tostring(nm) end
        m._ctx.selected = idx
        m:confirm()
    end
    return true, "picked"
end
function S.pickOpt(name)
    local m = S.menu()
    if m then
        local ok, why = false, "the pick threw"
        pcall(function() ok, why = S.pick(m, { name }) end)
        if ok then return true, why .. " (ZeD's menu)" end
    end
    local done, why = false, "no option " .. tostring(name)
    pcall(function()
        local c = getPlayerContextMenu(S.pn)
        for _, o in ipairs(c.options or {}) do
            if not done and S.same(o.name, name) and o.onSelect then
                o.onSelect(o.target, o.param1, o.param2, o.param3, o.param4)
                done, why = true, "picked (the game's option)"
            end
        end
    end)
    return done, why
end
function S.menuNames(m)
    local out = {}
    local function walk(defs)
        for _, d in ipairs(defs or {}) do
            out[#out + 1] = tostring(d.name)
            if d.children then walk(d.children) end
        end
    end
    walk(m and m._ctx and m._ctx.actions)
    pcall(function()
        local c = getPlayerContextMenu(S.pn)
        for _, o in ipairs(c.options or {}) do out[#out + 1] = tostring(o.name) end
    end)
    return out
end
-- the game's menu's own lines (the list openWearMenu built): count, names, the lone grayed None
function S.vanLines()
    local r = { count = 0, names = {}, noneGray = false }
    pcall(function()
        local c = getPlayerContextMenu(S.pn)
        local n = (c.numOptions or (#(c.options or {}) + 1)) - 1
        for i = 1, n do
            local o = c.options[i]
            if o and not o.isDefaultOption then
                r.count = r.count + 1
                r.names[#r.names + 1] = tostring(o.name) .. (o.notAvailable and " (grayed)" or "")
                if r.count == 1 then r.first = o end
            end
        end
    end)
    r.noneGray = r.count == 1 and r.first ~= nil and tostring(r.first.name) == getText("IGUI_None") and r.first.notAvailable == true
    return r
end
-- the row ZeD's menu has selected (its list look or its strip look)
function S.menuSel(m)
    if not m then return nil end
    local name = nil
    pcall(function()
        if m._levels then
            local lv = m._levels[#m._levels]
            local r = lv and lv.sel and lv.rows[lv.sel]
            name = r and r.def and r.def.name
        else
            local items = m._ctx.items or m:_currentItems()
            local d = items and m._ctx.selected and items[m._ctx.selected]
            name = d and d.name
        end
    end)
    return name
end
-- the pad's walk: ZeD's menu stepped by its own D-pad handler to the row, then its A
function S.padPick(name)
    local m = S.menu()
    if not m then return false, "ZeD's menu is not up (the pad walks ZeD's menu)" end
    local k = 0
    while k < 40 and not S.same(S.menuSel(m), name) do
        local ok = pcall(function() m:onJoypadDirDown() end)
        if not ok then return false, "the D-pad step threw" end
        k = k + 1
    end
    if not S.same(S.menuSel(m), name) then return false, "the D-pad never reached " .. tostring(name) .. " (on " .. tostring(S.menuSel(m)) .. ")" end
    local ok, err = pcall(function() m:onJoypadDown(Joypad.AButton) end)
    if not ok then S.errs = S.errs + 1; return false, "A threw: " .. tostring(err) end
    return true, "walked " .. k .. " steps down, then A"
end

-- ===================================================================== pictures (lv_calls'; a name may be a function)
function S.park(on)
    if on then
        if not S.parked then
            S.parked = { mx = getMouseX, my = getMouseY }
            getMouseX = function() return -9000 end
            getMouseY = function() return -9000 end
        end
        pcall(function() Mouse.setCursorVisible(false) end)
        return
    end
    if S.parked then
        getMouseX, getMouseY = S.parked.mx, S.parked.my
        S.parked = nil
        pcall(function() Mouse.setCursorVisible(true) end)
    end
end
function S.shot(name, what, gate)
    local st = {}
    Q.step(1, function()
        if S.dead then return end
        if gate and not gate() then st.off = true; return end
        st.mine = S.parked == nil
        S.park(true)
    end)
    Q.step(4, function()
        if st.off then return end
        if S.dead then if st.mine then S.park(false) end; return end
        local nm = (type(name) == "function") and name() or name
        local file = tostring(nm) .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then S.shots[#S.shots + 1] = file; Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. tostring(what))
        else Q.say("NOTE the picture " .. tostring(nm) .. " was not taken: " .. tostring(e)) end
        if st.mine then S.park(false) end
    end)
    Q.waitMs(1500)
end
function S.caseEnd(label)
    Q.step(1, function()
        if S.dead then return end
        S.cancelDrags()
        S.closeMenu()
        local e1 = S.errN()
        local te = S.tabErrs - (S.te0 or 0)
        Q.check((S.e0 == nil or e1 == nil or e1 == S.e0) and te == 0, label .. ": no Lua error over the case",
            ((S.e0 and e1) and ((e1 - S.e0) .. " new") or "the count cannot be read") .. ", the Thermal tab's own " .. te
            .. (te > 0 and (" (" .. tostring(S.tabErrLast) .. ")") or ""))
        S.e0 = e1
        S.te0 = S.tabErrs
    end)
end

-- ===================================================================== the theme and the text size (lv_calls')
function S.theme(key)
    local o = S.zopt("baseTheme")
    local i = nil
    for k, v in ipairs(ZeD.Settings.baseKeys or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, key, nil, nil)
    S.back.theme = true
end
function S.themeBack()
    if not S.back.theme then return end
    S.back.theme = nil
    local o = S.zopt("baseTheme")
    if o and S.found.baseIdx then pcall(function() o:setValue(S.found.baseIdx) end) end
    pcall(ZeD.applyTheme, S.found.base, nil, nil)
end
function S.sizeSet(key)
    local o = S.zopt("textSize")
    local i = nil
    for k, v in ipairs(ZeD.Settings.sizeKeys or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, nil, nil, key)
    S.back.size = true
end
function S.sizeBack()
    if not S.back.size then return end
    S.back.size = nil
    local f = S.found
    local o = S.zopt("textSize")
    if o and f.sizeIdx then pcall(function() o:setValue(f.sizeIdx) end) end
    pcall(ZeD.applyTheme, nil, nil, f.size)
end

-- ===================================================================== the pad (eq_tab's)
function S.lockFound()
    local key = nil
    pcall(function()
        local o = S.zopt("inputModeLock")
        local keys = ZeD.Settings.inputLockKeys
        if o and keys then key = keys[o:getValue() or 1] end
    end)
    if key == nil then pcall(function() local md = S.p:getModData().ZeD_Gamepad; key = md and md.inputModeLock end) end
    return key or "auto"
end
function S.padOn()
    local Det = ZeD.Input and ZeD.Input.Detector
    if not (Det and Det.setLockedMode) then return false end
    if S.lockWas == nil then S.lockWas = S.lockFound() end
    pcall(Det.setLockedMode, "gamepad")
    S.back.pad = true
    local w = RT.cw()
    if w and S.F and S.F.claimFocus then pcall(S.F.claimFocus, w) end
    return true
end
function S.padOff()
    if not S.back.pad then return end
    S.back.pad = nil
    for _, b in ipairs({ "A", "B", "X", "Y", "LeftBump", "RightBump" }) do RT.pad(b, nil) end
    local Det = ZeD.Input and ZeD.Input.Detector
    pcall(function()
        Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then Det.setLockedMode(S.lockWas) end
    end)
end
function S.focused(w)
    local z, el = nil, nil
    pcall(function() z = S.F.getFocusedZone(w); el = S.F.getFocusedElement(w) end)
    return z, el
end
function S.focusedId() local _, el = S.focused(RT.cw()); return el and el.id or nil end
function S.focusEl(id)
    local w = RT.cw()
    if not (w and S.F and S.F.focusWhere and id) then return false end
    pcall(S.F.claimFocus, w)
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "charTabContent", function(el) return el.id == id end) end)
    return e ~= nil
end
function S.tap(name, joy, gate)
    local st = {}
    S.step(1, function()
        local w = RT.cw()
        if not w then return end
        if gate and not gate() then return end
        st.on = true
        RT.pad(name, true)
        if joy then RT.padDown(Joypad[joy], w) end
    end)
    S.step(4, function() if st.on then RT.pad(name, false) end end)
    S.step(4, function() if st.on then RT.pad(name, nil) end end)
end
function S.tapA(gate) S.tap("A", "AButton", gate) end

-- ===================================================================== the Equip tab (eq_tab's)
function S.dp() local w = RT.cw(); return w and w._drawerPanel end
function S.ep() local w = RT.cw(); return w and (w._equipPanel or w._drawerPanel) end
function S.ecard()
    local p = S.ep()
    local c = p and p._equipCard
    if c then return c end
    local w = RT.cw()
    return w and S.findField(w, "_equipCard", 0) or nil
end
function S.cardItem()
    local w, c = RT.cw(), S.ecard()
    if not (w and w._equipSelected and c) then return nil end
    local vis = false
    pcall(function() vis = c:isVisible() end)
    return vis and c.item or nil
end
function S.cardOn(item) local ci = S.cardItem(); return ci ~= nil and (item == nil or ci == item) end
function S.cardClose() local w = RT.cw(); if w then w._equipSelected = nil; w._equipClickWait = nil end end
function S.cardVerbIdx(id)
    local c = S.ecard()
    for i, v in ipairs((c and c._lastHeaderVerbs) or {}) do if v.id == id then return i, v end end
    return nil, nil
end
function S.cardIdList()
    local out = {}
    local c = S.ecard()
    for _, v in ipairs((c and c._lastHeaderVerbs) or {}) do out[#out + 1] = tostring(v.id) end
    return out
end
-- a click on the card's verb, as the card's pointer poll takes it: the button down over the verb, then up
function S.cardClick(id)
    local c = S.ecard()
    local i = S.cardVerbIdx(id)
    local r = i and c._backBarRects and c._backBarRects.verbs and c._backBarRects.verbs[i]
    if not r then return false, "no " .. tostring(id) .. " on the card (" .. S.idsText(S.cardIdList()) .. ")" end
    local x, y = c:getAbsoluteX() + r.x + math.floor(r.w / 2), c:getAbsoluteY() + r.y + math.floor(r.h / 2)
    local mx, my = function() return x end, function() return y end
    local ok1, e1 = S.withGlobals({ getMouseX = mx, getMouseY = my, isMouseButtonDown = function() return true end }, function() c:_pointer() end)
    local ok2, e2 = S.withGlobals({ getMouseX = mx, getMouseY = my, isMouseButtonDown = function() return false end }, function() c:_pointer() end)
    if not (ok1 and ok2) then S.errs = S.errs + 1; return false, "the press threw: " .. tostring(e1 or e2) end
    return true, "pressed " .. tostring(id)
end
function S.focusVerb(id)
    local i = S.cardVerbIdx(id)
    if not i then return false end
    return S.focusEl("equipcard:hverb_" .. i)
end
function S.slotZone(item)
    local w = RT.cw()
    if not item then return nil end
    for _, z in ipairs((w and w._equipSlotZones) or {}) do if z.item == item then return z end end
    return nil
end
function S.zoneT(ty)
    local w = RT.cw()
    for _, z in ipairs((w and w._equipSlotZones) or {}) do if z.type == ty then return z end end
    return nil
end
function S.beltZone(i)
    local w = RT.cw()
    for _, z in ipairs((w and w._equipBeltZones) or {}) do if z.i == i then return z end end
    return nil
end
function S.rect(id)
    local w = RT.cw()
    for _, r in ipairs((w and w._equipDollAll) or {}) do if r.id == id then return r end end
    return nil
end
-- an empty slot's zone: a list row (_equipListEmpty) or a doll box (_equipDollEmpty)
function S.emptyZone(key)
    local w = RT.cw()
    if not w then return nil end
    for _, l in ipairs({ w._equipListEmpty or {}, w._equipDollEmpty or {} }) do
        for _, z in ipairs(l) do if z.type == key then return z end end
    end
    return nil
end
function S.mid(z) return z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2) end
function S.clickAt(x, y)
    local dp = S.dp()
    if not dp then return false, "no drawer" end
    local ok, e = pcall(function() dp:onMouseDown(x, y); dp:onMouseUp(x, y) end)
    if not ok then S.errs = S.errs + 1 end
    return ok, e
end
function S.clickZone(z) if not z then return false, "no zone" end; local x, y = S.mid(z); return S.clickAt(x, y) end
function S.cancelDrags()
    pcall(function() local w = RT.cw(); if w and w._equipDrag then w._equipDrag:cancel() end; if w then w._equipPress = nil; w._equipColDrag = nil; w._wearPress = nil end end)
    pcall(function() local dp = S.dp(); if dp then dp:setCapture(false) end end)
    pcall(function() ISMouseDrag.dragging = nil end)
end
function S.isHalf() local w = RT.cw(); return w ~= nil and math.abs((w._drawerEffW or 0) - ZeD.T.px(220)) <= 1 end
function S.isFull() local w = RT.cw(); return w ~= nil and math.abs((w._drawerEffW or 0) - ZeD.T.px(480)) <= 1 end
function S.eqReady(view)
    local w = RT.cw()
    if not (w and w._activeTab == "equip" and w._drawerOpen ~= false and w._equipDefenseZone ~= nil) then return false end
    if w._equipSelected then return false end
    if view == "doll" then return w._equipDollShown == true and w._equipDollAll ~= nil end
    return #(w._equipGroupZones or {}) > 0
end
-- queue: the Equip tab on its view, the list open, every group open, at the top, the drawer settled
function S.toEquip(view, T, label)
    S.step(2, function()
        if T.off then return end
        local w = RT.cw()
        if w then w._equipSelected = nil end
        if ZeD.EquipDoll.view() ~= view then pcall(ZeD.EquipDoll.setView, view) end
        RT.charTab("equip")
        w = RT.cw()
        if w then
            w._equipListExpanded = true
            w._equipExpanded = w._equipExpanded or {}
            for _, g in ipairs(S.GROUPS) do w._equipExpanded[g] = true end
            if w._equipScroll then pcall(function() w._equipScroll:setScrollPos(0) end) end
        end
        S.eqDirty()
        T.eqSt = { last = -1, n = 0 }
    end)
    S.wait(4, 600, function()
        if T.off then return true end
        if not S.eqReady(view) then return false end
        local e = math.floor(RT.cw()._drawerEffW or 0)
        if e == T.eqSt.last then T.eqSt.n = T.eqSt.n + 1 else T.eqSt.last, T.eqSt.n = e, 0 end
        return T.eqSt.n >= 4
    end, function(ok)
        if T.off then return end
        local w = RT.cw()
        if not Q.check(ok, label .. ": the Equipment tab shows its " .. view .. " view",
            "tab " .. tostring(w and w._activeTab) .. ", view " .. tostring(ZeD.EquipDoll.view()) .. ", drawer " .. tostring(w and math.floor(w._drawerEffW or 0))) then
            T.off = true
        end
    end)
end
-- every group folded but one (the held group near the top, on screen for the pictures)
function S.foldAllBut(keep)
    local w = RT.cw()
    if not w then return end
    w._equipExpanded = w._equipExpanded or {}
    for _, g in ipairs(S.GROUPS) do w._equipExpanded[g] = (g == keep) end
    if w._equipScroll then pcall(function() w._equipScroll:setScrollPos(0) end) end
    S.eqDirty()
end
-- queue: a row's card opened by the mouse (one click; the card waits DOUBLE_MS for a second, then opens)
function S.openRow(T, key, itemFn, label)
    S.step(2, function()
        T[key] = nil
        T[key .. "It"] = nil
        if T.off then return end
        S.cardClose()
        T[key .. "It"] = itemFn()
    end)
    S.wait(2, 90, function() return T.off or T[key .. "It"] == nil or S.slotZone(T[key .. "It"]) ~= nil end, function(ok)
        if T.off then return end
        local it = T[key .. "It"]
        if it == nil then T[key .. "Row"] = nil; return end
        T[key .. "Row"] = Q.check(ok, label .. ": the row of " .. S.nm(it) .. " is drawn on the tab")
        if T[key .. "Row"] then S.clickZone(S.slotZone(it)) end
    end)
    S.wait(2, 150, function() return T.off or not T[key .. "Row"] or S.cardOn(T[key .. "It"]) end, function(ok)
        if T.off or not T[key .. "Row"] then return end
        T[key] = Q.check(ok, label .. ": a click on its row opens its card (after DOUBLE_MS)", "the card shows " .. S.nm(S.cardItem()))
    end)
end
-- queue: a row's card opened by the pad (focus on its stop, A)
function S.openRowPad(T, key, itemFn, label)
    -- (the card shut first, and a few frames for the tab to draw its rows again: with a card open the pad's stops are
    -- the card's, so a row can't take the focus in the same frame the card shuts)
    S.step(2, function() if not T.off then S.cardClose() end end)
    S.waitIdle(8)
    S.step(2, function()
        T[key] = nil
        T[key .. "It"] = nil
        T[key .. "Row"] = nil
        if T.off then return end
        S.cardClose()
        local it = itemFn()
        T[key .. "It"] = it
        if it == nil then Q.skip(label, "the thing to open is not there"); return end
        local z = S.slotZone(it)
        T[key .. "Row"] = z ~= nil and S.padOn() and S.focusEl("equipslot:" .. tostring(z.type))
        Q.check(T[key .. "Row"], label .. ": the pad's focus lands on the row of " .. S.nm(it), "on " .. tostring(S.focusedId()))
    end)
    S.tapA(function() return T[key .. "Row"] end)
    S.wait(2, 120, function() return T.off or not T[key .. "Row"] or S.cardOn(T[key .. "It"]) end, function(ok)
        if T.off or not T[key .. "Row"] then return end
        T[key] = Q.check(ok, label .. ": A on its row opens its card", "the card shows " .. S.nm(S.cardItem()))
    end)
end
-- the half card brought about (eq_tab's): the window's width cap made too narrow for the full card
function S.halfOn(T)
    S.step(2, function()
        T.half = nil
        if T.off then return end
        local w = RT.cw()
        if not S.isHalf() and w then
            if S.back.maxW == nil then S.back.maxW = { v = w._maxWinW } end
            S.layoutTouched = true
            w._maxWinW = ZeD.T.px(620)
        end
        T.hs = { last = -1, n = 0 }
    end)
    S.wait(4, 900, function()
        if T.off then return true end
        local w = RT.cw()
        local e = math.floor((w and w._drawerEffW) or 0)
        if e == T.hs.last then T.hs.n = T.hs.n + 1 else T.hs.last, T.hs.n = e, 0 end
        return T.hs.n >= 6 and S.isHalf()
    end, function(ok)
        if T.off then return end
        T.half = ok
        if not ok then S.note("the half card could not be brought about here (the drawer is " .. math.floor(RT.cw()._drawerEffW or 0) .. " px)") end
    end)
end
function S.halfBack()
    if not S.back.maxW then return end
    local w = RT.cw()
    if w then w._maxWinW = S.back.maxW.v end
    S.back.maxW = nil
end
function S.halfOff(T)
    S.step(2, function() S.halfBack() end)
    S.wait(4, 900, function()
        local w = RT.cw()
        local e = math.floor((w and w._drawerEffW) or 0)
        T.hs2 = T.hs2 or { last = -1, n = 0 }
        if e == T.hs2.last then T.hs2.n = T.hs2.n + 1 else T.hs2.last, T.hs2.n = e, 0 end
        return T.hs2.n >= 6
    end, function() T.hs2 = nil end)
end
-- the drawer's draws watched for a few frames (words, their colour; icons, their alpha)
function S.spyOn()
    if S.spy then return end
    local p = S.ep()
    if not p then return end
    local sp = { p = p, ownT = rawget(p, "drawText"), ownX = rawget(p, "drawTextureScaledAspect"), texts = {}, texs = {} }
    sp.baseT, sp.baseX = p.drawText, p.drawTextureScaledAspect
    p.drawText = function(self, s, x, y, r, g, b, a, font)
        sp.texts[#sp.texts + 1] = { s = tostring(s), x = x, y = y, r = r, g = g, b = b, a = a }
        return sp.baseT(self, s, x, y, r, g, b, a, font)
    end
    p.drawTextureScaledAspect = function(self, tex, x, y, w, h, a, r, g, b)
        sp.texs[#sp.texs + 1] = { tex = tex, x = x, y = y, w = w, h = h, a = a }
        return sp.baseX(self, tex, x, y, w, h, a, r, g, b)
    end
    S.spy = sp
end
function S.spyOff()
    local sp = S.spy
    if not sp then return nil end
    S.spy = nil
    pcall(function() rawset(sp.p, "drawText", sp.ownT) end)
    pcall(function() rawset(sp.p, "drawTextureScaledAspect", sp.ownX) end)
    return sp
end
function S.inBand(list, y0, h)
    local out = {}
    if not y0 then return out end
    for _, e in ipairs(list or {}) do if e.y >= y0 - 1 and e.y < y0 + h then out[#out + 1] = e end end
    return out
end
function S.inBox(list, z)
    local out = {}
    if not z then return out end
    for _, e in ipairs(list or {}) do
        if e.x >= z.x - 1 and e.x <= z.x + z.w and e.y >= z.y - 1 and e.y <= z.y + z.h then out[#out + 1] = e end
    end
    return out
end
function S.alphaIn(texs, a) for _, t in ipairs(texs or {}) do if type(t.a) == "number" and math.abs(t.a - a) < 0.01 then return t end end; return nil end
function S.alphas(texs) local o = {}; for _, t in ipairs(texs or {}) do o[#o + 1] = S.n2(t.a) end; return S.idsText(o) end
function S.textsText(texts) local o = {}; for _, t in ipairs(texts or {}) do o[#o + 1] = "\"" .. t.s .. "\"" end; return S.idsText(o) end
function S.slotDef(data, ty)
    for _, g in ipairs((data and data.groups) or {}) do
        for _, s in ipairs(g.slots or {}) do if s.type == ty then return s end end
    end
    return nil
end

-- ===================================================================== what fits a slot, worked out from the game
-- (the item's body location by getBodyLocation, else canBeEquipped; a hand takes a HandWeapon not broken)
function S.wornLoc(it)
    local l = nil
    local cl = false
    pcall(function() cl = instanceof(it, "Clothing") or instanceof(it, "InventoryContainer") end)
    if cl then pcall(function() l = it:getBodyLocation() end) end
    if l == nil or tostring(l) == "" then l = nil; pcall(function() l = it:canBeEquipped() end) end
    if l == nil or tostring(l) == "" then return nil end
    return S.normLoc(l)
end
function S.isHandKey(key) return key == "PRI" or key == "SEC" or key == "doll:main" or key == "doll:off" end
function S.myFit(key, it, bands)
    if S.isHandKey(key) then
        local wp = false
        pcall(function() wp = instanceof(it, "HandWeapon") end)
        if not wp then return false end
        local c = 0
        pcall(function() c = it:getCondition() end)
        return (c or 0) > 0
    end
    local loc = S.wornLoc(it)
    if not loc then return false end
    if string.sub(key, 1, 5) == "doll:" then
        local d = S.DOLL_LOCS[string.sub(key, 6)]
        if not d then return false end
        return d.big[loc] == true or ((not bands) and d.fold[loc] == true)
    end
    local s = S.LIST_LOCS[key]
    return s ~= nil and s[loc] == true
end
-- on the character: in the main inventory and in a hand, worn or on the belt
function S.isOn(it)
    if S.where(it) ~= S.inv() then return false end
    if S.p:getPrimaryHandItem() == it or S.p:getSecondaryHandItem() == it then return true end
    local on = false
    pcall(function() on = S.p:getWornItems():contains(it) end)
    if on then return true end
    return S.slotOf(it) > -1
end
-- the fitting things carried (the main inventory and the bags in it), one per name, none on
function S.myCount(key, bands)
    local names, seen = {}, {}
    local function scan(inv, depth)
        for _, it in ipairs(S.list(inv)) do
            if not S.isOn(it) and S.myFit(key, it, bands) then
                local nm = S.nm(it)
                if not seen[nm] then seen[nm] = true; names[#names + 1] = nm end
            end
            local bag = false
            pcall(function() bag = instanceof(it, "InventoryContainer") end)
            if depth < 1 and bag then
                local sub = nil
                pcall(function() sub = it:getInventory() end)
                if sub then scan(sub, depth + 1) end
            end
        end
    end
    scan(S.inv(), 0)
    return #names, names
end

-- ===================================================================== Thermal: the body and the game's values (th_tab's)
function S.labelOf(name) local s = name; pcall(function() s = ZeD.partLabel(name) end); return tostring(s) end
function S.bpOf(name) for _, P in ipairs(S.PARTS) do if P.name == name then return P.bp end end; return nil end
function S.celsius() local c = true; pcall(function() c = ZeD.ThermalTab.useCelsius() end); return c end
function S.toUnit(c, cel) if type(c) ~= "number" then return nil end; if cel then return c end; return c * 9 / 5 + 32 end
function S.tol(cel) return cel and 0.15 or 0.27 end
function S.dispC() local v = nil; pcall(function() v = getCore():getOptionDisplayAsCelsius() end); return v end
function S.setDisp(b) pcall(function() getCore():setOptionDisplayAsCelsius(b and true or false) end) end
function S.bd() local b = nil; pcall(function() b = S.p:getBodyDamage() end); return b end
function S.thermo() local t = nil; pcall(function() t = S.p:getBodyDamage():getThermoregulator() end); return t end
function S.core() local v = nil; pcall(function() v = S.thermo():getCoreCelcius() end); return v end
function S.node(name)
    local bp = S.bpOf(name)
    local n = nil
    if bp and BodyPartType and BodyPartType[bp] then pcall(function() n = S.thermo():getNodeForType(BodyPartType[bp]) end) end
    return n
end
function S.nv(name, getter)
    local v = nil
    local n = S.node(name)
    if n then pcall(function() v = n[getter](n) end) end
    return v
end
function S.cs(k) return CharacterStat and CharacterStat[k] or nil end
function S.stat(k) local v = nil; local cs = S.cs(k); if cs then pcall(function() v = S.p:getStats():get(cs) end) end; return v end
function S.setStat(k, v) local cs = S.cs(k); if cs and v ~= nil then pcall(function() S.p:getStats():set(cs, v) end) end end
function S.statMax(k) local m = nil; local cs = S.cs(k); if cs then pcall(function() m = cs:getMaximumValue() end) end; return m or 100 end
function S.moodle(k)
    local n = 0
    if MoodleType and MoodleType[k] then pcall(function() n = S.p:getMoodles():getMoodleLevel(MoodleType[k]) end) end
    return n or 0
end
function S.bodyParts()
    local out = {}
    pcall(function() local ps = S.bd():getBodyParts(); for i = 0, ps:size() - 1 do out[#out + 1] = ps:get(i) end end)
    return out
end

-- ===================================================================== Thermal: the draw, recorded (th_tab's wrappers)
function S.wrapOn()
    if S.w0 then return end
    local TT, M, A, F = ZeD.ThermalTab, ZeD.Molecules, ZeD.Atoms, ZeD.TabFill
    S.w0 = { hdr = TT._renderHeader, grid = TT._renderCardGrid, picked = TT._renderPicked, seg = A.drawSegFill,
             bar = M.drawStatBarRow, block = F.block, row = F.row, log = ZeD.logOnce }
    local W = S.w0
    TT._renderHeader = function(panel, win, data, rx, ry, rw)
        local h = { data = data }
        S.rmode, S.rhdr = "header", h
        local ok, e = pcall(W.hdr, panel, win, data, rx, ry, rw)
        S.rmode = nil
        S.rec.header = h
        S.renders = S.renders + 1
        if not ok then error(e, 0) end
    end
    A.drawSegFill = function(panel, x, y, w, h, n, k, color)
        if S.rmode == "header" and S.rhdr and not S.rhdr.seg then S.rhdr.seg = { n = n, lit = k, color = color } end
        return W.seg(panel, x, y, w, h, n, k, color)
    end
    TT._renderCardGrid = function(panel, win, data, rx, ry, rw, rh)
        local g = { cells = {}, view = win and win._thermalView or nil }
        S.rmode, S.rgrid = "grid", g
        local ok, e = pcall(W.grid, panel, win, data, rx, ry, rw, rh)
        S.rmode = nil
        S.rec.grid = g
        if not ok then error(e, 0) end
    end
    M.drawStatBarRow = function(panel, x, y, w, value, label, fillRatio, fillColor, valueColor, flat)
        if S.rmode == "grid" and S.rgrid then
            local c = { value = value, label = label, color = fillColor and { r = fillColor.r, g = fillColor.g, b = fillColor.b } or nil }
            S.rgrid.cells[#S.rgrid.cells + 1] = c
        end
        return W.bar(panel, x, y, w, value, label, fillRatio, fillColor, valueColor, flat)
    end
    TT._renderPicked = function(panel, win, data, x, y, w)
        if not panel then return W.picked(panel, win, data, x, y, w) end
        local pk = { rows = {} }
        S.rmode, S.rpk = "picked", pk
        local ok, r = pcall(W.picked, panel, win, data, x, y, w)
        S.rmode = nil
        S.rec.picked = pk
        if not ok then error(r, 0) end
        return r
    end
    F.block = function(panel, win, key, block, x, y, w, label, count, rows, opts)
        if panel and key == "thermal" and S.rmode == "picked" and S.rpk then S.rpk.title = label end
        return W.block(panel, win, key, block, x, y, w, label, count, rows, opts)
    end
    F.row = function(panel, win, key, r, x, y, w, opts)
        if panel and key == "thermal" and S.rmode == "picked" and S.rpk then
            local bc = r.barColor
            S.rpk.rows[#S.rpk.rows + 1] = { label = r.label, value = r.value, word = r.word,
                color = bc and { r = bc.r, g = bc.g, b = bc.b } or nil }
        end
        return W.row(panel, win, key, r, x, y, w, opts)
    end
    -- (the Character window runs each tab's draw in a pcall and logs a throw once as "tab <id>": counted here)
    ZeD.logOnce = function(key, msg)
        if tostring(key) == "tab thermal" then S.tabErrs = S.tabErrs + 1; S.tabErrLast = tostring(msg) end
        return W.log(key, msg)
    end
end
function S.wrapOff()
    local W = S.w0
    if not W then return end
    local TT, M, A, F = ZeD.ThermalTab, ZeD.Molecules, ZeD.Atoms, ZeD.TabFill
    TT._renderHeader, TT._renderCardGrid, TT._renderPicked = W.hdr, W.grid, W.picked
    M.drawStatBarRow, A.drawSegFill = W.bar, W.seg
    F.block, F.row, ZeD.logOnce = W.block, W.row, W.log
    S.w0 = nil
    S.rmode = nil
end
function S.ask() S.reqAt = S.renders; local w = RT.cw(); if w then w._thermalCache = nil end end
function S.fresh() return S.reqAt ~= nil and S.renders >= S.reqAt + 2 end
function S.readThen(lab, fn)
    S.step(1, function() if not S.thOff then S.ask() end end)
    S.wait(1, 180, function() return S.thOff or S.fresh() end, function(ok)
        if S.thOff then return end
        if not ok then
            Q.check(false, lab .. ": the Thermal tab drew after a fresh read", "no draw in 180 frames; tab " .. tostring(RT.cw() and RT.cw()._activeTab))
            return
        end
        fn()
    end)
end
function S.cellOf(name)
    local g = S.rec.grid
    local l = S.labelOf(name)
    for _, c in ipairs(g and g.cells or {}) do if tostring(c.label) == l then return c end end
    return nil
end
-- the part the picked block shows (by its title): the pick, unless something pointed at another
function S.shownPart()
    local pk = S.rec.picked
    local t = pk and pk.title and tostring(pk.title)
    if not t then return nil end
    for _, P in ipairs(S.PARTS) do if S.labelOf(P.name) == t then return P.name end end
    return nil
end
function S.front()
    RT.pairOpen()
    local w = RT.cw()
    if not w then return end
    if w._activeTab ~= "thermal" then RT.charTab("thermal") end
    w._thermalFigureExpanded = true
    S.pickedFoldSet(false)
end
function S.setView(i)
    local w = RT.cw()
    if not w then return end
    pcall(ZeD.ThermalTab.closeMenu, w, i)
    w._thermalReturnToMenu = nil
end
function S.pickedFoldSet(v)
    local w = RT.cw()
    if not w then return end
    w._fill = w._fill or {}
    w._fill.thermal = w._fill.thermal or { zones = {}, last = {}, fold = {}, pool = {}, folds = {} }
    w._fill.thermal.fold = w._fill.thermal.fold or {}
    w._fill.thermal.fold.picked = v and true or nil
end
function S.pickedFolded() local w = RT.cw(); return (w and ZeD.TabFill.folded(w, "thermal", "picked")) and true or false end
function S.scroll(p) local w = RT.cw(); local s = w and w._thermalScroll; if s then pcall(function() s:setScrollPos(p) end) end end
function S.scrollPos() local w = RT.cw(); local s = w and w._thermalScroll; return s and s.scrollPos or 0 end

-- ===================================================================== Thermal: the hold (every player update) and the guard
function S.apply()
    local W = S.want
    if not W then return end
    if W.temp then S.setStat("TEMPERATURE", W.temp) end
    if W.intox then S.setStat("INTOXICATION", 0) end
    if W.wet ~= nil then
        S.setStat("WETNESS", W.wet * S.statMax("WETNESS"))
        for _, bp in ipairs(S.bodyParts()) do pcall(function() bp:setWetness(W.wet * 100) end) end
    end
    if W.cloth ~= nil then
        for _, it in ipairs(S.wornClothes()) do pcall(function() it:setWetness(W.cloth * 100) end) end
    end
end
function S.keep(pl) if S.want and pl == S.p then pcall(S.apply) end end
function S.stage(W)
    S.want = W
    S.apply()
    if not S.keeping then Events.OnPlayerUpdate.Add(S.keep); S.keeping = true end
end
function S.unstage()
    S.want = nil
    if S.keeping then Events.OnPlayerUpdate.Remove(S.keep); S.keeping = false end
end
function S.wetBack()
    local f = S.found
    if f.stats and f.stats.WETNESS ~= nil then S.setStat("WETNESS", f.stats.WETNESS) end
    for i, bp in ipairs(S.bodyParts()) do
        local v = f.partWet and f.partWet[i]
        if v ~= nil then pcall(function() bp:setWetness(v) end) end
    end
    for it, v in pairs(f.clothWet or {}) do pcall(function() it:setWetness(v) end) end
end
function S.wetDiff()
    local f = S.found
    local wb = {}
    for i, bp in ipairs(S.bodyParts()) do
        local v = nil
        pcall(function() v = bp:getWetness() end)
        if f.partWet and f.partWet[i] ~= nil and not S.near(v, f.partWet[i], 1) then wb[#wb + 1] = "part " .. i .. " " .. S.n1(v) .. " (was " .. S.n1(f.partWet[i]) .. ")" end
    end
    for it, v0 in pairs(f.clothWet or {}) do
        local v = nil
        pcall(function() v = it:getWetness() end)
        if not S.near(v, v0, 1) then wb[#wb + 1] = "a garment " .. S.n1(v) .. " (was " .. S.n1(v0) .. ")" end
    end
    local ws = S.stat("WETNESS")
    if f.stats and f.stats.WETNESS ~= nil and not S.near(ws, f.stats.WETNESS, 0.03 * S.statMax("WETNESS")) then
        wb[#wb + 1] = "the stat " .. S.n2(ws) .. " (was " .. S.n2(f.stats.WETNESS) .. ")"
    end
    return wb
end
function S.noInfection(bd)
    if not bd then return end
    local parts = bd:getBodyParts()
    for i = 0, parts:size() - 1 do
        local b = parts:get(i)
        if b:IsInfected() then b:SetInfected(false) end
        if b:IsFakeInfected() then b:SetFakeInfected(false) end
    end
    if bd:isInfected() then bd:setInfected(false) end
    if bd:isIsFakeInfected() then bd:setIsFakeInfected(false) end
end
function S.bail(why)
    if S.bailed then return end
    S.bailed = true
    S.dead = true
    Q.check(false, "the run went on to its end", "stopped, on to the put-back: " .. tostring(why))
    if Q.backAt and Q.qi < Q.backAt then Q.qi = Q.backAt; Q.wait = nil end
end
-- hg_fit's guard, every tick while the thermal cases run with god mode off
function S.guardTick()
    local p, bd = S.p, S.bd()
    if not bd then return end
    if p:isDead() then
        if not S.deadSaid then
            S.deadSaid = true
            Q.check(false, "the character is alive", "DEAD during the run: restore the QA save from its backup")
            S.bail("the character died")
        end
        return
    end
    if S.found.zInf == false then S.noInfection(bd) end
    local h = bd:getOverallBodyHealth()
    if h < 75 then
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do parts:get(i):SetHealth(100) end
        S.topUps = (S.topUps or 0) + 1
    end
    if h < 35 and not S.bailed then
        p:setGodMod(true)
        S.bail("health fell to " .. S.n1(h) .. ": god mode ON")
    end
end
function S.safety()
    if not S.live then return end
    local ok, err = pcall(S.guardTick)
    if not ok and not S.guardSaid then
        S.guardSaid = true
        Q.say("ERR the guard threw: " .. tostring(err))
        pcall(function() S.p:setGodMod(true) end)
        S.bail("the guard threw: god mode ON")
    end
end

-- ===================================================================== setup (what is found, for the put-back)
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.err0 = S.errN()
        S.e0, S.te0 = S.err0, 0
        f.pair = RT.isOpen()
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "et_calls") end
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        pcall(function() f.inst = S.p:isTimedActionInstantCheat() end)
        pcall(function() f.god = S.p:isGodMod() end)
        pcall(function() f.invc = S.p:isInvincible() end)
        f.speed = S.gameSpeed()
        f.hands = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
        f.worn = S.wornList()
        f.hb = S.hbSnap()
        f.inv0 = {}
        for _, it in ipairs(S.list(S.inv())) do f.inv0[it] = true end
        f.stats = {}
        for _, k in ipairs({ "TEMPERATURE", "WETNESS", "INTOXICATION", "ENDURANCE", "FATIGUE" }) do f.stats[k] = S.stat(k) end
        f.partWet = {}
        for i, bp in ipairs(S.bodyParts()) do pcall(function() f.partWet[i] = bp:getWetness() end) end
        f.clothWet = {}
        for _, it in ipairs(S.wornClothes()) do pcall(function() f.clothWet[it] = it:getWetness() end) end
        f.disp = S.dispC()
        f.base, f.baseIdx = ZeD.currentBase, S.optVal(S.zopt("baseTheme"))
        f.size, f.sizeIdx = ZeD.currentSize, S.optVal(S.zopt("textSize"))
        f.view = ZeD.EquipDoll and ZeD.EquipDoll.view() or "list"
        pcall(function() f.focusWin = S.F.getFocusedWindow(S.pn) end)
        f.lock = S.lockFound()
        f.zInf = false
        pcall(function() f.zInf = S.bd():isInfected() end)
        if ZEDQA_LAYOUT_SNAP and f.pair then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        f.recorded = true
        S.back.on = true
        RT.pairOpen()
        S.instant(true)
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", core " .. S.n2(S.core()) .. " C, intoxication "
            .. S.n2(f.stats.INTOXICATION) .. ", " .. #f.worn .. " worn, " .. #f.hb .. " on the belt, Equip view " .. tostring(f.view)
            .. ", theme " .. tostring(f.base) .. ", text " .. tostring(f.size) .. ", units " .. ((f.disp == false) and "F" or "C")
            .. ", god mode " .. tostring(f.god) .. ", input lock " .. f.lock .. ", screen " .. S.sizeTag())
    end)
    S.wait(10, 300, function() local w = RT.cw(); return w ~= nil and w._tabStripPanel ~= nil end, function(ok)
        local w = RT.cw()
        if not Q.check(ok and w ~= nil, "setup: the Character window is open") then S.dead = true; return end
        local f = S.found
        f.charTab = w._activeTab
        f.listExp, f.exp, f.colW = w._equipListExpanded, S.copy(w._equipExpanded), S.copy(w._equipColWidths)
        f.tview, f.tpick, f.tfold, f.thovered = w._thermalView, w._thermalPick, w._thermalFigureExpanded and true or false, w._thermalHoveredPart
        pcall(function() f.tpickedFold = S.pickedFolded() end)
        f.maxWinW = w._maxWinW
    end)
end

-- ===================================================================== the thermal cases' bookends
function S.thSetup()
    S.step(2, function()
        local TT = ZeD and ZeD.ThermalTab
        local ready = TT ~= nil and TT.coreLook ~= nil and TT.coreLevel ~= nil and TT.wetColor ~= nil and TT.wetWordKey ~= nil
            and TT._renderHeader ~= nil and TT._renderCardGrid ~= nil and TT._renderPicked ~= nil and TT.closeMenu ~= nil
            and ZeD.TabFill ~= nil and ZeD.TabFill.row ~= nil and ZeD.TabFill.block ~= nil and ZeD.Molecules.drawStatBarRow ~= nil
            and ZeD.Atoms.drawSegFill ~= nil and ZeD.logOnce ~= nil and ZeD.partLabel ~= nil and S.thermo() ~= nil
            and S.cs("TEMPERATURE") ~= nil and S.cs("WETNESS") ~= nil and MoodleType ~= nil and MoodleType.HYPOTHERMIA ~= nil
            and MoodleType.HYPERTHERMIA ~= nil
        if not Q.check(ready, "thermal setup: the tab's call pieces (coreLook, coreLevel, wetColor, wetWordKey), its draw pieces and the game's thermoregulator are loaded") then
            S.thOff = true
            return
        end
        S.back.th = true
        S.speed(1)
        S.live = true
        Events.OnTick.Add(S.safety)
        pcall(function() S.p:setInvincible(true) end)
        pcall(function() S.p:setGodMod(false) end)
        S.setStat("INTOXICATION", 0)
        S.wrapOn()
        S.park(true)
        S.front()
        S.setView(1)
        Q.check(S.p:isGodMod() == false, "thermal setup: god mode is off for the thermal cases (it keeps the moodles off), the guard on, intoxication 0",
            "intoxication " .. S.n2(S.stat("INTOXICATION")) .. " (found " .. S.n2(S.found.stats.INTOXICATION) .. ")")
    end)
    S.wait(5, 300, function()
        if S.thOff then return true end
        local w = RT.cw()
        return w ~= nil and w._activeTab == "thermal" and S.rec.header ~= nil and S.rec.grid ~= nil and S.rec.picked ~= nil
    end, function(ok)
        if S.thOff then return end
        if not Q.check(ok, "thermal setup: the Thermal tab draws (its meter, grid and picked block are read off the draw)") then S.thOff = true; return end
        S.found.tscroll = S.scrollPos()
        S.scroll(0)
    end)
end
-- the core back (held at the found TEMPERATURE until it is there), the stats, god mode as found, the wrappers off
function S.thEnd()
    local st = {}
    S.step(1, function()
        if not S.back.th then return end
        st.c = S.found.stats and S.found.stats.TEMPERATURE or 37
        S.stage({ temp = st.c, intox = true })
    end)
    S.wait(2, 1500, function()
        if not S.back.th then return true end
        local c = S.core()
        return c ~= nil and math.abs(c - st.c) <= 0.15
    end, function(ok)
        if not S.back.th then return end
        S.unstage()
        Q.check(ok, "thermal end: the core back where it was found", S.n2(S.core()) .. " C (found " .. S.n2(st.c) .. " C)")
    end)
    S.step(2, function() S.thBack() end)
    S.step(10, function()
        if not st.c then return end
        local f = S.found
        Q.check(S.p:isGodMod() == (f.god and true or false) and S.w0 == nil and S.parked == nil, "thermal end: god mode as found, the tab's draw pieces and the pointer the game's own again",
            "god mode " .. tostring(S.p:isGodMod()) .. " (found " .. tostring(f.god) .. ")")
    end)
end
function S.thBack()
    if not S.back.th then return end
    S.back.th = nil
    local f = S.found
    S.unstage()
    S.wetBack()
    for _, k in ipairs({ "INTOXICATION", "ENDURANCE", "FATIGUE" }) do if f.stats and f.stats[k] ~= nil then S.setStat(k, f.stats[k]) end end
    if f.disp ~= nil then S.setDisp(f.disp) end
    local w = RT.cw()
    if w then
        pcall(ZeD.ThermalTab.closeMenu, w)
        w._thermalReturnToMenu = nil
        if f.tview then w._thermalView = f.tview end
        w._thermalPick = f.tpick
        w._thermalFigureExpanded = f.tfold
        S.pickedFoldSet(f.tpickedFold)
        w._thermalHoveredPart = f.thovered
        S.scroll(f.tscroll or 0)
    end
    S.wrapOff()
    S.park(false)
    S.live = false
    pcall(function() Events.OnTick.Remove(S.safety) end)
    if S.bailed then pcall(function() S.p:setGodMod(true) end)
    else pcall(function() S.p:setGodMod(f.god and true or false) end) end
    if f.invc ~= nil then pcall(function() S.p:setInvincible(f.invc) end) end
    S.speed(f.speed)
end

-- ===================================================================== 1. the core meter follows the moodles
function S.coreLv()
    local hypo, hyper = S.moodle("HYPOTHERMIA"), S.moodle("HYPERTHERMIA")
    return ((hyper > 0) and hyper or -hypo), hypo, hyper
end
function S.coreTok(lv)
    if lv == 0 then return "tempNorm" elseif lv == -1 then return "tempCool" elseif lv < -1 then return "tempCold" elseif lv == 1 then return "tempWarm" end
    return "tempHot"
end
function S.tokOf(c)
    if not c then return "none" end
    for _, tok in ipairs({ "tempCold", "tempCool", "tempNorm", "tempWarm", "tempHot" }) do if S.sameC(c, ZeD.T[tok]) then return tok end end
    return "no temperature token"
end
function S.lvWord(lv) if lv == 0 then return "no moodle" elseif lv < 0 then return "Hypothermia " .. (-lv) end; return "Hyperthermia " .. lv end
function S.coreHold(c, lab)
    local st = { n = 0 }
    S.step(1, function() if not S.thOff then S.stage({ temp = c, intox = true }) end; st.lv = nil end)
    S.wait(2, 1500, function()
        if S.thOff then return true end
        local core = S.core()
        if not (core and math.abs(core - c) <= 0.12) then st.n = 0; return false end
        local lv = S.moodle("HYPOTHERMIA") * 10 + S.moodle("HYPERTHERMIA")
        if lv ~= st.lv then st.lv = lv; st.n = 0; return false end
        st.n = st.n + 1
        return st.n >= 45
    end, function(ok)
        if not ok and not S.thOff then S.note(lab .. ": the core did not settle at " .. c .. " C (now " .. S.n2(S.core()) .. " C); the meter is read where it stands") end
    end)
end
function S.coreCheck(P, lab)
    local h = S.rec.header
    local seg = h and h.seg
    local lv, hypo, hyper = S.coreLv()
    local tok, wantLit = S.coreTok(lv), S.CORE_LIT[lv]
    local core = h and h.data and h.data.coreTemp
    local drawn = "lit " .. tostring(seg and seg.lit) .. " of " .. tostring(seg and seg.n) .. " in " .. S.tokOf(seg and seg.color) .. " (" .. S.cText(seg and seg.color) .. ")"
    Q.check(seg ~= nil and seg.lit == wantLit and S.sameC(seg.color, ZeD.T[tok]) and not (hypo > 0 and hyper > 0),
        lab .. ": the core meter draws the look of the game's moodle (" .. S.lvWord(lv) .. ": lit " .. tostring(wantLit) .. ", " .. tok .. ")",
        "Hypothermia " .. hypo .. ", Hyperthermia " .. hyper .. ", core " .. S.n2(core) .. " C; drawn " .. drawn)
    local green = seg ~= nil and S.sameC(seg.color, ZeD.T.tempNorm)
    Q.check(green == (hypo == 0 and hyper == 0), lab .. ": the meter is green (tempNorm) exactly when neither moodle is on",
        "green " .. tostring(green) .. ", Hypothermia " .. hypo .. ", Hyperthermia " .. hyper)
    if seg then
        P.byLv[lv] = P.byLv[lv] or {}
        P.byLv[lv][#P.byLv[lv] + 1] = seg.lit
    end
    local zl = core and ZeD.ThermalTab.coreLevel(core)
    if zl ~= lv then
        S.note(lab .. ": ZeD's coreLevel(" .. S.n2(core) .. ") reads " .. S.lvWord(zl or 0) .. " while the game's moodle is " .. S.lvWord(lv)
            .. " (the meter is drawn from the core, not the moodle)")
    end
    P.rows[#P.rows + 1] = S.n2(core) .. " C: " .. S.lvWord(lv) .. ", " .. drawn
end
function S.coreThemeCheck(lab, th)
    local h = S.rec.header
    local seg = h and h.seg
    local lv = S.coreLv()
    local tok = S.coreTok(lv)
    local B = ZeD.BaseThemes and ZeD.BaseThemes[th.key]
    Q.check(ZeD.currentBase == th.key and seg ~= nil and S.sameC(seg.color, ZeD.T[tok]) and seg.lit == S.CORE_LIT[lv],
        lab .. ": in " .. th.word .. " the meter takes the theme's own " .. tok,
        "drawn " .. S.cText(seg and seg.color) .. ", lit " .. tostring(seg and seg.lit) .. "; the theme's " .. tok .. " " .. S.cText(ZeD.T[tok])
        .. (B and B[tok] and (" (BaseThemes " .. S.cText(B[tok]) .. ")") or ""))
end
function S.coreSummary(P)
    local bad, seen, lvs, n = {}, {}, {}, 0
    for lv = -4, 4 do
        local lits = P.byLv[lv]
        if lits then
            n = n + 1
            lvs[#lvs + 1] = S.lvWord(lv) .. " lit " .. S.idsText(lits)
            for _, l in ipairs(lits) do if l ~= lits[1] then bad[#bad + 1] = S.lvWord(lv) .. " drew both " .. lits[1] .. " and " .. l end end
            if seen[lits[1]] ~= nil then bad[#bad + 1] = S.lvWord(lv) .. " and " .. S.lvWord(seen[lits[1]]) .. " both light " .. lits[1] end
            seen[lits[1]] = lv
        end
    end
    Q.check(#bad == 0 and n >= 5, "1 core: each moodle level reached lights a count of its own (" .. n .. " levels reached)",
        S.idsText(lvs) .. (#bad > 0 and ("; " .. table.concat(bad, "; ")) or ""))
    local miss = {}
    for lv = -4, 2 do if not P.byLv[lv] then miss[#miss + 1] = S.lvWord(lv) end end
    if #miss > 0 then S.note("1 core: levels the holds did not reach: " .. S.idsText(miss)) end
    S.note("1 core: the game caps the core at 40.0 C, so Hyperthermia 3 and 4 cannot be staged; coreLevel and coreLook are checked at 40.5 and 41.5 as plain calls")
    for _, e in ipairs({ { c = 40.5, lv = 3 }, { c = 41.5, lv = 4 } }) do
        local lit, col, lv = ZeD.ThermalTab.coreLook(e.c)
        Q.check(ZeD.ThermalTab.coreLevel(e.c) == e.lv and lv == e.lv and lit == S.CORE_LIT[e.lv] and S.sameC(col, ZeD.T.tempHot),
            "1 core: coreLook(" .. e.c .. ") is Hyperthermia " .. e.lv .. ", lit " .. S.CORE_LIT[e.lv] .. ", tempHot (a plain call: the game cannot reach it)",
            "level " .. tostring(lv) .. ", lit " .. tostring(lit) .. ", " .. S.tokOf(col))
    end
    for _, r in ipairs(P.rows) do S.note("1 core | " .. r) end
end
function S.case1()
    local P = { byLv = {}, rows = {} }
    S.step(2, function() if not S.thOff then S.front(); S.setView(1); S.scroll(0) end end)
    for _, C in ipairs(S.CORES) do
        local lab = "1 core " .. C.c .. " C"
        S.coreHold(C.c, lab)
        S.readThen(lab, function() S.coreCheck(P, lab) end)
        if C.shot then
            for _, th in ipairs(S.THEMES) do
                S.step(2, function() if not S.thOff then S.theme(th.key) end end)
                S.wait(4, 120, function() return S.thOff or ZeD.currentBase == th.key end, S.noop)
                S.readThen(lab, function() S.coreThemeCheck(lab, th) end)
                S.shot("et_calls_core_" .. C.shot .. "_" .. th.key .. "_" .. S.sizeTag(), th.word .. ": the Thermal tab's core meter at " .. C.c
                    .. " C (" .. C.shot .. "): its lit count and colour should read as the moodle shown", function() return not S.thOff end)
            end
            S.step(2, function() S.themeBack() end)
            S.wait(2, 120, function() return ZeD.currentBase == S.found.base end, S.noop)
        end
    end
    S.step(2, function() if not S.thOff then S.coreSummary(P) end end)
    S.caseEnd("1 core meter")
end

-- ===================================================================== 2 and 4. the wetness colours and word
function S.wetLvOf(v) local lv = 0; for i, c in ipairs(S.WET_CUTS) do if (v or 0) >= c then lv = i end end; return lv end
function S.nearWetCut(v) for _, c in ipairs(S.WET_CUTS) do if math.abs((v or 0) - c) < 0.01 then return true end end; return false end
function S.mixC(a, b) return { r = (a.r + b.r) / 2, g = (a.g + b.g) / 2, b = (a.b + b.b) / 2 } end
-- the colour of a WET step, worked out from the theme's tokens (dry green, half way, teal, half way, blue)
function S.wetWant(lv)
    local T = ZeD.T
    if lv == 0 then return T.tempNorm elseif lv == 1 then return S.mixC(T.tempNorm, T.tempCool) elseif lv == 2 then return T.tempCool
    elseif lv == 3 then return S.mixC(T.tempCool, T.tempCold) end
    return T.tempCold
end
function S.wetOK(c, v)
    if c == nil or v == nil then return false end
    if S.sameC(c, S.wetWant(S.wetLvOf(v))) then return true end
    if S.nearWetCut(v) then return S.sameC(c, S.wetWant(S.wetLvOf(v - 0.011))) or S.sameC(c, S.wetWant(S.wetLvOf(v + 0.011))) end
    return false
end
function S.wetKey(lv) return (lv == 0) and "IGUI_Temp_Dry" or ("Moodles_Wet_lvl" .. lv) end
function S.wordOK(word, v)
    if v == nil then return false end
    if tostring(word) == getText(S.wetKey(S.wetLvOf(v))) then return true end
    if S.nearWetCut(v) then return tostring(word) == getText(S.wetKey(S.wetLvOf(v - 0.011))) or tostring(word) == getText(S.wetKey(S.wetLvOf(v + 0.011))) end
    return false
end
function S.wetHold(W)
    local st = { n = 0 }
    S.step(1, function() if not S.thOff then S.stage({ wet = W.v, cloth = W.v, intox = true }) end; st.lv = nil end)
    S.wait(10, 900, function()
        if S.thOff then return true end
        local b = S.nv(S.WPART, "getBodyWetnessUI")
        if not (b and math.abs(b - W.v) < 0.03) then st.n = 0; return false end
        local lv = S.moodle("WET")
        if lv ~= st.lv then st.lv = lv; st.n = 0; return false end
        st.n = st.n + 1
        return st.n >= 40
    end, function(ok)
        if not ok and not S.thOff then S.note("2 wet " .. W.lab .. ": the body's wetness did not settle at " .. W.v .. " (now " .. S.n2(S.nv(S.WPART, "getBodyWetnessUI")) .. ")") end
    end)
end
-- the four colours of the part (figure, cell, the two wetness rows) against the steps of the game's values
function S.wetColours()
    local part = S.shownPart() or S.WPART
    local pk = S.rec.picked
    local r7, r8 = pk and pk.rows[7], pk and pk.rows[8]
    local body, cloth = S.nv(part, "getBodyWetnessUI"), S.nv(part, "getClothingWetnessUI")
    local w = RT.cw()
    local fig = w and w._thermalBodyFigure
    local figC = fig and fig.colorMap and fig.colorMap[part]
    local cell = S.cellOf(part)
    local R = { part = part, body = body, cloth = cloth, r7 = r7, r8 = r8, bad = {}, hot = {} }
    local list = { { "the figure", figC, body }, { "the grid cell", cell and cell.color, body }, { "the body wetness row", r7 and r7.color, body },
                   { "the clothing wetness row", r8 and r8.color, cloth } }
    for _, e in ipairs(list) do
        if not S.wetOK(e[2], e[3]) then R.bad[#R.bad + 1] = e[1] .. " " .. S.cText(e[2]) .. " (its value " .. S.n2(e[3]) .. ", step " .. S.wetLvOf(e[3]) .. " wants " .. S.cText(S.wetWant(S.wetLvOf(e[3]))) .. ")" end
        if e[2] and S.sameC(e[2], ZeD.T.tempHot) then R.hot[#R.hot + 1] = e[1] end
    end
    R.seen = "figure " .. S.cText(figC) .. ", cell " .. S.cText(cell and cell.color) .. ", rows " .. S.cText(r7 and r7.color) .. " / " .. S.cText(r8 and r8.color)
    return R
end
function S.wetCheck(P, W, th)
    local R = S.wetColours()
    local lab = "2 wet " .. W.lab .. (th and (", " .. th.word) or "")
    Q.check(#R.bad == 0, lab .. ": the figure, the grid cell and both wetness rows of " .. R.part .. " take the WET step's colour (dry green to soaked blue)",
        "the game: body " .. S.n2(R.body) .. " (step " .. S.wetLvOf(R.body) .. "), clothing " .. S.n2(R.cloth) .. " (step " .. S.wetLvOf(R.cloth) .. "); "
        .. (#R.bad == 0 and R.seen or table.concat(R.bad, "; ")))
    if W.v >= 0.9 then Q.check(#R.hot == 0, lab .. ": soaked, nothing of it in the temperature colours' hot red", S.idsText(R.hot)) end
    if th then return end
    local hc = ZeD.ThermalTab.wetColor(R.body)
    Q.check(S.wetOK(hc, R.body), lab .. ": ZeD's wetColor gives the step of the game's value", S.cText(hc) .. " for " .. S.n2(R.body))
    -- 4: the word
    local w7, w8 = R.r7 and tostring(R.r7.word), R.r8 and tostring(R.r8.word)
    local okStaged = w7 == getText(W.key)
    local okGame = S.wordOK(w7, R.body)
    Q.check(okGame and (okStaged or S.wetLvOf(R.body) ~= S.wetLvOf(W.v)),
        "4 word " .. W.lab .. ": the body wetness row reads " .. getText(W.key) .. " (" .. W.key .. ")",
        "drawn \"" .. tostring(w7) .. "\"; the part's getBodyWetnessUI " .. S.n2(R.body) .. " is step " .. S.wetLvOf(R.body) .. " (" .. getText(S.wetKey(S.wetLvOf(R.body))) .. ")")
    if not okStaged and okGame then S.note("4 word " .. W.lab .. ": the part's wetness sits at step " .. S.wetLvOf(R.body) .. ", not the staged " .. S.wetLvOf(W.v) .. "; the word follows the game's value") end
    Q.check(S.wordOK(w8, R.cloth), "4 word " .. W.lab .. ": the clothing wetness row's word is the WET step of its own value",
        "drawn \"" .. tostring(w8) .. "\"; getClothingWetnessUI " .. S.n2(R.cloth) .. " (" .. getText(S.wetKey(S.wetLvOf(R.cloth))) .. ")")
    local ml = S.moodle("WET")
    if ml ~= S.wetLvOf(R.body) then
        S.note("4 word " .. W.lab .. ": the body's WET moodle is level " .. ml .. " (the WETNESS stat " .. S.n1(S.stat("WETNESS")) .. ") while the part's wetness is step "
            .. S.wetLvOf(R.body) .. ": the part and the whole body differ here")
    end
    P.rows[#P.rows + 1] = W.lab .. ": WET moodle " .. ml .. ", body row \"" .. tostring(w7) .. "\" " .. S.cText(R.r7 and R.r7.color) .. ", clothing row \"" .. tostring(w8) .. "\""
end
function S.case24()
    local P = { rows = {} }
    S.step(2, function()
        if S.thOff then return end
        S.front(); S.setView(7); S.scroll(0)
        local w = RT.cw()
        if w then w._thermalPick = S.WPART end
        if #S.wornClothes() == 0 then S.note("2 wet: nothing is worn, so the clothing wetness stays 0 (Dry) in every state") end
    end)
    for _, W in ipairs(S.WETS) do
        S.wetHold(W)
        S.readThen("2 wet " .. W.lab, function() S.wetCheck(P, W, nil) end)
        if W.shot then
            for _, th in ipairs(S.THEMES) do
                S.step(2, function() if not S.thOff then S.theme(th.key) end end)
                S.wait(4, 120, function() return S.thOff or ZeD.currentBase == th.key end, S.noop)
                S.readThen("2 wet " .. W.lab, function() S.wetCheck(P, W, th) end)
                S.shot("et_calls_wet_" .. W.shot .. "_" .. th.key .. "_" .. S.sizeTag(), th.word .. ": the Thermal tab's Wetness view at " .. W.v
                    .. " (" .. W.shot .. "): green when dry to blue when soaked, the rows' word the WET moodle's", function() return not S.thOff end)
            end
            S.step(2, function() S.themeBack() end)
            S.wait(2, 120, function() return ZeD.currentBase == S.found.base end, S.noop)
        end
    end
    S.step(2, function()
        if S.thOff then return end
        S.unstage()
        S.wetBack()
        for _, r in ipairs(P.rows) do S.note("4 word | " .. r) end
    end)
    S.waitIdle(3)
    S.step(2, function()
        if S.thOff then return end
        local wb = S.wetDiff()
        Q.check(#wb == 0, "2 wet: the wetness of the body, its parts and the garments is back as found", #wb == 0 and "as found" or table.concat(wb, "; "))
        S.stage({ intox = true })
    end)
    S.caseEnd("2 and 4 wetness")
end

-- ===================================================================== 3. one unit: the grid and the block read the same
function S.pctCheck(i, part)
    local pk = S.rec.picked
    local shown = S.shownPart() or part
    local c = S.cellOf(shown)
    local row = pk and pk.rows[i]
    local cv, rv = c and tostring(c.value) or "none", row and tostring(row.value) or "none"
    local ui = S.VIEWS[i].ui
    local g = S.nv(shown, ui)
    local want = g and math.floor(S.clamp01(g) * 100 + 0.5)
    local isPct = string.match(cv, "^%-?%d+%%$") ~= nil
    Q.check(isPct and cv == rv and want ~= nil and math.abs((S.num(cv) or -999) - want) <= 1,
        "3 " .. S.VIEWS[i].id .. ", " .. shown .. ": the grid cell and the picked block's row read the same NN% (the game's " .. ui .. " x 100)",
        "cell " .. cv .. ", row " .. rv .. ", the game " .. S.n2(g) .. " (" .. tostring(want) .. "%)" .. ((shown ~= part) and (", the block showed " .. shown .. ", not the pick " .. part) or ""))
end
function S.skinCheck(part)
    local cel = S.celsius()
    local pk = S.rec.picked
    local shown = S.shownPart() or part
    local c = S.cellOf(shown)
    local row = pk and pk.rows[1]
    local cv, rv = c and tostring(c.value) or "none", row and tostring(row.value) or "none"
    local n = S.num(cv)
    local g = S.nv(shown, "getSkinCelcius")
    local unitOK = n ~= nil and cv == ZeD.tr(cel and "UI_ZeD_Thermal_TempC" or "UI_ZeD_Thermal_TempF", string.format("%.1f", n))
    Q.check(cv == rv and unitOK and g ~= nil and math.abs(n - S.toUnit(g, cel)) <= S.tol(cel) * 2 and string.find(cv, "%", 1, true) == nil,
        "3 Skin temperature, " .. shown .. ": the cell and the row read the same degrees, in " .. (cel and "C" or "F") .. " (the display option)",
        "cell " .. cv .. ", row " .. rv .. ", the game " .. S.n2(g) .. " C")
end
function S.case3()
    S.step(2, function() if not S.thOff then S.front(); S.scroll(0) end end)
    for i = 2, 7 do
        for _, part in ipairs(S.PCT_PARTS) do
            S.step(1, function()
                if S.thOff then return end
                S.setView(i)
                local w = RT.cw()
                if w then w._thermalPick = part end
            end)
            S.readThen("3 " .. S.VIEWS[i].id .. ", " .. part, function() S.pctCheck(i, part) end)
        end
    end
    for pass = 1, 2 do
        S.step(1, function()
            if S.thOff or pass == 1 then return end
            if S.found.disp == nil then S.note("3 Skin temperature: the display option cannot be read, so it is not switched"); return end
            S.back.disp = true
            S.setDisp(not S.found.disp)
        end)
        for _, part in ipairs(S.PCT_PARTS) do
            S.step(1, function()
                if S.thOff then return end
                S.setView(1)
                local w = RT.cw()
                if w then w._thermalPick = part end
            end)
            S.readThen("3 Skin temperature, " .. part, function() S.skinCheck(part) end)
        end
    end
    S.step(1, function()
        if S.back.disp then S.back.disp = nil; S.setDisp(S.found.disp) end
        S.setView(1)
        local w = RT.cw()
        if w then w._thermalPick = S.WPART end
    end)
    S.caseEnd("3 one unit")
end

-- ===================================================================== the equipment cases' bookends
function S.spareBack()
    local bagInv = nil
    pcall(function() bagInv = S.sp.bag:getInventory() end)
    for _, e in ipairs(S.spHome or {}) do
        local it = S.sp[e.k]
        if it then
            S.loose(it)
            local home = (e.home == "bag") and bagInv or S.inv()
            if home and (S.where(it) ~= home or S.onFloor(it)) then S.put(it, home) end
        end
    end
end
-- every case's start and end: nothing worn but the kept things, the hands empty, the spares where they belong
function S.eqBase()
    if not S.back.eq then return end
    for _, e in ipairs(S.wornList()) do if not S.keptSet[e.item] then S.unwear(e.item) end end
    S.keptBack()
    pcall(function() S.p:setPrimaryHandItem(nil) end)
    pcall(function() S.p:setSecondaryHandItem(nil) end)
    S.spareBack()
    S.wornEvent()
end
function S.caseStart()
    S.caseMade = {}
    S.closeMenu()
    S.cardClose()
    S.eqBase()
end
function S.caseClean()
    S.padOff()
    S.spyOff()
    S.cancelDrags()
    S.closeMenu()
    S.cardClose()
    for _, it in ipairs(S.caseMade) do S.removeItem(it) end
    S.caseMade = {}
    S.sweepNew()
    S.eqBase()
    local hb = S.hb()
    if hb then pcall(function() hb:refresh() end) end
    S.hbBack()
end
function S.eqSetup()
    S.step(2, function()
        local w = RT.cw()
        local ET = ZeD.EquipmentTab
        if not Q.check(w ~= nil and ET ~= nil and ET.openWearMenu ~= nil and ET.takeOff ~= nil and ET.DOUBLE_MS ~= nil and ET.emptyAt ~= nil
            and ET.gatherData ~= nil and ZeD.EquipDoll ~= nil and ZeD.EquipDoll.takeDrop ~= nil and ZeD.Belt ~= nil and ZeD.Belt.slots ~= nil
            and S.F ~= nil and S.F.focusWhere ~= nil,
            "equipment setup: the Equip tab's call pieces (openWearMenu, takeOff, DOUBLE_MS, emptyAt, takeDrop) and the pad's focus manager are loaded") then
            S.eqOff = true
            return
        end
        local f = S.found
        S.back.eq = true
        -- the character's own clothes aside: the belt-givers and the bags stay on
        f.kept = {}
        for _, e in ipairs(f.worn or {}) do
            if S.keeps(e.item) then f.kept[#f.kept + 1] = e; S.keptSet[e.item] = true else S.unwear(e.item) end
        end
        pcall(function() S.p:setPrimaryHandItem(nil) end)
        pcall(function() S.p:setSecondaryHandItem(nil) end)
        -- the spares: four in the main inventory, two more in a bag carried in it
        local sp = S.sp
        sp.hat = S.named(S.give(S.kind("hat"), true), "QA Spare Hat")
        sp.gloves = S.named(S.give(S.kind("gloves"), true), "QA Spare Gloves")
        sp.jacket = S.named(S.give(S.kind("jacket"), true), "QA Spare Jacket")
        sp.knife = S.named(S.give(S.kind("knife"), true), "QA Spare Knife")
        sp.hammer = S.named(S.give(S.kind("hammer"), true), "QA Spare Hammer")
        sp.bag = S.named(S.give(S.kind("bag"), true), "QA Spare Bag")
        local bagInv = nil
        pcall(function() bagInv = sp.bag:getInventory() end)
        sp.hat2 = S.named(S.addTo(bagInv, S.kind("hat2")), "QA Bag Hat")
        sp.knife2 = S.named(S.addTo(bagInv, S.kind("knife")), "QA Bag Knife")
        S.spHome = { { k = "hat", home = "inv" }, { k = "gloves", home = "inv" }, { k = "jacket", home = "inv" }, { k = "knife", home = "inv" },
                     { k = "hammer", home = "inv" }, { k = "bag", home = "inv" }, { k = "hat2", home = "bag" }, { k = "knife2", home = "bag" } }
        local miss = {}
        for _, e in ipairs(S.spHome) do if not sp[e.k] then miss[#miss + 1] = e.k end end
        S.keptBack()
        S.wornEvent()
        if not Q.check(#miss == 0, "equipment setup: the character's clothes set aside (" .. #f.kept .. " belt-givers and bags kept on), the spares carried (a bag holds a hat and a knife)",
            "not made: " .. S.idsText(miss)) then S.eqOff = true end
    end)
end

-- ===================================================================== 5. wear from an empty slot
-- the menu's check: lastWearMenu and the game's lines against the count worked out here
function S.menuCheck(L, ok)
    local lw = ZeD.EquipmentTab.lastWearMenu
    local lines = S.vanLines()
    local want = L.n or -1
    local okN = lw ~= nil and lw.key == L.key and lw.n == want
    local okLines = (want > 0 and lines.count == want) or (want == 0 and lines.noneGray)
    Q.check(ok and okN and okLines, L.lab .. ": the empty " .. tostring(L.key) .. " slot opens its list of what fits (n: the fitting things carried, one per name, none on)"
        .. ((want == 0) and "; nothing fits: one grayed IGUI_None line" or ""),
        "lastWearMenu " .. (lw and (tostring(lw.key) .. " n " .. tostring(lw.n)) or "nil") .. "; counted from the inventory and its bags " .. want .. " ("
        .. S.idsText(L.names) .. "); the menu's lines " .. lines.count .. ": " .. S.idsText(lines.names))
    if L.bounds then RT.bounds(Q, L.lab .. ", the list open") end
end
function S.judge(L)
    local it = L.it
    if L.judge == "pri" then return S.p:getPrimaryHandItem() == it, "the main hand holds " .. S.nm(S.p:getPrimaryHandItem()) end
    if L.judge == "sec" then return S.p:getSecondaryHandItem() == it, "the off hand holds " .. S.nm(S.p:getSecondaryHandItem()) end
    if L.judge == "hood" then
        local hoodies = S.wornOfType("Base.Hoodie")
        return S.isWorn(it) and #hoodies > 0, S.nm(it) .. " worn " .. tostring(S.isWorn(it)) .. ", hoodies worn: " .. S.idsText(hoodies)
    end
    return S.isWorn(it), S.nm(it) .. " worn " .. tostring(S.isWorn(it))
end
S.JUDGE_WORD = { worn = "wears it", pri = "puts it in the main hand", sec = "puts it in the off hand",
                 hood = "wears it and the raised hood's hoodie stays on (the game's Wear lowers the hood)" }
-- one empty slot's leg. L = { key (or keyFn), item = fn, lab, judge, pad, shot, what, bounds, none = candidates }
function S.wearLeg(T, L)
    S.step(2, function()
        L.go, L.picked, L.off = nil, nil, nil
        if T.off then L.off = true; return end
        S.closeMenu()
        ZeD.EquipmentTab.lastWearMenu = nil
        L.it = L.item and L.item() or nil
        if L.item and not L.it then L.off = true; Q.skip(L.lab, "the thing to pick is not there (the case says why above)"); return end
        L.st = { n = 0 }
    end)
    S.wait(2, 120, function()
        if L.off then return true end
        if L.none then return S.eqReady(L.view or "list") end
        return S.emptyZone(L.key) ~= nil
    end, function(ok)
        if L.off then return end
        local w = RT.cw()
        local bands = w and w._equipDollBands
        if L.none then
            L.key = nil
            for _, k in ipairs(L.none) do
                if not L.key and S.emptyZone(k) and S.myCount(k, bands) == 0 then L.key = k end
            end
            if not L.key then L.off = true; Q.skip(L.lab, "every candidate slot (" .. S.idsText(L.none) .. ") has something carried that fits, or is not drawn empty"); return end
            S.note(L.lab .. ": the slot nothing carried fits is " .. L.key)
        elseif not Q.check(ok, L.lab .. ": the " .. tostring(L.key) .. " slot is drawn empty", "view " .. tostring(ZeD.EquipDoll.view())) then
            L.off = true
            return
        end
        L.n, L.names = S.myCount(L.key, bands)
        if L.pad then
            L.go = S.padOn() and S.focusEl("equipslot:" .. L.key)
            Q.check(L.go, L.lab .. ": the pad's focus lands on the empty slot (equipslot:" .. L.key .. ")", "on " .. tostring(S.focusedId()))
        else
            L.go = true
            S.clickZone(S.emptyZone(L.key))
        end
    end)
    if L.pad then S.tapA(function() return L.go end) end
    S.wait(2, 150, function()
        if not L.go then return true end
        L.st.n = L.st.n + 1
        return S.menu() ~= nil or (S.menuUp() and L.st.n > 30)
    end, function(ok)
        if L.go then S.menuCheck(L, ok and S.menuUp()) end
    end)
    if L.shot then S.shot(L.shot, L.what, function() return L.go and S.menuUp() end) end
    S.step(2, function()
        if not L.go then return end
        if not L.it then S.closeMenu(); return end
        local why
        if L.pad then L.picked, why = S.padPick(S.nm(L.it)) else L.picked, why = S.pickOpt(S.nm(L.it)) end
        Q.check(L.picked, L.lab .. ": " .. S.nm(L.it) .. " picked from the list" .. (L.pad and " (the D-pad walks to it, A)" or " (the mouse)"), why)
        if not L.pad then S.closeMenu() end
    end)
    S.wait(4, 900, S.settled(10), S.noop)
    S.step(10, function()
        if not (L.go and L.picked) then return end
        local ok, why = S.judge(L)
        Q.check(ok, L.lab .. ": the pick " .. (S.JUDGE_WORD[L.judge or "worn"] or "wears it"), why)
        if L.pad then
            Q.check(not S.menuUp() and S.focusedId() == "equipslot:" .. L.key, L.lab .. ": the list shut and the pad's focus is back on the slot",
                "menu up " .. tostring(S.menuUp()) .. ", focus on " .. tostring(S.focusedId()))
        end
        S.closeMenu()
    end)
end
-- the pad's B on the list: it shuts, the focus back on the slot
function S.padBLeg(T, key, lab)
    local L = {}
    S.step(2, function()
        if T.off then return end
        S.closeMenu()
        ZeD.EquipmentTab.lastWearMenu = nil
    end)
    S.wait(2, 120, function() return T.off or S.emptyZone(key) ~= nil end, function(ok)
        if T.off then return end
        L.go = ok and S.padOn() and S.focusEl("equipslot:" .. key)
        Q.check(L.go, lab .. ": the pad's focus lands on the empty slot (equipslot:" .. key .. ")", "on " .. tostring(S.focusedId()))
    end)
    S.tapA(function() return L.go end)
    S.wait(2, 150, function() return not L.go or S.menu() ~= nil end, function(ok)
        if not L.go then return end
        local lw = ZeD.EquipmentTab.lastWearMenu
        L.m = ok and S.menu() or nil
        Q.check(L.m ~= nil and lw ~= nil and lw.key == key, lab .. ": A opens the slot's list (ZeD's menu)", "lastWearMenu " .. tostring(lw and lw.key))
        if L.m then
            local okB = pcall(function() L.m:onJoypadDown(Joypad.BButton) end)
            if not okB then S.errs = S.errs + 1 end
        end
    end)
    S.step(8, function()
        if not L.m then S.closeMenu(); return end
        Q.check(not S.menuUp() and S.focusedId() == "equipslot:" .. key, lab .. ": B shuts the list, nothing picked, the pad's focus back on the slot",
            "menu up " .. tostring(S.menuUp()) .. ", focus on " .. tostring(S.focusedId()))
        S.closeMenu()
        S.padOff()
    end)
end
function S.case5list()
    local T = {}
    S.step(2, function() if S.eqOff then T.off = true; return end; S.caseStart() end)
    S.toEquip("list", T, "5 wear, the list")
    local sp = S.sp
    S.wearLeg(T, { key = "HAT", item = function() return sp.hat end, lab = "5a list HAT (mouse)", bounds = true,
                   shot = "et_calls_wearmenu_list_" .. S.sizeTag(), what = "the empty Hat row's list of what fits (the mouse)" })
    S.wearLeg(T, { key = "GLV", item = function() return sp.gloves end, lab = "5a list GLV (mouse)" })
    S.wearLeg(T, { key = "OUT", item = function() return sp.jacket end, lab = "5a list OUT (mouse)" })
    S.wearLeg(T, { key = "PRI", item = function() return sp.knife end, lab = "5a list PRI (mouse)", judge = "pri" })
    S.wearLeg(T, { key = "SEC", item = function() return sp.hammer end, lab = "5a list SEC (mouse)", judge = "sec" })
    -- the hood rule: a hoodie with its hood up worn, a hat from the bag picked on the empty Hat row
    S.step(2, function()
        T.hood = nil
        if T.off then return end
        S.unwear(sp.hat)
        local up = S.kind("hoodieUp")
        T.hoodie = up and S.give(up) or nil
        T.hood = T.hoodie ~= nil and S.wearIt(T.hoodie)
        S.wornEvent()
        if not T.hood then Q.skip("5b list, the hood rule", "no hoodie with its hood up could be worn here (" .. tostring(up) .. ")") end
    end)
    S.wearLeg(T, { key = "HAT", item = function() return T.hood and sp.hat2 or nil end, lab = "5b list HAT on a raised hood (a hat from the bag)", judge = "hood" })
    S.step(2, function() S.caseClean() end)
    S.toEquip("list", T, "5 wear, the list")
    S.wearLeg(T, { none = S.NONE_LIST, view = "list", lab = "5c list, a slot nothing fits" })
    S.step(2, function() S.caseClean() end)
    S.caseEnd("5 wear, the list")
end
function S.case5doll()
    local T = {}
    S.step(2, function() if S.eqOff then T.off = true; return end; S.caseStart() end)
    S.toEquip("doll", T, "5 wear, the doll")
    local sp = S.sp
    S.wearLeg(T, { key = "doll:head", item = function() return sp.hat2 end, lab = "5d doll Head (mouse, a hat from the bag)", bounds = true,
                   shot = "et_calls_wearmenu_doll_" .. S.sizeTag(), what = "the empty Head box's list of what fits (the mouse)" })
    S.wearLeg(T, { key = "doll:outer", item = function() return sp.jacket end, lab = "5d doll Outer (mouse)" })
    S.wearLeg(T, { key = "doll:main", item = function() return sp.knife end, lab = "5d doll Main (mouse)", judge = "pri" })
    S.wearLeg(T, { key = "doll:off", item = function() return sp.hammer end, lab = "5d doll Off (mouse)", judge = "sec" })
    S.step(2, function() S.caseClean() end)
    S.toEquip("doll", T, "5 wear, the doll")
    S.wearLeg(T, { none = S.NONE_DOLL, view = "doll", lab = "5e doll, a box nothing fits" })
    S.step(2, function() S.caseClean() end)
    S.caseEnd("5 wear, the doll")
end
function S.case5pad()
    local T = {}
    S.step(2, function() if S.eqOff then T.off = true; return end; S.caseStart() end)
    S.toEquip("list", T, "5 wear, the pad")
    local sp = S.sp
    S.wearLeg(T, { key = "HAT", item = function() return sp.hat end, lab = "5f pad list HAT", pad = true })
    S.step(2, function() S.padOff() end)
    S.padBLeg(T, "GLV", "5f pad list GLV")
    S.step(2, function() S.caseClean() end)
    S.toEquip("doll", T, "5 wear, the pad")
    S.wearLeg(T, { key = "doll:main", item = function() return sp.knife2 end, lab = "5g pad doll Main (a knife from the bag)", pad = true, judge = "pri" })
    S.step(2, function() S.padOff() end)
    S.padBLeg(T, "doll:outer", "5g pad doll Outer")
    S.step(2, function() S.caseClean() end)
    S.caseEnd("5 wear, the pad")
end

-- ===================================================================== 5. double-click takes off; a single click waits
-- queue: two clicks inside DOUBLE_MS on a zone (zFn names it), then judge; no card after 0.4 s
function S.dblLeg(T, lab, zFn, itFn, judge)
    local L = {}
    S.step(2, function()
        L.go = nil
        if T.off then return end
        L.it = itFn()
        ZeD.EquipmentTab.lastTakeOff = nil
        S.cardClose()
    end)
    S.wait(2, 120, function() return T.off or not L.it or zFn(L) ~= nil end, function(ok)
        if T.off or not L.it then return end
        if not Q.check(ok, lab .. ": the filled slot of " .. S.nm(L.it) .. " is drawn") then return end
        local z = zFn(L)
        local x, y
        if L.x then x, y = L.x, L.y else x, y = S.mid(z) end
        local t0 = getTimestampMs()
        S.clickAt(x, y)
        S.clickAt(x, y)
        L.dt = getTimestampMs() - t0
        L.go = true
    end)
    S.wait(4, 900, S.settled(10), S.noop)
    S.step(6, function()
        if not L.go then return end
        local ok, why = judge(L)
        Q.check(ok and ZeD.EquipmentTab.lastTakeOff == L.it, lab .. ": two clicks inside DOUBLE_MS (" .. tostring(ZeD.EquipmentTab.DOUBLE_MS) .. " ms) take it off",
            why .. "; lastTakeOff " .. S.nm(ZeD.EquipmentTab.lastTakeOff) .. "; the clicks " .. tostring(L.dt) .. " ms apart")
    end)
    Q.waitMs(450)
    S.step(2, function()
        if not L.go then return end
        local w = RT.cw()
        Q.check(w ~= nil and w._equipSelected == nil and S.cardItem() == nil, lab .. ": no card opened (0.4 s on)", "selected " .. tostring(w and w._equipSelected))
    end)
end
function S.notWorn(L) return not S.isWorn(L.it) and S.where(L.it) == S.inv(), "worn " .. tostring(S.isWorn(L.it)) .. ", in the inventory " .. tostring(S.where(L.it) == S.inv()) end
function S.offBelt(L) return S.slotOf(L.it) < 0 and S.where(L.it) == S.inv(), "belt slot " .. S.slotOf(L.it) .. ", in the inventory " .. tostring(S.where(L.it) == S.inv()) end
-- a filled belt row's body (left of its button)
function S.beltRowPoint(L)
    local z = L.i and S.beltZone(L.i)
    if not (z and z.item == L.it) then return nil end
    L.x, L.y = z.x + ZeD.T.px(6), z.y + math.floor(z.h / 2)
    if z.btn and L.x >= z.btn.x then L.x = z.btn.x - ZeD.T.px(6) end
    return z
end
function S.beltOn(T)
    S.step(2, function()
        T.att = nil
        if T.off then return end
        local it = S.sp.hammer
        T.bit = it
        -- (out of the hands first: a held thing is still the hand's)
        if it and (S.p:getPrimaryHandItem() == it or S.p:getSecondaryHandItem() == it) then S.handsSet(nil, nil) end
        T.bi = S.emptyOrLend(it, "5 double-click, the belt")
        if T.bi then T.att = ZeD.Belt.attach(S.pn, it, T.bi) end
        if not T.att then
            -- say why: each slot's name, what it takes, what it holds, and the hammer's own attachment type and place
            local hb, parts = S.hb(), {}
            for j, slot in pairs((hb and hb.availableSlot) or {}) do
                local takes = {}
                pcall(function() for k, _ in pairs(slot.def.attachments) do takes[#takes + 1] = tostring(k) end end)
                local nm = "?"
                pcall(function() nm = tostring(slot.def.name or slot.slotType) end)
                parts[#parts + 1] = tostring(j) .. " " .. nm .. " takes [" .. table.concat(takes, " ") .. "] holds " .. S.nm(hb.attachedItems and hb.attachedItems[j])
            end
            local at = "?"
            if it then pcall(function() at = tostring(it:getAttachmentType()) end) end
            Q.skip("5 double-click on the belt", "no belt slot takes the spare hammer here, even lent: the hammer " .. S.nm(it) .. " (type " .. at
                .. ", in " .. tostring(it and S.where(it)) .. ", broken " .. tostring(it and it:isBroken()) .. "); slots: " .. table.concat(parts, "; "))
        end
    end)
    S.wait(4, 600, function() return T.off or not T.att or (S.queueEmpty() and S.slotOf(T.bit) == T.bi) end, S.noop)
end
function S.case5dbl()
    local T = {}
    local sp = S.sp
    S.step(2, function() if S.eqOff then T.off = true; return end; S.caseStart(); S.wearIt(sp.hat); S.wearIt(sp.jacket); S.wornEvent() end)
    S.toEquip("list", T, "5 double-click, the list")
    S.dblLeg(T, "5h list row (the hat)", function() return S.slotZone(sp.hat) end, function() return sp.hat end, S.notWorn)
    S.toEquip("doll", T, "5 double-click, the doll")
    S.dblLeg(T, "5h doll box (the jacket on Outer)", function() local z = S.zoneT("doll:outer"); return (z and z.item == sp.jacket) and z or nil end,
        function() return sp.jacket end, S.notWorn)
    -- the belt: a filled row in the list, then its box in the doll
    S.beltOn(T)
    S.toEquip("list", T, "5 double-click, a belt row")
    S.dblLeg(T, "5i list belt row (the hammer)", function(L) L.i = T.att and T.bi; return S.beltRowPoint(L) end,
        function() return T.att and sp.hammer or nil end, S.offBelt)
    S.step(2, function() if T.off then return end; S.loose(sp.hammer); S.put(sp.hammer, S.inv()) end)
    S.beltOn(T)
    S.toEquip("doll", T, "5 double-click, a belt box")
    S.dblLeg(T, "5i doll belt box (the hammer)", function() local z = T.bi and S.zoneT("doll:belt" .. tostring(T.bi)); return (z and z.item == sp.hammer) and z or nil end,
        function() return T.att and sp.hammer or nil end, S.offBelt)
    -- a single click: the card only after DOUBLE_MS
    S.step(2, function() if T.off then return end; S.loose(sp.hammer); S.put(sp.hammer, S.inv()); S.wearIt(sp.hat); S.wornEvent() end)
    S.toEquip("list", T, "5 single click")
    S.wait(2, 120, function() return T.off or S.slotZone(sp.hat) ~= nil end, function(ok)
        if T.off then return end
        T.one = Q.check(ok, "5j single click: the hat's row is drawn")
        if not T.one then return end
        S.clickZone(S.slotZone(sp.hat))
        local w = RT.cw()
        Q.check(w._equipSelected == nil and w._equipClickWait ~= nil, "5j single click: the card does not open at once (the click waits DOUBLE_MS for a second)",
            "selected " .. tostring(w._equipSelected) .. ", waiting " .. tostring(w._equipClickWait ~= nil))
    end)
    Q.waitMs(450)
    S.wait(1, 60, function() return T.off or not T.one or S.cardOn(sp.hat) end, function(ok)
        if T.off or not T.one then return end
        Q.check(ok and S.isWorn(sp.hat), "5j single click: 0.4 s on, the hat's card is open and the hat still worn", "the card shows " .. S.nm(S.cardItem()) .. ", worn " .. tostring(S.isWorn(sp.hat)))
    end)
    S.step(2, function() S.caseClean() end)
    S.caseEnd("5 double-click")
end

-- ===================================================================== 6. the belt rows show folded
function S.case6()
    local T = {}
    S.step(2, function() if S.eqOff then T.off = true; return end; S.caseStart() end)
    S.beltOn(T)
    S.toEquip("list", T, "6 belt")
    S.step(2, function()
        if T.off then return end
        local w = RT.cw()
        w._equipExpanded.held = false
        S.eqDirty()
    end)
    S.step(8, function()
        if T.off then return end
        local w = RT.cw()
        local sl, hb = S.bslots(), S.hb()
        local avail = 0
        for _ in pairs((hb and hb.availableSlot) or {}) do avail = avail + 1 end
        local miss, filled, empty = {}, 0, 0
        for _, s in ipairs(sl) do
            if s.item then filled = filled + 1 else empty = empty + 1 end
            if not S.beltZone(s.i) then miss[#miss + 1] = tostring(s.i) .. (s.item and " (filled)" or " (empty)") end
        end
        local rows = #(w._equipBeltZones or {})
        Q.check(w._equipExpanded.held == false and #sl > 0 and #miss == 0 and rows == #sl and #sl == avail,
            "6 belt: with Held and Belt folded every belt slot, filled and empty, has its row (as many as the game's hotbar slots)",
            rows .. " rows, " .. #sl .. " slots (" .. filled .. " filled, " .. empty .. " empty), the hotbar's availableSlot " .. avail
            .. ((#miss > 0) and ("; no row for " .. S.idsText(miss)) or ""))
        if filled == 0 or empty == 0 then S.note("6 belt: the belt shows " .. filled .. " filled and " .. empty .. " empty slots here (both kinds wanted for the call)") end
        w._equipExpanded.held = true
    end)
    S.step(2, function() S.caseClean() end)
    S.caseEnd("6 belt rows")
end

-- ===================================================================== 7. a two-handed weapon in the off hand
function S.twoKind()
    for _, ft in ipairs(S.KIND.two) do
        if S.known(ft) then
            local it = S.give(ft)
            local two = false
            pcall(function() two = it:isTwoHandWeapon() end)
            if two then return it end
            S.removeItem(it)
        end
    end
    return nil
end
function S.bothList(T, it, two)
    local sp = S.spyOff()
    local w = RT.cw()
    local data = ZeD.EquipmentTab.gatherData(S.p)
    local sec = S.slotDef(data, "SEC")
    local y0 = w and w._equipSlotYMap and w._equipSlotYMap.SEC
    local texts, texs = S.inBand(sp and sp.texts, y0, ZeD.T.rowH), S.inBand(sp and sp.texs, y0, ZeD.T.rowH)
    local exp = ZeD.tr("UI_ZeD_Equip_BothHands", S.nm(it))
    local hit = nil
    for _, t in ipairs(texts) do if S.textMatch(t.s, exp) then hit = t end end
    local lab = two and "7 list, a two-handed weapon in both hands" or "7 list, a one-handed weapon in the main hand"
    if two then
        Q.check(sec ~= nil and sec.bothHands == it and sec.item == nil, lab .. ": the SEC slot keeps it as bothHands (no thing of its own)",
            "bothHands " .. S.nm(sec and sec.bothHands) .. ", item " .. S.nm(sec and sec.item))
        local dc = ZeD.T.textDim or ZeD.T.textSec
        Q.check(hit ~= nil and S.sameC(hit, dc), lab .. ": the SEC row draws \"" .. exp .. "\" (UI_ZeD_Equip_BothHands), dimmed",
            "drawn in the row: " .. S.textsText(texts) .. (hit and ("; its colour " .. S.cText(hit) .. ", the dim text " .. S.cText(dc)) or ""))
        Q.check(S.alphaIn(texs, 0.4) ~= nil, lab .. ": the SEC row's icon is drawn at alpha 0.4", "the row's icons at alpha " .. S.alphas(texs))
    else
        Q.check(sec ~= nil and sec.bothHands == nil and hit == nil and S.alphaIn(texs, 0.4) == nil, lab .. ": the SEC row shows no both hands (no bothHands, no words, no 0.4 icon)",
            "bothHands " .. S.nm(sec and sec.bothHands) .. "; drawn " .. S.textsText(texts) .. "; icons at " .. S.alphas(texs))
    end
end
function S.bothDoll(T, it, two)
    local sp = S.spyOff()
    local w = RT.cw()
    local d = w and w._equipDollData
    local z = S.emptyZone("doll:off")
    local texs = S.inBox(sp and sp.texs, z)
    local lab = two and "7 doll, a two-handed weapon in both hands" or "7 doll, a one-handed weapon in the main hand"
    if two then
        Q.check(d ~= nil and d.offBoth == it and d.off == nil and d.main == it, lab .. ": the doll's data has offBoth (the Off box empty of its own)",
            "main " .. S.nm(d and d.main) .. ", off " .. S.nm(d and d.off) .. ", offBoth " .. S.nm(d and d.offBoth))
        Q.check(z ~= nil and S.alphaIn(texs, 0.35) ~= nil, lab .. ": the Off box draws the weapon's icon at alpha 0.35",
            "the box " .. tostring(z ~= nil) .. ", its icons at alpha " .. S.alphas(texs))
    else
        Q.check(d ~= nil and d.offBoth == nil and S.alphaIn(texs, 0.35) == nil, lab .. ": the Off box shows no both hands (no offBoth, no 0.35 icon)",
            "offBoth " .. S.nm(d and d.offBoth) .. ", icons at " .. S.alphas(texs))
    end
end
function S.case7()
    local T = {}
    S.step(2, function()
        if S.eqOff then T.off = true; return end
        S.caseStart()
        T.two = S.twoKind()
        if not T.two then T.off = true; Q.skip("7 both hands", "no weapon the game marks two-handed (isTwoHandWeapon) could be made: " .. S.idsText(S.KIND.two)); return end
        Q.say("NOTE 7 both hands: the two-handed weapon is " .. S.ft(T.two))
        S.handsSet(T.two, T.two)
    end)
    S.toEquip("list", T, "7 both hands")
    S.step(2, function() if not T.off then S.foldAllBut("held") end end)
    S.step(10, function() if not T.off then S.spyOn() end end)
    S.step(4, function() if T.off then S.spyOff(); return end; S.bothList(T, T.two, true) end)
    for _, th in ipairs(S.THEMES) do
        S.step(2, function() if not T.off then S.theme(th.key) end end)
        S.waitIdle(20)
        S.shot("et_calls_bothhands_list_" .. th.key .. "_" .. S.sizeTag(), th.word .. ": the list's SEC row with a two-handed weapon held: \"<name> (both hands)\" dimmed, its icon at 0.4",
            function() return not T.off end)
    end
    S.step(2, function() S.themeBack() end)
    S.toEquip("doll", T, "7 both hands")
    S.step(10, function() if not T.off then S.spyOn() end end)
    S.step(4, function() if T.off then S.spyOff(); return end; S.bothDoll(T, T.two, true) end)
    for _, th in ipairs(S.THEMES) do
        S.step(2, function() if not T.off then S.theme(th.key) end end)
        S.waitIdle(20)
        S.shot("et_calls_bothhands_doll_" .. th.key .. "_" .. S.sizeTag(), th.word .. ": the doll's Off box with a two-handed weapon held: its icon at 0.35",
            function() return not T.off end)
    end
    S.step(2, function() S.themeBack() end)
    -- a one-handed weapon: none of it
    S.step(2, function() if not T.off then S.handsSet(S.sp.knife, nil) end end)
    S.step(10, function() if not T.off then S.spyOn() end end)
    S.step(4, function() if T.off then S.spyOff(); return end; S.bothDoll(T, S.sp.knife, false) end)
    S.toEquip("list", T, "7 both hands")
    S.step(2, function() if not T.off then S.foldAllBut("held") end end)
    S.step(10, function() if not T.off then S.spyOn() end end)
    S.step(4, function() if T.off then S.spyOff(); return end; S.bothList(T, S.sp.knife, false) end)
    S.step(2, function() S.caseClean() end)
    S.caseEnd("7 both hands")
end

-- ===================================================================== 8. the card's hand buttons
-- ids as Build described: exact on the full card; on the half card UNEQUIP first, MORE last, between them hand buttons
-- of that state in order (DROP goes into More there)
function S.verbsOK(ids, want, compact)
    if not compact then return table.concat(ids, ",") == table.concat(want, ",") end
    if ids[1] ~= "UNEQUIP" or ids[#ids] ~= "MORE" then return false end
    local hands = {}
    for _, id in ipairs(want) do if id == "OFF HAND" or id == "TWO HANDS" then hands[#hands + 1] = id end end
    local j = 1
    for i = 2, #ids - 1 do
        while hands[j] and hands[j] ~= ids[i] do j = j + 1 end
        if not hands[j] then return false end
        j = j + 1
    end
    return true
end
function S.verbCheck(L, key, state)
    if not L[key] then return false end
    local ids = S.cardIdList()
    local compact = S.isHalf()
    local want = S.HANDVERBS[state]
    return Q.check(S.verbsOK(ids, want, compact), L.lab .. ": the weapon " .. S.STATE_VERBWORD[state] .. ", its card shows " .. table.concat(want, ", ")
        .. (compact and " (the half card: the hand buttons that fit, before MORE)" or ""), "the card shows " .. S.idsText(ids))
end
function S.pressVerb(L, key, id)
    L.v = nil
    if not L[key] then return end
    if L.pad then
        L.v = S.focusVerb(id)
        Q.check(L.v, L.lab .. ": the pad's focus is on the card's " .. id, "on " .. tostring(S.focusedId()))
    else
        local ok, why = S.cardClick(id)
        L.v = Q.check(ok, L.lab .. ": " .. id .. " pressed on the card (the mouse)", why)
    end
end
function S.openFor(L, key, it, pad)
    if pad then S.openRowPad(L, key, function() return it() end, L.lab) else S.openRow(L, key, function() return it() end, L.lab) end
end
function S.card8leg(T, how, pad)
    local L = { lab = "8 card (" .. how .. ")", pad = pad }
    local knife = function() return S.sp.knife end
    S.step(2, function()
        L.off = T.off
        if T.off then return end
        S.padOff()
        S.cardClose()
        S.handsSet(S.sp.knife, nil)
    end)
    S.waitIdle(10)
    S.openFor(L, "a", knife, pad)
    S.step(6, function() S.verbCheck(L, "a", "main"); if L.a and S.inList(S.cardIdList(), "OFF HAND") then S.pressVerb(L, "a", "OFF HAND") end end)
    if pad then S.tapA(function() return L.v end) end
    S.wait(4, 900, S.settled(10), S.noop)
    S.step(10, function()
        if not L.v then return end
        Q.check(S.handState(S.sp.knife) == "off", L.lab .. ": OFF HAND moves the weapon to the off hand", "it is " .. S.STATE_WORD[S.handState(S.sp.knife)])
    end)
    S.openFor(L, "b", knife, pad)
    S.step(6, function() S.verbCheck(L, "b", "off") end)
    -- the two-handed weapon held in the main hand only: TWO HANDS shows, and puts it in both hands
    local two = function() return T.two end
    S.step(2, function()
        S.padOff()
        S.cardClose()
        if T.off or not T.two then L.b = nil; L.c = nil; return end
        S.handsSet(T.two, nil)
    end)
    S.waitIdle(10)
    S.step(2, function() L.b = nil end)
    S.openFor(L, "b", two, pad)
    S.step(6, function() S.verbCheck(L, "b", "twomain"); if L.b and S.inList(S.cardIdList(), "TWO HANDS") then S.pressVerb(L, "b", "TWO HANDS") end end)
    if pad then S.tapA(function() return L.v end) end
    S.wait(4, 900, S.settled(10), S.noop)
    S.step(10, function()
        if not L.v then return end
        Q.check(S.handState(T.two) == "both", L.lab .. ": TWO HANDS puts the two-handed weapon in both hands", "it is " .. S.STATE_WORD[S.handState(T.two)])
    end)
    S.openFor(L, "c", two, pad)
    S.step(6, function() S.verbCheck(L, "c", "both") end)
    S.step(2, function() S.padOff(); S.cardClose() end)
end
-- the buttons inside the back bar: none past the card's edges, none over another or the close key
function S.fitCheck(F, card)
    local c = S.ecard()
    local rects = c and c._backBarRects
    local vr = (rects and rects.verbs) or {}
    local back = rects and rects.back
    local cw = 0
    if c then pcall(function() cw = c:getWidth() end) end
    local ids = S.cardIdList()
    local bad = {}
    for i = 1, #ids do
        local r = vr[i]
        if not r then bad[#bad + 1] = "no rect for " .. ids[i]
        else
            if r.x < -1 or r.x + r.w > cw + 1 then bad[#bad + 1] = ids[i] .. " at " .. math.floor(r.x) .. "+" .. math.floor(r.w) .. " past the card's 0.." .. math.floor(cw) end
            if back and r.x < back.x + back.w then bad[#bad + 1] = ids[i] .. " at " .. math.floor(r.x) .. " over the close key (to " .. math.floor(back.x + back.w) .. ")" end
            for j = i + 1, #ids do
                local q = vr[j]
                if q and r.x < q.x + q.w and q.x < r.x + r.w then bad[#bad + 1] = ids[i] .. " over " .. ids[j] end
            end
        end
    end
    local lab = F.lab
    F.cardOK = Q.check(#ids >= 2 and #bad == 0, lab .. ": the card's buttons (" .. S.idsText(ids) .. ") sit inside its back bar, none over another or the close key",
        "the card " .. math.floor(cw) .. " px" .. ((#bad > 0) and ("; " .. table.concat(bad, "; ")) or ""))
    local compact = (card == 220)
    Q.check(S.verbsOK(ids, S.HANDVERBS.twomain, compact), lab .. ": the two-handed weapon in the main hand, the buttons are "
        .. (compact and "UNEQUIP, the hand buttons that fit, MORE" or table.concat(S.HANDVERBS.twomain, ", ")), "shows " .. S.idsText(ids))
    F.missing = {}
    if compact then
        for _, id in ipairs({ "OFF HAND", "TWO HANDS" }) do if not S.inList(ids, id) then F.missing[#F.missing + 1] = id end end
    end
    RT.bounds(Q, lab)
end
function S.cardFitPass(T, card, sz)
    local F = {}
    S.step(2, function()
        F.off = T.off
        F.lab = "8 the " .. card .. " card, " .. ((sz == "large") and "Large" or tostring(S.found.size)) .. " text"
        if T.off then return end
        if card == 220 and not T.half then F.off = true; Q.skip(F.lab, "the half card could not be brought about here"); return end
        if sz == "large" then S.sizeSet("large") else S.sizeBack() end
        S.cardClose()
        if not T.two then F.off = true; Q.skip(F.lab, "no two-handed weapon could be made, so the five-button card can't be staged"); return end
        S.handsSet(T.two, nil)
    end)
    S.waitIdle(30)
    S.toEquip("list", F, "8 the " .. card .. " card")
    S.step(2, function()
        if F.off then return end
        local good = (card == 480) and S.isFull() or ((card == 220) and S.isHalf())
        if not good then
            F.off = true
            Q.skip(F.lab, "the drawer stands at " .. math.floor(RT.cw()._drawerEffW or 0) .. " px here, not the " .. card .. " card (" .. ZeD.T.px(card) .. " px)")
        end
    end)
    S.openRow(F, "f", function() return T.two end, "8 the " .. card .. " card")
    S.step(6, function() if F.f then S.fitCheck(F, card) end end)
    S.shot(function() return "et_calls_card" .. card .. "_" .. tostring(ZeD.currentSize) .. "_" .. S.sizeTag() end,
        "a two-handed weapon's equipped card (main hand only, all five buttons) on the " .. card .. " card: its buttons in the back bar", function() return F.f and true or false end)
    if card == 220 then
        S.step(2, function()
            F.more = nil
            if not F.f then return end
            if #F.missing == 0 then S.note(F.lab .. ": every hand button fits before MORE"); return end
            S.closeMenu()
            local c = S.ecard()
            local ok = pcall(function() c:_dispatchHeaderVerb("MORE") end)
            if not ok then S.errs = S.errs + 1 end
            F.more = ok
        end)
        S.wait(2, 120, function() return not F.more or S.menuUp() end, function(ok)
            if not F.more then return end
            local names = S.menuNames(S.menu())
            local want = { ["OFF HAND"] = getText("ContextMenu_Equip_Secondary"), ["TWO HANDS"] = getText("ContextMenu_Equip_Two_Hands") }
            local miss = {}
            for _, id in ipairs(F.missing) do if not S.inList(names, want[id]) then miss[#miss + 1] = id .. " (" .. want[id] .. ")" end end
            Q.check(ok and #miss == 0, F.lab .. ": each hand button left off the half card sits in More's menu (the game's own option)",
                "off the bar: " .. S.idsText(F.missing) .. "; More holds " .. S.idsText(names) .. ((#miss > 0) and ("; not in it: " .. S.idsText(miss)) or ""))
            S.closeMenu()
        end)
    end
    S.step(2, function() S.cardClose() end)
end
function S.case8()
    local T = {}
    S.step(2, function()
        if S.eqOff then T.off = true; return end
        S.caseStart()
        T.two = S.twoKind()
        if not T.two then Q.say("NOTE 8 card: no weapon the game marks two-handed could be made; the TWO HANDS legs and the fit passes SKIP") end
        S.handsSet(S.sp.knife, nil)
    end)
    S.toEquip("list", T, "8 card")
    S.card8leg(T, "mouse", false)
    S.card8leg(T, "pad", true)
    S.cardFitPass(T, 480, "found")
    S.cardFitPass(T, 480, "large")
    S.step(2, function() S.sizeBack() end)
    S.waitIdle(20)
    S.halfOn(T)
    S.cardFitPass(T, 220, "found")
    S.cardFitPass(T, 220, "large")
    S.step(2, function() S.sizeBack() end)
    S.halfOff(T)
    S.step(20, function()
        Q.check(ZeD.currentSize == S.found.size, "8 card: the text size is back as found", tostring(ZeD.currentSize))
        S.caseClean()
    end)
    S.caseEnd("8 card hand buttons")
end

-- ===================================================================== 9. a weapon dropped on a doll hand box
function S.dropOnDoll(r, item)
    local w = RT.cw()
    local panel = w and w._equipDollPanel
    if not (panel and r and item) then return false, "the doll or its box is not drawn" end
    local x, y = r.x + math.floor(r.w / 2), r.y + math.floor(r.h / 2)
    local took = false
    local ok, err = S.withFields({ { panel, "getMouseX", function() return x end }, { panel, "getMouseY", function() return y end } },
        function() took = ZeD.EquipDoll.takeDrop(S.pn, { item }) end)
    if not ok then S.errs = S.errs + 1; return false, "the drop threw: " .. tostring(err) end
    if took then return true, "takeDrop answered true" end
    -- (takeDrop's gates, read the same way it reads them)
    local why = {}
    why[#why + 1] = "drawer " .. tostring(w._drawerMode) .. "/" .. tostring(w._activeTab) .. ", card " .. S.nm(w._equipSelected) .. ", effW " .. tostring(w._drawerEffW)
    why[#why + 1] = "doll shown " .. tostring(w._equipDollShown) .. ", panel visible " .. tostring(panel:isVisible()) .. " " .. math.floor(panel:getWidth()) .. "x" .. math.floor(panel:getHeight())
    why[#why + 1] = "the point " .. x .. "," .. y .. " (box " .. r.id .. " " .. math.floor(r.x) .. "," .. math.floor(r.y) .. " " .. math.floor(r.w) .. "x" .. math.floor(r.h) .. ")"
    local c = w._equipDollClip
    if c then why[#why + 1] = "clip " .. math.floor(c.x) .. "," .. math.floor(c.y) .. " " .. math.floor(c.w) .. "x" .. math.floor(c.h) end
    local first = nil
    for _, q in ipairs(w._equipDollAll or {}) do
        if x >= q.x and x < q.x + q.w and y >= q.y and y < q.y + q.h then first = q.id; break end
    end
    why[#why + 1] = "first box hit " .. tostring(first)
    pcall(function() why[#why + 1] = "paused look " .. tostring(ZeD.PausedLook and ZeD.PausedLook.on()) end)
    pcall(function() why[#why + 1] = "HandWeapon " .. tostring(instanceof(item, "HandWeapon")) end)
    return false, "takeDrop answered " .. tostring(took) .. " (" .. table.concat(why, "; ") .. ")"
end
function S.dropLeg(T, D)
    local L = {}
    S.step(2, function()
        L.go = nil
        if T.off then return end
        L.it = T.items and T.items[D.k]
        if not L.it then Q.skip("9 " .. D.lab, "the thing could not be made"); return end
        S.loose(L.it)
        S.put(L.it, S.inv())
        S.handsSet(nil, nil)
        S.cardClose()
        local w = RT.cw()
        if w and w._equipScroll and w._equipScroll.visible then pcall(function() w._equipScroll:setScrollPos(1) end) end
    end)
    -- (a few frames for the doll to draw at the new scroll: its boxes and clip are set while it draws, so a box read
    -- the frame after the scroll still has the old place)
    S.waitIdle(8)
    S.wait(10, 120, function() return T.off or not L.it or (S.eqReady("doll") and S.rect(D.box) ~= nil) end, function(ok)
        if T.off or not L.it then return end
        if not Q.check(ok, "9 drop: the doll's " .. D.box .. " box is drawn") then return end
        L.res, L.why = S.dropOnDoll(S.rect(D.box), L.it)
        L.go = true
    end)
    S.wait(4, 900, S.settled(10), S.noop)
    S.step(10, function()
        if not L.go then return end
        local p, s = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
        local ok
        if D.want == "pri" then ok = L.res and p == L.it and s ~= L.it
        elseif D.want == "sec" then ok = L.res and s == L.it and p ~= L.it
        elseif D.want == "both" then ok = L.res and p == L.it and s == L.it
        else ok = p == nil and s == nil and S.where(L.it) == S.inv() and not S.onFloor(L.it) and not S.isWorn(L.it) end
        Q.check(ok, "9 " .. D.lab, L.why .. "; main " .. S.nm(p) .. ", off " .. S.nm(s) .. "; " .. S.nm(L.it) .. " in the inventory "
            .. tostring(S.where(L.it) == S.inv()) .. ", on the floor " .. tostring(S.onFloor(L.it)) .. ", worn " .. tostring(S.isWorn(L.it)))
    end)
end
function S.case9()
    local T = {}
    S.step(2, function()
        if S.eqOff then T.off = true; return end
        S.caseStart()
        T.items = { knife = S.sp.knife, hammer = S.sp.hammer, hat = S.sp.hat, two = S.twoKind(), apple = S.make("apple") }
    end)
    S.toEquip("doll", T, "9 doll hand drop")
    for _, D in ipairs(S.DROPS) do S.dropLeg(T, D) end
    S.step(2, function() S.caseClean() end)
    S.caseEnd("9 doll hand drop")
end

-- ===================================================================== put back
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    S.unstage()
    S.thBack()
    S.park(false)
    S.spyOff()
    S.padOff()
    S.cancelDrags()
    S.closeMenu()
    S.themeBack()
    S.sizeBack()
    S.halfBack()
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    if f.recorded then
        if ZeD.EquipDoll and ZeD.EquipDoll.view() ~= f.view then pcall(ZeD.EquipDoll.setView, f.view) end
        if S.back.disp then S.back.disp = nil; S.setDisp(f.disp) end
    end
    local w = RT.cw()
    if w then
        w._equipSelected = nil
        w._equipClickWait = nil
        if f.recorded and f.charTab then
            w._equipListExpanded = f.listExp
            w._equipExpanded = S.copy(f.exp)
            w._equipColWidths = S.copy(f.colW)
        end
    end
    -- the test's things away, then what the game made from them
    for _, it in ipairs(S.made) do S.removeItem(it) end
    S.sweepNew()
    -- the clothes, worn in their order, and the hands
    for _, e in ipairs(f.worn or {}) do
        if not S.isWorn(e.item) and S.where(e.item) == S.inv() then pcall(function() S.p:setWornItem(e.loc, e.item) end) end
    end
    if f.hands then
        pcall(function() if S.p:getPrimaryHandItem() ~= f.hands.p then S.p:setPrimaryHandItem(f.hands.p) end end)
        pcall(function() if S.p:getSecondaryHandItem() ~= f.hands.s then S.p:setSecondaryHandItem(f.hands.s) end end)
    end
    S.wornEvent()
    S.wetBack()
end
function S.buildPutBack()
    Q.mark()
    -- the core back first (the guard still on): the found TEMPERATURE held until the core is there
    Q.step(2, function()
        if not (S.back.th and not S.bailed) then return end
        S.stage({ temp = S.found.stats and S.found.stats.TEMPERATURE or 37, intox = true })
    end)
    Q.waitFor(2, 900, function()
        if not (S.back.th and not S.bailed) then return true end
        local c = S.core()
        return c ~= nil and math.abs(c - (S.found.stats.TEMPERATURE or 37)) <= 0.2
    end, function() S.unstage() end)
    Q.step(2, function()
        S.putBack()
        RT.pairOpen()
    end)
    Q.step(10, function()
        S.hbBack()
        local f = S.found
        if f.pos then S.goTo(f.pos.x, f.pos.y, f.pos.z) end
        if f.dir then pcall(function() S.p:setDir(f.dir) end) end
        if S.layoutTouched and f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, "et_calls") end
    end)
    Q.step(20, function()
        local f = S.found
        S.cardClose()
        if f.charTab then RT.charTab(f.charTab) end
        S.instant(f.inst)
        local w = RT.cw()
        if w then w._thermalCache = nil; if f.charTab then w._maxWinW = f.maxWinW end end
        pcall(function()
            if f.focusWin == nil then S.F.releaseFocus(S.pn)
            elseif S.F.getFocusedWindow(S.pn) ~= f.focusWin then S.F.claimFocus(f.focusWin) end
        end)
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then Q.skip("put back", "nothing was staged"); return end
        local left, names = 0, {}
        for _, it in ipairs(S.made) do
            if S.where(it) ~= nil or S.onFloor(it) then
                left = left + 1
                if #names < 4 then names[#names + 1] = S.ft(it) end
            end
        end
        Q.check(left == 0, "put back: every thing the test made is gone (inventory, bag, floor, hands, belt)", left .. " of " .. #S.made .. " left " .. S.idsText(names))
        local extra = {}
        for _, it in ipairs(S.list(S.inv())) do if not f.inv0[it] then extra[#extra + 1] = S.ft(it) end end
        Q.check(#extra == 0, "put back: the inventory holds only what it held (nothing the game made from the test's things)", S.idsText(extra))
        local worn, on = 0, S.wornSet()
        for _, e in ipairs(f.worn or {}) do if on[e.item] then worn = worn + 1 end end
        local wl = S.wornList()
        Q.check(worn == #(f.worn or {}) and #wl == #(f.worn or {}), "put back: he wears what he wore, nothing else", worn .. " of " .. #(f.worn or {}) .. " back, " .. #wl .. " worn")
        local hp, hs = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
        Q.check(f.hands == nil or (hp == f.hands.p and hs == f.hands.s), "put back: the hands hold what they held", S.nm(hp) .. ", " .. S.nm(hs))
        local hb, belt = S.hb(), 0
        for _, e in ipairs(f.hb or {}) do
            local onIt = false
            pcall(function() onIt = hb:isInHotbar(e.item) end)
            if onIt then belt = belt + 1 end
        end
        Q.check(belt == #(f.hb or {}), "put back: the belt holds its own things again", belt .. " of " .. #(f.hb or {}))
        local core = S.core()
        if f.stats and f.stats.TEMPERATURE then
            Q.check(core ~= nil and math.abs(core - f.stats.TEMPERATURE) <= 0.3, "put back: the core temperature as found", S.n2(core) .. " C (found " .. S.n2(f.stats.TEMPERATURE) .. " C)")
        end
        local wb = S.wetDiff()
        if #wb > 0 then S.note("put back: the wetness drifted from what was found (weather or drying since it was put back): " .. table.concat(wb, "; ")) end
        Q.check(S.dispC() == f.disp and ZeD.currentBase == f.base and ZeD.currentSize == f.size and ZeD.EquipDoll.view() == f.view,
            "put back: the display unit, the theme, the text size and the Equip view as found",
            tostring(S.dispC()) .. ", " .. tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.currentSize) .. ", " .. tostring(ZeD.EquipDoll.view()))
        local w = RT.cw()
        if w and f.charTab then
            local pickOK = (w._thermalPick == f.tpick) or (f.tpick == nil and w._thermalPick == "Upper Torso")
            Q.check(w._activeTab == f.charTab and w._thermalView == f.tview and pickOK and w._maxWinW == f.maxWinW and w._equipSelected == nil,
                "put back: the Character window's tab, the Thermal view and pick, the width cap as found, no card open",
                "tab " .. tostring(w._activeTab) .. " (found " .. tostring(f.charTab) .. "), view " .. tostring(w._thermalView) .. " (" .. tostring(f.tview)
                .. "), pick " .. tostring(w._thermalPick) .. " (" .. tostring(f.tpick) .. "), width cap " .. tostring(w._maxWinW) .. " (" .. tostring(f.maxWinW)
                .. "), card " .. S.nm(w._equipSelected))
        end
        local held = nil
        pcall(function() held = S.F.getFocusedWindow(S.pn) end)
        Q.check(S.lockFound() == f.lock and held == f.focusWin and S.parked == nil and S.spy == nil and S.w0 == nil and S.back.maxW == nil and S.want == nil,
            "put back: the input lock, the pad focus, the pointer, the draws and the hold the game's own again",
            "lock " .. S.lockFound() .. " (found " .. tostring(f.lock) .. "), focus " .. tostring(held == f.focusWin))
        if S.bailed then Q.check(S.p:isGodMod() == true, "put back: the run stopped early, so god mode is left ON", tostring(S.p:isGodMod()))
        else Q.check(S.p:isGodMod() == (f.god and true or false), "put back: god mode as found", tostring(f.god)) end
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6 and not S.p:isDead(), "put back: he stands where he stood, alive", string.format("%.1f,%.1f off", dx, dy) .. ", health top-ups " .. tostring(S.topUps or 0))
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught")
        local e1 = S.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0 and S.tabErrs == 0, "the calls run ran with no Lua error", (e1 - S.err0) .. " new, the Thermal tab's own " .. S.tabErrs)
        else Q.skip("the calls run's Lua error count", "the game's Lua error count cannot be read here") end
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and RT.isOpen() then RT.pairShut() end
    end)
end

-- ===================================================================== the run
function S.build()
    S.setup()
    S.thSetup()
    S.case1()
    S.case24()
    S.case3()
    S.thEnd()
    S.eqSetup()
    S.case5list()
    S.case5doll()
    S.case5pad()
    S.case5dbl()
    S.case6()
    S.case7()
    S.case8()
    S.case9()
end
S.build()
S.buildPutBack()
Q.start()
