-- ZeDUI/tools/qa/b9a_sim.lua  (Nov 8 2026, hotfix 0.3.0-beta9a): three of the director's beta 9 finds that are not
-- the window halves (those are in dual_pin_sim's B9A section; the card's scroll is in card_model_sim's B9A 7), with
-- no game running. Each part loads the REAL file on a stub world:
--   DROP   (fix 2) InventoryRenderer.lua's handleDrop: a closed stack's row dragged to the other window or to the floor
--          carries every thing in the stack; an open stack's rows carry one each; a grid cell is the whole stack; a
--          stack in a Loot column; the Equip slot's drag (no list) and the doll and the belt still take one thing
--   BACK   (fix 5) EquipDoll.lua's takeDrop: a baseball bat released over the doll's Back, over the Back box under the
--          doll, and over the Back row of the list attaches by the game's own attach (ZeD.Belt.attach, which is
--          ISHotbar:attachItem); clothing over a doll slot is still worn; a thing that fits no slot is left alone
--   ICON   (fix 8) ContextMenuRegistry.lua with ContextIcons.lua and ContextPxIcons.lua: "Pin to title bar" and
--          "Unpin from title bar" get ZeD's pin, the drawing the title bar's pin boxes use (they showed "PI" / "UN")
-- Run from the repo root:  lua51 ZeDUI/tools/qa/b9a_sim.lua
-- It prints FAIL lines and a last line "b9a_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]b9a_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"
local SHARED = ROOT .. "42/media/lua/shared/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- a stand-in that answers every field and every call with itself (the parts of the game a file touches at load)
local stub
stub = setmetatable({}, { __index = function() return stub end, __call = function() return stub end })
function require() end
local function fresh()
    ZeD = setmetatable({}, { __index = function() return stub end })
end
local function load(path)
    local fn, err = loadfile(path)
    if not fn then return false, err end
    return pcall(fn)
end

-- ===========================================================================
-- DROP (fix 2)
-- ===========================================================================
do
    fresh()
    ISPanel = { derive = function() return setmetatable({}, { __index = stub }) end }
    local okL, errL = load(CLIENT .. "InventoryRenderer.lua")
    check("DROP: InventoryRenderer.lua loads on the stubs", okL, errL)
    local IR = ZeD.InventoryRenderer
    local handleDrop = okL and rawget(ZeD, "InventoryRenderer") and IR.handleDrop
    if handleDrop then
        -- the world the drop reads
        local moved, dropped, worn, belted
        ZeD.EquipDoll = { takeDrop = function(_, items) if DOLL then worn = items[1]; return true end return false end }
        ZeD.Belt = { takeDrop = function(_, items) if BELT then belted = items[1]; return true end return false end }
        ZeD.Curtain = { dropTarget = function() return nil end }
        ZeD.ContainerGates = { refuses = function() return false end }
        IR.dirtyModels = function() end
        local GRID = false
        IR.isGridKey = function() return GRID end
        getPlayerInventory, getPlayerLoot = function() return nil end, function() return nil end
        getMouseX, getMouseY = function() return 500 end, function() return 500 end
        UIManager = { getUI = function() return { size = function() return 0 end } end }
        ISTimedActionQueue = { add = function(a) moved[#moved + 1] = a.item end }
        ISInventoryTransferUtil = { newInventoryTransferAction = function(_, item, src, dst) return { item = item, src = src, dst = dst } end }
        ISInventoryPaneContextMenu = { dropItem = function(item) dropped[#dropped + 1] = item end }
        local function container(kind)
            return setmetatable({ kind = kind }, { __index = function(t, k)
                if k == "getType" then return function() return t.kind end end
                if k == "isItemAllowed" then return function() return true end end
                return function() return nil end
            end })
        end
        local crate, bag = container("crate"), container("none")
        local function thing(name, inv)
            return { name = name, getContainer = function() return inv end, isFavorite = function() return false end,
                getFullType = function() return "Base." .. name end }
        end
        local player = { getPlayerNum = function() return 0 end, getInventory = function() return bag end }
        local function list(inv, over)
            local c = { _inventory = inv, _playerObj = player, _stacks = {}, _expandedStacks = {} }
            c.getMouseX = function() return 10 end
            c.getMouseY = function() return 10 end
            c.hitZoneAt = function() return nil end
            c.isMouseOver = function() return over end
            c.getAbsoluteX = function() return 0 end
            return c
        end
        -- the World window's crate: six nails (one closed stack), two apples (an open stack), a hammer
        local nails, apples = {}, {}
        for i = 1, 6 do nails[i] = thing("Nails", crate) end
        for i = 1, 2 do apples[i] = thing("Apple", crate) end
        local hammer = thing("Hammer", crate)
        local src = list(crate, false)
        src._stacks[nails[1]] = { rep = nails[1], items = nails, count = 6, key = "Base.Nails" }
        src._stacks[apples[1]] = { rep = apples[1], items = apples, count = 2, key = "Base.Apple" }
        src._stacks[hammer] = { rep = hammer, items = { hammer }, count = 1, key = "Base.Hammer" }
        src._expandedStacks["Base.Apple"] = true
        local dst = list(bag, true)
        local overDst = true
        dst.isMouseOver = function() return overDst end
        -- (both windows open, neither title bar under the pointer: a release away from the lists is the floor)
        local cwin = { _contentPanel = dst, getIsVisible = function() return false end }
        local wwin = { _contentPanel = src, getIsVisible = function() return false end }
        ZeD_CharacterWindow = { getWindow = function() return cwin end }
        ZeD_WorldWindow = { getWindow = function() return wwin end }
        local function drop(rows, opts)
            opts = opts or {}
            moved, dropped, worn, belted = {}, {}, nil, nil
            src._dragSourceInv = crate
            if opts.noList then src._dragSourceInv = nil end
            src._dragSourceCol = opts.col
            overDst = not opts.floor
            handleDrop(src, rows, crate)
            return moved, dropped
        end
        local m = drop({ nails[1] })
        check("DROP 2: a closed stack's row to the other window moves all six", #m == 6, #m)
        local _, d = drop({ nails[1] }, { floor = true })
        check("DROP 2: a closed stack's row to the floor drops all six", #d == 6, #d)
        m = drop({ apples[1] })
        check("DROP 2: an open stack's header row moves only its own thing", #m == 1 and m[1] == apples[1], #m)
        m = drop({ apples[2] })
        check("DROP 2: an open stack's other row moves only its own thing", #m == 1 and m[1] == apples[2], #m)
        m = drop({ nails[1], hammer })
        check("DROP 2: a selection of a closed stack and a single thing moves seven", #m == 7, #m)
        GRID = true
        m = drop({ apples[1] })
        check("DROP 2: in the grid (no open stacks) a cell moves its whole stack", #m == 2, #m)
        GRID = false
        -- a Loot column: its own stacks and open stacks
        src._colStates = { { stacks = { [nails[1]] = src._stacks[nails[1]] }, expandedStacks = {}, inventory = crate, renderX = 0, renderW = 100 } }
        m = drop({ nails[1] }, { col = 1 })
        check("DROP 2: a closed stack in a Loot column moves all six", #m == 6, #m)
        src._colStates[1].expandedStacks["Base.Nails"] = true
        m = drop({ nails[1] }, { col = 1 })
        check("DROP 2: ... opened in that column, its row moves one", #m == 1, #m)
        src._colStates = nil
        -- no list behind the drag (an Equip slot's): one thing, as given
        m = drop({ nails[1] }, { noList = true })
        check("DROP 2: an Equip slot's drag (no list) moves the one thing", #m == 1, #m)
        -- the doll and the belt still take one thing
        DOLL = true; drop({ nails[1] }); DOLL = nil
        check("DROP 2: the doll still takes the one thing", worn == nails[1])
        BELT = true; drop({ nails[1] }); BELT = nil
        check("DROP 2: the belt still takes the one thing", belted == nails[1])
        check("DROP 2: dragItems is published for the windows and add-ons", type(IR.dragItems) == "function")
    end
end

-- ===========================================================================
-- BACK (fix 5)
-- ===========================================================================
do
    fresh()
    ISPanel = { new = function() return setmetatable({}, { __index = stub }) end, derive = function() return setmetatable({}, { __index = stub }) end }
    local okL, errL = load(CLIENT .. "EquipDoll.lua")
    check("BACK: EquipDoll.lua loads on the stubs", okL, errL)
    local D = okL and rawget(ZeD, "EquipDoll")
    if D and D.takeDrop then
        local attached, wornItem
        ZeD.Belt = {
            slots = function() return { { i = 1, slot = { slotType = "Back" } }, { i = 2, slot = { slotType = "SmallBeltLeft" } } } end,
            attach = function(_, item, i)
                if not item.attach then return false end   -- (the game's canBeAttached: a thing with no attachment type never fits)
                attached = { item = item, i = i }
                return true
            end,
        }
        ISInventoryPaneContextMenu = { wearItem = function(item) wornItem = item end }
        getSpecificPlayer = function() return { isEquippedClothing = function() return false end } end
        local MX, MY = 0, 0
        local panel = { getMouseX = function() return MX end, getMouseY = function() return MY end,
            isVisible = function() return true end, getWidth = function() return 480 end, getHeight = function() return 600 end }
        local win = { _drawerMode = "tab", _activeTab = "equip", _drawerEffW = 480 }
        ZeD_CharacterWindow = { getWindow = function() return win end }
        local bat = { name = "BaseballBat", attach = "BigWeapon", IsClothing = function() return false end,
            canBeEquipped = function() return "" end, getBodyLocation = function() return nil end }
        local apple = { name = "Apple", IsClothing = function() return false end, canBeEquipped = function() return "" end }
        local backpack = { name = "Bag_Schoolbag", IsClothing = function() return false end, IsInventoryContainer = function() return true end,
            getBodyLocation = function() return "Back" end }
        -- the doll: its Back slot (top right in the split), an empty Back box under the doll, a filled belt box
        local function doll()
            win._equipDollShown, win._equipDollPanel, win._equipPanel = true, panel, panel
            win._equipDollClip = { x = 0, y = 0, w = 480, h = 600 }
            win._equipDollAll = { { x = 330, y = 16, w = 50, h = 50, id = "back" } }
            win._equipBeltZones = { { x = 200, y = 520, w = 30, h = 30, i = 1, action = "attach" } }
            win._equipSlotZones = { { x = 240, y = 520, w = 30, h = 30, type = "doll:belt2", item = {} } }
        end
        local function listView()
            win._equipDollShown, win._equipDollPanel, win._equipPanel = false, nil, panel
            win._equipDollAll, win._equipDollClip = nil, nil
            win._equipBeltZones = { { x = 0, y = 300, w = 480, h = 34, i = 1, action = "attach" } }
            win._equipSlotZones = {}
        end
        local function dropAt(x, y, item)
            MX, MY, attached, wornItem = x, y, nil, nil
            return D.takeDrop(0, { item })
        end
        doll()
        local took = dropAt(350, 30, bat)
        check("BACK 5: a bat on the doll's Back slot is attached to the hotbar's Back", took and attached and attached.i == 1 and attached.item == bat,
            attached and attached.i)
        took = dropAt(210, 530, bat)
        check("BACK 5: a bat on the empty Back box under the doll is attached there", took and attached and attached.i == 1)
        took = dropAt(250, 530, bat)
        check("BACK 5: a bat on a filled belt box goes to that slot (the game swaps the old one off)", took and attached and attached.i == 2)
        took = dropAt(350, 30, backpack)
        check("BACK 5: a backpack on the doll's Back is still worn", took and wornItem == backpack and not attached)
        took = dropAt(350, 30, apple)
        check("BACK 5: an apple on the Back is left alone (nothing taken)", not took and not attached and not wornItem)
        listView()
        took = dropAt(100, 310, bat)
        check("BACK 5: list view: a bat on the Back row of the belt is attached there", took and attached and attached.i == 1)
        took = dropAt(100, 100, bat)
        check("BACK 5: list view: elsewhere on the tab nothing is taken", not took and not attached)
        win._activeTab = "health"
        took = dropAt(100, 310, bat)
        check("BACK 5: another tab open: the Equip tab takes nothing", not took)
        win._activeTab = "equip"
    end
end

-- ===========================================================================
-- ICON (fix 8)
-- ===========================================================================
do
    fresh()
    local WORDS = { UI_ZeD_Pin_Pin = "Pin to title bar", UI_ZeD_Pin_Unpin = "Unpin from title bar" }
    getText = function(k) return WORDS[k] or k end
    getTexture = function() return nil end
    getItemNameFromFullType = function(k) return k end
    ISContextMenu = setmetatable({}, { __index = stub })
    local okI, errI = load(SHARED .. "ContextIcons.lua")
    local okP, errP = load(SHARED .. "ContextPxIcons.lua")
    check("ICON: the icon tables load", okI and okP, tostring(errI) .. " " .. tostring(errP))
    ZeD.PxIcon = { has = function(id) return id ~= nil end, tex = function(id) return "tex:" .. tostring(id), id end }
    -- (the file wraps the game's menu classes at load: any game global it reads is a stand-in meanwhile)
    setmetatable(_G, { __index = function() return stub end })
    local okR, errR = load(CLIENT .. "ContextMenuRegistry.lua")
    setmetatable(_G, nil)
    check("ICON: ContextMenuRegistry.lua loads on the stubs", okR, errR)
    local R = okR and rawget(ZeD, "ContextMenu") and ZeD.ContextMenu.Registry
    if R and R.resolveIconForName then
        local _, idPin = R.resolveIconForName("Pin to title bar")
        local _, idUnpin = R.resolveIconForName("Unpin from title bar")
        check("ICON 8: Pin to title bar has ZeD's pin icon", idPin == "pin", idPin)
        check("ICON 8: Unpin from title bar has ZeD's pin icon", idUnpin == "pin", idUnpin)
    end
end

print("b9a_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
