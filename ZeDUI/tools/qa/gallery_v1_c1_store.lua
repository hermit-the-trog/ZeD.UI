-- ZeDUI/tools/qa/gallery_v1_c1_store.lua  (Nov 17 2026, QA): the ZeD-GUI 1.0 gallery's lived-in retake of chapter 11,
-- Sandbox Options in Game, inside the grocery on West Point's main street (gallery_v1_c1_common.lua's "grocery";
-- 11979-11991 x 6909-6926). ZeD on. Same content as zedqa_sandbox_ig.lua's two gallery pictures, same names:
--   zqa_sbx_pause_line   the pause window with Options > ZeD setup > Sandbox on: its Sandbox options line
--   zqa_sbx_world_help   the Sandbox options window on the World page, the help band on World Item Removal List
-- The windows: the pair shut (as today); the pause window and the Sandbox window keep their default sizes and are
-- moved to the left edge (their own place code centres them every frame: the window's build / place is wrapped on
-- the instance for the run, and the wrap taken off after). The Sandbox window is wide (1060 units): the box line says
-- whether it still reaches the character's rect.
-- Puts back: the Sandbox switch, the window wraps, the pause menu shut, the window pair. grep "ZEDQA c1x".
if not C1 then print("ZEDQA c1x ERR run gallery_v1_c1_common.lua first"); print("ZEDQA c1x DONE"); return end
local S = C1.make("c1x")
if not C1.zed then S.say("ERR ZeD is not loaded: this script is for the ZeD run"); S.say("DONE"); return end
S.p, S.pn = C1.p, C1.pn
S.MM = ZeD.MainMenu
S.opt = ZeD.Settings and ZeD.Settings.sandboxInGameOption
S.was = {}
if not (S.opt and S.MM and ZeD_MMSandboxIG) then S.say("ERR the in-game sandbox window is not loaded"); S.say("DONE"); return end

function S.menuUp() return MainScreen and MainScreen.instance and MainScreen.instance:isVisible() end
function S.toggleMenu() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end
function S.hasLine()
    for _, b in ipairs(S.MM.pause and S.MM.pause._specs or {}) do if b.id == "sandbox" then return true end end
    return false
end
-- the pause window and the Sandbox window to the left edge: their place code runs first, then the move
function S.wrap()
    local pw, sw = S.MM.pause, S.MM.pauseSandbox
    if pw and not S.pauseBuild then
        S.pauseBuild = pw.build
        pw.build = function(self) S.pauseBuild(self); self:setX(C1.margin()) end
    end
    if sw and not S.sbPlace then
        S.sbPlace = sw.place
        sw.place = function(self) local w, h = S.sbPlace(self); self:setX(C1.margin()); return w, h end
    end
end
function S.unwrap()
    if S.pauseBuild and S.MM.pause then S.MM.pause.build = nil end
    if S.sbPlace and S.MM.pauseSandbox then S.MM.pauseSandbox.place = nil end
    S.pauseBuild, S.sbPlace = nil, nil
end
function S.page(title)
    local sw = S.MM.pauseSandbox
    for i, pg in ipairs(sw:pages()) do if pg.raw == title or pg.title == title then sw.pageIdx = i; sw.scroll = 0; sw.focusId = nil; return pg end end
    return nil
end

C1.go(S, "grocery")
S.step(10, function()
    S.was.switch = S.opt:getValue()
    S.was.pair = ZeD_CharacterWindow.isOpen()
    C1.grid(true)
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(S.pn) end
    C1.hold, C1.extraBoxes = nil, { { "pause", function() return S.MM.pause end }, { "sandbox", function() return S.MM.pauseSandbox end } }
    pcall(function()
        local w = math.min(ZeD.T.px(1060), C1.core:getScreenWidth() - ZeD.T.px(40))
        local r = C1.charRect()
        S.say(string.format("the Sandbox window will be %d px wide from x %d; the character's rect starts at x %d", w, C1.margin(), r.x0))
    end)
end)
S.mark()
S.step(30, function()
    S.opt:setValue(2)
    S.wrap()
    if not S.menuUp() then S.toggleMenu() end
end)
S.step(40, function()
    S.wrap()
    if S.menuUp() and S.hasLine() then S.shot("zqa_sbx_pause_line") else S.notTaken("zqa_sbx_pause_line", "the pause window or its Sandbox options line is not up") end
end)
S.step(10, function() S.MM.openSandboxIG(); S.wrap() end)
S.step(40, function()
    local sw = S.MM.pauseSandbox
    if not (sw and sw:isVisible()) then S.say("note: the Sandbox window is not open"); return end
    local pg = S.page("World")
    sw.qaHelp = sw.ctls and sw.ctls["WorldItemRemovalList"]
    S.say("page " .. tostring(pg and pg.title) .. ", help on " .. tostring(sw.qaHelp ~= nil))
end)
S.step(30, function()
    local sw = S.MM.pauseSandbox
    if sw and sw:isVisible() then S.shot("zqa_sbx_world_help") else S.notTaken("zqa_sbx_world_help", "the Sandbox window is not open") end
end)

S.mark()
S.step(5, function()
    local sw = S.MM.pauseSandbox
    if sw then sw.qaHelp = nil; pcall(function() sw:finish() end) end
    S.opt:setValue(S.was.switch or 1)
    if S.menuUp() then S.toggleMenu() end
end)
S.step(20, function()
    S.unwrap()
    C1.extraBoxes = nil
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if S.was.pair and not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(S.pn) end
    S.say("put back: the Sandbox switch, the window wraps, the pause menu, the window pair")
end)
S.start()
