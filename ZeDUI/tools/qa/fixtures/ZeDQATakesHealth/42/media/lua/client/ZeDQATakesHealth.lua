-- ZeDQATakesHealth.lua (Nov 17 2026, QA fixture; DEV ONLY, never staged or uploaded)
-- A stand-in for a mod that takes a whole screen of the game, for zedqa_b8_stepaside.lua. It does what Wounds
-- Overhaul did: the Health page of the game's Character Info window holds this mod's own view, a class that is not
-- the game's ISHealthPanel nor derived from it. ZeD_StepAside's page check (checkPages) should find it, name this mod
-- and hand ZeD's Character info back to the game.
-- The game's ISCharacterInfoWindow:createChildren is wrapped and called through (a kept copy, called first), so
-- ZeD's whole-class check counts it as wrapping and not as a takeover: only the page swap is what ZeD should see.
require "ISUI/ISPanel"
require "XpSystem/ISUI/ISCharacterInfoWindow"

QATakesHealthView = ISPanel:derive("QATakesHealthView")

function QATakesHealthView:render()
    ISPanel.render(self)
    self:drawText("ZeD QA test mod: this mod has taken the Health page.", 12, 12, 1, 1, 1, 1, UIFont.Medium)
end

local function takeHealth(win)
    local old = win and win.healthView
    local tabs = win and win.panel
    if not (old and tabs and tabs.replaceView) then return end
    local view = QATakesHealthView:new(old:getX(), old:getY(), old:getWidth(), old:getHeight())
    view:initialise()
    view:setVisible(old:getIsVisible())
    if tabs:replaceView(old, view) then
        tabs:removeChild(old)
        tabs:addChild(view)
        view.parent = tabs
        if tabs.activeView and tabs.activeView.view == old then tabs.activeView.view = view end
        print("[ZeDQATakesHealth] the Health page now holds QATakesHealthView")
    end
end

local vanillaCreateChildren = ISCharacterInfoWindow.createChildren
function ISCharacterInfoWindow:createChildren()
    vanillaCreateChildren(self)
    takeHealth(self)
end
