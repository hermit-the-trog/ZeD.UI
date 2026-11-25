-- ZeDUI/tools/qa/menu_container_icon_sim.lua  (Nov 24 2026, Build; QA rt_menus: "no icon: Corpse (id corpse)")
-- Since the game's loot page follows the World window's container on show (syncLootPage), Move to's loot row is
-- named after that container (a body, a trunk, a crate) and found no icon by its name. Now:
--   ICON   ZeD_WorldWindow.containerIcon (cut from the real file): the strip button's own picture while the window
--          lists the container, else the game's icon for its type, else the game's box; never nil
--   WIRED  ContextMenuRegistry: a row with no icon whose param1 is an ItemContainer, or the game's onPutItems row
--          (param1 the player), gets containerIcon of that container, before the object fallback
-- Run from the repo root:  lua51 ZeDUI/tools/qa/menu_container_icon_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]menu_container_icon_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return "" end
    local s = f:read("*a"); f:close()
    return (s:gsub("\r\n", "\n"))
end
local function cut(src, from, to)
    local a = string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    return b and string.sub(src, a, b + #to - 1) .. "\n" or nil
end
local function has(s, x) return string.find(s, x, 1, true) ~= nil end

local WW = readFile(Z .. "ZeD_WorldWindow.lua")
local CR = readFile(Z .. "ContextMenuRegistry.lua")

print("-- ICON")
local BOX, CRATE_TEX, BODY_TEX = { n = "box" }, { n = "crate" }, { n = "body" }
ZeD = { genericContainerTex = function() return BOX end }
local icons = { crate = CRATE_TEX }
local function resolveContainerIcon(t) return icons[t] end
local wins = {}
ZeD_WorldWindow = {}
local src = cut(WW, "function ZeD_WorldWindow.containerIcon(inv, pn)", "\nend\n")
check("ICON: found", src ~= nil)
if src then
    local fn, e = loadstring("local _worldWins, resolveContainerIcon = ...\n" .. src, "containerIcon")
    check("ICON: loads", fn ~= nil, e)
    if fn then
        fn(wins, resolveContainerIcon)
        local function inv(t) return { getType = function() return t end } end
        local body, crate, odd = inv("corpse_male"), inv("crate"), inv("someModBox")
        wins[0] = { _containers = { { inventory = body, texture = BODY_TEX } } }
        check("ICON: a listed container: its strip button's picture (the body)", ZeD_WorldWindow.containerIcon(body, 0) == BODY_TEX)
        check("ICON: not listed: the game's icon for its type", ZeD_WorldWindow.containerIcon(crate, 0) == CRATE_TEX)
        check("ICON: an unknown kind: the game's box, never nil", ZeD_WorldWindow.containerIcon(odd, 0) == BOX)
        wins[0] = nil
        check("ICON: window shut: by type", ZeD_WorldWindow.containerIcon(crate, 0) == CRATE_TEX)
        check("ICON: no container: the box", ZeD_WorldWindow.containerIcon(nil, 0) == BOX)
    end
end

print("-- WIRED")
local a = string.find(CR, "QA rt_menus, Nov 24 2026", 1, true)
local b = string.find(CR, "def.iconTexture = objectIconOf(option)", 1, true)
check("WIRED: the container fallback comes before the object fallback", a ~= nil and b ~= nil and a < b)
check("WIRED: param1 an ItemContainer", has(CR, 'if c and instanceof(c, "ItemContainer") then return c, option.param2 end'))
check("WIRED: the game's onPutItems row reads the loot page", has(CR, "option.onSelect == ISInventoryPaneContextMenu.onPutItems"))
check("WIRED: uses containerIcon", has(CR, "def.iconTexture = ZeD_WorldWindow.containerIcon(inv,"))

print("menu_container_icon_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
