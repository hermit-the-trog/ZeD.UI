-- ZeDUI/tools/qa/zedqa_btn_look.lua  (Nov 5 2026, QA; 53766830, one line on buttons, two on the default): a test board of
-- ZeD.Molecules.drawButton: plain, default (primary), red, red with opts.default, disabled, hovered, pressed, each with the
-- controller's mark in all four styles, in Dark, Light and High contrast. The theme and the style are put back.
-- Pictures zqa_bnl_<theme>_<style>.png. grep "ZEDQA bnl".
local function say(s) print("ZEDQA bnl " .. tostring(s)) end
local M, T0 = ZeD.Molecules, ZeD
local B = ISPanel:derive("ZeDQAButtons")
local ROWS = {
    { "Plain", nil, {} }, { "Default", "primary", {} }, { "Red", "danger", {} }, { "Red default", "danger", { default = true } },
    { "Disabled", nil, { disabled = true } }, { "Hover", nil, { hover = true } },
}
function B:render()
    local T = ZeD.T
    self:drawRect(0, 0, self.width, self.height, 1, T.surf1.r, T.surf1.g, T.surf1.b)
    local w, h, gap = T.px(110), T.buttonH, T.px(12)
    local x0, y = T.px(12), T.px(12)
    for _, r in ipairs(ROWS) do
        M.drawButton(self, x0, y, w, h, r[1], r[2], false, nil, r[3])
        local o = {}
        for k, v in pairs(r[3]) do o[k] = v end
        o.focus = { win = self, pad = true, focused = true }
        M.drawButton(self, x0 + (w + gap), y, w, h, r[1] .. " on", r[2], false, nil, o)
        M.drawButton(self, x0 + (w + gap) * 2, y, w, h, r[1] .. " down", r[2], true, nil, r[3])
        y = y + h + gap
    end
    ZeD.Focus.drawOverlay(self, self)
end
local board = B:new(200, 400, 800, 400)
board:initialise(); board:instantiate(); board:addToUIManager(); board:setVisible(true)
board:bringToTop()
local S = ZeD.Settings
local keepStyle = S.focusStyle
local keepBase = ZeD.currentBase
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_bnl_" .. n .. ".png") end) end
for _, th in ipairs({ "dark", "hicon", "light" }) do
    add(300, function() ZeD.applyTheme(th, nil, nil) end)
    for _, st in ipairs({ "hand", "corners", "wash", "ants" }) do
        add(500, function() S.focusStyle = function() return st end end)
        add(500, function() shot(th .. "_" .. st); say("shot " .. th .. " " .. st) end)
    end
end
add(300, function()
    S.focusStyle = keepStyle
    ZeD.applyTheme(keepBase, nil, nil)
    board:setVisible(false); board:removeFromUIManager()
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); if i > #plan then say("DONE") end end
end
Events.OnTick.Add(drive)
