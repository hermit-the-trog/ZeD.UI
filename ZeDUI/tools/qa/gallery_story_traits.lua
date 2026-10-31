-- ZeDUI/tools/qa/gallery_story_traits.lua  (Oct 26 2026)
-- Story gallery, the Old job card for 0.2.0-t6: the Identity tab has Hair and beard between the license and the
-- traits, so one tall picture no longer holds both. Run after gallery_story_stage.lua and gallery_story_who.lua (the
-- skills), before the teardown. The tall Character window (fixed x 902) on Identity: story_00a_identity_tall.png
-- (the license, Hair and beard), then scrolled to the bottom: story_00c_identity_traits.png. "ZEDQA git ... DONE".
local ST = STORY
if not (ST and ST.ready and ST.newSeq) then print("ZEDQA git ERR no stage"); print("ZEDQA git DONE"); return end
local S = ST.newSeq("git", 300000)
local say = S.say
local p, pn, core = ST.p, ST.pn, ST.core
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local W = { kills = p:getZombieKills(), fav = p:getModData()["Fav:Crowbar"] }
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
    p:setZombieKills(23)
    p:getModData()["Fav:Crowbar"] = 23
    ZeD.applyTheme(((GAL_LOOK and GAL_LOOK[1]) or "hicon"), ((GAL_LOOK and GAL_LOOK[2]) or "teal"), ZeD.currentSize)   -- GAL_LOOK: gallery_t14_look.lua
    if not (CWm.isOpen() and WWm.isOpen()) then
        if WWm.isOpen() then WWm.close() end
        if CWm.isOpen() then CWm.toggle(pn) end
        CWm.toggleBothPaired(pn)
    end
end)
S.zoomTo(1.0)
S.poll(10, 120, function() return charTab("identity") end)
S.step(120, function()
    local c, w = CW(), WW()
    W.h = c:getHeight()
    c:setX(902); c:setY(0)
    w:setX(c:getX() + c:getWidth() + ZeD.T.px(8)); w:setY(0)
    c:setHeight(math.floor(core:getScreenHeight() * 0.86))
end)
S.step(90, function()
    local c, w = CW(), WW()
    c:setX(902); w:setX(c:getX() + c:getWidth() + ZeD.T.px(8))
    if ST.parkMouse then ST.parkMouse() end
end)
S.step(30, function() S.shot("story_00a_identity_tall"); box("identity") end)
S.step(2, function() local c = CW(); if c._identityScroll then c._identityScroll:setScrollPos(1.0) end end)
S.step(60, function() S.shot("story_00c_identity_traits"); box("traits") end)
S.step(2, function()
    local c = CW()
    if c._identityScroll then c._identityScroll:setScrollPos(0) end
    if W.h then c:setHeight(W.h) end
    charTab("loot")
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(pn) end
    p:setZombieKills(W.kills)
    p:getModData()["Fav:Crowbar"] = W.fav
    say("put back: kills " .. p:getZombieKills())
end)
S.start()
