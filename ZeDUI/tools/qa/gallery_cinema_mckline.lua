-- ZeDUI/tools/qa/gallery_cinema_mckline.lua  (Nov 4 2026, QA; the director's cinema breaks): McKline on the top floor
-- of a downtown Louisville tower at night, crouched, every window on the floor smashed. White tank top, dark trousers,
-- barefoot with glass in both feet, a pistol and
-- a walkie-talkie. Run on the shot save: zedqa_run.ps1 -ShotSave ZeD-Shots-McKline -Manifest cinema_mckline.txt
-- (after gallery_cinema_lib.lua). Pictures cin_mck_<name>.png:
--   health  the Character window on Health (the feet), the World window on Maps
--   radio   the Character window on Radio (the walkie), the World window on Maps
--   wide    no windows, pulled back: the floor and the city edge
-- The look: High Contrast with the red accent (the director). grep "ZEDQA cmck".
local C = CIN
local S = C.seq("cmck")
local p = getPlayer()
local TX, TY, TZ = 12757, 1518, 26

S.step(5, function() C.look("hicon", "red"); C.noWindows(); C.time(0.4); C.moveTo(TX, TY, TZ) end)
-- let the tower load, then stand on a real floor square at the top (search around the probe's square)
S.poll(30, 40, function()
    local cell = getCell()
    local sq = cell:getGridSquare(TX, TY, TZ)
    if sq and sq:getFloor() then
        -- prefer a floor square next to an outer wall or window, a few squares in
        S.say("floor at " .. TX .. "," .. TY .. "," .. TZ)
        return true
    end
    for r = 1, 12 do for dx = -r, r do for dy = -r, r do
        local s2 = cell:getGridSquare(TX + dx, TY + dy, TZ)
        if s2 and s2:getFloor() then TX, TY = TX + dx, TY + dy; C.moveTo(TX, TY, TZ); S.say("floor near: " .. TX .. "," .. TY); return true end
    end end end
    return false
end)
S.step(10, function()
    C.time(0.4)   -- night (the director)
    C.clearSky()
    C.dress({ "Base.Vest_DefaultTEXTURE_TINT", "Base.Trousers_Black", "Base.WristWatch_Left_DigitalBlack", "Base.HolsterShoulder" }, "Base.Pistol",
        { "Base.WalkieTalkie3", "Base.Bullets9mm", "Base.Lighter", "Base.Cigarettes" })
    C.profession("POLICE_OFFICER")   -- (a profession that fits the role: the director)
    C.tint("Base.Vest_DefaultTEXTURE_TINT", 0.86, 0.83, 0.76)
    -- the walkie in the off hand, switched on (the Character window's Radio tab shows for a radio in hand)
    pcall(function()
        local w = p:getInventory():getFirstTypeRecurse("WalkieTalkie3")
        if w then p:setSecondaryHandItem(w); w:getDeviceData():setIsTurnedOn(true) end
    end)
    pcall(function() p:setGodMod(false) end)   -- god mode heals every frame; the save has no zombies
    local bd = p:getBodyDamage()
    for _, part in ipairs({ BodyPartType.Foot_L, BodyPartType.Foot_R }) do
        pcall(function() bd:getBodyPart(part):generateDeepShardWound() end)
    end
    pcall(function() bd:getBodyPart(BodyPartType.ForeArm_L):setScratched(true, true) end)
    pcall(function() bd:getBodyPart(BodyPartType.Head):setScratched(true, true) end)
    p:setDir(IsoDirections.S)
    -- every window on the floor smashed, glass where he walked, and he keeps low (the director)
    C.clearScene(TX, TY, 6, TZ)
    local nw = C.smashWindows(TX, TY, 30, TZ)
    local ng = C.glass(TX, TY, 4, TZ, 12)
    pcall(function() p:setSneaking(true) end)
    -- night on a tower floor is black: a warm emergency light on him and a cold blue fill over the floor (taken away
    -- at the end)
    S.lights = {}
    pcall(function() S.lights[#S.lights + 1] = getCell():addLamppost(TX, TY, TZ, 1.0, 0.82, 0.55, 7) end)
    pcall(function() S.lights[#S.lights + 1] = getCell():addLamppost(TX + 5, TY + 5, TZ, 0.35, 0.45, 0.8, 16) end)
    S.say("windows smashed " .. nw .. ", glass " .. ng)
    local fl = bd:getBodyPart(BodyPartType.Foot_L)
    S.say("dressed; worn " .. tostring(p:getWornItems():size()) .. "; left foot deep " .. tostring(fl:isDeepWounded()) .. " glass " .. tostring(fl:haveGlass()))
end)
C.pointerAway(S)
C.zoom(S, 0.5)
S.step(30, function() C.windows("health", "maps") end)
-- the left foot's detail, as when the pointer rests on it in the figure
S.step(20, function() local cw = ZeD_CharacterWindow.getWindow(); cw._healthFigureExpanded = true; cw._healthHoveredPart = "Left Foot" end)
S.step(150, function() p:setSneaking(true); C.shot(S, "mck_health") end)
S.step(20, function() C.windows("radio", "maps") end)
S.step(150, function() p:setSneaking(true); C.shot(S, "mck_radio") end)
S.step(20, function() C.noWindows() end)
C.zoom(S, 1.25)
S.step(90, function() p:setSneaking(true); C.shot(S, "mck_wide") end)
S.step(30, function() for _, l in ipairs(S.lights or {}) do if l then pcall(function() getCell():removeLamppost(l) end) end end; pcall(function() p:getBodyDamage():RestoreToFullHealth() end); pcall(function() p:setGodMod(true) end); S.say("DONE") end)
S.run()
