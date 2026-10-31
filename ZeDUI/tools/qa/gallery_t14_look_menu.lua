-- ZeDUI/tools/qa/gallery_t14_look_menu.lua  (Oct 30 2026)
-- The Workshop gallery retake on 0.2.0-t14 (ZeDUI/HANDOFF_gallery_book_20261030.md): run it FIRST in the gallery
-- manifest (after zedqa_prelude.lua), and again after any block whose teardown puts the options back. Nothing in the mod
-- changes: what it does is done at run time and put back by gallery_t14_end.lua.
--   1. no debug artifacts in the pictures (the bridge needs -debug):
--      a. the desk's menu bar without its Debug menu: ZeD.MainMenu.menus wrapped to leave out the "debug" entry (the
--         in-game pause window draws the same bar)
--      b. the position readout in the bottom right: vanilla's WaterMarkUI.render (ISVersionWaterMark.lua) draws
--         "x: , y: , z: ; WxH@fps" and the cheat lines (God mode, Invisible ...) under -debug; the wrap keeps only the
--         version button a player sees without -debug
--      c. vanilla's left-edge column (ISEquippedItem: the Debug and ARF buttons) hidden, as ZeD hides it without -debug
--   2. the default look: Dark, Orange, small text, both windows following the accent, see-through 90, the pointing
--      hand (the options themselves, so every script's reapplyFromOptions lands on it); GAL_LOOK = { "dark", "orange" }
--      for the gallery scripts that set a theme of their own (they used high contrast + teal before t14)
--   3. GAL_STILL: the gallery sequencers (gallery_v3_core.lua, gallery_story_stage.lua) wait until both windows have
--      kept their place, size and drawer width for GAL_STILL frames before every step, so no picture catches a window
--      still widening; GAL_SHAPE() is that shape
-- Safe to run twice (what was there is kept the first time only). grep "ZEDQA g14l".
-- The tag is g14l the first time in a game session, then g14l2, g14l3 ... (a manifest's tags are unique).
GAL_T14 = GAL_T14 or {}
local G = GAL_T14
G.runs = (G.runs or 0) + 1
local TAG = "g14l" .. ((G.runs > 1) and tostring(G.runs) or "")
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
GAL_LOOK = { "dark", "orange" }
GAL_STILL = 20

function GAL_SHAPE()
    local t = {}
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    local ww = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    for _, w in ipairs({ cw or false, ww or false }) do
        if w and w:isVisible() then
            local dp = w._drawerPanel
            t[#t + 1] = string.format("%d,%d,%d,%d,%d,%d", w:getX(), w:getY(), w:getWidth(), w:getHeight(),
                math.floor(w._drawerEffW or 0), dp and dp:getWidth() or 0)
        end
    end
    return table.concat(t, ";")
end

-- 1a. the desk's Debug menu
local MM = ZeD and ZeD.MainMenu
if MM and MM.menus and not G.menus then
    G.menus = MM.menus
    MM.menus = function(...)
        local out = {}
        for _, m in ipairs(G.menus(...)) do if m.key ~= "debug" then out[#out + 1] = m end end
        return out
    end
end
if MM and MM.ctx and MM.ctx.open == "debug" then MM.ctx.open = nil end
say("desk menu bar: Debug left out " .. tostring(G.menus ~= nil))

-- 1b. the readout (in game only: the watermark is made at game start)
if WaterMarkUI and not G.wm then
    G.wm = WaterMarkUI.render
    WaterMarkUI.render = function(self)
        ISPanel.render(self)
        if not self.revButton then return end
        self:setWidth(self.revButton:getWidth())
        self:setX(getCore():getScreenWidth() - 10 - self.width)
        self:setY(getCore():getScreenHeight() - 10 - self.revButton:getHeight())
    end
end
say("position readout and cheat lines off " .. tostring(G.wm ~= nil))

-- 1c. the left-edge column
local col = ISEquippedItem and ISEquippedItem.instance
if col and G.colWas == nil then
    G.colWas = col:getIsVisible() and true or false
    col:setVisible(false)
elseif col then
    col:setVisible(false)
end
say("left-edge column hidden " .. tostring(col ~= nil))

-- 2. the default look, through the options
local opts = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
local function opt(id) return opts and opts:getOption(id) end
local IDS = { baseTheme = 1, accentColor = 2, textSize = 1, charAccent = 10, worldAccent = 10, seeThrough = 2, focusStyle = 1 }
if opts then
    if not G.optWas then
        G.optWas = {}
        for id, _ in pairs(IDS) do local o = opt(id); if o then G.optWas[id] = o:getValue() end end
    end
    for id, v in pairs(IDS) do local o = opt(id); if o then pcall(function() o:setValue(v) end) end end
    pcall(function() ZeD.Settings.reapplyFromOptions() end)
    for _, w in ipairs({ ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow() or false,
                         ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow() or false }) do
        if w then w._accentKey = nil end
    end
    pcall(function() PZAPI.ModOptions:save() end)
end
say("look " .. tostring(ZeD and ZeD.currentBase) .. " " .. tostring(ZeD and ZeD.currentAccent) .. " " .. tostring(ZeD and ZeD.currentSize)
    .. " | GAL_LOOK dark orange, GAL_STILL " .. GAL_STILL)

-- DONE a few ticks later (the runner looks for it after the bridge's own "run #n" line); at the main menu OnFETick runs
local n = 0
local function later()
    n = n + 1
    if n < 10 then return end
        Events.OnFETick.Remove(later)
    say("DONE")
end
Events.OnFETick.Add(later)
