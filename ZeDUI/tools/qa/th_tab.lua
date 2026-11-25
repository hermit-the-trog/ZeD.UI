-- ZeDUI/tools/qa/th_tab.lua  (Nov 24 2026, QA; tag th_tab): the Thermal ("Temperature") tab of the Character window,
-- the whole gamut, in the style of the Health and loot sweeps. Its spec is the map, qa/audits/2026-11-24_map_thermal.md
-- (what the tab shows, where each number comes from, the game's moodle thresholds read from the jar, suspicions T1-T14).
-- Run after zedqa_prelude.lua, rt_kit.lua and eq_tab.lua (et.txt). grep "ZEDQA th_tab". Built the way hg_fit.lua,
-- hg_tint.lua and lv_calls.lua are (their helpers copied: each script stands alone).
--
-- How the tab is read: ThermalTab's draw pieces are wrapped for the run (_renderHeader, _renderCardGrid, _renderPicked,
-- Molecules.drawStatRow / drawStatBarRow, Atoms.drawSegFill, TabFill.block / row and the drawer's drawText), so every
-- check reads what was DRAWN that frame (words, numbers, the bar colour token, where each word sits) and the game's own
-- values read in the same frame. A fresh read is asked for by clearing win._thermalCache (the tab reads the game every
-- 15 frames). The core is held by setting the game's TEMPERATURE stat every player update: the thermoregulator moves
-- the core half way to that stat each update, then writes the stat back from it (Thermoregulator.updateHeatDeltas,
-- javap), so a held stat holds the core. God mode is off for the run (it keeps the moodles off) with hg_fit's guard on
-- every tick (health under 75 topped up, under 35 god mode ON and on to the put-back); invincible on.
-- No controller is plugged into the QA PC: for the pad case ZeD's input mode is locked to the controller
-- (Detector.setLockedMode, put back as found) and the presses go through FocusManager's QA hook and its own dispatch
-- (Focus.qaButton + dispatchJoypadDown / dispatchJoypadDir), lv_calls.lua's way.
--
-- Checks (FAIL = a plain bug; NOTE = data for a design call; SKIP = could not be staged here, said why):
--   setup      the tab's pieces are loaded; the Character window opens on Thermal and the tab draws
--   readings   outdoors, then indoors (a loaded room square within 60 tiles): Core, Air, Wind chill and Body heat in
--              that order; Core matches getCoreCelcius AND the game's TEMPERATURE stat; Air matches getTemperatureAir and
--              ClimateManager:getAirTemperatureForCharacter(false); Wind chill matches getTemperatureAirAndWind and the
--              ClimateManager's (true); Body heat is the game's word for getHeatGenerationUI in thirds; the picked block's
--              8 rows match the game's ...UI getters (value and word); NOTE the outdoor temperature and the WINDCHILL
--              moodle; NOTE indoors when Wind chill is not Air
--   units      the game's display option switched with the tab open: Core, the skin cells and the picked block's skin row
--              change unit on the next frame; the oven's own isCelsius set opposite: Thermal follows the display option
--              (NOTE T6: ThermalTab.lua's comment says the oven reads the same setting; it reads isCelsius); both put back
--   views      each of the 7 views picked from the View list (a click on the box, a click on its row): the figure's 17
--              parts each take the colour band of their reading; the grid's 17 cells (two columns) each show a value;
--              Head, Left Hand and Right Foot match the game's getter for that view; NOTE T3 for insulation and wind
--              (the cell's 0.xx, the picked row's %, the game's raw value)
--   clothes    naked: the game's insulation and wind resistance low on all 17 parts and ZeD's insulation and wind cells
--              equal the game's on all 17; a stocked layered outfit (given): the game's values rise and ZeD's 17 cells
--              follow (NOTE any part at 100%); one bare hand (a hole in the left glove): the game's Left Hand drops below
--              the Right and ZeD's cells show it (SKIP if the game does not drop it); the outfit off, the clothes found
--              back on exactly
--   wet        body and clothing wetness held at dry, 0.3, 0.6 and soaked, then wet clothes on a dry body: the picked
--              block's body and clothing wetness rows match the game (value and Dry / Soaked by halves); NOTE T4 table
--              (the game's WET moodle level against ZeD's word) and NOTE T2 (the colours, dry in the cold colour)
--   core       the core held at 37.0, 37.3, 37.6, 39.2, 40.2, 41.2, 36.8, 36.2, 34.5, 29 and 24 until the moodles
--              settle: Core matches the game; the meter lights max(1, tenths of (core - 30) / 12) in the colour of its
--              fifth; FAIL if the meter reads normal (green) while the game shows Hypothermia or Hyperthermia at level
--              2 or higher; NOTE T1 table (moodle levels against the meter); NOTE T5 at 41.2, 29 and 24 (skin words and
--              colours)
--   themes     Dark, Light and High contrast, each with a cold (33.0) and a hot (40.5) core: the meter takes the theme's
--              own colour token; pictures th_skinTemp_<theme>_<cold|hot>_<w>x<h>; NOTE High contrast's five temperature
--              colours equal Dark's
--   pad        from the figure's heading the D-pad Down walks the stops in order (heading, parts, cells, block head,
--              rows, View box: the zone's order is checked on every step); A on a cell picks it; A on the View box
--              opens the list, the focus on the current view's row, Down and A pick the next view, the list shuts and
--              the focus returns to the box; A again, then B, shuts the list with the view kept and the focus on the
--              box; focus on a part swaps the picked block to that part; NOTE T10 (A on a part picks nothing); T8: the
--              pad on a part, Up to the heading and A folds the figure: the block shows the pick; and the pointer left
--              resting on a part, the pad folds the figure: the block shows the pick (FAIL when it sticks on the part)
--   mouse      the pointer on a cell swaps the block to it, a click picks it, the pointer off shows the pick again; a
--              click on a figure part: NOTE T10 (whether it picks); T9: a part scrolled under the pinned heading must
--              not take the pointer's hover (SKIP when no scroll puts a part under it)
--   layout     the 480 card and the 220 card (held in: the window's width cap lowered for the case), at the text size
--              found and in Large text: T7: every grid cell draws its part's name, whole or cut ("..."); every cell's
--              words stay in the cell; every picked row's words and bar stay in the row and the card; every ZeD window
--              on screen; pictures th_layout_<card>_<size>_<w>x<h>
--   lite       Style set to Lite: the tab still draws its 4 readings, 17 cells and 8 rows with no error
--   car        a pickup spawned (the prelude's helpers), the character seated, the heater on (the game's own part data,
--              as its toggleHeater command sets it) and its warm-engine effect held on the passenger compartment at +25
--              and -25 (the game warms it only with the engine running hot): ZeD's Air and Wind chill match the game's
--              at each; the game's air moved with the heater (SKIP when the game's air did not move or no car could be staged)
--   each case  no Lua error over it (the game's count and ZeD's own "tab thermal" log, where a throwing tab lands)
-- Covered elsewhere and not repeated here: the View list has 7 rows and a pick shuts it, the figure heading folds by
-- click, tempText follows the option (rt_windows 574-627); a cell click through TabFill.onClick picks (rt_media
-- 1603-1663); no strain tint on the figure (rt_strain, hg_tint); the soak cycles the tab (rt_system); bx_health's core
-- check (T13: the same call, it cannot fail). T11 (dead code), T12 (getters read twice) and T14 (no nil guard) are code
-- notes, not behaviour: not tested. Exertion (sprinting, sleeping), a fire, a long-word language and 4K are not staged.
-- Puts back: the core (held at the found TEMPERATURE until it is back), the wetness stat, every body part's wetness, every
-- worn garment's wetness, the clothes worn (the outfit given taken off and away), the display unit and the oven's unit,
-- the theme, the text size, Style, the view, the pick, the figure's fold, the picked block's fold, the body's scroll, the
-- hovered part, the window's width cap and layout, the input lock, the pad focus, the pointer, god mode, invincible, the
-- game speed, the character where he stood, the car taken away, the window pair and its tab; the wrappers off.
if not RT then print("ZEDQA th_tab ERR rt_kit.lua did not run first"); print("ZEDQA th_tab DONE"); return end
local Q = RT.make("th_tab")
Q.maxMs = 1080000                    -- (the put-back runs before 18 minutes are up)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, rec = {}, held = {}, hooked = {}, textBase = {}, renders = 0,
            tabErrs = 0, live = false, t0 = getTimestampMs(), t1 = {}, wetRows = {}, keeping = false, given = {} }
S.F = RT.focus()

-- ===================================================================== constants
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
S.SAMPLE = { "Head", "Left Hand", "Right Foot" }
-- the seven views in ThermalTab's order (VIEWS, TT:43-51): the id its cache keys by, the raw getter, the UI getter
S.VIEWS = {
    { id = "skinTemp", get = "getSkinCelcius", ui = "getSkinCelciusUI", temp = true },
    { id = "response", get = "getBodyResponse", ui = "getBodyResponseUI" },
    { id = "vessels", get = "getPrimaryDelta", ui = "getPrimaryDeltaUI" },
    { id = "shiver", get = "getSecondaryDelta", ui = "getSecondaryDeltaUI" },
    { id = "insul", get = "getInsulation", ui = "getInsulationUI" },
    { id = "wind", get = "getWindresist", ui = "getWindresistUI" },
    { id = "wetness", get = "getBodyWetness", ui = "getBodyWetnessUI" },
}
-- the picked block's eight rows (DETAIL_ROWS, TT:56-73) and the game's scale words (false: two words, split at halves)
S.ROWS = {
    { ui = "getSkinCelciusUI", raw = "getSkinCelcius", temp = true, w = { "IGUI_Temp_Cold", "IGUI_Temp_Normal", "IGUI_Temp_Hot" } },
    { ui = "getBodyResponseUI", w = { "IGUI_Temp_FightCold", "IGUI_Temp_Normal", "IGUI_Temp_FightHot" } },
    { ui = "getPrimaryDeltaUI", w = { "IGUI_Temp_Vasoconstriction", "IGUI_Temp_Normal", "IGUI_Temp_Vasodilation" } },
    { ui = "getSecondaryDeltaUI", w = { "IGUI_Temp_Shivering", "IGUI_Temp_Normal", "IGUI_Temp_Perspiring" } },
    { ui = "getInsulationUI", raw = "getInsulation", w = { "IGUI_Temp_Low", "IGUI_Temp_Med", "IGUI_Temp_High" } },
    { ui = "getWindresistUI", raw = "getWindresist", w = { "IGUI_Temp_Low", "IGUI_Temp_Med", "IGUI_Temp_High" } },
    { ui = "getBodyWetnessUI", w = { "IGUI_Temp_Dry", false, "IGUI_Temp_Soaked" } },
    { ui = "getClothingWetnessUI", w = { "IGUI_Temp_Dry", false, "IGUI_Temp_Soaked" } },
}
S.CORES = { 37.0, 37.3, 37.6, 39.2, 40.2, 41.2, 36.8, 36.2, 34.5, 29, 24 }
S.BANDS = { "tempCold", "tempCool", "tempNorm", "tempWarm", "tempHot" }
S.BAND_WORD = { tempCold = "cold (blue)", tempCool = "cool (teal)", tempNorm = "normal (green)", tempWarm = "warm (amber)",
                tempHot = "hot (red)", none = "none" }
S.THEMES = { { key = "dark", tag = "dark", say = "Dark" }, { key = "light", tag = "light", say = "Light" },
             { key = "hicon", tag = "hc", say = "High contrast" } }
S.OUTFIT = { "Base.LongJohns", "Base.Shirt_Lumberjack", "Base.Jumper_DiamondPatternTINT", "Base.Jacket_Padded",
             "Base.Trousers_Padded", "Base.Socks_Heavy", "Base.Shoes_BlackBoots", "Base.Gloves_LeatherGloves",
             "Base.Hat_WinterHat", "Base.Scarf_White", "Base.Hat_BalaclavaFull" }
S.WETS = { { lab = "dry", body = 0, cloth = 0 }, { lab = "damp 0.3", body = 0.3, cloth = 0.3 },
           { lab = "wet 0.6", body = 0.6, cloth = 0.6 }, { lab = "soaked", body = 1, cloth = 1 },
           { lab = "wet clothes on a dry body", body = 0, cloth = 1 } }

-- ===================================================================== small helpers
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.note(s) Q.say("NOTE " .. tostring(s)) end
function S.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function S.wait(n, max, cond, fn)
    Q.waitFor(n, max, function() if S.dead then return true end; return cond() end,
        function(ok) if S.dead then return end; fn(ok) end)
end
function S.n1(v) local x = tonumber(v); if x == nil then return "?" end; return string.format("%.1f", x) end
function S.n2(v) local x = tonumber(v); if x == nil then return "?" end; return string.format("%.2f", x) end
function S.num(s)
    if s == nil then return nil end
    local m = string.match(tostring(s), "%-?%d+%.?%d*")
    return m and tonumber(m) or nil
end
function S.inList(list, x) for _, v in ipairs(list or {}) do if v == x then return true end end; return false end
function S.near(a, b, e) return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= (e or 0.002) end
function S.sameC(a, b) return a ~= nil and b ~= nil and S.near(a.r, b.r) and S.near(a.g, b.g) and S.near(a.b, b.b) end
function S.cText(c) return c and string.format("%.2f,%.2f,%.2f", c.r or -1, c.g or -1, c.b or -1) or "none" end
function S.screen()
    local w, h = 0, 0
    pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end)
    return math.floor(w), math.floor(h)
end
function S.sizeTag() local w, h = S.screen(); return w .. "x" .. h end
function S.speed(n)
    if n == nil then return end
    local f = ZEDQA_SPEED or setGameSpeed
    if f then pcall(f, n) end
end
function S.gameSpeed() local v = nil; pcall(function() v = getGameSpeed() end); return v end
function S.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function S.setOpt(o, v) if o and v ~= nil then pcall(function() o:setValue(v) end) end end
function S.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function S.goTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z)
    end)
end
function S.labelOf(name) local s = name; pcall(function() s = ZeD.partLabel(name) end); return tostring(s) end
function S.bpOf(name) for _, P in ipairs(S.PARTS) do if P.name == name then return P.bp end end; return nil end
-- the game's three words for a 0..1 value in thirds (mid false: two words, halves)
function S.third(v, lo, mid, hi)
    v = v or 0
    if not mid then return (v < 0.5) and lo or hi end
    if v < 1 / 3 then return lo end
    if v > 2 / 3 then return hi end
    return mid
end
-- a value within 0.02 of a cut: either word passes there (the value moves between the tab's read and this one)
function S.nearCut(v, thirds)
    if type(v) ~= "number" then return false end
    local cuts = thirds and { 1 / 3, 2 / 3 } or { 0.5 }
    for _, c in ipairs(cuts) do if math.abs(v - c) < 0.02 then return true end end
    return false
end
function S.clamp01(v) v = tonumber(v) or 0; if v < 0 then return 0 end; if v > 1 then return 1 end; return v end

-- ===================================================================== units
function S.celsius() local c = true; pcall(function() c = ZeD.ThermalTab.useCelsius() end); return c end
function S.toUnit(c, cel) if type(c) ~= "number" then return nil end; if cel then return c end; return c * 9 / 5 + 32 end
function S.tol(cel) return cel and 0.15 or 0.27 end
function S.dispC() local v = nil; pcall(function() v = getCore():getOptionDisplayAsCelsius() end); return v end
function S.setDisp(b) pcall(function() getCore():setOptionDisplayAsCelsius(b and true or false) end) end
function S.ovenC() local v = nil; pcall(function() v = getCore():isCelsius() end); return v end
function S.setOven(b) pcall(function() getCore():setCelsius(b and true or false) end) end

-- ===================================================================== the body and the game's values
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
-- the game's values this frame (read beside each drawn header, so a check compares one frame with itself)
function S.gameNow()
    local g = {}
    local t = S.thermo()
    if not t then return g end
    pcall(function() g.core = t:getCoreCelcius() end)
    pcall(function() g.air = t:getTemperatureAir() end)
    pcall(function() g.wind = t:getTemperatureAirAndWind() end)
    pcall(function() g.heat = t:getHeatGenerationUI() end)
    g.stat = S.stat("TEMPERATURE")
    pcall(function()
        local c = getClimateManager()
        g.cAir = c:getAirTemperatureForCharacter(S.p, false)
        g.cWind = c:getAirTemperatureForCharacter(S.p, true)
        g.outside = c:getTemperature()
    end)
    return g
end
-- the worn things: { loc, item }
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
function S.isClothing(it) local ok = false; if it then pcall(function() ok = instanceof(it, "Clothing") end) end; return ok end
function S.wornClothes() local out = {}; for _, e in ipairs(S.wornList()) do if S.isClothing(e.item) then out[#out + 1] = e.item end end; return out end
function S.clothesChanged() pcall(function() triggerEvent("OnClothingUpdated", S.p) end); pcall(function() S.p:resetModelNextFrame() end) end

-- ===================================================================== colour bands
-- the band a 0..1 value takes (getThermalColor, TT:144-152: cuts at fifths)
function S.bandFor(v)
    v = S.clamp01(v)
    if v < 0.2 then return "tempCold" end
    if v < 0.4 then return "tempCool" end
    if v < 0.6 then return "tempNorm" end
    if v < 0.8 then return "tempWarm" end
    return "tempHot"
end
function S.bandOK(b, v) return b == S.bandFor(v) or b == S.bandFor((v or 0) - 0.004) or b == S.bandFor((v or 0) + 0.004) end
function S.bandOf(c)
    if not c then return "none" end
    for _, tok in ipairs(S.BANDS) do if S.sameC(c, ZeD.T[tok]) then return tok end end
    return "none"
end
function S.bw(b) return S.BAND_WORD[b or "none"] or tostring(b) end

-- ===================================================================== the draw, recorded (wrappers on for the run)
-- S.rec.header = { rows = { {label, value} x4 }, seg = { n, lit, color }, data, game, t }
-- S.rec.grid = { cells = { {x, y, w, h, value, label, pct, color, texts} }, view, data }
-- S.rec.picked = { title, folded, rows = { {x, y, w, h, label, value, word, bar, color, texts, segs} } }
function S.textHook(self, s, x, y, r, g, b, a, font)
    local m = S.rmode
    if m == "grid" and S.rgrid and S.rgrid.cur then
        local c = S.rgrid.cur
        c.texts[#c.texts + 1] = { s = s, x = x, y = y, font = font }
    elseif m == "picked" and S.rpk and S.rpk.cur then
        local c = S.rpk.cur
        c.texts[#c.texts + 1] = { s = s, x = x, y = y, font = font }
    end
    local base = S.textBase[self]
    return base(self, s, x, y, r, g, b, a, font)
end
function S.hook(panel)
    if not panel or S.hooked[panel] then return end
    S.hooked[panel] = { own = rawget(panel, "drawText") }
    S.textBase[panel] = panel.drawText
    panel.drawText = S.textHook
end
function S.unhook()
    for panel, h in pairs(S.hooked) do pcall(function() rawset(panel, "drawText", h.own) end) end
    S.hooked, S.textBase = {}, {}
end
function S.wrapOn()
    if S.w0 then return end
    local TT, M, A, F = ZeD.ThermalTab, ZeD.Molecules, ZeD.Atoms, ZeD.TabFill
    S.w0 = { hdr = TT._renderHeader, grid = TT._renderCardGrid, picked = TT._renderPicked, stat = M.drawStatRow,
             bar = M.drawStatBarRow, seg = A.drawSegFill, block = F.block, row = F.row, log = ZeD.logOnce }
    local W = S.w0
    TT._renderHeader = function(panel, win, data, rx, ry, rw)
        local h = { rows = {}, data = data, x = rx, y = ry, w = rw, t = getTimestampMs() }
        S.rmode, S.rhdr = "header", h
        local ok, e = pcall(W.hdr, panel, win, data, rx, ry, rw)
        S.rmode = nil
        if S.live then h.game = S.gameNow() end
        S.rec.header = h
        S.renders = S.renders + 1
        if not ok then error(e, 0) end
    end
    M.drawStatRow = function(panel, x, y, w, label, value, valueColor, labelFont)
        if S.rmode == "header" and S.rhdr then
            local r = S.rhdr.rows
            r[#r + 1] = { label = label, value = value }
        end
        return W.stat(panel, x, y, w, label, value, valueColor, labelFont)
    end
    A.drawSegFill = function(panel, x, y, w, h, n, k, color)
        local m = S.rmode
        if m == "header" and S.rhdr and not S.rhdr.seg then
            S.rhdr.seg = { n = n, lit = k, color = color, x = x, y = y, w = w, h = h }
        elseif m == "picked" and S.rpk and S.rpk.cur then
            local c = S.rpk.cur
            c.segs[#c.segs + 1] = { x = x, y = y, w = w, h = h, color = color }
        end
        return W.seg(panel, x, y, w, h, n, k, color)
    end
    TT._renderCardGrid = function(panel, win, data, rx, ry, rw, rh)
        local g = { cells = {}, x = rx, y = ry, w = rw, view = win and win._thermalView or nil, data = data }
        S.hook(panel)
        S.rmode, S.rgrid = "grid", g
        local ok, e = pcall(W.grid, panel, win, data, rx, ry, rw, rh)
        S.rmode = nil
        S.rec.grid = g
        if not ok then error(e, 0) end
    end
    M.drawStatBarRow = function(panel, x, y, w, value, label, fillRatio, fillColor, valueColor, flat)
        if S.rmode == "grid" and S.rgrid then
            local c = { x = x, y = y, w = w, value = value, label = label, pct = fillRatio, color = fillColor, texts = {} }
            S.rgrid.cur = c
            local ok, h = pcall(W.bar, panel, x, y, w, value, label, fillRatio, fillColor, valueColor, flat)
            S.rgrid.cur = nil
            if not ok then error(h, 0) end
            c.h = h
            S.rgrid.cells[#S.rgrid.cells + 1] = c
            return h
        end
        return W.bar(panel, x, y, w, value, label, fillRatio, fillColor, valueColor, flat)
    end
    TT._renderPicked = function(panel, win, data, x, y, w)
        if not panel then return W.picked(panel, win, data, x, y, w) end
        local pk = { rows = {}, x = x, y = y, w = w, t = getTimestampMs() }
        S.hook(panel)
        S.rmode, S.rpk = "picked", pk
        local ok, r = pcall(W.picked, panel, win, data, x, y, w)
        S.rmode = nil
        S.rec.picked = pk
        if not ok then error(r, 0) end
        return r
    end
    F.block = function(panel, win, key, block, x, y, w, label, count, rows, opts)
        if panel and key == "thermal" and S.rmode == "picked" and S.rpk then
            S.rpk.title = label
            S.rpk.folded = F.folded(win, key, block)
        end
        return W.block(panel, win, key, block, x, y, w, label, count, rows, opts)
    end
    F.row = function(panel, win, key, r, x, y, w, opts)
        if panel and key == "thermal" and S.rmode == "picked" and S.rpk then
            local row = { x = x, y = y, w = w, label = r.label, value = r.value, word = r.word, bar = r.bar, color = r.barColor,
                          texts = {}, segs = {} }
            S.rpk.cur = row
            local ok, h = pcall(W.row, panel, win, key, r, x, y, w, opts)
            S.rpk.cur = nil
            if not ok then error(h, 0) end
            row.h = h
            S.rpk.rows[#S.rpk.rows + 1] = row
            return h
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
    M.drawStatRow, M.drawStatBarRow, A.drawSegFill = W.stat, W.bar, W.seg
    F.block, F.row, ZeD.logOnce = W.block, W.row, W.log
    S.w0 = nil
    S.rmode = nil
    S.unhook()
end
function S.hdr() return S.rec.header end
-- ask the tab for a fresh read of the game on its next draw; fresh() once it has drawn twice since
function S.ask() S.reqAt = S.renders; local w = RT.cw(); if w then w._thermalCache = nil end end
function S.fresh() return S.reqAt ~= nil and S.renders >= S.reqAt + 2 end
function S.readThen(lab, fn)
    S.step(1, S.ask)
    S.wait(1, 180, S.fresh, function(ok)
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

-- ===================================================================== the hold (every player update)
-- S.want = { temp = core C, wet = 0..1 body, cloth = 0..1 garments, pc = the car's compartment C }
function S.apply()
    local W = S.want
    if not W then return end
    if W.temp then S.setStat("TEMPERATURE", W.temp) end
    if W.wet ~= nil then
        S.setStat("WETNESS", W.wet * S.statMax("WETNESS"))
        for _, bp in ipairs(S.bodyParts()) do pcall(function() bp:setWetness(W.wet * 100) end) end
    end
    if W.cloth ~= nil then
        for _, it in ipairs(S.wornClothes()) do pcall(function() it:setWetness(W.cloth * 100) end) end
    end
    if W.pc ~= nil and S.car then
        pcall(function()
            local pc = S.car:getPartById("PassengerCompartment")
            if pc then pc:getModData().temperature = W.pc end
            local ht = S.car:getPartById("Heater")
            if ht then local md = ht:getModData(); md.active = true; md.temperature = W.pc end
        end)
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

-- ===================================================================== the guard (hg_fit's): god mode off for the moodles
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
function S.guard()
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
    if getTimestampMs() - S.t0 > Q.maxMs + 150000 then
        S.live = false
        pcall(S.putBack)
        Q.say("ERR the put-back did not come in time: the guard put the character back")
    end
end
function S.safety()
    if not S.live then return end
    local ok, err = pcall(S.guard)
    if not ok and not S.guardSaid then
        S.guardSaid = true
        Q.say("ERR the guard threw: " .. tostring(err))
        pcall(function() S.p:setGodMod(true) end)
        S.bail("the guard threw: god mode ON")
    end
end

-- ===================================================================== windows, the pointer, pictures
function S.holdWin(w)
    if not w then return end
    for _, h in ipairs(S.held) do if h.w == w then return end end
    S.held[#S.held + 1] = { w = w, own = rawget(w, "pointerOn") }
    w.pointerOn = function() return true end
end
function S.unholdAll()
    for _, h in ipairs(S.held) do h.w.pointerOn = h.own end
    S.held = {}
end
-- the game's pointer read answers (sx, sy) until mouseBack (screen pixels); park = far off every window
function S.mouseAt(sx, sy)
    if not S.mouse then S.mouse = { mx = getMouseX, my = getMouseY } end
    getMouseX = function() return sx end
    getMouseY = function() return sy end
    pcall(function() Mouse.setCursorVisible(false) end)
end
function S.mouseBack()
    if not S.mouse then return end
    getMouseX, getMouseY = S.mouse.mx, S.mouse.my
    S.mouse = nil
    pcall(function() Mouse.setCursorVisible(true) end)
end
function S.park() S.mouseAt(-9000, -9000) end
function S.shot(name, what)
    local st = {}
    S.step(1, function() st.had = S.mouse ~= nil; S.park() end)
    S.step(4, function()
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then S.note("picture Zomboid/Screenshots/" .. file .. " | " .. what)
        else S.note("the picture " .. name .. " was not taken: " .. tostring(e)) end
        if not st.had then S.mouseBack() end
    end)
    Q.waitMs(1200)
end
function S.drawer() local w = RT.cw(); return w and w._drawerPanel or nil end
-- a panel's place on screen (its draws are panel-local; the game's pointer read takes off the panel's scroll)
function S.abs(panel)
    local x, y, xs, ys = 0, 0, 0, 0
    pcall(function() x, y = panel:getAbsoluteX(), panel:getAbsoluteY() end)
    pcall(function() xs = panel:getXScroll() or 0 end)
    pcall(function() ys = panel:getYScroll() or 0 end)
    return x + (tonumber(xs) or 0), y + (tonumber(ys) or 0)
end
function S.toScreen(lx, ly) local ax, ay = S.abs(S.drawer()); return ax + lx, ay + ly end
-- a press and its release on the drawer at x, y (drawer-local), through its own mouse handlers (rt_windows' X.clickAt)
function S.click(x, y)
    local d = S.drawer()
    if not d then return false end
    local ok = pcall(function() d:onMouseDown(x, y) end)
    pcall(function() d:onMouseUp(x, y) end)
    return ok
end
function S.mid(z) return z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2) end
function S.inBody(z)
    local v = RT.cw() and RT.cw()._thermalBodyRect
    return v ~= nil and z.y >= v.y and z.y + z.h <= v.y + v.h and z.x >= v.x and z.x + z.w <= v.x + v.w
end
-- the window's scroll of the tab's body (0..1)
function S.scroll(p) local w = RT.cw(); local s = w and w._thermalScroll; if s then pcall(function() s:setScrollPos(p) end) end end
function S.scrollPos() local w = RT.cw(); local s = w and w._thermalScroll; return s and s.scrollPos or 0 end
-- a view set at once (the pick path is the list: S.pickView)
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

-- ===================================================================== theme, text size (lv_calls')
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
    local o = S.zopt("textSize")
    if o and S.found.sizeIdx then pcall(function() o:setValue(S.found.sizeIdx) end) end
    pcall(ZeD.applyTheme, nil, nil, S.found.size)
end

-- ===================================================================== the pad (lv_calls')
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
    return true
end
function S.padOff()
    if not S.back.pad then return end
    S.back.pad = nil
    for _, b in ipairs({ "A", "B" }) do RT.pad(b, nil) end
    local Det = ZeD.Input and ZeD.Input.Detector
    pcall(function()
        Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then Det.setLockedMode(S.lockWas) end
    end)
end
-- the pad on the Character window with its marks showing (a claim in pad mode shows them)
function S.padClaim()
    local w = RT.cw()
    if not (w and S.F) then return end
    pcall(S.F.releaseFocus, S.pn)
    pcall(S.F.claimFocus, w)
end
function S.focEl() local w = RT.cw(); local e = nil; pcall(function() e = S.F.getFocusedElement(w) end); return e end
function S.focId() local e = S.focEl(); return e and e.id or nil end
function S.focusOn(pred)
    local w = RT.cw()
    local e = nil
    if w and S.F and S.F.focusWhere then pcall(function() e = S.F.focusWhere(w, "charTabContent", pred) end) end
    return e
end
function S.tabEls()
    local w = RT.cw()
    for _, z in ipairs(w and w._focusRing or {}) do if z.zone == "charTabContent" then return z.elements or {} end end
    return {}
end
-- a tap: the QA hook holds the button, FocusManager's dispatch takes the press on the window, up after 4 frames, then
-- the hook lets go (gate false: nothing pressed)
function S.tap(name, joy, gate)
    local st = {}
    S.step(1, function()
        if gate and not gate() then return end
        st.on = true
        RT.pad(name, true)
        if joy then RT.padDown(Joypad[joy], RT.cw()) end
    end)
    S.step(4, function() if st.on then RT.pad(name, false) end end)
    S.step(4, function() if st.on then RT.pad(name, nil) end end)
end
-- the kind of a stop by its id, in the order the tab's stops should come
S.KINDS = { "heading", "part", "cell", "block head", "row", "grid scroll", "View box", "list row" }
function S.kindOf(id)
    id = tostring(id or "")
    if id == "thermal:__disclosure" then return 1 end
    if string.sub(id, 1, 12) == "thermalpart:" then return 2 end
    if string.sub(id, 1, 18) == "fill:thermal:cell:" then return 3 end
    if string.sub(id, 1, 18) == "fill:thermal:head:" then return 4 end
    if string.sub(id, 1, 17) == "fill:thermal:row:" then return 5 end
    if id == "thermal:__gridscroll" then return 6 end
    if id == "thermal:view" then return 7 end
    if string.sub(id, 1, 16) == "thermal:viewRow:" then return 8 end
    return 0
end
-- the stops' kinds in the zone's order: is it heading, parts, cells, block head, rows, View box?
function S.orderOf(els)
    local seq, ok, last = {}, true, 0
    for _, e in ipairs(els) do
        local k = S.kindOf(e.id)
        if k ~= last then seq[#seq + 1] = S.KINDS[k] or ("other " .. tostring(e.id)) end
        if k < last or k == 0 then ok = false end
        last = k
    end
    return ok, table.concat(seq, ", ")
end

-- ===================================================================== case bookends
function S.caseEnd(label)
    S.step(1, function()
        local w = RT.cw()
        if w and w._thermalMenuOpen then pcall(ZeD.ThermalTab.closeMenu, w); w._thermalReturnToMenu = nil end
        local e1 = S.errN()
        local te = S.tabErrs - (S.te0 or 0)
        Q.check((S.e0 == nil or e1 == nil or e1 == S.e0) and te == 0, label .. ": no Lua error over the case",
            ((S.e0 and e1) and ((e1 - S.e0) .. " new") or "the game's count cannot be read") .. ", the tab's own " .. te
            .. (te > 0 and (" (" .. tostring(S.tabErrLast) .. ")") or ""))
        S.e0 = e1
        S.te0 = S.tabErrs
    end)
end
-- the tab in front, its figure open, the picked block open, the body at its top
function S.front()
    RT.pairOpen()
    local w = RT.cw()
    if not w then return end
    if w._activeTab ~= "thermal" then RT.charTab("thermal") end
    w._thermalFigureExpanded = true
    S.pickedFoldSet(false)
    S.holdWin(w)
end

-- ===================================================================== checks shared by the cases
function S.tempRow(lab, name, shown, cached, game, getter, cel, clim)
    local s = tostring(shown)
    local same = cached ~= nil and s == ZeD.ThermalTab.tempText(cached, cel)
    local v = S.num(s)
    local ok = v ~= nil and game ~= nil and math.abs(v - S.toUnit(game, cel)) <= S.tol(cel)
    local okC = clim == nil or (game ~= nil and math.abs(clim - game) < 0.01)
    Q.check(same and ok and okC, lab .. ": " .. name .. " shows the game's " .. getter .. (clim and " (ClimateManager agrees)" or ""),
        "shown " .. s .. ", the game " .. S.n2(game) .. " C" .. (clim and (", ClimateManager " .. S.n2(clim) .. " C") or "")
        .. (same and "" or (", ZeD's own read " .. S.n2(cached) .. " C")))
end
function S.readCheck(lab)
    local h = S.hdr()
    if not Q.check(h ~= nil and #h.rows >= 4, lab .. ": the tab drew its four readings", h and (#h.rows .. " rows") or "nothing drawn") then return end
    local g, d, cel = h.game or {}, h.data or {}, S.celsius()
    local labs = { ZeD.tr("UI_ZeD_Thermal_Core"), ZeD.tr("UI_ZeD_Thermal_Air"), ZeD.tr("UI_ZeD_Thermal_WindChill"), getText("IGUI_Temp_BodyHeat") }
    local lb = {}
    for i = 1, 4 do if tostring(h.rows[i].label) ~= tostring(labs[i]) then lb[#lb + 1] = i .. ": " .. tostring(h.rows[i].label) end end
    Q.check(#lb == 0, lab .. ": the readings are Core, Air, Wind chill and Body heat in that order",
        #lb == 0 and table.concat(labs, ", ") or table.concat(lb, "; "))
    S.tempRow(lab, "Core", h.rows[1].value, d.coreTemp, g.core, "getCoreCelcius", cel)
    local shown = S.num(h.rows[1].value)
    Q.check(shown ~= nil and g.stat ~= nil and math.abs(shown - S.toUnit(g.stat, cel)) <= S.tol(cel),
        lab .. ": Core matches the game's TEMPERATURE stat", "shown " .. tostring(h.rows[1].value) .. ", the stat " .. S.n2(g.stat) .. " C")
    S.tempRow(lab, "Air", h.rows[2].value, d.airTemp, g.air, "getTemperatureAir", cel, g.cAir)
    S.tempRow(lab, "Wind chill", h.rows[3].value, d.windTemp, g.wind, "getTemperatureAirAndWind", cel, g.cWind)
    local want = getText(S.third(g.heat, "IGUI_Temp_Low", "IGUI_Temp_Normal", "IGUI_Temp_High"))
    local word = tostring(h.rows[4].value)
    Q.check(word == want or S.nearCut(g.heat, true), lab .. ": Body heat is the game's word for getHeatGenerationUI (thirds)",
        "shown " .. word .. ", the game " .. S.n2(g.heat) .. " (" .. want .. ")")
end
-- the picked block's 8 rows against the game's getters for the region it shows
function S.pickedCheck(lab, name)
    local pk = S.rec.picked
    local w = RT.cw()
    name = name or (w and w._thermalPick) or "Upper Torso"
    if not (pk and #pk.rows == 8) then
        Q.check(false, lab .. ": the picked block draws its 8 rows", pk and (#pk.rows .. " rows" .. (pk.folded and " (folded)" or "")) or "not drawn")
        return
    end
    local cel = S.celsius()
    local bad, seen = {}, {}
    for i, R in ipairs(S.ROWS) do
        local row = pk.rows[i]
        local ui = S.nv(name, R.ui)
        local v = S.num(row.value)
        local okV
        if R.temp then
            local raw = S.nv(name, R.raw)
            okV = v ~= nil and raw ~= nil and math.abs(v - S.toUnit(raw, cel)) <= S.tol(cel) * 2
        else
            okV = v ~= nil and ui ~= nil and math.abs(v - math.floor(S.clamp01(ui) * 100 + 0.5)) <= 2
        end
        local wantW = (ui ~= nil) and getText(S.third(S.clamp01(ui), R.w[1], R.w[2], R.w[3])) or "?"
        local okW = tostring(row.word) == wantW or S.nearCut(ui, R.w[2] ~= false)
        seen[#seen + 1] = tostring(row.value) .. " " .. tostring(row.word)
        if not (okV and okW) then
            bad[#bad + 1] = i .. " " .. tostring(row.label) .. ": " .. tostring(row.value) .. " " .. tostring(row.word) .. " (the game "
                .. (R.temp and (S.n1(S.nv(name, R.raw)) .. " C, ") or "") .. S.n2(ui) .. ", " .. wantW .. ")"
        end
    end
    local title = tostring(pk.title)
    Q.check(#bad == 0 and title == S.labelOf(name), lab .. ": the picked block (" .. S.labelOf(name) .. ") shows the game's 8 values and words",
        (#bad == 0 and "" or (table.concat(bad, "; ") .. " | ")) .. "title " .. title .. "; " .. table.concat(seen, ", "))
end
-- the grid's cells for view i against the game's getter, for the named parts
function S.cellsCheck(lab, i, names)
    local V = S.VIEWS[i]
    local cel = S.celsius()
    local g = S.rec.grid
    if not (g and g.view == i) then Q.check(false, lab .. ": the grid shows view " .. i, "it drew view " .. tostring(g and g.view)); return end
    local bad, seen = {}, {}
    for _, name in ipairs(names) do
        local c = S.cellOf(name)
        local v = c and S.num(c.value)
        local gv = V.temp and S.nv(name, V.get) or S.nv(name, V.ui)
        local exp = V.temp and S.toUnit(gv, cel) or gv
        local tol = V.temp and S.tol(cel) * 2 or 0.02
        if not (v and exp and math.abs(v - exp) <= tol) then bad[#bad + 1] = name .. " " .. tostring(c and c.value) .. " (the game " .. S.n2(exp) .. ")" end
        seen[#seen + 1] = name .. " " .. tostring(c and c.value)
    end
    Q.check(#bad == 0, lab .. ": the grid's " .. V.id .. " cells match the game's " .. (V.temp and V.get or V.ui) .. " (" .. #names .. " parts)",
        #bad == 0 and table.concat(seen, ", ") or table.concat(bad, "; "))
end
function S.allNames() local t = {}; for _, P in ipairs(S.PARTS) do t[#t + 1] = P.name end; return t end
-- set view i, then a fresh read, then fn
function S.viewRead(i, lab, fn)
    S.step(1, function() S.setView(i) end)
    S.readThen(lab, fn)
end

-- ===================================================================== setup
function S.setup()
    S.step(10, function()
        local TT = ZeD and ZeD.ThermalTab
        local ready = TT ~= nil and TT._renderHeader ~= nil and TT._renderCardGrid ~= nil and TT._renderPicked ~= nil
            and TT.tempText ~= nil and TT.useCelsius ~= nil and TT.closeMenu ~= nil and TT.openMenu ~= nil and ZeD.TabFill ~= nil
            and ZeD.TabFill.row ~= nil and ZeD.TabFill.block ~= nil and ZeD.Molecules.drawStatRow ~= nil
            and ZeD.Molecules.drawStatBarRow ~= nil and ZeD.Atoms.drawSegFill ~= nil and ZeD.Atoms.fillSegsLit ~= nil
            and ZeD.partLabel ~= nil and ZeD.logOnce ~= nil and S.thermo() ~= nil and S.cs("TEMPERATURE") ~= nil
            and S.cs("WETNESS") ~= nil and MoodleType ~= nil and MoodleType.HYPOTHERMIA ~= nil and S.F ~= nil
        if not Q.check(ready, "setup: the Thermal tab, its draw pieces and the game's thermoregulator are loaded") then S.dead = true; return end
        local f = S.found
        S.err0 = S.errN()
        S.e0, S.te0 = S.err0, 0
        f.pair = RT.isOpen()
        f.god = S.p:isGodMod()
        pcall(function() f.inv = S.p:isInvincible() end)
        f.speed = S.gameSpeed()
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        f.stats = {}
        for _, k in ipairs({ "TEMPERATURE", "WETNESS", "INTOXICATION", "ENDURANCE", "FATIGUE" }) do f.stats[k] = S.stat(k) end
        f.partWet = {}
        for i, bp in ipairs(S.bodyParts()) do pcall(function() f.partWet[i] = bp:getWetness() end) end
        f.worn = S.wornList()
        f.clothWet = {}
        for _, it in ipairs(S.wornClothes()) do pcall(function() f.clothWet[it] = it:getWetness() end) end
        f.disp, f.oven = S.dispC(), S.ovenC()
        f.base, f.baseIdx = ZeD.currentBase, S.optVal(S.zopt("baseTheme"))
        f.size, f.sizeIdx = ZeD.currentSize, S.optVal(S.zopt("textSize"))
        f.style = S.optVal(ZeD.Settings and ZeD.Settings.lookStyleOption)
        pcall(function() f.focusWin = S.F.getFocusedWindow(S.pn) end)
        f.lock = S.lockFound()
        local bd = S.bd()
        f.zInf = false
        pcall(function() f.zInf = bd:isInfected() end)
        f.recorded = true
        S.back.on = true
        S.speed(1)
        S.live = true
        Events.OnTick.Add(S.safety)
        pcall(function() S.p:setInvincible(true) end)
        pcall(function() S.p:setGodMod(false) end)
        Q.check(S.p:isGodMod() == false, "setup: god mode is off for the run (it keeps the moodles off), the guard is on", "was " .. tostring(f.god))
        S.wrapOn()
        RT.pairOpen()
        Q.say("found: core " .. S.n2(S.core()) .. " C, intoxication " .. S.n2(f.stats.INTOXICATION) .. ", units " .. (f.disp and "C" or "F")
            .. " (the oven " .. (f.oven and "C" or "F") .. "), theme " .. tostring(f.base) .. ", text " .. tostring(f.size) .. ", Style "
            .. tostring(f.style) .. ", " .. #f.worn .. " things worn, input lock " .. tostring(f.lock) .. ", at "
            .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", screen " .. S.sizeTag())
    end)
    S.wait(10, 300, function() local w = RT.cw(); return w ~= nil and w:isReallyVisible() and w._tabStripPanel ~= nil end, function(ok)
        local w = RT.cw()
        local f = S.found
        f.tab = w and w._activeTab or nil
        if w then
            f.view, f.pick, f.fold = w._thermalView, w._thermalPick, w._thermalFigureExpanded and true or false
            f.hovered, f.maxWinW = w._thermalHoveredPart, w._maxWinW
            f.pickedFold = ZeD.TabFill.folded(w, "thermal", "picked") and true or false
        end
        S.snap = ZEDQA_LAYOUT_SNAP and ZEDQA_LAYOUT_SNAP() or nil
        if not Q.check(ok and RT.charTab("thermal"), "setup: the Character window opens on the Thermal tab", tostring(f.tab)) then S.dead = true end
    end)
    S.wait(5, 300, function() local w = RT.cw(); return w ~= nil and w._activeTab == "thermal" and S.rec.header ~= nil and S.rec.grid ~= nil end, function(ok)
        if not Q.check(ok, "setup: the Thermal tab draws (its readings and its grid are read off the draw)") then S.dead = true; return end
        local w = RT.cw()
        S.found.view = S.found.view or w._thermalView
        S.found.pick = S.found.pick or w._thermalPick
        S.found.scroll = S.scrollPos()
        S.front()
        S.scroll(0)
    end)
end

-- ===================================================================== readings: outdoors and indoors
function S.indoorSquare()
    local px, py, pz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    local found = nil
    pcall(function()
        local cell = getCell()
        for r = 1, 60 do
            for dx = -r, r do
                for _, dy in ipairs({ -r, r }) do
                    local sq = cell:getGridSquare(px + dx, py + dy, pz)
                    if sq and sq:getRoom() ~= nil and sq:isFree(false) and sq:getChunk() ~= nil then found = sq; return end
                end
            end
            for dy = -r + 1, r - 1 do
                for _, dx in ipairs({ -r, r }) do
                    local sq = cell:getGridSquare(px + dx, py + dy, pz)
                    if sq and sq:getRoom() ~= nil and sq:isFree(false) and sq:getChunk() ~= nil then found = sq; return end
                end
            end
        end
    end)
    return found
end
function S.inRoom() local r = false; pcall(function() r = S.p:getCurrentSquare():getRoom() ~= nil end); return r end
function S.airNote(where)
    local h = S.hdr()
    local g = h and h.game or {}
    S.note("readings " .. where .. ": the game's outdoor temperature " .. S.n1(g.outside) .. " C, air " .. S.n1(g.air) .. " C, wind chill "
        .. S.n1(g.wind) .. " C, body heat " .. S.n2(g.heat) .. ", WINDCHILL moodle " .. S.moodle("WINDCHILL") .. ", in a room " .. tostring(S.inRoom()))
end
function S.caseReadings()
    local T = {}
    S.step(1, function() S.front(); S.setView(1); S.scroll(0) end)
    S.readThen("readings outdoors", function()
        if S.inRoom() then S.note("readings outdoors: the character stands in a room here; this pass reads wherever he stands") end
        S.readCheck("readings outdoors")
        S.pickedCheck("readings outdoors")
        S.airNote("outdoors")
    end)
    S.step(1, function()
        local sq = S.indoorSquare()
        if not sq then T.off = true; Q.skip("readings indoors", "no loaded, free room square within 60 tiles of the character"); return end
        S.goTo(sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ())
        S.back.moved = true
        T.at = sq:getX() .. "," .. sq:getY()
    end)
    S.wait(30, 600, function() return T.off or S.inRoom() end, function(ok)
        if T.off then return end
        if not ok then T.off = true; Q.skip("readings indoors", "moved to " .. tostring(T.at) .. " but the game does not put him in a room") end
    end)
    S.waitIdle(60)
    S.readThen("readings indoors", function()
        if T.off then return end
        S.readCheck("readings indoors (" .. tostring(T.at) .. ")")
        local h = S.hdr()
        local air, wind = h and h.rows[2] and tostring(h.rows[2].value), h and h.rows[3] and tostring(h.rows[3].value)
        if air ~= wind then S.note("readings indoors: Wind chill " .. tostring(wind) .. " is not Air " .. tostring(air) .. " (indoors there is no wind)") end
        S.airNote("indoors")
    end)
    S.step(1, function()
        local f = S.found
        if f.pos then S.goTo(f.pos.x, f.pos.y, f.pos.z) end
    end)
    S.waitIdle(30)
    S.caseEnd("readings")
end
function S.waitIdle(n) Q.step(n, function() end) end

-- ===================================================================== units: C and F, with the tab open
function S.unitCheck(lab, cel, nextFrame)
    local h = S.hdr()
    local d = h and h.data
    local w = RT.cw()
    local TT = ZeD.ThermalTab
    local core = h and h.rows[1] and tostring(h.rows[1].value)
    local want = d and TT.tempText(d.coreTemp or 0, cel)
    local c = S.cellOf("Head")
    local nd = d and d.nodes and d.nodes["Head"]
    local wantC = nd and TT.tempText(nd.skinTemp or 0, cel)
    local pk = S.rec.picked
    local r1 = pk and pk.rows[1]
    local np = d and d.nodes and w and d.nodes[w._thermalPick or "Upper Torso"]
    local wantR = np and TT.tempText(np.getSkinCelcius or 0, cel)
    Q.check(core ~= nil and core == want and c ~= nil and tostring(c.value) == wantC and r1 ~= nil and tostring(r1.value) == wantR
        and S.celsius() == cel,
        lab .. ": Core, the skin cells and the picked block's skin row show " .. (cel and "Celsius" or "Fahrenheit") .. (nextFrame and " on the next frame" or ""),
        "Core " .. tostring(core) .. " (want " .. tostring(want) .. "), Head cell " .. tostring(c and c.value) .. " (want " .. tostring(wantC)
        .. "), skin row " .. tostring(r1 and r1.value) .. " (want " .. tostring(wantR) .. "); the option " .. tostring(S.dispC()) .. ", the oven " .. tostring(S.ovenC()))
end
function S.caseUnits()
    local U = {}
    S.step(1, function() S.front(); S.setView(1); S.scroll(0) end)
    S.readThen("units", function()
        U.disp, U.oven = S.dispC(), S.ovenC()
        if U.disp == nil then U.off = true; Q.skip("units", "the game's display option cannot be read"); return end
        S.back.units = true
        S.setDisp(not U.disp)
        U.t = S.renders
    end)
    S.wait(1, 30, function() return U.off or S.renders >= (U.t or 0) + 1 end, function(ok)
        if U.off then return end
        S.unitCheck("units: the display option switched with the tab open", not U.disp, true)
        S.setOven(U.disp)   -- (the oven's own setting, opposite to the display option now)
        U.t = S.renders
    end)
    S.wait(1, 30, function() return U.off or S.renders >= (U.t or 0) + 2 end, function()
        if U.off then return end
        S.unitCheck("units: the oven's own setting set opposite", not U.disp)
        S.note("T6: ThermalTab.lua's comment at useCelsius says the oven reads the same unit; the oven reads getCore():isCelsius(), a separate setting (ISOvenUI.lua 28-29 and 70); the tab follows the display option, as it should")
        S.setDisp(U.disp)
        U.t = S.renders
    end)
    S.wait(1, 30, function() return U.off or S.renders >= (U.t or 0) + 1 end, function()
        if U.off then return end
        S.unitCheck("units: the display option back", U.disp, true)
        S.setOven(U.oven)
        S.back.units = nil
        Q.check(S.dispC() == U.disp and S.ovenC() == U.oven, "units: both settings are back as found",
            "display " .. tostring(S.dispC()) .. " (was " .. tostring(U.disp) .. "), the oven " .. tostring(S.ovenC()) .. " (was " .. tostring(U.oven) .. ")")
    end)
    S.caseEnd("units")
end

-- ===================================================================== the seven views, picked from the list
function S.pickView(i, lab)
    local t = {}
    S.step(1, function()
        local w = RT.cw()
        local bz = w and w._thermalBand
        if w and w._thermalMenuOpen then pcall(ZeD.ThermalTab.closeMenu, w); w._thermalReturnToMenu = nil end
        if not (bz and bz.box and bz.box.w) then t.off = true; Q.check(false, lab .. ": the View box is drawn"); return end
        S.click(S.mid(bz.box))
    end)
    S.wait(1, 60, function()
        local w = RT.cw()
        return t.off or (w ~= nil and w._thermalMenuOpen == true and w._thermalMenuZones ~= nil and #w._thermalMenuZones > 0)
    end, function(ok)
        if t.off then return end
        local w = RT.cw()
        if not ok then
            t.off = true
            Q.check(false, lab .. ": a click on the View box opens its list", "open " .. tostring(w and w._thermalMenuOpen))
            S.setView(i)
            return
        end
        local z = nil
        for _, zz in ipairs(w._thermalMenuZones or {}) do if zz.id == i then z = zz end end
        if not z then t.off = true; Q.check(false, lab .. ": the View list has a row for view " .. i, #w._thermalMenuZones .. " rows"); S.setView(i); return end
        S.click(S.mid(z))
    end)
    S.wait(1, 30, function()
        local w = RT.cw()
        return t.off or (w ~= nil and w._thermalView == i and not w._thermalMenuOpen)
    end, function(ok)
        if t.off then return end
        local w = RT.cw()
        if not ok then
            Q.check(false, lab .. ": a click on its row picks the view and shuts the list", "view " .. tostring(w and w._thermalView) .. ", open " .. tostring(w and w._thermalMenuOpen))
            S.setView(i)
        end
        if w then w._thermalReturnToMenu = nil end
    end)
end
function S.viewChecks(i, lab)
    local V = S.VIEWS[i]
    local w = RT.cw()
    local d = w and w._thermalCache
    local key = V.id .. "_ui"
    local n0 = d and d.nodes and d.nodes["Upper Torso"]
    Q.check(w ~= nil and w._thermalView == i and n0 ~= nil and n0[key] ~= nil, lab .. ": the view is on and ZeD reads it as " .. key,
        "view " .. tostring(w and w._thermalView) .. ", " .. key .. " " .. tostring(n0 and n0[key]))
    -- the figure: each of the 17 parts takes the band of its reading
    local fig = w and w._thermalBodyFigure
    local cm = fig and fig.colorMap or {}
    local bad, n = {}, 0
    for _, P in ipairs(S.PARTS) do
        local c = cm[P.name]
        local nd = d and d.nodes and d.nodes[P.name]
        local uiv = nd and nd[key]
        if c and uiv ~= nil and S.bandOK(S.bandOf(c), uiv) then n = n + 1
        else bad[#bad + 1] = P.name .. " " .. S.bw(S.bandOf(c)) .. " (" .. S.cText(c) .. "), its reading " .. S.n2(uiv) .. " wants " .. S.bw(S.bandFor(uiv)) end
    end
    Q.check(#bad == 0, lab .. ": the figure's 17 parts each take the colour of their reading", #bad == 0 and (n .. " parts") or table.concat(bad, "; "))
    -- the grid: 17 cells, each with a value
    local g = S.rec.grid
    local empty = {}
    for _, c in ipairs(g and g.cells or {}) do if tostring(c.value or "") == "" then empty[#empty + 1] = tostring(c.label) end end
    Q.check(g ~= nil and #g.cells == 17 and #empty == 0, lab .. ": the grid's 17 cells (two columns) each show a value",
        tostring(g and #g.cells) .. " cells" .. (#empty > 0 and ("; empty: " .. table.concat(empty, ", ")) or ""))
    S.cellsCheck(lab, i, S.SAMPLE)
    if V.id == "insul" or V.id == "wind" then
        local name = w._thermalPick or "Upper Torso"
        local c = S.cellOf(name)
        local pk = S.rec.picked
        local row = pk and pk.rows[(V.id == "insul") and 5 or 6]
        S.note("T3 " .. V.id .. ", " .. name .. ": the cell shows " .. tostring(c and c.value) .. ", the picked row " .. tostring(row and row.value)
            .. ", the game's raw " .. V.get .. " " .. S.n2(S.nv(name, V.get)) .. " and its UI value " .. S.n2(S.nv(name, V.ui))
            .. " (the same reading in two units; the game's panel prints the raw value)")
    end
end
function S.caseViews()
    S.step(1, function() S.front(); S.scroll(0) end)
    S.waitIdle(3)
    for i = 1, #S.VIEWS do
        local lab = "view " .. i .. " (" .. S.VIEWS[i].id .. ")"
        S.pickView(i, lab)
        S.readThen(lab, function() S.viewChecks(i, lab) end)
    end
    S.step(1, function() S.setView(1) end)
    S.caseEnd("views")
end

-- ===================================================================== clothes: naked, layered, one bare hand
function S.lowNote(lab)
    local hi, hiW = 0, 0
    for _, P in ipairs(S.PARTS) do
        hi = math.max(hi, S.nv(P.name, "getInsulationUI") or 0)
        hiW = math.max(hiW, S.nv(P.name, "getWindresistUI") or 0)
    end
    return hi, hiW
end
function S.fullNote(lab)
    local full = {}
    for _, P in ipairs(S.PARTS) do
        local a, b = S.nv(P.name, "getInsulationUI") or 0, S.nv(P.name, "getWindresistUI") or 0
        if a >= 0.995 or b >= 0.995 then full[#full + 1] = P.name .. " (insulation " .. S.n2(a) .. ", wind " .. S.n2(b) .. ", raw " .. S.n2(S.nv(P.name, "getInsulation")) .. ")" end
    end
    if #full > 0 then S.note(lab .. ": at 100% (the game's UI value capped at 1): " .. table.concat(full, "; ")) end
end
function S.outfitOff()
    for _, it in ipairs(S.given) do
        pcall(function() if S.p:isEquippedClothing(it) then S.p:removeWornItem(it) end end)
    end
    S.clothesChanged()
end
function S.wornBack()
    local on = S.wornSet()
    for _, e in ipairs(S.found.worn or {}) do
        if not on[e.item] then pcall(function() S.p:setWornItem(e.loc, e.item) end) end
    end
    S.clothesChanged()
end
function S.caseClothes()
    local C = {}
    S.step(1, function()
        S.front()
        for _, e in ipairs(S.found.worn or {}) do pcall(function() S.p:removeWornItem(e.item) end) end
        S.back.clothes = true
        S.clothesChanged()
    end)
    S.wait(10, 400, function() return #S.wornList() == 0 and (S.nv("Upper Torso", "getInsulationUI") or 1) < 0.05 end, function(ok)
        local hi, hiW = S.lowNote("naked")
        Q.check(#S.wornList() == 0, "clothes naked: nothing worn", #S.wornList() .. " things still worn")
        if hi >= 0.05 or hiW >= 0.05 then S.note("clothes naked: the game's highest insulation " .. S.n2(hi) .. ", wind resistance " .. S.n2(hiW) .. " (not all low)") end
        C.nakedTorso = S.nv("Upper Torso", "getInsulationUI") or 0
    end)
    S.viewRead(5, "clothes naked", function() S.cellsCheck("clothes naked", 5, S.allNames()) end)
    S.viewRead(6, "clothes naked", function() S.cellsCheck("clothes naked", 6, S.allNames()); S.pickedCheck("clothes naked") end)
    -- the layered outfit
    S.step(1, function()
        C.miss = {}
        for _, ft in ipairs(S.OUTFIT) do
            local it = RT.give(ft)
            if it then
                S.given[#S.given + 1] = it
                local loc = nil
                pcall(function() loc = it:getBodyLocation() end)
                pcall(function() S.p:setWornItem(loc, it) end)
                if ft == "Base.Gloves_LeatherGloves" then C.gloves = it end
            else C.miss[#C.miss + 1] = ft end
        end
        S.clothesChanged()
    end)
    S.wait(10, 400, function() return (S.nv("Upper Torso", "getInsulationUI") or 0) > (C.nakedTorso or 0) + 0.2 end, function(ok)
        local on = S.wornSet()
        local worn = 0
        for _, it in ipairs(S.given) do if on[it] then worn = worn + 1 end end
        Q.check(ok and worn > 0, "clothes layered: the outfit is worn and the game's insulation rose",
            worn .. " of " .. #S.given .. " worn" .. (#C.miss > 0 and (", not known: " .. table.concat(C.miss, ", ")) or "")
            .. "; Upper Torso " .. S.n2(C.nakedTorso) .. " to " .. S.n2(S.nv("Upper Torso", "getInsulationUI")))
        S.fullNote("clothes layered")
    end)
    S.viewRead(5, "clothes layered", function() S.cellsCheck("clothes layered", 5, S.allNames()) end)
    S.viewRead(6, "clothes layered", function() S.cellsCheck("clothes layered", 6, S.allNames()); S.pickedCheck("clothes layered") end)
    -- one bare hand: a hole in the left glove, the gloves taken off and put on again so the game reads them again
    S.step(1, function()
        if not (C.gloves and BloodBodyPartType and BloodBodyPartType.Hand_L) then C.noHand = "no gloves were given"; return end
        C.l0, C.r0 = S.nv("Left Hand", "getInsulationUI"), S.nv("Right Hand", "getInsulationUI")
        pcall(function() C.gloves:getVisual():setHole(BloodBodyPartType.Hand_L) end)
        pcall(function() S.p:removeWornItem(C.gloves) end)
        S.clothesChanged()
    end)
    S.step(3, function()
        if C.noHand or not C.gloves then return end
        local loc = nil
        pcall(function() loc = C.gloves:getBodyLocation() end)
        pcall(function() S.p:setWornItem(loc, C.gloves) end)
        S.clothesChanged()
    end)
    S.wait(10, 400, function()
        if C.noHand then return true end
        local l, r = S.nv("Left Hand", "getInsulationUI"), S.nv("Right Hand", "getInsulationUI")
        return l ~= nil and r ~= nil and l < r - 0.05
    end, function(ok)
        if C.noHand then Q.skip("clothes one bare hand", C.noHand); return end
        if not ok then
            C.noHand = "the game kept the left hand's insulation with a hole in the left glove (" .. S.n2(S.nv("Left Hand", "getInsulationUI")) .. " against the right's "
                .. S.n2(S.nv("Right Hand", "getInsulationUI")) .. ", before " .. S.n2(C.l0) .. " / " .. S.n2(C.r0) .. ")"
            Q.skip("clothes one bare hand", C.noHand)
        end
    end)
    S.viewRead(5, "clothes one bare hand", function()
        if C.noHand then return end
        S.cellsCheck("clothes one bare hand", 5, { "Left Hand", "Right Hand", "Left Forearm" })
        local l, r = S.cellOf("Left Hand"), S.cellOf("Right Hand")
        Q.check(l ~= nil and r ~= nil and (S.num(l.value) or 1) < (S.num(r.value) or 0),
            "clothes one bare hand: the left hand's cell reads below the right's, as the game's do", tostring(l and l.value) .. " against " .. tostring(r and r.value))
    end)
    -- the outfit off, the clothes found back on
    S.step(1, function()
        S.outfitOff()
        for _, it in ipairs(S.given) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
        S.wornBack()
    end)
    S.wait(5, 300, function()
        local on = S.wornSet()
        for _, e in ipairs(S.found.worn or {}) do if not on[e.item] then return false end end
        return #S.wornList() == #(S.found.worn or {})
    end, function(ok)
        S.back.clothes = nil
        Q.check(ok, "clothes: the outfit off and away, the clothes found back on", #S.wornList() .. " worn (found " .. #(S.found.worn or {}) .. ")")
        S.given = {}
    end)
    S.step(1, function() S.setView(1) end)
    S.caseEnd("clothes")
end

-- ===================================================================== wet: body and clothing wetness
function S.wetState(W)
    local st = { n = 0 }
    local lab = "wet " .. W.lab
    S.step(1, function() S.stage({ wet = W.body, cloth = W.cloth }); st.lv = nil end)
    S.wait(10, 900, function()
        local b = S.nv(S.pickName(), "getBodyWetnessUI")
        if not (b and math.abs(b - W.body) < 0.03) then st.n = 0; return false end
        local lv = S.moodle("WET")
        if lv ~= st.lv then st.lv = lv; st.n = 0; return false end
        st.n = st.n + 1
        return st.n >= 40
    end, function(ok)
        if not ok then S.note(lab .. ": the body's wetness did not settle at " .. W.body .. " (now " .. S.n2(S.nv(S.pickName(), "getBodyWetnessUI")) .. ")") end
    end)
    S.readThen(lab, function()
        local pk = S.rec.picked
        local name = S.pickName()
        local r7, r8 = pk and pk.rows[7], pk and pk.rows[8]
        local bad = {}
        for k, R in ipairs({ { row = r7, ui = "getBodyWetnessUI" }, { row = r8, ui = "getClothingWetnessUI" } }) do
            local ui = S.nv(name, R.ui)
            local v = R.row and S.num(R.row.value)
            local wantW = ui and getText(S.third(S.clamp01(ui), "IGUI_Temp_Dry", false, "IGUI_Temp_Soaked")) or "?"
            local okV = v ~= nil and ui ~= nil and math.abs(v - math.floor(S.clamp01(ui) * 100 + 0.5)) <= 2
            local okW = R.row ~= nil and (tostring(R.row.word) == wantW or S.nearCut(ui, false))
            if not (okV and okW) then bad[#bad + 1] = (k == 1 and "body " or "clothing ") .. tostring(R.row and R.row.value) .. " " .. tostring(R.row and R.row.word) .. " (the game " .. S.n2(ui) .. ", " .. wantW .. ")" end
        end
        Q.check(#bad == 0 and r7 ~= nil and r8 ~= nil, lab .. ": the picked block's body and clothing wetness rows match the game (value, Dry or Soaked by halves)",
            #bad == 0 and (tostring(r7 and r7.value) .. " " .. tostring(r7 and r7.word) .. ", " .. tostring(r8 and r8.value) .. " " .. tostring(r8 and r8.word)) or table.concat(bad, "; "))
        S.wetRows[#S.wetRows + 1] = W.lab .. ": WET moodle " .. S.moodle("WET") .. " (stat " .. S.n1(S.stat("WETNESS")) .. "); body "
            .. tostring(r7 and r7.value) .. " " .. tostring(r7 and r7.word) .. " in " .. S.bw(S.bandOf(r7 and r7.color)) .. "; clothing "
            .. tostring(r8 and r8.value) .. " " .. tostring(r8 and r8.word) .. " in " .. S.bw(S.bandOf(r8 and r8.color))
        if W.lab == "dry" then S.dryBand = S.bandOf(r7 and r7.color) end
    end)
end
function S.pickName() local w = RT.cw(); return (w and w._thermalPick) or "Upper Torso" end
function S.caseWet()
    S.step(1, function()
        S.front()
        S.back.wet = true
        if #S.wornClothes() == 0 then S.note("wet: nothing is worn, so the clothing wetness stays 0 in every state") end
    end)
    for _, W in ipairs(S.WETS) do S.wetState(W) end
    S.step(1, function()
        S.unstage()
        S.wetBack()
        S.back.wet = nil
        S.note("T4 wetness words (a design call): the game's WET moodle fires at 15, 40, 70 and 90 of 100; ZeD's rows read Dry below 0.5:")
        for _, r in ipairs(S.wetRows) do S.note("T4 | " .. r) end
        S.note("T2 wetness colours (a design call): the rows take the temperature colours; dry shows " .. S.bw(S.dryBand)
            .. (S.dryBand == "tempCold" and " (the cold colour for dry)" or "") .. "; the game's own wetness views go green when dry and blue when soaked")
    end)
    S.waitIdle(3)
    S.step(1, function()
        local wb = S.wetDiff()
        Q.check(#wb == 0, "wet: the wetness of the body, its parts and the garments is back as found", #wb == 0 and "as found" or table.concat(wb, "; "))
    end)
    S.waitIdle(30)
    S.caseEnd("wet")
end
-- what differs from the wetness found (parts and garments within 1 of 100, the stat within 3 per cent of its range)
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

-- ===================================================================== the core sweep (T1, T5)
function S.coreHold(c, lab, maxF)
    local st = { n = 0 }
    S.step(1, function() S.stage({ temp = c }); st.lv = nil end)
    S.wait(2, maxF or 1500, function()
        local core = S.core()
        if not (core and math.abs(core - c) <= 0.12) then st.n = 0; return false end
        local lv = S.moodle("HYPOTHERMIA") * 10 + S.moodle("HYPERTHERMIA")
        if lv ~= st.lv then st.lv = lv; st.n = 0; return false end
        st.n = st.n + 1
        return st.n >= 45
    end, function(ok)
        st.ok = ok
        if not ok then S.note(lab .. ": the core did not settle at " .. c .. " C (now " .. S.n2(S.core()) .. ")") end
    end)
    return st
end
-- the core meter as drawn: lit segments and band against (core - 30) / 12
function S.meter()
    local h = S.hdr()
    local seg = h and h.seg
    local v = h and h.data and ((h.data.coreTemp or 0) - 30) / 12 or 0
    local wantLit = math.max(1, ZeD.Atoms.fillSegsLit(S.clamp01(v)))
    local band = S.bandOf(seg and seg.color)
    return seg, v, wantLit, band
end
function S.skinNote(lab)
    local pk = S.rec.picked
    local r1 = pk and pk.rows[1]
    local parts = {}
    for _, name in ipairs(S.SAMPLE) do
        local c = S.cellOf(name)
        parts[#parts + 1] = name .. " skin " .. S.n1(S.nv(name, "getSkinCelcius")) .. " C (UI " .. S.n2(S.nv(name, "getSkinCelciusUI")) .. "), cell "
            .. tostring(c and c.value) .. " in " .. S.bw(S.bandOf(c and c.color))
    end
    S.note("T5 skin, " .. lab .. ": the picked " .. tostring(pk and pk.title) .. " row " .. tostring(r1 and r1.value) .. " " .. tostring(r1 and r1.word)
        .. " in " .. S.bw(S.bandOf(r1 and r1.color)) .. "; " .. table.concat(parts, "; ")
        .. " (the game's getSkinCelciusUI puts 0.5 at 33 C and its upper branch lacks the x0.5, so Hot reads from 34.5 C)")
end
function S.coreState(c)
    local lab = "core " .. c .. " C"
    S.coreHold(c, lab)
    S.readThen(lab, function()
        local h = S.hdr()
        local g = h.game or {}
        local cel = S.celsius()
        local hypo, hyper = S.moodle("HYPOTHERMIA"), S.moodle("HYPERTHERMIA")
        local seg, v, wantLit, band = S.meter()
        S.tempRow(lab, "Core", h.rows[1] and h.rows[1].value, h.data and h.data.coreTemp, g.core, "getCoreCelcius", cel)
        local shown = S.num(h.rows[1] and h.rows[1].value)
        Q.check(shown ~= nil and g.stat ~= nil and math.abs(shown - S.toUnit(g.stat, cel)) <= S.tol(cel), lab .. ": Core matches the game's TEMPERATURE stat",
            "shown " .. tostring(h.rows[1] and h.rows[1].value) .. ", the stat " .. S.n2(g.stat) .. " C")
        Q.check(seg ~= nil and seg.lit == wantLit and S.bandOK(band, v),
            lab .. ": the core meter lights " .. wantLit .. " of 10 in the " .. S.bw(S.bandFor(v)) .. " colour ((core - 30) / 12 by fifths)",
            "lit " .. tostring(seg and seg.lit) .. ", " .. S.bw(band) .. " (" .. S.cText(seg and seg.color) .. ")")
        Q.check(not (band == "tempNorm" and (hypo >= 2 or hyper >= 2)),
            lab .. ": the core meter never reads normal (green) while the game shows a temperature moodle at level 2 or higher",
            "meter " .. S.bw(band) .. ", Hypothermia " .. hypo .. ", Hyperthermia " .. hyper)
        S.t1[#S.t1 + 1] = "set " .. c .. " | core " .. S.n2(g.core) .. " | stat " .. S.n2(g.stat) .. " | ZeD " .. tostring(h.rows[1] and h.rows[1].value)
            .. " | Hypothermia " .. hypo .. " | Hyperthermia " .. hyper .. " | meter " .. tostring(seg and seg.lit) .. " of 10 " .. S.bw(band)
        if c <= 29 or c >= 41 then S.skinNote(lab) end
    end)
end
function S.coreBack(lab)
    local st = { n = 0 }
    S.step(1, function() st.c = S.found.stats and S.found.stats.TEMPERATURE or 37; S.stage({ temp = st.c }) end)
    S.wait(2, 1500, function() local c = S.core(); return c ~= nil and math.abs(c - st.c) <= 0.15 end, function(ok)
        S.unstage()
        Q.check(ok, lab .. ": the core back where it was found", S.n2(S.core()) .. " C (found " .. S.n2(st.c) .. " C)")
    end)
end
function S.caseCore()
    S.step(1, function() S.front(); S.setView(1); S.scroll(0) end)
    for _, c in ipairs(S.CORES) do S.coreState(c) end
    S.coreBack("core sweep")
    S.step(1, function()
        S.note("T1 the core meter against the game's moodles (a design call for the director; intoxication " .. S.n2(S.found.stats.INTOXICATION)
            .. ", Hypothermia 1 needs 30 or less): the meter's bands cut at 32.4, 34.8, 37.2 and 39.6 C; the game's moodles at 36.5, 35, 30 and 25 (cold) and 37.5, 39, 40 and 41 (hot)")
        for _, r in ipairs(S.t1) do S.note("T1 | " .. r) end
    end)
    S.caseEnd("core sweep")
end

-- ===================================================================== themes, a cold and a hot core (pictures)
function S.caseThemes()
    S.step(1, function()
        S.front(); S.setView(1); S.scroll(0)
        local B = ZeD.BaseThemes or {}
        local same, diff = 0, {}
        for _, tok in ipairs(S.BANDS) do
            if B.hicon and B.dark and S.sameC(B.hicon[tok], B.dark[tok]) then same = same + 1 else diff[#diff + 1] = tok end
        end
        S.note("themes: High contrast's five temperature colours equal Dark's: " .. same .. " of 5" .. (#diff > 0 and (" (differ: " .. table.concat(diff, ", ") .. ")") or ""))
    end)
    for _, th in ipairs(S.THEMES) do
        S.step(1, function() S.theme(th.key) end)
        S.wait(5, 120, function() return ZeD.currentBase == th.key end, function(ok)
            Q.check(ok, "themes: " .. th.say .. " is on", tostring(ZeD.currentBase))
        end)
        for _, k in ipairs({ { w = "cold", c = 33.0 }, { w = "hot", c = 40.5 } }) do
            local lab = "themes " .. th.say .. ", a " .. k.w .. " core"
            S.coreHold(k.c, lab, 1200)
            S.readThen(lab, function()
                local seg, v, wantLit, band = S.meter()
                local tok = S.bandFor(v)
                local B = ZeD.BaseThemes and ZeD.BaseThemes[th.key]
                Q.check(seg ~= nil and S.sameC(seg.color, ZeD.T[tok]) and B ~= nil and S.sameC(ZeD.T[tok], B[tok]),
                    lab .. ": the core meter takes " .. th.say .. "'s own " .. tok .. " colour", S.cText(seg and seg.color) .. " (the theme's " .. S.cText(B and B[tok]) .. ")")
            end)
            S.shot("th_skinTemp_" .. th.tag .. "_" .. k.w .. "_" .. S.sizeTag(), "the Thermal tab, Skin temperature view, " .. th.say .. ", a " .. k.w .. " core (" .. k.c .. " C)")
        end
    end
    S.step(1, function() S.themeBack() end)
    S.wait(2, 120, function() return ZeD.currentBase == S.found.base end, function(ok)
        Q.check(ok, "themes: the theme is back as found", tostring(ZeD.currentBase))
    end)
    S.coreBack("themes")
    S.caseEnd("themes")
end

-- ===================================================================== the pad
function S.casePad()
    local P = {}
    S.step(1, function()
        S.front(); S.setView(1); S.scroll(0)
        S.park()
        local w = RT.cw()
        P.pick0 = w._thermalPick
        w._thermalHoveredPart = nil
        if not S.padOn() then P.off = true; Q.skip("pad", "ZeD's input detector cannot be locked to the controller"); return end
        S.padClaim()
    end)
    S.wait(5, 180, function()
        if P.off then return true end
        local w = RT.cw()
        local held = nil
        pcall(function() held = S.F.getFocusedWindow(S.pn) end)
        return held == w and S.focusOn(function(e) return e.id == "thermal:__disclosure" end) ~= nil
    end, function(ok)
        if P.off then return end
        if not Q.check(ok, "pad: the Character window holds the pad, on the figure's heading", "focus " .. tostring(S.focId())) then P.off = true; return end
        local okO, seq = S.orderOf(S.tabEls())
        Q.check(okO, "pad: the tab's stops come in order (heading, parts, cells, block head, rows, View box)", seq)
        P.walk = { n = 0, phase = "press", seen = {}, ids = {}, bad = {}, presses = 0, same = 0 }
    end)
    -- the D-pad Down from the heading to the View box
    S.wait(2, 900, function()
        if P.off then return true end
        local W = P.walk
        if W.phase == "press" then
            RT.padDir("down", RT.cw())
            W.presses = W.presses + 1
            W.phase, W.k = "settle", 0
            return false
        end
        W.k = W.k + 1
        if W.k < 4 then return false end
        local id = S.focId()
        local k = S.kindOf(id)
        W.seen[k] = true
        if #W.ids < 60 then W.ids[#W.ids + 1] = S.KINDS[k] or tostring(id) end
        local okO, seq = S.orderOf(S.tabEls())
        if not okO and #W.bad < 3 then W.bad[#W.bad + 1] = seq end
        if id == "thermal:view" then W.done = true; return true end
        if id == W.last then W.same = W.same + 1 else W.same = 0 end
        W.last = id
        if W.same >= 3 or W.presses >= 80 then return true end
        W.phase = "press"
        return false
    end, function()
        if P.off then return end
        local W = P.walk
        local miss = {}
        for k = 2, 5 do if not W.seen[k] then miss[#miss + 1] = S.KINDS[k] end end
        if not W.seen[7] then miss[#miss + 1] = S.KINDS[7] end
        -- (consecutive kinds folded: "part x5")
        local fold, last, n = {}, nil, 0
        for _, kd in ipairs(W.ids) do
            if kd == last then n = n + 1 else if last then fold[#fold + 1] = last .. (n > 1 and (" x" .. n) or "") end; last, n = kd, 1 end
        end
        if last then fold[#fold + 1] = last .. (n > 1 and (" x" .. n) or "") end
        Q.check(#miss == 0 and W.done == true, "pad: Down from the heading walks the parts, the cells, the block head and the rows to the View box",
            W.presses .. " presses: " .. table.concat(fold, ", ") .. (#miss > 0 and (" | never reached: " .. table.concat(miss, ", ")) or "")
            .. (W.done and "" or " | stopped short of the View box"))
        Q.check(#W.bad == 0, "pad: on every step of the walk the stops stay in order", #W.bad == 0 and "in order" or table.concat(W.bad, " || "))
    end)
    -- A on a cell picks it
    S.step(1, function()
        if P.off then return end
        local w = RT.cw()
        local e = S.focusOn(function(el) return S.kindOf(el.id) == 3 and el.partName ~= nil and el.partName ~= w._thermalPick end)
        P.cell = e and e.partName
        if not P.cell then Q.skip("pad: A on a cell picks it", "no cell other than the pick is a stop in view") end
    end)
    S.tap("A", "AButton", function() return not P.off and P.cell ~= nil end)
    S.step(4, function()
        if P.off or not P.cell then return end
        local w = RT.cw()
        Q.check(w._thermalPick == P.cell, "pad: A on a cell picks that region", tostring(w._thermalPick) .. ", want " .. tostring(P.cell))
        w._thermalPick = P.pick0
    end)
    S.casePadView(P)
    S.casePadParts(P)
    S.step(2, function()
        S.padOff()
        local w = RT.cw()
        if w then
            w._thermalPick = P.pick0
            w._thermalHoveredPart = S.found.hovered
            w._thermalFigureExpanded = true
        end
        S.mouseBack()
        Q.check(S.lockFound() == (S.lockWas or S.lockFound()), "pad: the input lock is back as found", S.lockFound() .. " (found " .. tostring(S.lockWas) .. ")")
    end)
    S.caseEnd("pad")
end
-- A on the View box, A on a row, B on the list
function S.casePadView(P)
    S.step(1, function()
        if P.off then return end
        P.v0 = RT.cw()._thermalView
        P.box = S.focusOn(function(el) return el.id == "thermal:view" end) ~= nil
        if not P.box then Q.check(false, "pad: the View box is a stop", "focus " .. tostring(S.focId())) end
    end)
    S.tap("A", "AButton", function() return not P.off and P.box end)
    S.wait(2, 60, function() return P.off or not P.box or (RT.cw()._thermalMenuOpen == true and S.kindOf(S.focId()) == 8) end, function(ok)
        if P.off or not P.box then return end
        local w = RT.cw()
        Q.check(ok and S.focId() == "thermal:viewRow:" .. tostring(P.v0), "pad: A on the View box opens the list, the focus on the current view's row",
            "open " .. tostring(w._thermalMenuOpen) .. ", focus " .. tostring(S.focId()))
        if ok then RT.padDir((P.v0 or 1) < 7 and "down" or "up", w) end
    end)
    S.step(4, function()
        if P.off or not P.box then return end
        P.row = S.focEl() and S.focEl().menuRowId or nil
    end)
    S.tap("A", "AButton", function() return not P.off and P.box and P.row ~= nil end)
    S.wait(2, 60, function()
        if P.off or not P.box or not P.row then return true end
        local w = RT.cw()
        return not w._thermalMenuOpen and S.focId() == "thermal:view"
    end, function(ok)
        if P.off or not P.box then return end
        local w = RT.cw()
        Q.check(ok and P.row ~= nil and P.row ~= P.v0 and w._thermalView == P.row,
            "pad: the D-pad and A on another row pick that view, the list shuts and the focus returns to the box",
            "row " .. tostring(P.row) .. " (was view " .. tostring(P.v0) .. "), view " .. tostring(w._thermalView) .. ", open " .. tostring(w._thermalMenuOpen) .. ", focus " .. tostring(S.focId()))
        P.v1 = w._thermalView
    end)
    S.tap("A", "AButton", function() return not P.off and P.box and S.focId() == "thermal:view" end)
    S.wait(2, 60, function() return P.off or not P.box or RT.cw()._thermalMenuOpen == true end, function(ok)
        if P.off or not P.box then return end
        P.reopen = ok
        if not ok then Q.check(false, "pad: A on the box opens the list again", "focus " .. tostring(S.focId())) end
    end)
    S.tap("B", "BButton", function() return not P.off and P.box and P.reopen end)
    S.wait(2, 60, function() return P.off or not P.box or not P.reopen or (not RT.cw()._thermalMenuOpen and S.focId() == "thermal:view") end, function(ok)
        if P.off or not P.box or not P.reopen then return end
        local w = RT.cw()
        Q.check(ok and w._thermalView == P.v1, "pad: B shuts the list, the view kept and the focus back on the box",
            "open " .. tostring(w._thermalMenuOpen) .. ", view " .. tostring(w._thermalView) .. " (was " .. tostring(P.v1) .. "), focus " .. tostring(S.focId()))
        S.setView(1)
    end)
end
-- the focus on a part swaps the block; A on a part; T8 twice
function S.casePadParts(P)
    S.step(1, function()
        if P.off then return end
        S.scroll(0)
        RT.cw()._thermalFigureExpanded = true
    end)
    S.waitIdle(4)
    S.step(1, function()
        if P.off then return end
        local w = RT.cw()
        local e = S.focusOn(function(el) return S.kindOf(el.id) == 2 and el.partName == "Left Hand" and el.partName ~= w._thermalPick end)
            or S.focusOn(function(el) return S.kindOf(el.id) == 2 and el.partName ~= nil and el.partName ~= w._thermalPick end)
        P.part = e and e.partName
        if not P.part then Q.skip("pad: the focus on a part", "no figure part is a stop in view") end
    end)
    S.wait(3, 60, function()
        if P.off or not P.part then return true end
        local pk = S.rec.picked
        return pk ~= nil and tostring(pk.title) == S.labelOf(P.part)
    end, function(ok)
        if P.off or not P.part then return end
        local w = RT.cw()
        local pk = S.rec.picked
        Q.check(ok and w._thermalActivePart == P.part, "pad: the focus on a figure part swaps the picked block to that part",
            "block " .. tostring(pk and pk.title) .. ", the part " .. tostring(P.part) .. ", active " .. tostring(w._thermalActivePart))
        P.pickA = w._thermalPick
    end)
    S.tap("A", "AButton", function() return not P.off and P.part ~= nil end)
    S.step(4, function()
        if P.off or not P.part then return end
        local w = RT.cw()
        S.note("T10 pad: A on the figure's " .. P.part .. (w._thermalPick == P.pickA and " picks nothing (the pick stays " .. tostring(w._thermalPick) .. ")" or (" picks it (" .. tostring(w._thermalPick) .. ")"))
            .. "; the game's own figure picks a part for its details")
        w._thermalPick = P.pick0
    end)
    -- T8 (a): from the part, Up to the heading and A folds the figure: the block shows the pick
    S.wait(2, 200, function()
        if P.off or not P.part then return true end
        P.up = (P.up or 0) + 1
        if S.focId() == "thermal:__disclosure" then return true end
        if P.up - math.floor(P.up / 4) * 4 == 1 then RT.padDir("up", RT.cw()) end
        return P.up > 60
    end, function(ok)
        if P.off or not P.part then return end
        P.atHead = S.focId() == "thermal:__disclosure"
        if not P.atHead then Q.check(false, "pad: Up from a figure part reaches the figure's heading", "focus " .. tostring(S.focId())) end
    end)
    S.tap("A", "AButton", function() return not P.off and P.atHead end)
    S.wait(2, 60, function() return P.off or not P.atHead or RT.cw()._thermalFigureExpanded == false end, function(ok)
        if P.off or not P.atHead then return end
        P.foldOK = ok
    end)
    S.waitIdle(4)
    S.step(1, function()
        if P.off or not P.atHead then return end
        local w = RT.cw()
        local pk = S.rec.picked
        Q.check(P.foldOK and pk ~= nil and tostring(pk.title) == S.labelOf(w._thermalPick),
            "pad (T8): the figure folded by A on its heading after the pad left a part, the block shows the pick, not the part",
            "folded " .. tostring(P.foldOK) .. ", block " .. tostring(pk and pk.title) .. ", pick " .. tostring(w._thermalPick) .. ", the part was " .. tostring(P.part))
    end)
    S.tap("A", "AButton", function() return not P.off and P.atHead and RT.cw()._thermalFigureExpanded == false end)
    S.waitIdle(4)
    -- T8 (b): the pointer left resting on a part, then the pad folds the figure
    S.step(1, function()
        if P.off then return end
        local w = RT.cw()
        w._thermalFigureExpanded = true
        local fig = w._thermalBodyFigure
        P.rest = nil
        for _, r in ipairs(fig and fig.getPartRects and fig:getPartRects() or {}) do
            if not P.rest and r.name ~= w._thermalPick then
                local cx, cy = S.mid(r)
                local hit = nil
                pcall(function() hit = fig:hitTestAt(cx, cy) end)
                if hit == r.name then P.rest = { name = r.name, x = cx, y = cy } end
            end
        end
        if not P.rest then Q.skip("pad (T8): the pointer rested on a part", "no figure part answers the hit test at its middle"); return end
        S.mouseAt(S.toScreen(P.rest.x, P.rest.y))
        pcall(function() S.drawer():onMouseMove(0, 0) end)
        P.hov = w._thermalHoveredPart
        S.park()
        S.focusOn(function(el) return el.id == "thermal:__disclosure" end)
    end)
    S.tap("A", "AButton", function() return not P.off and P.rest ~= nil and P.hov ~= nil end)
    S.waitIdle(5)
    S.step(1, function()
        if P.off or not P.rest then return end
        local w = RT.cw()
        local pk = S.rec.picked
        if P.hov == nil then Q.skip("pad (T8): the pointer rested on a part", "the drawer's onMouseMove did not take the part " .. P.rest.name); return end
        Q.check(w._thermalFigureExpanded == false and pk ~= nil and tostring(pk.title) == S.labelOf(w._thermalPick),
            "pad (T8): with the pointer left resting on a figure part, the figure folded by the pad, the block shows the pick, not that part",
            "folded " .. tostring(w._thermalFigureExpanded == false) .. ", block " .. tostring(pk and pk.title) .. ", pick " .. tostring(w._thermalPick)
            .. ", the part under the pointer " .. tostring(P.hov) .. " (_thermalHoveredPart " .. tostring(w._thermalHoveredPart) .. ")")
        w._thermalFigureExpanded = true
        w._thermalHoveredPart = S.found.hovered
    end)
end

-- ===================================================================== the mouse
function S.cellZones()
    local out = {}
    local w = RT.cw()
    for _, z in ipairs(w and ZeD.TabFill.zones(w, "thermal") or {}) do
        if S.kindOf(z.id) == 3 and z.partName then out[#out + 1] = z end
    end
    return out
end
function S.caseMouse()
    local M = {}
    S.step(1, function()
        S.front(); S.setView(1); S.scroll(1)
        S.park()
        M.pick0 = RT.cw()._thermalPick
    end)
    S.wait(3, 60, function()
        for _, z in ipairs(S.cellZones()) do
            if z.partName ~= M.pick0 and S.inBody(z) then M.z = { x = z.x, y = z.y, w = z.w, h = z.h, part = z.partName }; return true end
        end
        return false
    end, function(ok)
        if not ok then M.off = true; Q.skip("mouse: a cell", "no grid cell lies whole in the tab's view"); return end
        local lx, ly = S.mid(M.z)
        S.mouseAt(S.toScreen(lx, ly))
    end)
    S.wait(3, 60, function()
        if M.off then return true end
        local pk = S.rec.picked
        return RT.cw()._thermalHoverCell == M.z.part and pk ~= nil and tostring(pk.title) == S.labelOf(M.z.part)
    end, function(ok)
        if M.off then return end
        local pk = S.rec.picked
        Q.check(ok, "mouse: the pointer on a cell swaps the picked block to that region",
            "hover " .. tostring(RT.cw()._thermalHoverCell) .. ", block " .. tostring(pk and pk.title) .. ", the cell " .. tostring(M.z.part))
        S.click(S.mid(M.z))
    end)
    S.step(3, function()
        if M.off then return end
        Q.check(RT.cw()._thermalPick == M.z.part, "mouse: a click on a cell picks that region", tostring(RT.cw()._thermalPick) .. ", want " .. tostring(M.z.part))
        S.park()
    end)
    S.wait(3, 60, function()
        if M.off then return true end
        local pk = S.rec.picked
        return RT.cw()._thermalHoverCell == nil and pk ~= nil and tostring(pk.title) == S.labelOf(RT.cw()._thermalPick)
    end, function(ok)
        if M.off then return end
        Q.check(ok, "mouse: the pointer off the grid, the block shows the pick", "block " .. tostring(S.rec.picked and S.rec.picked.title))
        RT.cw()._thermalPick = M.pick0
    end)
    -- a click on a figure part (T10)
    S.step(1, function() S.scroll(0); RT.cw()._thermalFigureExpanded = true end)
    S.step(4, function()
        local w = RT.cw()
        local fig = w._thermalBodyFigure
        M.part = nil
        for _, r in ipairs(fig and fig.getPartRects and fig:getPartRects() or {}) do
            if not M.part and r.name ~= w._thermalPick then
                local cx, cy = S.mid(r)
                local hit = nil
                pcall(function() hit = fig:hitTestAt(cx, cy) end)
                if hit == r.name then M.part = { name = r.name, x = cx, y = cy } end
            end
        end
        if not M.part then Q.skip("mouse: a click on a figure part", "no figure part answers the hit test at its middle"); return end
        S.mouseAt(S.toScreen(M.part.x, M.part.y))
        pcall(function() S.drawer():onMouseMove(0, 0) end)
        S.click(M.part.x, M.part.y)
    end)
    S.step(4, function()
        if not M.part then return end
        local w = RT.cw()
        S.note("T10 mouse: a click on the figure's " .. M.part.name .. (w._thermalPick == M.pick0 and (" picks nothing (the pick stays " .. tostring(w._thermalPick) .. ")") or (" picks it (" .. tostring(w._thermalPick) .. ")"))
            .. "; the pointer on it shows it in the block (" .. tostring(S.rec.picked and S.rec.picked.title) .. "); FEATURE_MAP row 196 says the figure picks")
        S.park()
        pcall(function() S.drawer():onMouseMoveOutside(0, 0) end)
        w._thermalHoveredPart = nil
        w._thermalPick = M.pick0
        w._thermalFigureExpanded = true
    end)
    S.caseT9(M)
    S.step(1, function()
        local w = RT.cw()
        w._thermalHoveredPart = S.found.hovered
        w._thermalPick = M.pick0
        S.scroll(0)
        S.mouseBack()
    end)
    S.caseEnd("mouse")
end
-- T9: a part scrolled under the pinned heading takes no hover
function S.caseT9(M)
    M.t9 = { i = 0, pos = { 0.04, 0.08, 0.12, 0.16, 0.22, 0.3, 0.4 } }
    S.wait(2, 200, function()
        local t = M.t9
        local w = RT.cw()
        if t.k == nil then
            t.i = t.i + 1
            if t.i > #t.pos then return true end
            S.scroll(t.pos[t.i])
            t.k = 0
            return false
        end
        t.k = t.k + 1
        if t.k < 3 then return false end
        t.k = nil
        local fz = w._thermalFigureZone
        local fig = w._thermalBodyFigure
        if not (fz and fig and w._thermalFigureExpanded) then return false end
        for _, r in ipairs(fig:getPartRects() or {}) do
            local top, bot = math.max(r.y, fz.y), math.min(r.y + r.h, fz.y + fz.h)
            if bot - top >= 2 then
                for yy = top, bot - 1 do
                    for _, xx in ipairs({ r.x + math.floor(r.w / 2), r.x + math.floor(r.w / 4), r.x + math.floor(r.w * 3 / 4) }) do
                        local hit = nil
                        pcall(function() hit = fig:hitTestAt(xx, yy) end)
                        if hit == r.name and not t.at then t.at = { name = r.name, x = xx, y = yy } end
                    end
                end
            end
        end
        return t.at ~= nil
    end, function()
        local t = M.t9
        local w = RT.cw()
        if not t.at then Q.skip("mouse (T9): a part scrolled under the pinned heading", "no scroll put a figure part under the heading here"); S.scroll(0); return end
        w._thermalHoveredPart = nil
        S.mouseAt(S.toScreen(t.at.x, t.at.y))
        pcall(function() S.drawer():onMouseMove(0, 0) end)
        local hov = w._thermalHoveredPart
        Q.check(hov == nil, "mouse (T9): a figure part scrolled under the pinned heading does not take the pointer's hover",
            "the pointer on the heading at " .. t.at.x .. "," .. t.at.y .. " (the scroll " .. S.n2(S.scrollPos()) .. "): hovered " .. tostring(hov))
        S.park()
        pcall(function() S.drawer():onMouseMoveOutside(0, 0) end)
        w._thermalHoveredPart = nil
        S.scroll(0)
    end)
end

-- ===================================================================== layout: 480 and 220, the text size found and Large
function S.textW(t) local w = 0; pcall(function() w = ZeD.TM:MeasureStringX(t.font or UIFont.Small, tostring(t.s)) end); return w end
function S.textH(t) local h = 0; pcall(function() h = ZeD.TM:getFontHeight(t.font or UIFont.Small) end); return h end
function S.inside(t, x, y, w, h)
    local tw, th = S.textW(t), S.textH(t)
    return t.x >= x - 1 and t.x + tw <= x + w + 1 and t.y >= y - 1 and t.y + th <= y + h + 1
end
function S.layoutCheck(lab)
    local g, pk, w = S.rec.grid, S.rec.picked, RT.cw()
    local view = w and w._thermalBodyRect
    local right = view and (view.x + view.w) or 99999
    local noName, outs = {}, {}
    for _, c in ipairs(g and g.cells or {}) do
        local name = nil
        for _, t in ipairs(c.texts) do if tostring(t.s) ~= tostring(c.value) then name = t end end
        local ns = name and tostring(name.s) or ""
        if ns == "" or ns == "..." then noName[#noName + 1] = tostring(c.label) end
        for _, t in ipairs(c.texts) do
            if not S.inside(t, c.x, c.y, c.w, c.h or 0) then outs[#outs + 1] = tostring(c.label) .. ": \"" .. tostring(t.s) .. "\" at " .. math.floor(t.x) .. " (" .. S.textW(t) .. " wide) in " .. math.floor(c.x) .. "+" .. math.floor(c.w) end
        end
    end
    Q.check(g ~= nil and #g.cells == 17 and #noName == 0, lab .. " (T7): every grid cell draws its part's name, whole or cut",
        tostring(g and #g.cells) .. " cells" .. (#noName > 0 and ("; no name drawn: " .. table.concat(noName, ", ")) or ""))
    Q.check(#outs == 0, lab .. ": every cell's words stay inside the cell", #outs == 0 and "inside" or table.concat(outs, "; "))
    local rb = {}
    for i, r in ipairs(pk and pk.rows or {}) do
        for _, t in ipairs(r.texts) do
            if not S.inside(t, r.x, r.y, r.w, r.h or 0) or t.x + S.textW(t) > right + 1 then
                rb[#rb + 1] = "row " .. i .. " \"" .. tostring(t.s) .. "\" at " .. math.floor(t.x) .. "," .. math.floor(t.y) .. " (" .. S.textW(t) .. " wide) in " .. math.floor(r.x) .. "+" .. math.floor(r.w) .. ", card to " .. math.floor(right)
            end
        end
        for _, sg in ipairs(r.segs) do
            if sg.x < r.x - 1 or sg.x + sg.w > r.x + r.w + 1 or sg.x + sg.w > right + 1 then rb[#rb + 1] = "row " .. i .. " bar at " .. math.floor(sg.x) .. "+" .. math.floor(sg.w) end
        end
    end
    Q.check(pk ~= nil and #pk.rows == 8 and #rb == 0, lab .. " (T7): every picked row's words and bar stay inside the row and the card",
        tostring(pk and #pk.rows) .. " rows" .. (#rb > 0 and ("; " .. table.concat(rb, "; ")) or ""))
    RT.bounds(Q, lab)
end
function S.cardHold(card)
    local w = RT.cw()
    if not w then return end
    if card == 220 then
        -- (the window's half-screen cap lowered to 620 units: the strips (36 + 36), the least inventory beside a card
        -- (180) and a full card (480) no longer fit, so getTargetDrawerW holds the tab in to the half card, as on a
        -- 1280-wide screen; the inventory keeps about 330 units beside it)
        S.back.cap = true
        w._maxWinW = ZeD.T.px(620)
    else
        w._maxWinW = S.found.maxWinW
    end
end
function S.layoutPass(card, sizeKey)
    local L = {}
    local lab = "layout, the " .. card .. " card, " .. tostring(sizeKey) .. " text"
    S.step(1, function() S.front(); S.setView(1); S.scroll(0); S.cardHold(card) end)
    S.wait(5, 400, function()
        local w = RT.cw()
        local eff = w and math.floor(w._drawerEffW or 0)
        if eff == L.last then L.n = (L.n or 0) + 1 else L.n = 0 end
        L.last = eff
        return L.n >= 10
    end, function(ok)
        local want = ZeD.T.px(card)
        L.eff = L.last
        if L.eff ~= want then
            if card == 220 then L.off = true; Q.skip(lab, "the card was not held in to 220 units (" .. tostring(L.eff) .. " px, want " .. want .. "): the window's inventory may not be open beside it")
            else S.note(lab .. ": the card stands at " .. tostring(L.eff) .. " px, not " .. want .. " (held in on this screen at this size)") end
        end
    end)
    S.readThen(lab, function()
        if L.off then return end
        S.layoutCheck(lab .. " (" .. tostring(L.eff) .. " px)")
    end)
    S.shot("th_layout_" .. card .. "_" .. tostring(sizeKey) .. "_" .. S.sizeTag(), "the Thermal tab on the " .. card .. " card, " .. tostring(sizeKey) .. " text")
end
function S.caseLayout()
    S.step(1, function() S.back.layout = true end)
    local sizes = { S.found.size or "small" }
    if S.found.size ~= "large" then sizes[#sizes + 1] = "large" end
    for _, sz in ipairs(sizes) do
        S.step(1, function() if ZeD.currentSize ~= sz then S.sizeSet(sz) end end)
        S.waitIdle(30)
        S.layoutPass(480, sz)
        S.layoutPass(220, sz)
    end
    S.step(1, function()
        S.sizeBack()
        local w = RT.cw()
        if w then w._maxWinW = S.found.maxWinW end
        S.back.cap = nil
    end)
    S.waitIdle(40)
    S.step(1, function()
        Q.check(ZeD.currentSize == S.found.size, "layout: the text size is back as found", tostring(ZeD.currentSize))
    end)
    S.caseEnd("layout")
end

-- ===================================================================== Lite
function S.caseLite()
    local L = {}
    S.step(1, function()
        S.front(); S.setView(1); S.scroll(0)
        if not (ZeD.Settings and ZeD.Settings.lookStyleOption) then L.off = true; Q.skip("Lite", "no Style setting"); return end
        S.back.style = true
        S.setOpt(ZeD.Settings.lookStyleOption, 2)
        L.at, L.te = S.renders, S.tabErrs
        S.rec.header, S.rec.grid, S.rec.picked = nil, nil, nil
    end)
    S.wait(10, 300, function() return L.off or (S.renders >= (L.at or 0) + 10 and S.rec.grid ~= nil and S.rec.picked ~= nil) end, function(ok)
        if L.off then return end
        local lite = false
        pcall(function() lite = ZeD.Settings.lite() end)
        local h, g, pk = S.hdr(), S.rec.grid, S.rec.picked
        Q.check(ok and lite and h ~= nil and #h.rows == 4 and g ~= nil and #g.cells == 17 and pk ~= nil and #pk.rows == 8 and S.tabErrs == L.te,
            "Lite: the tab still draws its 4 readings, 17 cells and 8 rows with no error",
            "Lite " .. tostring(lite) .. ", readings " .. tostring(h and #h.rows) .. ", cells " .. tostring(g and #g.cells) .. ", rows " .. tostring(pk and #pk.rows)
            .. ", the tab's own errors " .. (S.tabErrs - (L.te or 0)))
        S.setOpt(ZeD.Settings.lookStyleOption, S.found.style)
        S.back.style = nil
    end)
    S.caseEnd("Lite")
end

-- ===================================================================== a car with its heater on
function S.carLive(v)
    if not v then return false end
    local live = false
    pcall(function() local it = getCell():getVehicles():iterator(); while it:hasNext() do if it:next() == v then live = true end end end)
    return live
end
function S.carState(C, temp, lab)
    local st = { n = 0 }
    S.step(1, function()
        if C.off then return end
        if temp == nil then S.unstage() else S.stage({ pc = temp }) end
    end)
    S.wait(30, 1200, function()
        if C.off then return true end
        local a = nil
        pcall(function() a = S.thermo():getTemperatureAir() end)
        if a and st.a and math.abs(a - st.a) < 0.01 then st.n = st.n + 1 else st.n = 0 end
        st.a = a
        return st.n >= 60
    end, function() end)
    S.readThen(lab, function()
        if C.off then return end
        local h = S.hdr()
        local g = h and h.game or {}
        S.tempRow(lab, "Air", h.rows[2] and h.rows[2].value, h.data and h.data.airTemp, g.air, "getTemperatureAir", S.celsius(), g.cAir)
        S.tempRow(lab, "Wind chill", h.rows[3] and h.rows[3].value, h.data and h.data.windTemp, g.wind, "getTemperatureAirAndWind", S.celsius(), g.cWind)
        C.air[#C.air + 1] = { lab = lab, game = g.air, shown = h.rows[2] and tostring(h.rows[2].value) }
    end)
end
function S.caseCar()
    local C = { air = {} }
    S.step(1, function()
        if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_ENTER and ZEDQA_CAR_AWAY and ZEDQA_CAR_KEEP) then C.off = true; Q.skip("car heater", "the prelude's car helpers are not loaded"); return end
        C.t0 = getTimestampMs()
        S.back.car = true
        ZEDQA_CAR_WAIT("Base.PickUpTruck", "th_tab", function(v)
            S.car = v
            ZEDQA_CAR_KEEP[v] = true
            C.ready = true
        end, function(why) C.why = why or "no ready car" end, 6000)
    end)
    S.wait(4, 30000, function() return C.off or C.ready or C.why ~= nil or getTimestampMs() - C.t0 > 60000 end, function()
        if C.off then return end
        if not C.ready then C.off = true; Q.skip("car heater", "no car could be staged: " .. tostring(C.why or "not ready in a minute")); return end
        if ZEDQA_CAR_PREP then local ok, k = pcall(ZEDQA_CAR_PREP, S.car); if ok and k then S.carKey = k end end
        local okC, okE, why = pcall(ZEDQA_CAR_ENTER, S.car, 0)
        if not (okC and okE == true and S.p:getVehicle() == S.car) then C.off = true; Q.skip("car heater", "the character could not be seated: " .. tostring(why or okE)); return end
        pcall(function()
            local door = S.car:getPassengerDoor(S.car:getSeat(S.p))
            pcall(function() local dd = door and door:getDoor(); if dd then dd:setOpen(false) end end)
            pcall(function() VehicleUtils.getChildWindow(door):getWindow():setOpen(false) end)
        end)
        pcall(function() local ht = S.car:getPartById("Heater"); C.heat0 = ht and { active = ht:getModData().active, temperature = ht:getModData().temperature } end)
        S.front()
    end)
    S.carState(C, nil, "car, the heater off")
    S.carState(C, 25, "car, the heater at +25 (the compartment held warm, as a hot engine runs it)")
    S.carState(C, -25, "car, the heater at -25 (the compartment held cold)")
    S.step(1, function()
        if C.off then return end
        S.unstage()
        pcall(function()
            local ht = S.car:getPartById("Heater")
            if ht then local md = ht:getModData(); md.active = C.heat0 and C.heat0.active or nil; md.temperature = C.heat0 and C.heat0.temperature or nil end
        end)
        local seen = {}
        for _, a in ipairs(C.air) do seen[#seen + 1] = a.lab .. ": the game " .. S.n1(a.game) .. " C, ZeD " .. tostring(a.shown) end
        local hot, cold = C.air[2] and C.air[2].game, C.air[3] and C.air[3].game
        if hot and cold and math.abs(hot - cold) > 1 then
            Q.check(true, "car: the game's air in the car moved with the heater and ZeD's Air followed it", table.concat(seen, "; "))
        else
            Q.skip("car: the air moving with the heater", "the game's air in the car did not move with the compartment's temperature (" .. table.concat(seen, "; ") .. ")")
        end
    end)
    S.step(2, function()
        if S.car then
            pcall(function() ZEDQA_CAR_KEEP[S.car] = nil end)
            pcall(ZEDQA_CAR_AWAY, S.car, S.carKey)
            S.carAway = true
        end
    end)
    S.wait(4, 600, function() return S.car == nil or (S.p:getVehicle() == nil and not S.carLive(S.car)) end, function(ok)
        if S.car then Q.check(ok, "car: out of the car and the car taken away", "in a car " .. tostring(S.p:getVehicle() ~= nil) .. ", the car in the cell " .. tostring(S.carLive(S.car))) end
        S.car, S.carKey = nil, nil
        S.back.car = nil
        local f = S.found
        if f.pos then S.goTo(f.pos.x, f.pos.y, f.pos.z) end
        S.front()
    end)
    S.waitIdle(30)
    S.caseEnd("car")
end

-- ===================================================================== put back
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    S.unstage()
    S.mouseBack()
    S.padOff()
    if S.car then
        pcall(function() ZEDQA_CAR_KEEP[S.car] = nil end)
        pcall(ZEDQA_CAR_AWAY, S.car, S.carKey)
        S.carAway = true
    end
    if f.recorded then
        S.outfitOff()
        for _, it in ipairs(S.given) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
        S.given = {}
        S.wornBack()
        S.wetBack()
        if f.stats then
            for _, k in ipairs({ "INTOXICATION", "ENDURANCE", "FATIGUE" }) do if f.stats[k] ~= nil then S.setStat(k, f.stats[k]) end end
        end
        if f.disp ~= nil then S.setDisp(f.disp) end
        if f.oven ~= nil then S.setOven(f.oven) end
        S.themeBack()
        S.sizeBack()
        if S.back.style then S.back.style = nil; S.setOpt(ZeD.Settings.lookStyleOption, f.style) end
    end
    local w = RT.cw()
    if w and f.recorded then
        pcall(ZeD.ThermalTab.closeMenu, w)
        w._thermalReturnToMenu = nil
        if f.view then w._thermalView = f.view end
        w._thermalPick = f.pick
        w._thermalFigureExpanded = f.fold
        S.pickedFoldSet(f.pickedFold)
        w._thermalHoveredPart = f.hovered
        w._maxWinW = f.maxWinW
        S.scroll(f.scroll or 0)
    end
    S.unholdAll()
    S.wrapOff()
    if S.bailed then pcall(function() S.p:setGodMod(true) end)
    else pcall(function() S.p:setGodMod(f.god and true or false) end) end
    if f.inv ~= nil then pcall(function() S.p:setInvincible(f.inv) end) end
    S.speed(f.speed)
end
function S.buildPutBack()
    Q.mark()
    -- the core back first (the guard still on): the found TEMPERATURE held until the core is there
    Q.step(2, function()
        if not S.found.recorded or S.bailed then return end
        S.want = nil
        S.stage({ temp = S.found.stats and S.found.stats.TEMPERATURE or 37 })
    end)
    Q.waitFor(2, 900, function()
        if not S.found.recorded or S.bailed then return true end
        local c = S.core()
        return c ~= nil and math.abs(c - (S.found.stats.TEMPERATURE or 37)) <= 0.2
    end, function() S.unstage() end)
    Q.step(2, function()
        S.putBack()
        if S.back.layout and S.snap and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, S.snap, "th_tab") end
        S.back.layout = nil
    end)
    Q.waitFor(4, 600, function() return S.p:getVehicle() == nil end, function()
        local f = S.found
        if f.pos then S.goTo(f.pos.x, f.pos.y, f.pos.z) end
        if f.dir then pcall(function() S.p:setDir(f.dir) end) end
        if f.pair then RT.pairOpen() else RT.pairShut() end
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair and f.tab then RT.charTab(f.tab) end
        local w = RT.cw()
        if w then w._thermalCache = nil end
        pcall(function()
            if f.focusWin == nil then S.F.releaseFocus(S.pn)
            elseif S.F.getFocusedWindow(S.pn) ~= f.focusWin then S.F.claimFocus(f.focusWin) end
        end)
    end)
    Q.step(20, function()
        S.live = false
        pcall(function() Events.OnTick.Remove(S.safety) end)
        local f = S.found
        if not f.recorded then Q.skip("put back", "nothing was staged (the tab's pieces were not loaded)"); return end
        local w = RT.cw()
        if f.pair and f.tab then Q.check(w ~= nil and w._activeTab == f.tab, "put back: the Character window's tab as found", tostring(w and w._activeTab)) end
        local on = S.wornSet()
        local worn = 0
        for _, e in ipairs(f.worn or {}) do if on[e.item] then worn = worn + 1 end end
        Q.check(worn == #(f.worn or {}) and #S.wornList() == #(f.worn or {}), "put back: he wears what he wore, nothing more", worn .. " of " .. #(f.worn or {}) .. ", " .. #S.wornList() .. " worn")
        -- (the wet case checks its own put-back; by now the weather may have wet or dried him, so a drift is a NOTE)
        local wb = S.wetDiff()
        if #wb > 0 then S.note("put back: the wetness drifted from what was found since the wet case put it back (weather or drying): " .. table.concat(wb, "; ")) end
        local core = S.core()
        Q.check(core ~= nil and math.abs(core - (f.stats.TEMPERATURE or 37)) <= 0.3, "put back: the core temperature as found", S.n2(core) .. " C (found " .. S.n2(f.stats.TEMPERATURE) .. " C)")
        Q.check(S.dispC() == f.disp and S.ovenC() == f.oven and ZeD.currentBase == f.base and ZeD.currentSize == f.size
            and S.optVal(ZeD.Settings and ZeD.Settings.lookStyleOption) == f.style,
            "put back: the display unit, the oven's unit, the theme, the text size and Style as found",
            tostring(S.dispC()) .. ", " .. tostring(S.ovenC()) .. ", " .. tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.currentSize) .. ", " .. tostring(S.optVal(ZeD.Settings and ZeD.Settings.lookStyleOption)))
        if w then
            Q.check(w._thermalView == f.view and w._thermalPick == f.pick and (w._thermalFigureExpanded and true or false) == f.fold
                and S.pickedFolded() == f.pickedFold and w._thermalHoveredPart == f.hovered and w._maxWinW == f.maxWinW and not w._thermalMenuOpen,
                "put back: the view, the pick, the figure's fold, the block's fold, the hovered part and the window's width cap as found",
                "view " .. tostring(w._thermalView) .. ", pick " .. tostring(w._thermalPick) .. ", figure " .. tostring(w._thermalFigureExpanded)
                .. ", block folded " .. tostring(S.pickedFolded()) .. ", cap " .. tostring(w._maxWinW) .. " (found " .. tostring(f.maxWinW) .. ")")
        end
        local held = nil
        pcall(function() held = S.F.getFocusedWindow(S.pn) end)
        Q.check(S.lockFound() == f.lock and held == f.focusWin and S.mouse == nil and #S.held == 0,
            "put back: the input lock, the pad focus and the pointer as found, no window held",
            "lock " .. S.lockFound() .. " (found " .. tostring(f.lock) .. "), focus " .. tostring(held == f.focusWin))
        local TT = ZeD.ThermalTab
        Q.check(S.w0 == nil and TT._renderHeader ~= nil and rawget(S.drawer() or {}, "drawText") ~= S.textHook,
            "put back: the tab's own draw pieces again (the wrappers off)")
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6 and S.p:getVehicle() == nil, "put back: he stands where he stood, in no car", string.format("%.1f,%.1f off", dx, dy))
        if S.bailed then
            Q.check(S.p:isGodMod() == true, "put back: the run stopped early, so god mode is left ON", tostring(S.p:isGodMod()))
        else
            Q.check(S.p:isGodMod() == (f.god and true or false), "put back: god mode as found", tostring(f.god))
        end
        Q.check(not S.p:isDead(), "put back: the character is alive", "health top-ups " .. tostring(S.topUps or 0))
        local e1 = S.errN()
        if S.err0 and e1 then
            Q.check(e1 == S.err0 and S.tabErrs == 0, "the Thermal run ran with no Lua error", (e1 - S.err0) .. " new, the tab's own " .. S.tabErrs)
        else
            Q.check(S.tabErrs == 0, "the Thermal run: the tab's own error log is clean (the game's Lua error count cannot be read here)", S.tabErrs .. " logged")
        end
    end)
end

-- ===================================================================== the run
S.setup()
S.caseReadings()
S.caseUnits()
S.caseViews()
S.caseClothes()
S.caseWet()
S.caseCore()
S.caseThemes()
S.casePad()
S.caseMouse()
S.caseLayout()
S.caseLite()
S.caseCar()
S.buildPutBack()
Q.start()
