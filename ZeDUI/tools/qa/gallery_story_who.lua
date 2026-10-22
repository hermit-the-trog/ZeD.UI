-- ZeDUI/tools/qa/gallery_story_who.lua  (Oct 22 2026)
-- Story gallery, beat 00 again ("who they are"), between gallery_story_stage.lua and
-- gallery_story_teardown.lua. Director, Oct 22: "We aren't showing the traits list or the
-- skills with skills already boosted from play. Some of the skills should be close to 6
-- or 7 and others are still 1 to 3 ... if we are talking about it, we show it"; and
-- "make the character window taller to show it all".
-- Six days in, the mechanic's skills have moved: Mechanics 7, Maintenance and Metalworking
-- 6, a spread of 1-3 elsewhere; 23 zombies killed with the crowbar as the favorite weapon.
-- The Character window is made tall enough to show the whole Identity tab (license and
-- both trait lists) and the whole Skills tab, one picture each:
--   story_00a_identity_tall.png, story_00b_skills_tall.png  (the window box is printed)
-- The skills go back with the teardown (the stage kept them); the kills, the favorite
-- weapon and the window's height go back here. "ZEDQA gsk ..." ending "ZEDQA gsk DONE".
local ST = STORY
if not (ST and ST.ready and ST.newSeq) then print("ZEDQA gsk ERR run gallery_story_stage.lua first"); print("ZEDQA gsk DONE"); return end
local S = ST.newSeq("gsk", 300000)
local say = S.say
local p, pn, core = ST.p, ST.pn, ST.core
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local P = ST.P or {}
local W = { kills = p:getZombieKills(), fav = p:getModData()["Fav:Crowbar"] }

-- level, then the part of the way to the next level
local SKILLS = {
    { "Mechanics", 7, 0.35 }, { "Maintenance", 6, 0.2 }, { "MetalWelding", 6, 0.1 },
    { "Electricity", 3, 0.4 }, { "Woodwork", 3, 0.15 }, { "SmallBlunt", 3, 0.5 },
    { "Cooking", 2, 0.3 }, { "Sprinting", 2, 0.6 }, { "Sneak", 2, 0.2 }, { "Doctor", 2, 0.1 },
    { "Lightfoot", 1, 0.5 }, { "Nimble", 1, 0.4 }, { "PlantScavenging", 1, 0.3 }, { "Aiming", 1, 0.2 },
    { "Fitness", 6, 0.3 },
}

local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end
local function goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
local function charTab(id) local w = CW(); return (w and goTab(w, w._tabStripPanel, id)) and true or false end
local function box(tag)
    local c = CW()
    if c then say(string.format("box %s char %d,%d-%d,%d", tag, c:getX(), c:getY(), c:getX() + c:getWidth(), c:getY() + c:getHeight())) end
end

S.step(2, function()
    local xp = p:getXp()
    local lv = {}
    for _, s in ipairs(SKILLS) do
        local perk = Perks[s[1]]
        local ok = perk and pcall(function()
            p:setPerkLevelDebug(perk, s[2])
            xp:setXPToLevel(perk, s[2])
            local pk = PerkFactory.getPerk(perk)
            local span = pk:getTotalXpForLevel(s[2] + 1) - pk:getTotalXpForLevel(s[2])
            xp:AddXPNoMultiplier(perk, span * s[3])
        end)
        lv[#lv + 1] = s[1] .. "=" .. tostring(perk and p:getPerkLevel(perk)) .. (ok and "" or "(ERR)")
    end
    pcall(function() SyncXp(p) end)
    p:setZombieKills(23)
    p:getModData()["Fav:Crowbar"] = 23
    say("skills " .. table.concat(lv, " ") .. " | kills " .. p:getZombieKills())
    if P.smoke and ST.tpSq then ST.tpSq(P.smoke) end
    if ST.face then ST.face("SE") end
    ZeD.applyTheme("hicon", "teal", ZeD.currentSize)
    if not (CWm.isOpen() and WWm.isOpen()) then
        if WWm.isOpen() then WWm.close() end
        if CWm.isOpen() then CWm.toggle(pn) end
        CWm.toggleBothPaired(pn)
    end
end)
S.zoomTo(1.0)
S.poll(10, 120, function() return charTab("identity") end)
-- taller: the same width and place, the height to just above the belt
S.step(20, function()
    local c, w = CW(), WW()
    W.h = c:getHeight()
    local gap = ZeD.T.px(8)
    local x0 = math.floor((core:getScreenWidth() - (c:getWidth() + gap + w:getWidth())) / 2)
    W.right, W.left = x0 + c:getWidth(), x0 + c:getWidth() + gap
    c._anchorRightEdge = W.right
    c:setX(W.right - c:getWidth()); c:setY(0); w:setX(W.left); w:setY(0)
    c:setHeight(math.floor(core:getScreenHeight() * 0.86))
    say("height " .. W.h .. " -> " .. c:getHeight())
end)
S.step(60, function() if ST.parkMouse then ST.parkMouse() end; S.shot("story_00a_identity_tall"); box("identity") end)
S.poll(2, 120, function() return charTab("skills") end)
S.step(60, function() S.shot("story_00b_skills_tall"); box("skills") end)
S.step(2, function()
    local c = CW()
    if c and W.h then c:setHeight(W.h) end
    charTab("loot")
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(pn) end
    p:setZombieKills(W.kills)
    p:getModData()["Fav:Crowbar"] = W.fav
    say("put back: height " .. tostring(W.h) .. ", kills " .. p:getZombieKills() .. " (skills go back with the teardown)")
end)
S.start()
