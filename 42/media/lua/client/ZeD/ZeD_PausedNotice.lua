-- ZeD-UI/42/media/lua/client/ZeD/ZeD_PausedNotice.lua
-- ============================================================================
-- THE PAUSED NOTICE (Nov 15 2026, punch list 242, the director): with the game
-- paused and a window over the middle of the screen (Options, the Survival
-- Guide), the game's own "Game Paused" line in the middle is hidden under it,
-- and the watch and the time buttons are not reassurance enough. A small
-- balloon at the top of the screen says it, in the game's words, over every
-- window. Not big; no tail (it points at nothing); it takes no clicks.
--
-- Shown while: the game is paused (not the pause menu itself, which says so)
-- and something on screen covers its middle point.
-- ============================================================================

require "ISUI/ISUIElement"

ZeD = ZeD or {}
ZeD.PausedNotice = ZeD.PausedNotice or {}
local PN = ZeD.PausedNotice

local TOP_U = 6          -- design units from the screen's top edge

ZeD_PausedNoticeBox = ISUIElement:derive("ZeD_PausedNoticeBox")

-- the game's own words ("- Game Paused -"), without the dashes round them: a balloon is its own frame
local function words()
    local s = getText("IGUI_GamePaused") or ""
    s = s:gsub("^%s*%-+%s*", ""):gsub("%s*%-+%s*$", "")
    return s
end

-- whether a window covers the middle of the screen (the pause menu itself does not count, nor this box)
local function middleCovered(me)
    local ok, covered = pcall(function()
        local cx, cy = math.floor(getCore():getScreenWidth() / 2), math.floor(getCore():getScreenHeight() / 2)
        local menu = MainScreen and MainScreen.instance and MainScreen.instance.javaObject
        local uis = UIManager.getUI()
        for i = 0, uis:size() - 1 do
            local ui = uis:get(i)
            -- (a see-through overlay lets clicks through: not a window)
            local okC, takes = pcall(function() return ui:isConsumeMouseEvents() end)
            if ui ~= me and ui ~= menu and ui:isVisible() and (not okC or takes) then
                local x, y = ui:getAbsoluteX(), ui:getAbsoluteY()
                if cx >= x and cy >= y and cx < x + ui:getWidth() and cy < y + ui:getHeight() then return true end
            end
        end
        return false
    end)
    return ok and covered == true
end

function PN.wanted(me)
    if not (isGamePaused and isGamePaused()) then return false end
    local F = ZeD.Input and ZeD.Input.Focus
    if F and F.pauseMenuUp and F.pauseMenuUp() then return false end
    return middleCovered(me)
end

function ZeD_PausedNoticeBox:new()
    local o = ISUIElement.new(self, 0, 0, 1, 1)
    o.anchorLeft, o.anchorTop = true, true
    o.content = { kind = "plain", title = "" }
    return o
end

-- no clicks: the windows under it keep them
function ZeD_PausedNoticeBox:isMouseOver() return false end
function ZeD_PausedNoticeBox:onMouseDown() return false end
function ZeD_PausedNoticeBox:onMouseUp() return false end
function ZeD_PausedNoticeBox:onMouseMove() return false end

function ZeD_PausedNoticeBox:render()
    local B, T = ZeD.Balloon, ZeD.T
    if not (B and B.layout and B.drawBox and T) then return end
    local s = words()
    if self.content.title ~= s then self.content = { kind = "plain", title = s } end
    local lay = B.layout(self.content)
    local x = math.floor((getCore():getScreenWidth() - lay.w) / 2)
    local y = T.px and T.px(TOP_U) or TOP_U
    if self:getX() ~= x or self:getY() ~= y or self:getWidth() ~= lay.w or self:getHeight() ~= lay.h then
        self:setX(x); self:setY(y); self:setWidth(lay.w); self:setHeight(lay.h)
    end
    B.drawBox(self, self.content, 0, 0, lay)
end

-- one box, made once a game is up; shown and hidden each frame, kept on top of the windows
local box = nil
local function tick()
    if not box then return end
    local want = PN.wanted(box.javaObject)
    if want ~= box:getIsVisible() then box:setVisible(want) end
    if want then box:bringToTop() end
end

local function make()
    if box then return end
    box = ZeD_PausedNoticeBox:new()
    box:initialise()
    box:addToUIManager()
    box:setAlwaysOnTop(true)
    box:setVisible(false)
end

if Events then
    if Events.OnGameStart then Events.OnGameStart.Add(make) end
    if Events.OnRenderTick then Events.OnRenderTick.Add(tick) end
end

return PN
