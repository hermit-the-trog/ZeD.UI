-- New game menu fixes (QA menus sweep, Nov 27 2026: NG34, NG50, NG51, NG39, NG12, NG30, NG23, NG62, NG4, NG61).
-- Each check cuts the real function out of its file and runs it over stubs; NG34 also runs the game's own
-- SandboxOptionsScreen:onTickBoxSelected and ISTickBox's arg table, so a rename in the game shows up here.
-- Set PZ_LUA to the game's media/lua folder if it is not at E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua.
local PZ = os.getenv("PZ_LUA") or "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua"
local ROOT = (debug.getinfo(1, "S").source:sub(2):gsub("\\", "/"):match("^(.*)/ZeDUI/tools/qa/") or ".") .. "/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function read(path)
    local f = io.open(path, "rb"); if not f then return nil end
    local s = f:read("*a"); f:close(); return s
end
local function cut(src, pat, name)
    local body = src and src:match(pat)
    check(name .. " found", body ~= nil)
    return body or ""
end
local Z = ROOT .. "42/media/lua/client/ZeD/"

-- ---------------------------------------------------------------------------------------------- NG34
do
    local opt = read(Z .. "ZeD_MainMenuOptions.lua")
    local chunk = cut(opt, "(local function tickDisabled.-\nend%s+local function setTick.-\nend%s)", "OPT setTick")
    local f = assert(loadstring(chunk .. "\nreturn setTick", "@setTick"))
    local setTick = f()
    -- the game's tick handler, from the game's file
    local so = read(PZ .. "/client/OptionScreens/SandboxOptions.lua")
    check("the game's SandboxOptions.lua is there", so ~= nil)
    local h = cut(so, "(function SandboxOptionsScreen:onTickBoxSelected.-\nend%s)", "SO onTickBoxSelected")
    SandboxOptionsScreen = {}
    assert(loadstring(h, "@onTickBoxSelected"))()
    local hours = "12.0"
    local scr = { controls = { ["ZombieConfig.RedistributeHours"] = { setText = function(_, t) hours = t end } } }
    -- B42's ISTickBox: the args in changeOptionArgs (checked against the game's file)
    local tb = read(PZ .. "/client/ISUI/ISTickBox.lua") or ""
    check("B42 ISTickBox keeps its args in changeOptionArgs", tb:find("o.changeOptionArgs = { changeOptionArg1, changeOptionArg2 }", 1, true) ~= nil)
    local c = { selected = { true }, changeOptionMethod = SandboxOptionsScreen.onTickBoxSelected, changeOptionTarget = scr,
                changeOptionArgs = { "ZombieMigrate" } }
    setTick(c, 1, false)
    check("NG34: unticking Zombie Migrate (B42 args) sets Redistribute hours to 0.0", hours == "0.0", hours)
    setTick(c, 1, true)
    check("NG34: ticking it sets 12.0", hours == "12.0", hours)
    -- an older build's fields
    hours = "12.0"
    local old = { selected = { true }, changeOptionMethod = SandboxOptionsScreen.onTickBoxSelected, changeOptionTarget = scr,
                  changeOptionArg1 = "ZombieMigrate" }
    setTick(old, 1, false)
    check("NG34: the older changeOptionArg1 field still works", hours == "0.0", hours)
    -- a disabled tick stays as it is
    hours = "12.0"
    local off = { enable = false, selected = { true }, changeOptionMethod = SandboxOptionsScreen.onTickBoxSelected, changeOptionTarget = scr, changeOptionArgs = { "ZombieMigrate" } }
    setTick(off, 1, false)
    check("NG34: a disabled tick box runs nothing", hours == "12.0" and off.selected[1] == true)
end

-- ---------------------------------------------------------------------------------------------- NG51
local trs = read(Z .. "ZeD_MainMenuTraits.lua")
do
    local setC = cut(trs, "(local SAFE_ANSWER = .-\nfunction ZeD_MMTraits:setConfirm.-\nend%s)", "TR setConfirm")
    local save = cut(trs, "(function ZeD_MMTraits:saveBuild.-\nend%s)", "TR saveBuild")
    ZeD_MMTraits = {}
    local writes = {}
    local P = { savedBuilds = { options = { "Chef", "Chef 1", "Mine" }, selected = 0 } }
    function P:presetExists(t) for _, o in ipairs(self.savedBuilds.options) do if o == t then return true end end return false end
    function P:saveBuildValidate(t) return t ~= "" and not t:find("[/\\:;\"]") end
    function P:getSelectedProf() return { getUIName = function() return "Chef" end } end
    function P:saveBuildStep2(btn) writes[#writes + 1] = btn.parent.entry:getText() end
    prof = function() return P end
    MM = { ctx = {}, clickSound = function() end }
    ZeD = {}
    assert(loadstring(setC .. save, "@builds"))()
    local fieldText = ""
    local field = { setText = function(_, t) fieldText = t end, getText = function() return fieldText end,
                    setVisible = function() end, focus = function() end, isFocused = function() return false end, unfocus = function() end }
    local w = setmetatable({ field = field, confirm = false }, { __index = ZeD_MMTraits })
    w:setConfirm("save")
    check("NG51: the offered name is numbered past existing builds (Chef 2)", fieldText == "Chef 2", fieldText)
    P.savedBuilds.options = { "Mine" }
    w:setConfirm(false); w:setConfirm("save")
    check("NG51: a free occupation name is offered as it is", fieldText == "Chef", fieldText)
    fieldText = "Mine"
    w:saveBuild()
    check("NG51: saving over an existing build asks first", w.confirm == "replace" and #writes == 0, tostring(w.confirm) .. " " .. #writes)
    check("NG51: the question lands on Cancel", w.focusId == "confirm:no", w.focusId)
    w:saveBuild(true)
    check("NG51: Replace writes the build", #writes == 1 and writes[1] == "Mine" and w.confirm == false)
    fieldText = "Fresh"
    w:setConfirm("save"); fieldText = "Fresh"
    w:saveBuild()
    check("NG51: a new name saves at once", #writes == 2 and writes[2] == "Fresh" and w.confirm == false)
    -- the band has the question and its words
    check("NG51: the band draws the replace question", trs:find('self.confirm == "replace"', 1, true) ~= nil and trs:find("UI_ZeD_Traits_AskReplace", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------------------------- NG50
do
    local memo = cut(trs, "(local helpMemo, helpMemoN = .-\nend%s)", "TR helpLines")
    local summ = cut(trs, "(local function profSummary.-\nend%s)", "TR profSummary")
    local hh = cut(trs, "(function ZeD_MMTraits:helpHeight.-\nend%s)", "TR helpHeight")
    UI = { plain = function(s) return s end }
    ZeD = { T = { fontF2 = "f2", px = function(n) return n end },
            Atoms = { wrapText = function(s) return { s } end } }   -- (a line per fact here)
    MM = { fontH = function() return 18 end }
    local P = { listboxProf = { selected = 1, items = { { text = "Chef", tooltip = "a\nb\nc\nd\ne" } } } }
    prof = function() return P end
    getText = function(k) return k end
    ZeD_MMTraits = {}
    assert(loadstring(memo .. summ .. hh, "@help"))()
    local cols = { { { help = "a\nb\nc\nd\ne" } }, { { help = "x\ny\nz\nw\nv\nu\nt" } }, {} }
    local h = ZeD_MMTraits.helpHeight({}, cols, 500, 0)
    check("NG50: the band fits the longest description (7 lines)", h == 7 + 7 * 20 + 4, h)
    local h2 = ZeD_MMTraits.helpHeight({}, { {}, {}, {} }, 500, 0)
    check("NG50: the occupation line counts too (name plus 5 facts)", h2 == 7 + 5 * 20 + 4, h2)
    check("NG50: prerender sizes the band with helpHeight", trs:find("self:helpHeight(cols", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------------------------- NG39, NG30
local sbs = read(Z .. "ZeD_MainMenuSandbox.lua")
do
    local sp = cut(sbs, "(function ZeD_MMSandbox:savePreset.-\nend%s)", "SB savePreset")
    ZeD_MMSandbox = {}
    local S = { presetList = { selected = 1 }, changed = 0 }
    function S:settingsFromUI() end
    function S:loadPresets()
        self.presets = { { name = "Apocalypse", userDefined = false }, { name = "Outbreak", userDefined = false },
                         { name = "Apocalypse", userDefined = true } }
    end
    function S:onPresetChange() self.changed = self.changed + 1 end
    sand = function() return S end
    SandboxOptions = { isValidPresetName = function(n) return n ~= "" end,
                       new = function() return { savePresetFile = function() end } end }
    MM = { clickSound = function() end }
    assert(loadstring(sp, "@savePreset"))()
    local w = setmetatable({ field = { getText = function() return "Apocalypse" end } },
        { __index = { setConfirm = function() end, refreshDiff = function() end } })
    ZeD_MMSandbox.savePreset(w)
    check("NG39: a preset saved as Apocalypse reloads as the saved file, not the built-in", S.presetList.selected == 3, S.presetList.selected)
    -- NG30: the debug label is the game's
    local rf = cut(sbs, "(function ZeD_MMSandbox:rowsFor.-\nend%s)", "SB rowsFor")
    local S2 = { controls = { WaterShutModifier = {}, WaterShut = {} } }
    sand = function() return S2 end
    getDebug = function() return true end
    getText = function(k) return "<" .. k .. ">" end
    assert(loadstring(rf, "@rowsFor"))()
    local rows = ZeD_MMSandbox.rowsFor({}, { raw = 1, page = { settings = {
        { name = "WaterShut", type = "enum", translatedName = "Water Shutoff" },
        { name = "WaterShutModifier", type = "entry", translatedName = "Water Shutoff" } } } })
    check("NG30: the debug row reads as the game's debug label", rows[2] and rows[2].label == "<IGUI_DebugContext_Title> <Sandbox_WaterShutModifier>", rows[2] and rows[2].label)
    check("NG30: the plain row keeps its name", rows[1] and rows[1].label == "Water Shutoff")
end

-- ---------------------------------------------------------------------------------------------- NG12
do
    local ui = read(ROOT .. "42/media/lua/shared/Translate/EN/UI.json") or ""
    local v = ui:match('"UI_ZeD_MMHelp_WorldNext": "([^"]*)"')
    check("NG12: the World Next help names the next step", v and v:find("spawn location", 1, true) and not v:find("start the new game", 1, true), v)
    check("NG51: the replace words are in UI.json", ui:find('"UI_ZeD_Traits_AskReplace": "Replace the build %1?"', 1, true) ~= nil and ui:find('"UI_ZeD_Traits_Replace": "Replace"', 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------------------------- NG23, NG62
do
    -- an element with the game's addChild rule: a child added elsewhere leaves its old parent first
    local function el(name)
        local e = { name = name, kids = {} }
        function e:addChild(c)
            if c.parent and c.parent ~= self then c.parent:removeChild(c) end
            for i, k in ipairs(self.kids) do if k == c then table.remove(self.kids, i) break end end
            self.kids[#self.kids + 1] = c; c.parent = self
        end
        function e:removeChild(c) for i, k in ipairs(self.kids) do if k == c then table.remove(self.kids, i) break end end end
        return e
    end
    local spn = read(Z .. "ZeD_MainMenuSpawn.lua")
    local show = cut(spn, "(function ZeD_MMSpawn:onShow.-\nend%s)", "SP onShow")
    local rp = cut(spn, "(function ZeD_MMSpawn:returnParts.-\nend%s)", "SP returnParts")
    MapSpawnSelectImage = { __name = "vanilla map" }
    ZeD_MMSpawnMap = { __name = "ZeD map" }
    ZeD_MMSpawn = {}
    local V = el("MapSpawnSelect")
    local recalced = false
    function V:recalculateMapSize() recalced = true end
    local mp = setmetatable({}, MapSpawnSelectImage)
    for k, f in pairs(el("map")) do mp[k] = f end
    V:addChild(mp)
    V.mapPanel = mp
    V.listbox = { selected = 1 }
    vanilla = function() return V end
    assert(loadstring(show .. rp, "@spawn"))()
    local win = el("ZeD spawn")
    win.nameEntry = { setText = function() end, unfocus = function() end }
    win.seedEntry = win.nameEntry
    setmetatable(win, { __index = ZeD_MMSpawn })
    win:onShow()
    check("NG23: Spawn takes the game's map in", mp.parent == win and getmetatable(mp) == ZeD_MMSpawnMap and #V.kids == 0)
    win:returnParts()
    check("NG23: returnParts puts the map back in the game's screen", mp.parent == V and #win.kids == 0 and #V.kids == 1, mp.parent and mp.parent.name)
    check("NG23: with its own metatable (the game's mouse handlers)", getmetatable(mp) == MapSpawnSelectImage)
    check("NG23: and the game's own place for it", recalced)
    win:onShow()
    check("NG23: shown again, Spawn takes it again", mp.parent == win and getmetatable(mp) == ZeD_MMSpawnMap)

    local lks = read(Z .. "ZeD_MainMenuLooks.lua")
    local block = cut(lks, "(local voiceMusic = false.-\nend%s+local function voicePlaying.-\nend%s)", "LK voice music block")
    local lrp = cut(lks, "(function ZeD_MMLooks:returnParts.-\nend%s)", "LK returnParts")
    ZeD_MMLooks = {}
    local CCM = el("CharacterCreationMain")
    local AP = el("avatar")
    local model = el("model")
    AP.avatarPanel = model
    AP:addChild(model)
    for _, k in ipairs({ "turnLeftButton", "turnRightButton", "animCombo" }) do AP[k] = el(k); AP:addChild(AP[k]) end
    CCM.avatarPanel = AP
    local rescaled = false
    function CCM:rescaleAvatarViewer() rescaled = true end
    local state = "MainMenu"
    local inGame = false
    getSoundManager = function() return { setMusicState = function(_, s) state = s end } end
    ms = function() return { inGame = inGame } end
    looks = function() return CCM end
    -- the game's preview press: InGame
    local playing = true
    CCM.soundRef = 5
    CCM.soundPlayer = { isPlaying = function() return playing end }
    CCM.voiceDemoButton = { internal = "PLAYDEMOVOICE", onclick = function() state = "InGame" end }
    local fns = assert(loadstring(block .. lrp .. "\nreturn wrapVoiceDemo, restoreMenuMusic, voicePlaying", "@looks"))
    local wrap, restore, voicePlaying = fns()
    local lw = setmetatable(el("ZeD looks"), { __index = ZeD_MMLooks })
    lw:addChild(model)
    check("NG62: Looks holds the figure", model.parent == lw and #AP.kids == 3)
    lw:returnParts()
    check("NG62: returnParts puts the figure back in the game's avatar panel", model.parent == AP and #lw.kids == 0)
    check("NG62: under the turn buttons and pose list (drawn first)", AP.kids[1] == model and #AP.kids == 4, AP.kids[1] and AP.kids[1].name)
    check("NG62: and the game's own size for it", rescaled)
    -- NG61
    wrap(CCM)
    CCM.voiceDemoButton.onclick(CCM, CCM.voiceDemoButton)
    check("NG61: the game's preview still sets InGame while it plays", state == "InGame")
    if not voicePlaying(CCM) then restore() end
    check("NG61: still playing: the state is left", state == "InGame")
    playing = false
    if not voicePlaying(CCM) then restore() end
    check("NG61: the preview has played: the menu music state is back", state == "MainMenu", state)
    CCM.voiceDemoButton.onclick(CCM, CCM.voiceDemoButton)
    lw:returnParts()
    check("NG61: leaving Looks mid-preview puts the menu music state back", state == "MainMenu", state)
    inGame = true
    CCM.voiceDemoButton.onclick(CCM, CCM.voiceDemoButton)
    restore()
    check("NG61: in a game (after a death) InGame is left alone", state == "InGame", state)
    check("NG61: prerender checks the preview each frame", lks:find("if voiceMusic and not voicePlaying(looks()) then restoreMenuMusic() end", 1, true) ~= nil)
    -- the hooks that call returnParts
    local mm = read(Z .. "ZeD_MainMenu.lua") or ""
    check("NG23/NG62: leaving a view returns its parts", mm:find("was.returnParts then pcall(was.returnParts, was)", 1, true) ~= nil)
    local omm = read(Z .. "Overrides/MainMenu.lua") or ""
    check("NG23/NG62: safe mode's hand-back returns them", omm:find("win.returnParts then pcall(win.returnParts, win)", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------------------------- NG4
do
    local sv = read(Z .. "ZeD_MainMenuSaves.lua")
    local wh = cut(sv, "(function ZeD_MMNewGame:wheel.-\nend%s)", "SV NewGame wheel")
    ZeD_MMNewGame = {}
    ZeD = { T = { px = function(n) return n end } }
    assert(loadstring(wh, "@wheel"))()
    local w = { bodyScroll = 0 }
    check("NG4: no wheel while the card fits", ZeD_MMNewGame.wheel(w, 1) == false)
    w._body = { max = 100 }
    ZeD_MMNewGame.wheel(w, 1); ZeD_MMNewGame.wheel(w, 1); ZeD_MMNewGame.wheel(w, 1)
    check("NG4: the wheel scrolls the card, stopping at its end", w.bodyScroll == 100, w.bodyScroll)
    ZeD_MMNewGame.wheel(w, -5)
    check("NG4: and back to its top", w.bodyScroll == 0, w.bodyScroll)
    check("NG4: MM.wheel sends the New game view's wheel to it", sv:find('MM.view == "newgame" and MM.root and MM.root.newWin then return MM.root.newWin:wheel(del)', 1, true) ~= nil)
    check("NG4: capped, the card draws its scroll bar", sv:find('MM.scrollBar(self, "newgame:track"', 1, true) ~= nil)
end

print(string.format("%d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
