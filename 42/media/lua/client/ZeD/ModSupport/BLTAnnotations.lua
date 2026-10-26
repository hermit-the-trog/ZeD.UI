-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/BLTAnnotations.lua
-- ============================================================================
-- SUPPORT FOR SHARE ANNOTATIONS (mod id BLTAnnotations, Workshop 2815560151).
-- Mockup zed_map_overlays_v1, approved "as recommended" Oct 26 2026.
--
-- The mod lets a character learn the marks on a map or a paper of notes
-- ("Remember annotations"); each lot it learns is a set, kept in the world's
-- ModData (BLTAnnotations.symsets, with BLTAnnotations.hidden for the sets the
-- player hid). On the game's map it puts a small list of the sets with a tick to
-- show or hide each and an x to delete it (its ShareAnnotations.UI), and it hides
-- the hidden sets again the first time the game's map opens in a session (its
-- ISWorldMap.ShowWorldMap wrapper). ZeD's Maps tab is its own map, so ZeD shows
-- the same list in the map's side list, through the Maps tab's general hook
-- (MapsTabExt.lua):
--   * a Learned notes section: one row per set, in the mod's own name for it,
--     how many places, a tick to show or hide it (the mod's setSymsetVisible) and
--     an x to delete it (the mod's deleteSymset), asked first in the list's footer;
--   * the first map ZeD makes in a session hides the sets the player hid, as the
--     mod's wrapper does (healHidden, hideSymsets), so a set hidden on the game's
--     map before stays hidden and can be shown again here (its row says so).
-- Every change goes through the mod's own functions and its own ModData.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "BLTAnnotations"

local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end

require "ZeD/Tr"
require "ZeD/MapsTab"

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.BLTAnnotations = S

local function Lib()
    local L = BLTAnnotations
    if L and L.getOrCreateModData and L.setSymsetVisible and L.deleteSymset then return L end
    return nil
end

-- the sets hidden when ZeD first applied them this session ("hidden on the game's map before")
S.hiddenBefore = nil

-- the mod's own "hide the hidden sets once a session" (its ShowWorldMap wrapper)
function S.applyHidden()
    if S.hiddenBefore then return end
    local L = Lib()
    if not L then return end
    S.hiddenBefore = {}
    pcall(function()
        L.healHidden()
        local md = L.getOrCreateModData()
        for k, _ in pairs(md.hidden) do S.hiddenBefore[k] = true end
        L.hideSymsets(md.hidden)
    end)
end

local X = { order = 50 }

function X.mapMade(mp, win) S.applyHidden() end

function X.side(win)
    local L = Lib()
    if not L then return nil end
    S.applyHidden()
    local md = L.getOrCreateModData()
    local names = {}
    for k, v in pairs(md.symsets or {}) do
        if type(v) == "table" then names[#names + 1] = k end
    end
    table.sort(names)
    local rows = {}
    for _, name in ipairs(names) do
        local n = #md.symsets[name]
        local shown = not md.hidden[name]
        local sub = (n == 1) and ZeD.tr("UI_ZeD_Map_SetPlace") or ZeD.tr("UI_ZeD_Map_SetPlaces", n)
        if not shown then sub = sub .. " | " .. ZeD.tr("UI_ZeD_Map_SetHidden") end
        rows[#rows + 1] = {
            key = name, title = name, sub = sub, check = shown,
            warn = (not shown and S.hiddenBefore and S.hiddenBefore[name]) and ZeD.tr("UI_ZeD_Map_SetHiddenBefore") or nil,
            onCheck = function(w)
                local ok, err = pcall(L.setSymsetVisible, name, not shown)
                if not ok then print("[ZeD] Share Annotations: " .. tostring(err)) end
                w._mapSideSecT = nil
            end,
            del = { ask = (n == 1) and ZeD.tr("UI_ZeD_Map_SetDeleteAskOne", name) or ZeD.tr("UI_ZeD_Map_SetDeleteAsk", name, n),
                    onYes = function(w)
                        local ok, err = pcall(L.deleteSymset, name)
                        if not ok then print("[ZeD] Share Annotations: " .. tostring(err)) end
                        if w._playerObj then w._playerObj:playSoundLocal("MapRemoveMarking") end
                        w._mapSideSecT = nil
                    end },
        }
    end
    return { key = "notes", title = ZeD.tr("UI_ZeD_Map_LearnedNotes"), count = #rows, rows = rows,
             empty = ZeD.tr("UI_ZeD_Map_NotesEmpty", ZeD.tr("IGUI_BLTRemember_Annotations")) }
end

S.X = X   -- (the QA scripts drive it)
ZeD.MapsTab.addExtension(MOD_ID, X)
