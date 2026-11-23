-- ZeDUI/tools/qa/rt_strain.lua  (Nov 22 2026, QA): the release test's fight row: muscle strain and fatigue.
-- The director, Nov 22 2026: "Can you add muscle strain and fatigue to a QA test? It's very common early in the game
-- to get muscle strain and fatigue, especially if you're trying to fight a lot."
-- Built on rt_kit.lua (the global RT). grep "ZEDQA rt_strain". No pictures.
--
-- What the game has (42.22, javap of the jar): muscle strain is BodyPart stiffness, 0..100 per part. A melee swing
-- adds it through IsoGameCharacter:addCombatMuscleStrain (times the sandbox's Muscle Strain Factor): one arm is
-- Hand, ForeArm and UpperArm (addArmMuscleStrain / addLeftArmMuscleStrain / addBothArmMuscleStrain), some swings
-- the back (Torso_Upper, Torso_Lower), neck or right leg. It fades by 0.002 x the game's multiplier per update.
-- There is NO strain moodle: MoodleType has none. Each part's stiffness / 3.5 goes into its pain
-- (BodyPart:getPain, getAdditionalPain(true)), so heavy strain shows as the game's Pain moodle. Vanilla's health
-- panel lists a part from stiffness 5 ("Minor Muscle Strain" under 20, "Muscle Strain" from 20). A fight also
-- drains endurance (CharacterStat.ENDURANCE, the Endurance moodle: under 0.75 / 0.5 / 0.25 / 0.1) and, over the
-- day, sleep (CharacterStat.FATIGUE, the Tired moodle: over 0.6 / 0.7 / 0.8 / 0.9).
--
-- Staged twice on the character, as a fight leaves it: both hands, forearms and upper arms at minor strain (10)
-- with endurance at 0.4 (exerted) and fatigue at 0.75 (tired), then at heavy strain (40) with endurance 0.2 and
-- fatigue 0.85; the upper torso at 4 both times (under the line of 5). Each time:
--   moodles   the game has the Endurance and Tired moodles on (and Pain, when heavy strain brings it): ZeD lists
--             them, places them on screen, the game's own column draws them where ZeD put it (ZeD's copy for the
--             row or columns), and no ZeD window, belt or HUD piece covers one (the pair shut, as in a fight)
--   wheel     the D-pad Left wheel's Medicine slice and its list are as they were before the strain (stiffness
--             has no treatment: no row names a strained part); the quick RB+A chord would do what it did before
--             (recorded through QuickChords.resolve and the slice's own pick, never run)
--   list      the Health tab lists each strained part with the game's words (IGUI_health_MinorStiffness or
--             IGUI_health_Stiffness) and its severity (warning / danger), drawn as an injury row; the part under 5
--             is not listed
--   figure    each strained part with no wound shows the strain tint (T.strainMinor at 10, T.strainHeavy at 40;
--             the director's pick A1, Nov 22 2026), a part with a wound (health 80 or less, a condition that is not
--             care, a mod's line) its health colour, and carries its strain for the figure's detail view; the
--             figure drew the part. The Thermal figure and Equipment's defense figure show the same strain tint on
--             the strained arms with no wound. (A build before the strain tint, no HealthTab.figureColor or
--             T.strainMinor: the health tint as before, the other figures skipped.)
--   overall   the overall health and the game's word for it are as before (no wound made up); the summary counts
--             the strain apart from the injuries (pick B1): no new injury, strainedCount up by the parts newly
--             strained, and its lines read "No injuries, Muscle Strain: N" (or "X of 17 injured" over "Muscle
--             Strain: N of 17" with wounds); every new condition is a strain word. (Before the strain tint: the
--             summary is not "No injuries" and counts the strained parts as injured, nothing more.)
--   band      the exercise block of the picked exercise drew, with the game's stiffness lines and a regularity;
--             exerted past the game's line (Endurance level 3) Start is off and the block says why
--   fill      the Muscle Strain block under the injuries names each strained part with the right word, the
--             Moodles block names Endurance and Tired; RT.bounds on the tab
-- Also: the game's own arm strain (addBothArmMuscleStrain) lands on the six parts staged here (skipped with the
-- sandbox's Muscle Strain Factor at 0), and no Lua error in the run.
-- Puts back: each part's stiffness, endurance, fatigue and pain exactly as found, god mode, the Health and Thermal
-- figures' folds, the Equip tab's picked slot, the window pair open or shut, and its tab. Nothing is given; the character stays well.
local Q = RT.make("rt_strain")
Q.maxMs = 600000                     -- (the runner gives this script 900 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, back = {}, base = {} }
local Z = ZeD

-- the parts a swing strains (both arms), and one under the line of 5
S.ARMS = { "Hand_L", "Hand_R", "ForeArm_L", "ForeArm_R", "UpperArm_L", "UpperArm_R" }
S.UNDER = "Torso_Upper"
S.ALL = { "Hand_L", "Hand_R", "ForeArm_L", "ForeArm_R", "UpperArm_L", "UpperArm_R", "Torso_Upper" }
S.STATS = { "ENDURANCE", "FATIGUE", "PAIN" }
S.LEVELS = {
    { name = "minor", stiff = 10, under = 4, endurance = 0.4, fatigue = 0.75 },
    { name = "heavy", stiff = 40, under = 4, endurance = 0.2, fatigue = 0.85 },
}
-- ZeD roots that lie over the screen without hiding anything (layers, notes): never "covering" a moodle
S.SEE_THROUGH = { ZeD_MoodleLayer = true, ZeD_MoodleNote = true, ZeD_ActionBarLayer = true, ZeD_MessagesToasts = true,
                  ZeD_PausedGlass = true, ZeD_Tooltip = true, ZeD_WindowOverlay = true, ZeD_JoinCover = true }

-- ===================================================================== helpers
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.part(name)
    local bp = nil
    pcall(function() bp = S.p:getBodyDamage():getBodyPart(BodyPartType[name]) end)
    return bp
end
function S.stiff(name)
    local bp = S.part(name)
    local v = nil
    if bp then pcall(function() v = bp:getStiffness() end) end
    return v
end
function S.setStiff(name, v)
    local bp = S.part(name)
    if bp and v then pcall(function() bp:setStiffness(v) end) end
end
function S.stat(k) local v = nil; pcall(function() v = S.p:getStats():get(CharacterStat[k]) end); return v end
function S.setStat(k, v) if v then pcall(function() S.p:getStats():set(CharacterStat[k], v) end) end end
function S.moodle(key)
    local n = 0
    pcall(function() n = S.p:getMoodles():getMoodleLevel(MoodleType[key]) end)
    return n or 0
end
function S.moodleName(key)
    local s = nil
    pcall(function() s = S.p:getMoodles():getMoodleDisplayString(MoodleType[key]) end)
    return s
end
function S.partWord(name)
    local s = nil
    pcall(function() s = BodyPartType.getDisplayName(BodyPartType[name]) end)
    return tostring(s or name)
end
function S.typeOf(bp) local s = nil; if bp then pcall(function() s = tostring(bp:getType()) end) end; return s end
function S.minorLbl() return getText("IGUI_health_MinorStiffness") end
function S.heavyLbl() return getText("IGUI_health_Stiffness") end
function S.isStrainLbl(s) return s == S.minorLbl() or s == S.heavyLbl() end
function S.hasCond(conds, label, sev)
    for _, c in ipairs(conds or {}) do
        if c.label == label and (sev == nil or c.severity == sev) then return true end
    end
    return false
end
-- the Health tab's read of the body for a part (by its BodyPartType name), or nil
function S.entryOf(data, name)
    for _, e in ipairs(data and data.entries or {}) do
        if S.typeOf(e.bodyPart) == name then return e end
    end
    return nil
end
-- the figure's name for a part (gatherData's partByFigure), or nil
function S.figOf(data, name)
    for fig, bp in pairs(data and data.partByFigure or {}) do
        if S.typeOf(bp) == name then return fig end
    end
    return nil
end
-- the figure's tint for a health (HealthTab.lua getHealthColor)
function S.tint(h)
    local T = Z.T
    if h > 80 then return T.positive end
    if h > 50 then return T.warning end
    if h > 20 then return T.danger end
    return { r = 0.95, g = 0.15, b = 0.15 }
end
-- a build with the strain tint (the director's picks A1 and B1, Nov 22 2026): HealthTab.figureColor and the tokens
function S.strainBuild()
    local HT, T = Z.HealthTab, Z.T
    return HT ~= nil and HT.figureColor ~= nil and HT.strainColor ~= nil and HT.summaryLines ~= nil and HT.healthColor ~= nil
        and T ~= nil and T.strainMinor ~= nil and T.strainHeavy ~= nil
end
-- the strain tint for a stage (minor under 20, heavy from 20)
function S.strainWant(L) local T = Z.T; return (L and L.stiff >= 20) and T.strainHeavy or T.strainMinor end
-- does a wound show on a figure part (Build's rule, read here from the data: health 80 or less, a condition that is
-- not care, or another mod's line on the part)
function S.woundOn(data, fn, hp)
    if hp <= 80 then return true, "health " .. tostring(hp) end
    if data.extraByFigureName and data.extraByFigureName[fn] then return true, "a mod's line" end
    for _, c in ipairs(data.condsByFigureName and data.condsByFigureName[fn] or {}) do
        if not c.care then return true, tostring(c.label) end
    end
    return false, nil
end
-- the colour a strained part should draw in, and why: on a strain build the strain tint unless a wound shows
function S.figWant(data, fn, hp, L)
    if not S.strainBuild() then return S.tint(hp), "health" end
    local wound, why = S.woundOn(data, fn, hp)
    if wound then return Z.HealthTab.healthColor(hp), "wound: " .. tostring(why) end
    return S.strainWant(L), "strain"
end
function S.near(a, b) return type(a) == "number" and type(b) == "number" and math.abs(a - b) < 0.002 end
function S.sameC(a, b) return a ~= nil and b ~= nil and S.near(a.r, b.r) and S.near(a.g, b.g) and S.near(a.b, b.b) end
function S.cText(c) return c and string.format("%.2f,%.2f,%.2f", c.r or -1, c.g or -1, c.b or -1) or "none" end
-- how the strained count moves from the start: the arms newly at 5 or more, less the part under 5 if it was strained
function S.newStrain()
    local d = 0
    for _, n in ipairs(S.ARMS) do if (S.sf0[n] or 0) < 5 then d = d + 1 end end
    if (S.sf0[S.UNDER] or 0) >= 5 then d = d - 1 end
    return d
end
function S.rectsMeet(ax, ay, aw, ah, bx, by, bw, bh) return ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah end

-- ===================================================================== the stage, held every player update
function S.apply()
    local L = S.want
    if not L then return end
    for _, n in ipairs(S.ARMS) do S.setStiff(n, L.stiff) end
    S.setStiff(S.UNDER, L.under)
    S.setStat("ENDURANCE", L.endurance)
    S.setStat("FATIGUE", L.fatigue)
end
function S.keep(pl) if S.want and pl == S.p then pcall(S.apply) end end
function S.stage(L)
    S.want = L
    S.apply()
    if not S.keeping then Events.OnPlayerUpdate.Add(S.keep); S.keeping = true end
end
function S.unstage()
    S.want = nil
    if S.keeping then Events.OnPlayerUpdate.Remove(S.keep); S.keeping = false end
end

-- ===================================================================== the Medicine list and the RB+A chord
-- the Medicine slice on the Character wheel's top level (the builder the wheel runs)
function S.medSlice()
    local D = Z.DpadWheels
    local ring = nil
    pcall(function() ring = D.B.character(S.p, S.pn) end)
    local want = Z.tr("UI_ZeD_Wheel_Medicine")
    for _, e in ipairs(ring or {}) do if e.name == want then return e end end
    return nil
end
-- the Medicine list's rows as "name | detail" (C.medicine, what the wheel's inner level shows)
function S.medRows()
    local out = {}
    local rows = nil
    pcall(function() rows = Z.DpadWheels.C.medicine(S.p, S.pn) end)
    for _, e in ipairs(rows or {}) do out[#out + 1] = tostring(e.name) .. " | " .. tostring(e.detail) end
    return out
end
function S.inList(list, s) for _, x in ipairs(list or {}) do if x == s then return true end end; return false end
-- what RB+A would do now, as QuickChords.run decides it, without running it: a line, and the slice it would run
function S.bestOf(e, depth)
    if e.pick then
        local ok, b = pcall(e.pick, S.p, S.pn)
        if ok and b then return b end
    end
    local list = nil
    if e.sub then pcall(function() list = e.sub(S.p, S.pn) end) end
    for _, x in ipairs(list or {}) do
        if not x.off then
            if x.run then return x end
            if x.sub and depth < 2 then
                local b = S.bestOf(x, depth + 1)
                if b then return b end
            end
        end
    end
    return nil
end
function S.chordAct()
    local Qc = Z.QuickChords
    if not Qc then return "no QuickChords", nil end
    local okG, path = pcall(Qc.get, "RB+A")
    if not okG or not path then return "nothing (RB+A has no action)", nil end
    local okR, e, why = pcall(Qc.resolve, S.p, S.pn, path)
    if not okR then return "resolve failed: " .. tostring(e), nil end
    if not e then return "says: " .. tostring(why or "gone"), nil end
    if e.off then return "says: " .. tostring(e.off), nil end
    if e.fill or (e.sub and not e.run and not (e.best or e.pick)) then return "opens the wheel at " .. tostring(path), nil end
    local act = e
    if not e.run and (e.sub or e.pick) then act = S.bestOf(e, 0) end
    if not act then return "says: not now", nil end
    if act.off then return "says: " .. tostring(act.off), nil end
    if not act.run then return "nothing", nil end
    return "runs: " .. tostring(act.name) .. " | " .. tostring(act.detail), act
end
-- the D-pad wheels shut (rt_pad's way)
function S.closeWheels()
    local D, W = Z.DpadWheels, Z.Wheel
    local st = D.state[S.pn]
    if st and st.menu and st.menu.undisplay then pcall(st.menu.undisplay, st.menu) end
    D.state[S.pn] = nil
    pcall(function()
        local m = getPlayerRadialMenu(S.pn)
        if m and m:isReallyVisible() then m:undisplay() end
    end)
    if W then W.qaPoint = nil end
end

-- ===================================================================== start
Q.step(10, function()
    S.err0 = S.errN()
    Q.check(Z.HealthTab ~= nil and Z.HealthTab.gatherData ~= nil and Z.Moodles ~= nil and Z.Moodles.rect ~= nil
        and Z.DpadWheels ~= nil and Z.DpadWheels.C ~= nil and Z.QuickChords ~= nil and Z.TabFill ~= nil,
        "every module the fight row reads is loaded (HealthTab, Moodles, DpadWheels, QuickChords, TabFill)")
    -- what to put back
    S.pairWas = RT.isOpen()
    local w = RT.cw()
    if w then S.tabWas = w._activeTab end
    S.god = S.p:isGodMod()
    S.st0 = {}
    for _, k in ipairs(S.STATS) do S.st0[k] = S.stat(k) end
    S.sf0 = {}
    for _, n in ipairs(S.ALL) do S.sf0[n] = S.stiff(n) end
    S.back.on = true
    Q.say("found: stiffness " .. (function()
        local t = {}
        for _, n in ipairs(S.ALL) do t[#t + 1] = n .. " " .. tostring(S.sf0[n]) end
        return table.concat(t, ", ")
    end)() .. "; endurance " .. tostring(S.st0.ENDURANCE) .. ", fatigue " .. tostring(S.st0.FATIGUE) .. ", god " .. tostring(S.god))
    -- the body and the medicine before any strain
    local okD, data = pcall(Z.HealthTab.gatherData, S.p)
    if okD and data then
        S.base.overall, S.base.wounded = data.overall, data.woundedCount or 0
        S.base.strained = data.strainedCount or 0       -- (a build with the strain tint; nil before it)
        S.base.conds = {}
        for _, e in ipairs(data.entries or {}) do
            local nm = S.typeOf(e.bodyPart)
            if nm then
                local set = {}
                for _, c in ipairs(e.conditions or {}) do set[#set + 1] = c.label end
                S.base.conds[nm] = set
            end
        end
    end
    Q.check(okD and data ~= nil, "before: the Health tab's read of the body works", okD and "" or tostring(data))
    S.base.med = S.medRows()
    local ms = S.medSlice()
    S.base.medOff = ms and ms.off or nil
    S.base.chord = S.chordAct()
    Q.say("this build " .. (S.strainBuild() and "has the strain tint (HealthTab.figureColor, T.strainMinor)" or "has no strain tint (the old expectations)"))
    Q.say("before: Medicine " .. (S.base.medOff and ("off (" .. tostring(S.base.medOff) .. ")") or (#S.base.med .. " rows"))
        .. "; RB+A " .. tostring(S.base.chord))
    RT.pairShut()
    S.closeWheels()
end)

-- ===================================================================== the game's own arm strain
-- (one swing's worth through the game's call: it lands on the six parts staged below; put back at once)
Q.step(2, function()
    local f = SandboxVars and SandboxVars.MuscleStrainFactor or nil
    if type(f) == "number" and f <= 0 then Q.skip("the game's arm strain", "the sandbox's Muscle Strain Factor is 0"); return end
    local before = {}
    for _, n in ipairs(S.ALL) do before[n] = S.stiff(n) end
    local ok, err = pcall(function() S.p:addBothArmMuscleStrain(5) end)
    local up, still = {}, {}
    for _, n in ipairs(S.ALL) do
        local a, b = before[n], S.stiff(n)
        if a and b and b > a then up[#up + 1] = n else still[#still + 1] = n end
    end
    for _, n in ipairs(S.ALL) do S.setStiff(n, S.sf0[n]) end
    if not Q.check(ok, "the game's arm strain (addBothArmMuscleStrain) runs", ok and "" or tostring(err)) then return end
    Q.check(#up == #S.ARMS and S.inList(still, S.UNDER), "the game's arm strain lands on both hands, forearms and upper arms",
        "up: " .. table.concat(up, ", ") .. "; not: " .. table.concat(still, ", ") .. "; factor " .. tostring(f))
end)

-- ===================================================================== each stage
function S.moodleSlot(L, r, key)
    for i, m in ipairs(L and L._list or {}) do
        if m.key == key then
            local ok, sx, sy = pcall(L._slotXY, L, i)
            if ok and sx and sy then return r.x + sx, r.y + sy, i end
            return nil, nil, i
        end
    end
    return nil, nil, nil
end
-- the visible ZeD roots that meet a box (the see-through layers and full-screen layers left out)
function S.coverers(x, y, w, h)
    local W, H = RT.core:getScreenWidth(), RT.core:getScreenHeight()
    local out = {}
    for _, r in ipairs(RT.roots()) do
        local vis = false
        pcall(function() vis = r.e:isVisible() end)
        if vis and RT.isZeD(r.t) and not S.SEE_THROUGH[tostring(r.t.Type)] then
            local ex, ey, ew, eh = r.e:getX(), r.e:getY(), r.e:getWidth(), r.e:getHeight()
            if ew > 2 and eh > 2 and not (ew >= W - 2 and eh >= H - 2) and S.rectsMeet(x, y, w, h, ex, ey, ew, eh) then
                out[#out + 1] = string.format("%s %d,%d %dx%d", tostring(r.t.Type), math.floor(ex), math.floor(ey), math.floor(ew), math.floor(eh))
            end
        end
    end
    return out
end
function S.checkMoodles(lab)
    local M = Z.Moodles
    local r = M.rect(S.pn)
    local L = M.getLayer and M.getLayer(S.pn) or nil
    if not Q.check(r ~= nil and L ~= nil, lab .. " moodles: ZeD places the moodles", r and r.place or "no rect") then return end
    local sw, sh = RT.core:getScreenWidth(), RT.core:getScreenHeight()
    local keys = { "ENDURANCE", "TIRED" }
    if S.moodle("PAIN") > 0 then keys[#keys + 1] = "PAIN"
    else Q.say(lab .. ": the game's Pain moodle is off (strain " .. tostring(S.want and S.want.stiff) .. " adds stiffness / 3.5 to each part's pain)") end
    for _, key in ipairs(keys) do
        local lvl = S.moodle(key)
        local x, y, idx = S.moodleSlot(L, r, key)
        local nm = tostring(S.moodleName(key) or key)
        if Q.check(lvl > 0 and idx ~= nil, lab .. " moodles: the game has " .. key .. " on and ZeD lists it",
            nm .. ", level " .. tostring(lvl) .. ", slot " .. tostring(idx)) and x then
            local sz = math.floor(r.size or 32)
            Q.check(x >= -1 and y >= -1 and x + sz <= sw + 1 and y + sz <= sh + 1, lab .. " moodles: " .. key .. " is on screen",
                string.format("%d,%d %dx%d", math.floor(x), math.floor(y), sz, sz))
            local cov = S.coverers(x, y, sz, sz)
            Q.check(#cov == 0, lab .. " moodles: no ZeD window, belt or HUD piece covers " .. key,
                #cov == 0 and "clear" or table.concat(cov, "; "))
        end
    end
    -- who draws them: the game's own column (right or left in one column), else ZeD's faithful copy
    if r.place ~= "bottom" and not r.cols then
        local mui = UIManager.getMoodleUI(S.pn)
        local mx, my, mv = nil, nil, false
        if mui then pcall(function() mx, my, mv = mui:getX(), mui:getY(), mui:isVisible() end) end
        Q.check(mv and mx ~= nil and math.abs(mx - r.x) <= 1 and math.abs(my - r.y) <= 1,
            lab .. " moodles: the game's own column draws them where ZeD put it (" .. tostring(r.place) .. ")",
            tostring(mx) .. "," .. tostring(my) .. " vs " .. tostring(r.x) .. "," .. tostring(r.y))
    else
        Q.check(L._show == true, lab .. " moodles: ZeD draws the game's moodles as its " .. tostring(r.place) .. (r.cols and " columns" or " row"))
    end
end

function S.checkWheel(lab)
    local D = Z.DpadWheels
    local st = D.state[S.pn]
    if not Q.check(st ~= nil and st.dir == "left", lab .. " wheel: the D-pad Left (Character) wheel opens") then return end
    local med = nil
    local want = Z.tr("UI_ZeD_Wheel_Medicine")
    for _, e in ipairs(st.path[1] and st.path[1].entries or {}) do if e.name == want then med = e end end
    if not Q.check(med ~= nil, lab .. " wheel: it has Medicine") then return end
    Q.check((med.off ~= nil) == (S.base.medOff ~= nil), lab .. " wheel: the Medicine slice is as it was before the strain",
        med.off and ("off: " .. tostring(med.off)) or "on")
    -- its list: the wheel's own inner level when the slice opens, and the builder either way
    local shown = {}
    if not med.off then
        D.enter(S.pn, med)
        st = D.state[S.pn]
        local lv = st and st.path[#st.path]
        for _, e in ipairs(lv and lv.entries or {}) do shown[#shown + 1] = tostring(e.name) .. " | " .. tostring(e.detail) end
    end
    local rows = S.medRows()
    local bogus = {}
    for _, n in ipairs(S.ARMS) do
        local pw = S.partWord(n)
        for _, s in ipairs(rows) do
            if s:find(" | " .. pw, 1, true) and not S.inList(S.base.med, s) then bogus[#bogus + 1] = s end
        end
        for _, s in ipairs(shown) do
            if s:find(" | " .. pw, 1, true) and not S.inList(S.base.med, s) and not S.inList(bogus, s) then bogus[#bogus + 1] = s end
        end
    end
    Q.check(#bogus == 0 and #rows == #S.base.med, lab .. " wheel: Medicine offers nothing for the strain (no row for a strained part)",
        #bogus == 0 and (#rows .. " rows, " .. #S.base.med .. " before") or table.concat(bogus, "; "))
    local line, act = S.chordAct()
    local harm = false
    if act then for _, n in ipairs(S.ARMS) do if tostring(act.detail) == S.partWord(n) then harm = true end end end
    Q.check(line == S.base.chord and not harm, lab .. " chord: RB+A would do what it did before the strain (recorded, not run)",
        tostring(line) .. (line == S.base.chord and "" or ("; before: " .. tostring(S.base.chord))))
    S.closeWheels()
end

-- the summary on a build with the strain tint (pick B1): strain counted apart from the injuries, in the game's words
function S.checkSummary(lab, data, L)
    local HT = Z.HealthTab
    local wantS = (S.base.strained or 0) + S.newStrain()
    local lv = (L.stiff >= 20) and 2 or 1
    Q.check(not HT.calm(data) and data.woundedCount == (S.base.wounded or 0) and data.strainedCount == wantS
        and type(data.strainWorst) == "number" and data.strainWorst >= lv,
        lab .. " overall: the summary counts the strain apart from the injuries (no new injury, the strained parts counted)",
        "wounded " .. tostring(data.woundedCount) .. " (before " .. tostring(S.base.wounded) .. "), strained "
        .. tostring(data.strainedCount) .. " (want " .. wantS .. "), worst " .. tostring(data.strainWorst))
    local okL, lines = pcall(HT.summaryLines, data)
    if not Q.check(okL and type(lines) == "table" and #lines > 0, lab .. " overall: the summary's lines are made",
        okL and "" or tostring(lines)) then return end
    local word = S.heavyLbl()          -- the game's own "Muscle Strain" (IGUI_health_Stiffness)
    local want = {}
    if (S.base.wounded or 0) == 0 then
        want[1] = Z.tr("UI_ZeD_Health_NoInjuriesStrain", word, wantS)
    else
        want[1] = Z.tr("UI_ZeD_Health_InjuredOf", S.base.wounded, data.totalParts)
        want[2] = Z.tr("UI_ZeD_Health_StrainOf", word, wantS, data.totalParts)
    end
    local got = {}
    for _, ln in ipairs(lines) do got[#got + 1] = tostring(ln.text) end
    local okT = #got == #want
    for i = 1, #want do
        if got[i] ~= want[i] then okT = false end
    end
    -- the strain line names the game's word and the count (a missing key would show its name)
    local sl = got[#got] or ""
    okT = okT and sl:find(word, 1, true) ~= nil and sl:find(tostring(wantS), 1, true) ~= nil
    Q.check(okT, lab .. " overall: the summary reads " .. ((S.base.wounded or 0) == 0 and "\"No injuries, Muscle Strain: N\""
        or "\"X of 17 injured\" over \"Muscle Strain: N of 17\""), table.concat(got, " / "))
    local dot = lines[#lines] and lines[#lines].dot or nil
    local wantDot = HT.strainColor(data.strainWorst or lv)
    Q.check(S.sameC(dot, wantDot), lab .. " overall: the summary's strain line has its dot in the strain tint",
        S.cText(dot) .. ", want " .. S.cText(wantDot))
end

-- the Thermal figure and Equipment's defense figure: the strained arms with no wound show the strain tint
S.OTHER = { thermal = "Thermal", equip = "Equipment's defense" }
function S.otherFig(w, which)
    if not w then return nil end
    if which == "thermal" then return w._thermalBodyFigure end
    return w._equipDefBodyFigure
end
-- (QA, Nov 22: the director, "No, Health only": the strain tint is the Health tab's and the medical card's only;
-- Thermal and Equipment keep their own colors) the strained arms the figure wrongly tints with strain, as "name tint";
-- nil with no figure drawn
function S.figMisses(which)
    local w = RT.cw()
    local fig = S.otherFig(w, which)
    local want = S.strainWant(S.want)
    if not (fig and fig.colorMap and want) then return nil end
    local miss = {}
    for _, a in ipairs(S.clean or {}) do
        local c = fig.colorMap[a.fn]
        if S.sameC(c, want) then miss[#miss + 1] = a.n .. " " .. S.cText(c) end
    end
    return miss
end
function S.openOther(which)
    S.otherOpen = false
    if not S.strainBuild() then return end
    local w = RT.cw()
    if not w then return end
    if which == "thermal" and not w._thermalFigureExpanded then
        if S.thermWas == nil then S.thermWas = false end
        w._thermalFigureExpanded = true
    end
    if which == "equip" and w._equipSelected then
        if S.equipSelWas == nil then S.equipSelWas = w._equipSelected end
        w._equipSelected = nil
    end
    S.otherOpen = RT.charTab(which)
end
function S.otherReady(which)
    if not S.strainBuild() or not S.otherOpen then return true end
    local w = RT.cw()
    if not (w and w._activeTab == which) then return false end
    return S.figMisses(which) ~= nil
end
function S.checkOther(lab, which, ok)
    local what = lab .. " " .. S.OTHER[which] .. " figure: the strained arms keep this tab's own colors, no strain tint (Health only)"
    if not S.strainBuild() then Q.skip(what, "this build has no strain tint (HealthTab.figureColor, T.strainMinor)"); return end
    if not Q.check(S.otherOpen == true, lab .. " " .. S.OTHER[which] .. ": the tab opens on the Character window") then return end
    if #(S.clean or {}) == 0 then Q.skip(what, "a wound shows on every strained arm (its colour wins there)"); return end
    local miss = S.figMisses(which)
    local w = RT.cw()
    Q.check(ok and miss ~= nil and #miss == 0, what .. " (no wound on them)",
        tostring(w and w._activeTab) .. ", want " .. S.cText(S.strainWant(S.want)) .. "; "
        .. (miss == nil and "no figure drawn" or (#miss == 0 and (#S.clean .. " arms in their own colors") or ("strain-tinted " .. table.concat(miss, "; ")))))
end

-- the Health tab shows this stage (its own throttled reads have caught up)
function S.healthReady()
    local w = RT.cw()
    if not (w and w._activeTab == "health" and w._drawerOpen ~= false) then return false end
    local data, fill = w._healthCache, w._healthFill
    -- (Nov 23 2026, the treatment card: with strain listed, the middle column is the injury list, not the exercise info)
    if not (data and fill and (w._healthInfoShown or w._healthMiddle == "injuries")) then return false end
    local L = S.want
    local lbl = (L.stiff < 20) and S.minorLbl() or S.heavyLbl()
    for _, n in ipairs(S.ARMS) do
        local e = S.entryOf(data, n)
        if not (e and S.hasCond(e.conditions, lbl)) then return false end
    end
    local minorN = 0
    for _, s in ipairs(fill.strain or {}) do if s.minor == (L.stiff < 20) then minorN = minorN + 1 end end
    if minorN < #S.ARMS then return false end
    return S.moodle("ENDURANCE") > 0 and S.moodle("TIRED") > 0
end

function S.checkHealth(lab, ok)
    local w = RT.cw()
    if not Q.check(ok and w ~= nil, lab .. " health: the Health tab shows the strain within a few reads",
        w and (tostring(w._activeTab) .. ", drawer " .. tostring(w._drawerOpen)) or "no window") then return end
    local HT = Z.HealthTab
    local data, fill = w._healthCache, w._healthFill
    local L = S.want
    local heavy = L.stiff >= 20
    local lbl, sev = heavy and S.heavyLbl() or S.minorLbl(), heavy and "danger" or "warning"
    -- the list
    local zones = {}
    for _, z in ipairs(w._healthInjuryZones or {}) do zones[tostring(z.bodyPartName)] = true end
    local names = {}
    for _, n in ipairs(S.ARMS) do
        local e = S.entryOf(data, n)
        names[n] = e and e.name or nil
        Q.check(e ~= nil and S.hasCond(e.conditions, lbl, sev),
            lab .. " list: " .. n .. " is listed as the game's \"" .. tostring(lbl) .. "\" (" .. sev .. ")",
            e and (tostring(e.name) .. ", worst " .. tostring(e.worstSev)) or "not listed")
        if e then Q.check(zones[tostring(e.name)] == true, lab .. " list: " .. n .. "'s injury row is drawn") end
    end
    -- the treatment card (the director, Nov 23 2026: "Muscle strain should also show up there"; strain alone keeps
    -- the exercise footer, as the game has no treatment for it)
    local hasWound = false
    for _, e in ipairs(data.entries or {}) do
        for _, c in ipairs(e.conditions or {}) do if not c.strain then hasWound = true end end
    end
    Q.check(w._healthMiddle == "injuries" and (tonumber(w._healthInjuryShown) or 0) >= #S.ARMS
        and (hasWound or w._healthFooterMode == "exercise"),
        lab .. " list: the middle column lists the strained arms and, with strain alone, the footer stays the exercise's",
        "middle " .. tostring(w._healthMiddle) .. ", rows " .. tostring(w._healthInjuryShown) .. ", footer " .. tostring(w._healthFooterMode)
        .. ", a wound listed " .. tostring(hasWound))
    local eu = S.entryOf(data, S.UNDER)
    local wasListed = S.base.conds and S.base.conds[S.UNDER] ~= nil
    Q.check(wasListed or eu == nil, lab .. " list: " .. S.UNDER .. " at stiffness " .. tostring(L.under) .. " (under 5) is not listed",
        eu and ("listed: " .. tostring(eu.name)) or "not listed")
    -- the figure
    local fig = w._healthBodyFigure
    local rects = {}
    if fig and fig.getPartRects then
        local okR, rs = pcall(fig.getPartRects, fig)
        for _, r in ipairs(okR and rs or {}) do rects[tostring(r.name)] = true end
    end
    local strainOn = S.strainBuild()
    S.clean = {}
    if strainOn then
        -- the strain tint is its own: apart from the health tints (the token, not a fallback to one of them)
        local sw, T = S.strainWant(L), Z.T
        Q.check(sw ~= nil and not S.sameC(sw, T.positive) and not S.sameC(sw, T.warning) and not S.sameC(sw, T.danger)
            and not S.sameC(T.strainMinor, T.strainHeavy),
            lab .. " figure: the " .. (heavy and "heavy" or "minor") .. " strain tint is its own (not a health tint, minor and heavy apart)",
            "minor " .. S.cText(T.strainMinor) .. ", heavy " .. S.cText(T.strainHeavy))
    end
    for _, n in ipairs(S.ARMS) do
        local fn = S.figOf(data, n)
        local hp = fn and data.partHealth[fn] or nil
        local c = fig and fn and fig.colorMap and fig.colorMap[fn] or nil
        local want, why = nil, "no health"
        if hp then want, why = S.figWant(data, fn, hp, L) end
        local okC = c ~= nil and S.sameC(c, want)
        local detail = tostring(fn) .. " " .. tostring(hp) .. "% " .. S.cText(c) .. ", want " .. S.cText(want) .. " (" .. tostring(why) .. ")"
        if strainOn and hp then
            -- the read behind it (partStrain, partWound) and the medical card's path (HealthTab.figureColor) agree
            local lv = (L.stiff >= 20) and 2 or 1
            local wound = S.woundOn(data, fn, hp)
            local okF, fc = pcall(Z.HealthTab.figureColor, data, fn, hp)
            okC = okC and data.partStrain ~= nil and data.partStrain[fn] == lv and data.partWound ~= nil
                and (data.partWound[fn] == true) == wound and okF and S.sameC(fc, want)
            detail = detail .. "; partStrain " .. tostring(data.partStrain and data.partStrain[fn]) .. ", partWound "
                .. tostring(data.partWound and data.partWound[fn]) .. ", figureColor " .. (okF and S.cText(fc) or tostring(fc))
            if not wound then S.clean[#S.clean + 1] = { n = n, fn = fn } end
        end
        Q.check(okC, lab .. " figure: " .. n .. (strainOn and " shows the strain tint (its health colour where a wound shows)"
            or " is tinted for its health (strain costs no health: no wound colour)"), detail)
        Q.check(fn ~= nil and S.hasCond(data.condsByFigureName[fn], lbl, sev) and rects[tostring(fn)] == true,
            lab .. " figure: " .. n .. " is drawn and carries its strain for the detail view", tostring(fn))
    end
    -- overall and the summary
    Q.check(S.base.overall ~= nil and math.abs((data.overall or 0) - S.base.overall) < 0.5
        and HT.overallWord(data.overall) == HT.overallWord(S.base.overall),
        lab .. " overall: the overall health and the game's word for it are as before the strain (no wound made up)",
        tostring(data.overall) .. " " .. tostring(HT.overallWord(data.overall)) .. ", before " .. tostring(S.base.overall))
    local newLbl, others = 0, {}
    for _, e in ipairs(data.entries or {}) do
        local nm = S.typeOf(e.bodyPart)
        local before = S.base.conds and S.base.conds[nm] or {}
        for _, c in ipairs(e.conditions or {}) do
            if not S.inList(before, c.label) then
                newLbl = newLbl + 1
                if not S.isStrainLbl(c.label) then others[#others + 1] = tostring(nm) .. ": " .. tostring(c.label) end
            end
        end
    end
    Q.check(#others == 0, lab .. " overall: every new condition is a strain word",
        #others == 0 and (newLbl .. " new") or table.concat(others, "; "))
    if strainOn then
        S.checkSummary(lab, data, L)
    else
        local strainedNew = 0
        for _, n in ipairs(S.ARMS) do
            local was = S.base.conds and S.base.conds[n] or nil
            if not (was and #was > 0) then strainedNew = strainedNew + 1 end
        end
        Q.check(not HT.calm(data) and data.woundedCount == (S.base.wounded or 0) + strainedNew,
            lab .. " overall: the summary counts the strained parts, nothing more",
            Z.tr("UI_ZeD_Health_InjuredOf", data.woundedCount, data.totalParts) .. " (before " .. tostring(S.base.wounded) .. ")")
    end
    -- the exercise band and its block
    local sel = HT.selectedExercise(w)
    -- (the treatment card, Nov 23 2026: with strain listed, the list takes the exercise block's place in the middle
    -- column; the footer keeps the picked exercise and Start)
    Q.check(sel ~= nil and w._healthInfoShown == nil and w._healthMiddle == "injuries" and w._healthFooterMode == "exercise",
        lab .. " band: the strain list takes the exercise block's place, the footer keeps the picked exercise",
        tostring(sel) .. "; block " .. tostring(w._healthInfoShown) .. ", middle " .. tostring(w._healthMiddle) .. ", footer " .. tostring(w._healthFooterMode))
    local okI, info = pcall(HT.exerciseInfo, S.p, sel)
    if Q.check(okI and info ~= nil and type(info.regularity) == "number", lab .. " band: the block has its regularity",
        okI and info and tostring(info.regularity) or tostring(info)) then
        local exe = FitnessExercises and FitnessExercises.exercisesType and FitnessExercises.exercisesType[sel]
        local wantN = 0
        if exe and exe.stiffness then
            for part in string.gmatch(exe.stiffness, "[^,]+") do
                if part == "legs" or part == "arms" or part == "abs" then wantN = wantN + 1 end
            end
        end
        Q.check(#info.stiff == wantN, lab .. " band: the block has the game's stiffness lines for " .. tostring(sel),
            #info.stiff .. " lines, the game's list " .. tostring(exe and exe.stiffness))
        if S.moodle("ENDURANCE") > 2 then
            local okS, can = pcall(HT.canStart, w)
            Q.check(okS and can == false and #info.warn > 0, lab .. " band: exerted past the game's line, Start is off and the block says why",
                table.concat(info.warn, "; "))
        end
    end
    -- the blocks under the injuries
    local missing = {}
    for _, n in ipairs(S.ARMS) do
        local found = false
        for _, s in ipairs(fill.strain or {}) do
            if names[n] and s.name == names[n] and s.minor == (not heavy) then found = true end
        end
        if not found then missing[#missing + 1] = n end
    end
    Q.check(#missing == 0, lab .. " fill: the Muscle Strain block names each strained part with the game's word",
        #missing == 0 and (#(fill.strain or {}) .. " rows") or ("missing " .. table.concat(missing, ", ")))
    local eu2 = nil
    for _, s in ipairs(fill.strain or {}) do if eu and s.name == eu.name then eu2 = s end end
    Q.check(eu2 == nil or wasListed, lab .. " fill: the part under 5 is not in the Muscle Strain block")
    local mn = {}
    for _, m in ipairs(fill.moodles or {}) do mn[#mn + 1] = tostring(m.name) end
    Q.check(S.inList(mn, S.moodleName("ENDURANCE")) and S.inList(mn, S.moodleName("TIRED")),
        lab .. " fill: the Moodles block names the Endurance and Tired moodles", table.concat(mn, ", "))
    local F = Z.TabFill
    if F.folded(w, "health", "strain") then
        Q.skip(lab .. " fill: the Muscle Strain block's rows drawn", "the player folded the block")
    else
        local drawn = false
        local b = w._fill and w._fill.health
        for _, list in ipairs({ b and b.last or {}, b and b.zones or {} }) do
            for _, z in ipairs(list) do if z.id == "fill:health:strain:1" then drawn = true end end
        end
        Q.check(drawn, lab .. " fill: the Muscle Strain block's rows are drawn")
    end
    RT.bounds(Q, lab .. " Health tab")
end

for _, L in ipairs(S.LEVELS) do
    local lab = L.name
    Q.step(5, function() S.clean = nil; S.stage(L) end)
    -- (god mode keeps the moodles off: off for the run, put back at the end, as rt_hud does)
    Q.step(30, function()
        if S.moodle("ENDURANCE") == 0 or S.moodle("TIRED") == 0 or not S.near(S.stiff("Hand_L"), L.stiff) then
            if S.p:isGodMod() then
                pcall(function() S.p:setGodMod(false) end)
                Q.say(lab .. ": god mode off for the moodles (put back at the end)")
            end
            S.apply()
        end
    end)
    Q.waitFor(2, 300, function()
        return S.moodle("ENDURANCE") > 0 and S.moodle("TIRED") > 0 and Z.Moodles.rect(S.pn) ~= nil
    end, function()
        Q.check(S.near(S.stiff("ForeArm_R"), L.stiff) and S.near(S.stiff(S.UNDER), L.under)
            and S.near(S.stat("ENDURANCE"), L.endurance) and S.near(S.stat("FATIGUE"), L.fatigue),
            lab .. ": the fight is staged (strain " .. L.stiff .. ", endurance " .. L.endurance .. ", fatigue " .. L.fatigue .. ")",
            "forearm " .. tostring(S.stiff("ForeArm_R")) .. ", torso " .. tostring(S.stiff(S.UNDER)))
        S.checkMoodles(lab)
    end)
    -- the D-pad Left wheel, opened the way the game opens it
    Q.step(5, function()
        S.closeWheels()
        pcall(ISDPadWheels.onDisplayLeft, { player = S.pn, id = nil })
    end)
    Q.step(5, function() S.checkWheel(lab) end)
    -- the Health tab
    Q.step(5, function() RT.pairOpen() end)
    Q.waitFor(10, 120, function() local w = RT.cw(); return w ~= nil and w:isReallyVisible() and w._tabStripPanel ~= nil end, function()
        local w = RT.cw()
        if w and not w._healthFigureExpanded then
            if S.figWas == nil then S.figWas = false end
            w._healthFigureExpanded = true
        end
        Q.check(RT.charTab("health"), lab .. ": the Health tab is on the Character window's strip")
    end)
    Q.waitFor(5, 300, function() return S.healthReady() end, function(ok) S.checkHealth(lab, ok) end)
    -- the Thermal and Equip tabs' figures (their strain reads every 15 frames or 250 ms)
    for _, which in ipairs({ "thermal", "equip" }) do
        Q.step(5, function() S.openOther(which) end)
        Q.waitFor(5, 120, function() return S.otherReady(which) end, function(ok) S.checkOther(lab, which, ok) end)
    end
    Q.step(5, function() RT.pairShut() end)
end

-- ===================================================================== put back
Q.mark()
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    S.unstage()
    S.closeWheels()
    for _, n in ipairs(S.ALL) do S.setStiff(n, S.sf0[n]) end
    for _, k in ipairs(S.STATS) do S.setStat(k, S.st0[k]) end
    pcall(function() S.p:setGodMod(S.god) end)
    S.putExact = true
    for _, n in ipairs(S.ALL) do if S.stiff(n) ~= S.sf0[n] then S.putExact = n end end
    for _, k in ipairs({ "ENDURANCE", "FATIGUE" }) do if not S.near(S.stat(k), S.st0[k]) then S.putExact = k end end
end
Q.step(5, function()
    S.putBack()
    Q.check(S.putExact == true, "put back: each part's stiffness, endurance and fatigue exactly as found", tostring(S.putExact))
    local w = RT.cw()
    if w and S.figWas == false then w._healthFigureExpanded = false end
    if w and S.thermWas == false then w._thermalFigureExpanded = false end
    if w and S.equipSelWas then w._equipSelected = S.equipSelWas end
    if S.pairWas then
        RT.pairOpen()
    else
        RT.pairShut()
    end
end)
Q.waitFor(5, 120, function() return RT.isOpen() == (S.pairWas == true) end, function(ok)
    if S.pairWas and S.tabWas and S.tabWas ~= "health" then RT.charTab(S.tabWas) end
    Q.check(ok, "put back: the window pair " .. (S.pairWas and "open" or "shut") .. " as found")
end)
Q.step(10, function()
    Q.check(S.p:isGodMod() == S.god, "put back: god mode as found", tostring(S.god))
    local w = RT.cw()
    if S.pairWas and S.tabWas then Q.check(w ~= nil and w._activeTab == S.tabWas, "put back: the Character window's tab", tostring(w and w._activeTab)) end
    local hurt = {}
    pcall(function()
        local parts = S.p:getBodyDamage():getBodyParts()
        for i = 0, parts:size() - 1 do
            local bp = parts:get(i)
            if bp:HasInjury() and not (S.base.conds and S.base.conds[S.typeOf(bp)]) then hurt[#hurt + 1] = S.typeOf(bp) end
        end
    end)
    Q.check(#hurt == 0, "put back: the character is as well as found (no new wound)", table.concat(hurt, ", "))
    local e1 = S.errN()
    if S.err0 and e1 then
        Q.check(e1 == S.err0, "the fight row ran with no Lua error", (e1 - S.err0) .. " new")
    else
        Q.skip("the fight row's Lua error count", "the game's Lua error count cannot be read here")
    end
end)
Q.start()
