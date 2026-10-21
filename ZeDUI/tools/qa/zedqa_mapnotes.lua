-- ZeDUI/tools/qa/zedqa_mapnotes.lua  (Oct 20 2026)
-- In game on the ZeD-QA save: ZeD's map notes in vanilla's own store
-- (MapNotes.lua). Gives a pencil and an eraser, then on the Maps tab:
--   a note through ZeD's text tool and the A press at the cursor lands in
--   vanilla's store (counted through ZeD's store and through the map's own
--   vanilla symbols API, found by its text); a star through ZeD's star tool
--   lands as vanilla's "Star" in pencil;
--   the old modData store is migrated once: a seeded old note and old star
--   are added by the first run, nothing by the second, nothing by a third
--   with the done-flag cleared (the duplicate guard);
--   the note is deleted through ZeD's context menu (Delete at the cursor)
--   and is gone from vanilla's store; the menu offers Share (vanilla's own word)
--   in multiplayer only;
--   a note and a symbol both come off by MapNotes.remove (vanilla's removal; the
--   server-only branches cannot run in single player), and a mark already gone
--   changes nothing;
--   Paper hides the map's own place labels (every label layer's fill alpha is 0),
--   Survey and Color show them, and the note hand (text-note) keeps its fill on
--   all three; the map's style is put back.
-- Everything added is taken back: the marks, the modData, the pencil and eraser.
-- Screenshots zqa_mnote_*.png. grep "ZEDQA mnote".
local p = getPlayer()
local function say(s) print("ZEDQA mnote " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_mnote_" .. n .. ".png") end) end
local function ww() return ZeD_WorldWindow.getWindow() end
local function mp() return ww()._worldMapPanel end
local N = ZeD.MapNotes
local TEXT = "ZEDQA note " .. tostring(ZombRand(100000))
local OLD_TEXT = "ZEDQA old " .. tostring(ZombRand(100000))
local md = p:getModData()
local oldList, oldFlag = md[N.OLD_KEY], md[N.MIGRATED_KEY]   -- put back at the end
local inv = p:getInventory()
local given = {}
local c0, v0, starW, oldW = nil, nil, nil, nil
local added = {}   -- store symbols this script made (removed at the end if still there)

-- user marks through the visible map's own vanilla symbols API (not ZeD's store wrapper)
local function vanillaCount()
    local api = mp().mapAPI:getSymbolsAPIv2()
    local n = 0
    for i = 0, api:getSymbolCount() - 1 do
        if api:getSymbolByIndex(i):isUserDefined() then n = n + 1 end
    end
    return n, api:getSymbolCount()
end
local function vanillaFindText(text)
    local api = mp().mapAPI:getSymbolsAPIv2()
    for i = 0, api:getSymbolCount() - 1 do
        local s = api:getSymbolByIndex(i)
        if s:isUserDefined() and s:isText() and s:getTranslatedText() == text then return s end
    end
    return nil
end
local function storeTextureAt(id, wx, wy)
    local api = N.api()
    for i = 0, api:getSymbolCount() - 1 do
        local s = api:getSymbolByIndex(i)
        if s:isUserDefined() and s:isTexture() and s:getSymbolID() == id
           and math.abs(s:getWorldX() - wx) < 0.5 and math.abs(s:getWorldY() - wy) < 0.5 then return s end
    end
    return nil
end
local function toolZone(id)
    for _, z in ipairs(ww()._mapToolZones or {}) do if z.id == id and not z.isGrid then return z end end
    return nil
end
local function clickTool(id)
    local z = toolZone(id)
    if not z then say("ERR no toolbar button " .. id); return false end
    ZeD.MapsTab.onClick(ww(), z.x + 2, z.y + 2)
    return ww()._mapActiveTool == id
end

at(2, function()
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    -- the drawer's map: a pop-out left open (a Show on map before this script)
    -- takes the map, and a click on the drawer would fold it back instead
    if ww() and ww()._mapPopout then ZeD.MapsTab.closePopout(ww()); say("folded back a pop-out left open") end
    ZeD_WorldWindow.openTab(0, "maps")
    if not inv:containsTypeRecurse("Pencil") then given[#given + 1] = inv:AddItem("Base.Pencil") end
    if not inv:containsTypeRecurse("Eraser") then given[#given + 1] = inv:AddItem("Base.Eraser") end
    say("gave " .. #given .. " (pencil / eraser)")
end)

at(60, function()
    local m = mp()
    say("map bound to the world map item: " .. tostring(m and m._zedNotesBound))
    m.mapAPI:centerOn(p:getX(), p:getY()); m:_zoomTo(18)
    c0 = N.count()
    local all
    v0, all = vanillaCount()
    say("before: store marks " .. c0 .. " | vanilla api marks " .. v0 .. " of " .. all .. " symbols (the rest are the map's own labels)")
    say("text tool armed: " .. tostring(clickTool("text")))
    ww()._mapTextEntry:setText(TEXT)
    m:seedGpCursor()
    m._gpCursorX = math.floor(m:getWidth() / 2); m._gpCursorY = math.floor(m:getHeight() / 2)
end)

at(70, function()
    ZeD.MapsTab.gpPlaceAtCursor(ww())   -- the A press on the canvas
    local c1 = N.count()
    local v1 = vanillaCount()
    local s = N.findByText(TEXT)
    local vs = vanillaFindText(TEXT)
    if s then added[#added + 1] = s end
    say("after note: store " .. c0 .. " -> " .. c1 .. " | vanilla api " .. v0 .. " -> " .. v1 .. " | found in store " .. tostring(s ~= nil) .. " | found by vanilla api " .. tostring(vs ~= nil))
    if c1 ~= c0 + 1 or v1 ~= v0 + 1 or not s or not vs then say("ERR the note did not land in vanilla's store once") end
    if vs then say("note ink " .. tostring(N.inkOf(vs)) .. " rgb " .. string.format("%.3f %.3f %.3f", vs:getRed(), vs:getGreen(), vs:getBlue()) .. " scale " .. vs:getScale() .. " layer " .. tostring(vs:getLayerID())) end
    ww()._mapActiveTool = nil
    -- a star a little to the right
    local m = mp()
    say("star tool armed: " .. tostring(clickTool("star")))
    m._gpCursorX = m._gpCursorX + ZeD.T.px(80)
    starW = { x = m.mapAPI:uiToWorldX(m._gpCursorX, m._gpCursorY), y = m.mapAPI:uiToWorldY(m._gpCursorX, m._gpCursorY) }
    ZeD.MapsTab.gpPlaceAtCursor(ww())
    ww()._mapActiveTool = nil
    m._gpCursorX = m._gpCursorX - ZeD.T.px(80)
    local st = storeTextureAt("Star", starW.x, starW.y)
    if st then added[#added + 1] = st end
    say("star as vanilla's Star: " .. tostring(st ~= nil) .. " ink " .. tostring(st and N.inkOf(st)) .. " | store " .. N.count())
    if not st then say("ERR the star did not land in vanilla's store") end
end)

at(100, function() shot("placed") end)

-- the migration: one old note and one old star in the character's old store
at(110, function()
    local before = N.count()
    oldW = { x = p:getX() + 12, y = p:getY() + 12 }
    md[N.OLD_KEY] = {
        { worldX = oldW.x, worldY = oldW.y, iconId = "text", colorIdx = 4, text = OLD_TEXT },
        { worldX = oldW.x + 4, worldY = oldW.y, iconId = "star", colorIdx = 3, text = "" },
    }
    md[N.MIGRATED_KEY] = nil
    local n1 = N.migrate(p)
    local after1 = N.count()
    local n2 = N.migrate(p)
    local after2 = N.count()
    md[N.MIGRATED_KEY] = nil          -- the flag lost: the duplicate guard must still hold
    local n3 = N.migrate(p)
    local after3 = N.count()
    local s = N.findByText(OLD_TEXT)
    local st = storeTextureAt("Star", oldW.x + 4, oldW.y)
    if s then added[#added + 1] = s end
    if st then added[#added + 1] = st end
    say("migration: first run added " .. n1 .. " (" .. before .. " -> " .. after1 .. "), second " .. n2 .. " (" .. after2 .. "), flag cleared " .. n3 .. " (" .. after3 .. ")")
    say("migrated note ink " .. tostring(s and N.inkOf(s)) .. " (want 4) | star ink " .. tostring(st and N.inkOf(st)) .. " (want 3) | done flag " .. tostring(md[N.MIGRATED_KEY]))
    if n1 ~= 2 or after1 ~= before + 2 or n2 ~= 0 or after2 ~= after1 or n3 ~= 0 or after3 ~= after1 then say("ERR the migration did not run exactly once") end
    if md[N.OLD_KEY] == nil or #md[N.OLD_KEY] ~= 2 then say("ERR the old store was not kept as it was") end
end)

-- delete the note through ZeD: X at the cursor opens ZeD's menu, Delete takes it off
at(130, function()
    local hit = ZeD.MapsTab.gpFindAnnotAtCursor(ww())
    say("cursor finds the note: " .. tostring(hit ~= nil and N.textOf(hit.sym) == TEXT))
    ZeD.MapsTab.gpContextMenuAtCursor(ww())
    local ctx = getPlayerContextMenu(0)
    local del = ctx and ctx:getOptionFromName(getText("ContextMenu_Delete"))
    local edit = ctx and ctx:getOptionFromName(getText("IGUI_Map_EditNote"))
    local share = ctx and ctx:getOptionFromName(getText("IGUI_Map_Sharing"))
    say("menu: delete " .. tostring(del ~= nil) .. " | edit note " .. tostring(edit ~= nil) .. " | change colour " .. tostring(ctx and ctx:getOptionFromName(ZeD.tr("UI_ZeD_Map_ChangeColor")) ~= nil)
        .. " | share " .. tostring(share ~= nil) .. " (multiplayer " .. tostring(isClient()) .. ")")
    -- vanilla offers sharing in multiplayer only, and for a mark the player may change
    if (share ~= nil) ~= (isClient() == true) then say("ERR the Share option is " .. (share and "shown" or "missing") .. " but multiplayer is " .. tostring(isClient())) end
    shot("menu")
    local before = N.count()
    local vb = vanillaCount()
    if del and del.onSelect then del.onSelect(del.target) else say("ERR no Delete in the menu") end
    if ctx then ctx:hideAndChildren() end
    local after = N.count()
    local va = vanillaCount()
    say("after delete: store " .. before .. " -> " .. after .. " | vanilla api " .. vb .. " -> " .. va .. " | still found " .. tostring(N.findByText(TEXT) ~= nil) .. " / " .. tostring(vanillaFindText(TEXT) ~= nil))
    if after ~= before - 1 or va ~= vb - 1 or N.findByText(TEXT) or vanillaFindText(TEXT) then say("ERR the note is still in vanilla's store") end
end)

at(150, function() shot("deleted") end)

-- how a mark comes off (vanilla's removeAnnotation, branch for branch): a note and a
-- symbol both come off the list, and a mark that is already gone changes nothing.
-- (The server branches -- a shared symbol asks the server, a shared note still comes off
-- locally -- need a server; single player runs the local branch of each.)
at(152, function()
    local api = N.api()
    local base = N.count()
    local nWx, nWy = p:getX() + 20, p:getY() + 20
    local note = N.addNote("ZEDQA rm note " .. tostring(ZombRand(100000)), nWx, nWy, 1)
    local star = N.addSymbol("Star", nWx + 3, nWy, 1)
    if note then added[#added + 1] = note end
    if star then added[#added + 1] = star end
    say("removal: made a note " .. tostring(note ~= nil) .. " and a star " .. tostring(star ~= nil) .. " | store " .. base .. " -> " .. N.count())
    if not (note and star) or N.count() ~= base + 2 then say("ERR could not make the two marks") return end
    local rn = N.remove(note, api)
    local afterNote = N.count()
    local rs = N.remove(star, api)
    local afterStar = N.count()
    local rn2 = N.remove(note, api)    -- (stale: already gone)
    say("removal: note " .. tostring(rn) .. " (" .. (base + 2) .. " -> " .. afterNote .. "), star " .. tostring(rs) .. " (-> " .. afterStar .. "), stale note again " .. tostring(rn2) .. " (-> " .. N.count() .. ")")
    if rn ~= true or afterNote ~= base + 1 or N.contains(api, note) then say("ERR the note did not come off") end
    if rs ~= true or afterStar ~= base or N.contains(api, star) then say("ERR the symbol did not come off") end
    if rn2 ~= false or N.count() ~= base then say("ERR removing a mark already gone was not a no-op") end
end)

-- Paper hides the map's own place labels (they would double the names the illustration
-- prints); Survey and Color keep them. Read through the style's label layers (the fill
-- stops' alpha); the player's own hand, text-note, keeps its fill on every style.
local styleWas, mdStyleWas, mdPaperWas = nil, nil, nil
local function labelAlpha()
    local style = mp().mapAPI:getStyleAPI()
    local mx, seen = 0, 0
    for _, name in ipairs(ZeD.MapsTab.LABEL_LAYERS) do
        local layer = style:getLayerByName(name)
        if layer then
            seen = seen + 1
            for i = 0, layer:getFillStops() - 1 do mx = math.max(mx, layer:getFillAlpha(i)) end
        end
    end
    local note = style:getLayerByName("text-note")
    local noteMx = 0
    if note then for i = 0, note:getFillStops() - 1 do noteMx = math.max(noteMx, note:getFillAlpha(i)) end end
    return mx, seen, noteMx
end
-- (a map on screen is restyled a few frames after it is asked for, MapsTab
-- requestStyle: the style is set at one tick and read some ticks later)
local function styleSet(id) ZeD.MapsTab.setStyle(ww(), id) end
local function styleCheck(id, wantShown)
    if mp()._styleWanted then say("ERR the restyle to " .. id .. " is still on hold") end
    local mx, seen, noteMx = labelAlpha()
    say("style " .. id .. ": map style " .. tostring(mp().style) .. " | label layers " .. seen .. " | strongest label alpha " .. mx .. " | note hand alpha " .. noteMx)
    if mp().style ~= id then say("ERR the map did not switch to " .. id); return end
    if seen == 0 then say("ERR no label layers found") end
    if wantShown and mx <= 0 then say("ERR " .. id .. " should show the map's labels") end
    if not wantShown and mx > 0 then say("ERR " .. id .. " still shows the map's labels") end
    if noteMx <= 0 then say("ERR " .. id .. " lost the note hand (notes would not draw)") end
end
local hasPaper = false
at(154, function()
    styleWas = mp().style
    mdStyleWas, mdPaperWas = md.ZeD_MapStyle, md.ZeD_MapPaper
    hasPaper = ZeD.MapsTab.hasPaper()
    if hasPaper then styleSet("paper") else say("no paper map in this install: Paper skipped") end
end)
at(164, function() if hasPaper then styleCheck("paper", false) end end)
at(166, function() shot("paper_labels") end)
at(168, function() styleSet("survey") end)
at(178, function() styleCheck("survey", true) end)
at(180, function() styleSet("color") end)
at(190, function() styleCheck("color", true) end)

at(192, function()
    if styleWas and mp().style ~= styleWas then ZeD.MapsTab.setStyle(ww(), styleWas) end
    md.ZeD_MapStyle, md.ZeD_MapPaper = mdStyleWas, mdPaperWas
    say("style back to " .. tostring(mp().style))
end)

at(202, function()
    -- take back everything still there
    local api = N.api()
    local left = 0
    for _, s in ipairs(added) do
        if N.contains(api, s) then N.remove(s, api); left = left + 1 end
    end
    md[N.OLD_KEY] = oldList
    md[N.MIGRATED_KEY] = oldFlag
    for _, it in ipairs(given) do inv:Remove(it) end
    local w = ww()
    w._mapActiveTool = nil; w._mapEdit = nil
    if w._mapTextEntry then w._mapTextEntry:setText(ZeD.tr("UI_ZeD_Map_NoteDefault")) end
    say("cleanup: removed " .. left .. " marks | store " .. N.count() .. " (started " .. tostring(c0) .. ") | modData back")
    if c0 and N.count() ~= c0 then say("ERR the store did not go back to where it started") end
    say("DONE")
end)

local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 207 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
