-- ZeDUI/tools/qa/zedqa_seat_outlines.lua  (Oct 15 2026)
-- Captures vanilla's seat-chooser car drawings (media/ui/vehicles/seatui/
-- <shape>base_small.png, packed, 263 x 600 canvases: white lines over a black fill) at 1.75x on a
-- flat panel, once on black and once on white, so ZeDUI/tools/seats/
-- bake_car_outlines.py can recover each pixel's alpha and brightness and keep
-- the lines alone (the black fill drops out). Prints each
-- shape's drawn rect: "ZEDQA so <prefix> x y w h". Run in game (a 1080p
-- window): copy to Zomboid/Lua/zedqa.lua, bump zedqa.go.

local function say(s) print("ZEDQA so " .. tostring(s)) end
local list, seen = {}, {}
for _, v in pairs(ISCarMechanicsOverlay.CarList or {}) do
    local p = v.imgPrefix
    if p and not seen[p] then
        seen[p] = true
        local t = getTexture("media/ui/vehicles/seatui/" .. p .. "base_small.png")
        if t then list[#list + 1] = { p = p, t = t } end
    end
end
table.sort(list, function(a, b) return a.p < b.p end)
say("shapes " .. #list)
local K, PER = 1.75, 4
local batches = {}
for i, e in ipairs(list) do
    local b = math.floor((i - 1) / PER) + 1
    batches[b] = batches[b] or {}
    table.insert(batches[b], e)
end
local panel = ISPanel:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight())
panel:initialise()
panel.batch = nil
panel.bg = 0
function panel:prerender()
    self:drawRect(0, 0, self.width, self.height, 1, self.bg, self.bg, self.bg)
    local x = 20
    for _, e in ipairs(self.batch or {}) do
        local w, h = e.t:getWidthOrig() * K, e.t:getHeightOrig() * K
        -- vanilla's own call: the packed drawing is trimmed, and only this one puts it back at
        -- its offset inside the 263 x 600 canvas (an aspect fit centres the trimmed part)
        self:drawTextureScaledUniform(e.t, x, 15, K, 1, 1, 1, 1)
        e.rect = { x = x, y = 15, w = w, h = h }
        x = x + w + 40
    end
end
function panel:render() end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local el = ui:get(i); if el:getClass():getSimpleName() == "UIDebugConsole" then el:setVisible(false) end end
    panel:addToUIManager(); panel:setAlwaysOnTop(true)
end)
for b, batch in ipairs(batches) do
    local t0 = 10 + (b - 1) * 40
    at(t0, function() panel.batch = batch; panel.bg = 0 end)
    at(t0 + 12, function()
        for _, e in ipairs(batch) do say(string.format("%s %d %d %d %d %d", e.p, b, e.rect.x, e.rect.y, e.rect.w, e.rect.h)) end
        getCore():TakeFullScreenshot("zqa_so_" .. b .. "_black.png")
    end)
    at(t0 + 20, function() panel.bg = 1 end)
    at(t0 + 32, function() getCore():TakeFullScreenshot("zqa_so_" .. b .. "_white.png") end)
end
at(20 + #batches * 40, function() panel:removeFromUIManager(); say("DONE") end)
local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. tostring(e)) end end end
    if tick > 40 + #batches * 40 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
