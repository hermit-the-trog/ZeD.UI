-- ZeDUI/tools/qa/zedqa_b19_tint.lua  (Nov 16 2026, QA): "Item-colored tiles" (74e61b03e, 96945fba9) in game.
-- Checks: the choice is off by default (as found in a fresh ModOptions) and the tile color is nil while off; on,
-- a known item (axe, CD, bat, hammer) gets a color near each theme's lightness rule (Light 0.74, Dark 0.17, High
-- contrast 0.13) and an unknown texture gets none. Pictures: the Character window's inventory and the World window's
-- ground in Grid view, in Dark, Light and High contrast, plain, with a tile selected, and with the pointer on one.
-- Puts back: the choice, the theme, both grid view choices, the given things. grep "ZEDQA b19t".
-- Compare with the mock grid_tint_preview2.png (Build's scratchpad).
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA b19t " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b19t_" .. n .. ".png") end); say("shot zqa_b19t_" .. n) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local IR, G, Se = ZeD.InventoryRenderer, ZeD.GridTint, ZeD.Settings
if not (IR and G and Se and Se.gridTintOption) then say("ERR the tint code is not loaded"); say("DONE"); return end
local baseWas, accentWas, sizeWas = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
local S = { gave = {} }
local function give(full) local x = p:getInventory():AddItem(full); if x then S.gave[#S.gave + 1] = x end; return x end
local function lightness(r, g, b) local mx, mn = math.max(r, g, b), math.min(r, g, b); return (mx + mn) / 2 end

step(10, function()
    S.tintWas = Se.gridTintOption:getValue()
    -- the default as the option was made (the first item is the default)
    local def
    pcall(function() def = Se.gridTintOption.defaultValue or Se.gridTintOption:getDefaultValue() end)
    say("as found: " .. tostring(S.tintWas) .. ", default " .. tostring(def))
    check(S.tintWas == 1 and (def == nil or def == 1), "the choice is off as found (" .. tostring(S.tintWas) .. ")")
    for _, it in ipairs({ "Base.Axe", "Base.Disc_Retail", "Base.BaseballBat", "Base.Hammer", "Base.Apple", "Base.Battery",
                          "Base.Book", "Base.Pan", "Base.WaterBottle", "Base.Bandage", "Base.Screwdriver", "Base.Crowbar" }) do give(it) end
    pcall(function()
        local axe = S.gave[1]
        S.axeTex = axe and axe:getTex()
    end)
    Se.gridTintOption:setValue(1)
    local r = G.of(ZeD.T, S.axeTex)
    check(r == nil, "off: an axe tile has no tint")
    -- the grid views, as found kept
    local store = p:getModData().ZeD_GridViews or {}
    S.gp, S.gf = store["player"], store["type:floor"]
    IR.setGridKey("player", true, p)
    IR.setGridKey("type:floor", true, p)
    if not (ZeD_CharacterWindow.isOpen and ZeD_CharacterWindow.isOpen(pn)) then pcall(ZeD_CharacterWindow.toggleBothPaired, pn) end
end)
step(20, function()
    pcall(function() ZeD_WorldWindow.openTab(pn, "loot") end)
    local cw = ZeD_CharacterWindow.getWindow(pn)
    if cw then cw._activeTab = "inventory" end
end)
step(20, function() shot("off_dark") end)

local cases = { { "dark", 0.17 }, { "light", 0.74 }, { "hicon", 0.13 } }
for _, c in ipairs(cases) do
    local base, L = c[1], c[2]
    step(10, function()
        pcall(ZeD.applyTheme, base, accentWas, sizeWas)
        Se.gridTintOption:setValue(2)
        local r, g, b = G.of(ZeD.T, S.axeTex)
        check(r ~= nil, base .. ": on, the axe tile has a tint")
        if r then
            local l = lightness(r, g, b)
            check(math.abs(l - L) < 0.06, string.format("%s: the axe tile's lightness %.2f near %.2f (r %.2f g %.2f b %.2f)", base, l, L, r, g, b))
        end
        local nr = G.of(ZeD.T, nil)
        check(nr == nil, base .. ": no texture, no tint")
    end)
    step(25, function() shot(base .. "_on") end)
    -- the pointer on a tile: hover the Character window's grid near its first tile
    step(5, function()
        local cw = ZeD_CharacterWindow.getWindow(pn)
        pcall(function()
            local x, y = cw:getAbsoluteX() + math.floor(cw:getWidth() * 0.25), cw:getAbsoluteY() + math.floor(cw:getHeight() * 0.22)
            Mouse.setXY(x, y)
        end)
    end)
    step(20, function() shot(base .. "_hover") end)
    step(5, function() pcall(function() Mouse.setXY(getCore():getScreenWidth() - 4, getCore():getScreenHeight() - 4) end) end)
end

step(10, function()
    Se.gridTintOption:setValue(S.tintWas or 1)
    pcall(ZeD.applyTheme, baseWas, accentWas, sizeWas)
    local store = p:getModData().ZeD_GridViews
    if store then store["player"] = S.gp; store["type:floor"] = S.gf end
    for _, x in ipairs(S.gave) do pcall(function() local c = x:getContainer(); if c then c:DoRemoveItem(x) end end) end
    say("put back: choice " .. tostring(Se.gridTintOption:getValue()) .. ", theme " .. tostring(ZeD.currentBase))
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
