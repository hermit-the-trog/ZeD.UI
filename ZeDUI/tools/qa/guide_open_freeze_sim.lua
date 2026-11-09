-- ZeDUI/tools/qa/guide_open_freeze_sim.lua  (Nov 8 2026, Build; the beta 10 "guide open freeze" report)
-- The survival guide opened and drawn frame after frame with no game running, every Lua call counted, so a draw that
-- never ends shows here as a FAIL with its place instead of a frozen game.
--   * Loads the real Scale, Tokens, Tr, ZeD_Surface, Atoms, AtomExtensions, Molecules, DrawMemo, Balloon, RichTip,
--     PixelFonts, ZeD_PadGlyphs, ZeD_GuideChapters, ZeD_SurvivalGuide, ZeD_SurvivalGuideBook and ZeD_GuideBubble on
--     stubs of the game: a 3840 x 2160 screen at the 1.75x root scale (4K), the game's own topics from its English
--     SurvivalGuide.json, ZeD's English UI.json.
--   * Opens the guide (the Immersive look, the book) by the three roads QA reported: ZeD.Guide.open(0), the guide
--     bubble's click (ZeD.GuideBubble.open with a live offer, as the Messages balloon calls it) and F1
--     (ZeD.Guide.toggle). Each open and each frame after it runs under an instruction cap (a count hook): past the
--     cap it is a FAIL with the traceback of where it spun.
--   * Draws 120 frames after each open, then every spread of the book, at Small and at Large text.
--   * The screen at 0 x 0, 0 x 2160, 3840 x 0 and 1 x 1 (the game minimized, a resolution change on its way): the
--     book's unit goes to 0 or below there, and the ruled NOTES lines, the contents' dotted leaders and the house
--     ad's coupon dashes step by a multiple of it; every spread must still end.
-- Found with it (Nov 8 2026, main 8b7538e7): no loop in the guide's open or draw fails to end, by any road, at either
-- text size, on any spread or screen size. The "freeze" QA saw was the pause: the open book sets the game speed to 0
-- (as the game's own guide does), the game's OnTick stops while paused, and zedqa_guide_bubble.lua and
-- b10_guide_open_repro.lua ran their steps on OnTick, so they stopped at the open and never reached DONE (the QA
-- bridge, which polls on OnRenderTick, kept answering: frames were still drawn).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/guide_open_freeze_sim.lua   (FREEZE_LIMIT=<instructions> for the cap)
-- It prints FAIL lines, the worst frame's instruction count, and a last line "guide_open_freeze_sim: N checks, M
-- failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]guide_open_freeze_sim%.lua$", "")
local PZ = "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/"
-- (a frame of the open book is about 10 000 to 60 000 instructions here and an open about 1.2 million: the cap is
-- 50 times the open, so only a loop that does not end reaches it)
local LIMIT = tonumber(os.getenv("FREEZE_LIMIT") or "") or 60000000

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function noop() end
local function readFile(path)
    local f = io.open(path, "rb"); if not f then return nil end
    local s = f:read("*a"); f:close(); return s
end
local function readJson(path, into, order)
    local s = readFile(path)
    if not s then return false end
    for line in s:gmatch("[^\n]+") do
        local k, v = line:match('^%s*"([^"]+)"%s*:%s*"(.*)"%s*,?%s*$')
        if k then
            into[k] = (v:gsub('\\"', '"'):gsub("\\n", "\n"):gsub("\\\\", "\\"))
            if order then order[#order + 1] = k end
        end
    end
    return true
end

local FILES = {
    "42/media/lua/shared/ZeD/Scale.lua",
    "42/media/lua/shared/ZeD/Tokens.lua",
    "42/media/lua/shared/ZeD/Tr.lua",
    "42/media/lua/client/ZeD/ZeD_Surface.lua",
    "42/media/lua/client/ZeD/Atoms.lua",
    "42/media/lua/client/ZeD/AtomExtensions.lua",
    "42/media/lua/client/ZeD/Molecules.lua",
    "42/media/lua/client/ZeD/DrawMemo.lua",
    "42/media/lua/client/ZeD/Balloon.lua",
    "42/media/lua/client/ZeD/RichTip.lua",
    "42/media/lua/client/ZeD/PixelFonts.lua",
    "42/media/lua/client/ZeD/ZeD_PadGlyphs.lua",
    "42/media/lua/client/ZeD/ZeD_GuideChapters.lua",
    "42/media/lua/client/ZeD/ZeD_SurvivalGuide.lua",
    "42/media/lua/client/ZeD/ZeD_SurvivalGuideBook.lua",
    "42/media/lua/client/ZeD/ZeD_GuideBubble.lua",
}

-- ---------------------------------------------------------------------------
-- THE WORDS: ZeD's English, the game's English guide (its order makes the sections and topics)
-- ---------------------------------------------------------------------------
local EN, GAME_ORDER = {}, {}
check("ZeD's English UI.json reads", readJson(ROOT .. "42/media/lua/shared/Translate/EN/UI.json", EN))
local haveGame = readJson(PZ .. "lua/shared/Translate/EN/SurvivalGuide.json", EN, GAME_ORDER)
if not haveGame then print("(the game's SurvivalGuide.json is not at " .. PZ .. ": the book has ZeD's chapters only)") end

local function JL(items) return { size = function() return #items end, get = function(_, i) return items[i + 1] end } end
local ENTRIES = {}
for _, k in ipairs(GAME_ORDER) do
    local stem = k:match("^SurvivalGuide_(.+)_title$")
    if stem then
        local cat = EN["SurvivalGuide_" .. stem .. "_category_image"] ~= nil
        local desc = "SurvivalGuide_" .. stem .. "_description"
        local nk = 0
        for _ in (EN[desc] or ""):gmatch("%%%d") do nk = nk + 1 end
        local keys = {}
        for i = 1, nk do keys[i] = "Forward" end
        local e = setmetatable({}, { __tostring = function() return stem end })
        e.getTitle = function() return k end
        e.getSubCategory = function() return (not cat) and "sub" or nil end
        e.getDescription = function() return EN[desc] and desc or nil end
        e.getKeys = function() return JL(keys) end
        e.getJoypadKeys = function() return JL(keys) end
        e.getVideo = function() return "media/videos/" .. stem .. ".bk2" end
        e.getThumbnail = function() return nil end
        ENTRIES[#ENTRIES + 1] = e
    end
end

-- ---------------------------------------------------------------------------
-- THE STUBS
-- ---------------------------------------------------------------------------
local SCREEN = { w = 3840, h = 2160 }
local clock = { ms = 1700000000000 }
local speed = { v = 1 }
local function J(name, methods)
    return setmetatable({ __name = name }, { __index = function(_, k)
        local m = methods[k]
        if m == nil then return function() return nil end end
        if type(m) == "function" then return m end
        return function() return m end
    end, __tostring = function() return name end })
end
-- the engine's TextManager: every letter its own width (6 to 10 px), 16 px lines
local realTM = {
    MeasureStringX = function(_, font, s)
        s = tostring(s)
        local w = 0
        for i = 1, #s do w = w + 6 + (string.byte(s, i) % 5) end
        return w
    end,
    MeasureStringY = function() return 16 end,
    getFontHeight = function() return 16 end,
    getFontFromEnum = function() return nil end,
}
local core = J("Core", {
    getScreenWidth = function() return SCREEN.w end, getScreenHeight = function() return SCREEN.h end,
    getOptionFontSize = 2, getOptionShowSurvivalGuide = true, getOptionDoVideoEffects = false, getGameMode = "Sandbox",
    getKey = 59,
    getGoodHighlitedColor = J("Color", { getR = 0, getG = 1, getB = 0 }),
    getBadHighlitedColor = J("Color", { getR = 1, getG = 0, getB = 0 }),
})
local UIFont = setmetatable({}, { __index = function(t, k)
    local v = setmetatable({ __name = "UIFont." .. k }, { __tostring = function() return "UIFont." .. k end })
    rawset(t, k, v)
    return v
end })
-- the UI classes: a panel keeps its place and size and visibility; draws and the rest of the engine's methods do nothing
local draws = { n = 0 }
local function panelClass(typeName)
    local P = { Type = typeName }
    P.__index = P
    function P:derive(name) local o = { Type = name }; setmetatable(o, self); self.__index = self; o.__index = o; return o end
    function P:new(x, y, w, h) local o = { x = x, y = y, width = w, height = h, _vis = false }; setmetatable(o, self); return o end
    function P:setVisible(v) self._vis = v end
    function P:isReallyVisible() return self._vis == true end
    function P:isVisible() return self._vis == true end
    function P:getMouseX() return 1920 - (self.x or 0) end
    function P:getMouseY() return 1080 - (self.y or 0) end
    function P:getAbsoluteX() return self.x or 0 end
    function P:getAbsoluteY() return self.y or 0 end
    function P:getX() return self.x or 0 end
    function P:getY() return self.y or 0 end
    function P:getWidth() return self.width end
    function P:getHeight() return self.height end
    function P:setX(v) self.x = v end
    function P:setY(v) self.y = v end
    function P:setWidth(v) self.width = v end
    function P:setHeight(v) self.height = v end
    function P:removeFromUIManager() self._vis = false end
    -- (an engine method: lower-case names only, so a missing field of the panel's own reads nil)
    setmetatable(P, { __index = function(_, k)
        if type(k) == "string" and k:match("^%l") then
            if k:sub(1, 4) == "draw" then return function() draws.n = draws.n + 1 end end
            return noop
        end
        return nil
    end })
    return P
end

local env = {}
local base = {
    print = print, require = noop, tostring = tostring, tonumber = tonumber, type = type, pairs = pairs, ipairs = ipairs,
    select = select, unpack = unpack, pcall = pcall, error = error, assert = assert, setmetatable = setmetatable,
    getmetatable = getmetatable, rawget = rawget, rawset = rawset, rawequal = rawequal,
    string = string, table = table, math = math, os = { time = os.time, date = os.date, clock = os.clock },
    loadstring = loadstring, xpcall = xpcall, UIFont = UIFont,
    getTimestampMs = function() return clock.ms end,
    getTimestamp = function() return math.floor(clock.ms / 1000) end,
    getCore = function() return core end,
    getTextManager = function() return realTM end,
    getText = function(k) return EN[k] or k end,
    getTextOrNull = function(k) return EN[k] end,
    getTexture = function() return J("Texture", { getWidth = 32, getHeight = 32, getWidthOrig = 32, getHeightOrig = 32, isReady = true }) end,
    isServer = function() return false end, isClient = function() return false end,
    getDebug = function() return false end, isDebugEnabled = function() return false end,
    getPlayerScreenWidth = function() return SCREEN.w end, getPlayerScreenHeight = function() return SCREEN.h end,
    getPlayerScreenLeft = function() return 0 end, getPlayerScreenTop = function() return 0 end,
    getSpecificPlayer = function() return nil end, getPlayer = function() return nil end,
    Events = setmetatable({}, { __index = function(t, k) local e = { Add = noop, Remove = noop }; rawset(t, k, e); return e end }),
    UIManager = { getMillisSinceLastRender = function() return 16 end, isShowPausedMessage = function() return true end,
                  setShowPausedMessage = noop },
    Keyboard = setmetatable({}, { __index = function() return 0 end }),
    Joypad = setmetatable({}, { __index = function() return 0 end }),
    JoypadState = { players = {} },
    KeybindId = setmetatable({}, { __index = function(_, k) return k end }),
    isKeyDown = function() return false end,
    getMouseX = function() return 1920 end, getMouseY = function() return 1080 end,
    getSoundManager = function() return J("SoundManager", {}) end,
    getGameSpeed = function() return speed.v end, setGameSpeed = function(v) speed.v = v end,
    Translator = { getLanguage = function() return J("Language", { name = "EN", toString = "EN" }) end },
    getFileReader = function() return nil end, getFileWriter = function() return nil end,
    SurvivalGuideEntry = { getAll = function() return JL(ENTRIES) end },
    ZombRand = function() return 0 end, triggerEvent = noop, updateJoypadFocus = noop,
}
for _, n in ipairs({ "ISPanelJoypad", "ISPanel", "ISUIElement", "ISButton", "ISScrollBar", "ISToolTip", "ISRichTextPanel",
                     "ISCollapsableWindow", "ISTextEntryBox" }) do base[n] = panelClass(n) end
-- (Kahlua's string.char takes past 255: Tr.lua's look-alikes)
local str = {}
for k, v in pairs(string) do str[k] = v end
str.char = function(...) local t = { ... }; for i, c in ipairs(t) do if c > 255 then t[i] = 63 end end; return string.char(unpack(t)) end
base.string = str
base._G = env
setmetatable(env, { __index = function(t, k)
    local v = base[k]
    if v ~= nil then return v end
    if type(k) == "string" and (k:sub(1, 4) == "ZeD_" or k:sub(1, 2) == "IS") then
        local c = panelClass(k); rawset(t, k, c); return c
    end
    return nil
end })

for _, path in ipairs(FILES) do
    local src = readFile(ROOT .. path)
    check(path .. " found", src ~= nil)
    if src then
        local fn, err = loadstring(src, "@" .. path)
        check(path .. " compiles", fn ~= nil, err)
        if fn then
            setfenv(fn, env)
            local ok, e = pcall(fn)
            check(path .. " loads", ok, e)
        end
    end
end
local Z = env.ZeD
local logs = {}
Z.logOnce = function(k, e) logs[#logs + 1] = tostring(k) .. ": " .. tostring(e) end
Z.Text._fontsSettled = true
Z.Text.fallback = false
Z.Text.checkRoleFonts = function() return false end
Z.Scale._root = 1.75
Z.Scale.root = function() return 1.75 end
-- the Messages stand-in the bubble asks: its balloon taken down
local dropped = {}
Z.Messages = { dropToast = function(t) dropped[#dropped + 1] = t end, sources = {}, toasts = {} }

-- ---------------------------------------------------------------------------
-- THE CAP
-- ---------------------------------------------------------------------------
local STEP = 1000
local function guarded(name, f)
    local n = 0
    debug.sethook(function()
        n = n + 1
        if n * STEP > LIMIT then
            debug.sethook()
            error("still running after " .. LIMIT .. " instructions in " .. name .. debug.traceback("", 2), 0)
        end
    end, "", STEP)
    local ok, e = pcall(f)
    debug.sethook()
    return ok, e, n * STEP
end

local worst, worstAt = 0, ""
local function frame(bk, name)
    clock.ms = clock.ms + 16
    local ok, e, n = guarded(name, function() bk:prerender(); bk:render() end)
    if n > worst then worst, worstAt = n, name end
    return ok, e
end

local function bookOf() return Z.GuideBook and Z.GuideBook.books and Z.GuideBook.books[0] end
-- (the spreads laid out; a book whose open was stopped by the cap has none)
local function spreadsOf(bk)
    local p = bk and rawget(bk, "pages")
    return type(p) == "table" and math.floor(#p / 2) or 0
end
local function closeAll()
    local bk = bookOf()
    if bk and bk:isReallyVisible() then Z.GuideBook.close(0) end
    speed.v = 1
end

-- open by one road, then 120 frames and every spread; one FAIL per road and text size at most for the frames
local function road(label, open)
    closeAll()
    local ok, e = guarded(label .. ": the open", open)
    check(label .. ": the open returns", ok, e)
    local bk = bookOf()
    check(label .. ": the book is open", bk and bk:isReallyVisible())
    check(label .. ": the game is paused while it is open (as the game's own guide)", speed.v == 0, speed.v)
    if not bk then return end
    for f = 1, 120 do
        local okF, eF = frame(bk, label .. ": frame " .. f)
        if not okF then check(label .. ": frame " .. f .. " ends", false, eF); break end
    end
    local n = spreadsOf(bk)
    check(label .. ": the book has spreads", n > 1, n)
    for s = 1, n do
        bk.spread = s
        local okS, eS = frame(bk, label .. ": spread " .. s)
        if not okS then check(label .. ": spread " .. s .. " ends", false, eS); break end
    end
    bk.spread = 1
end

for _, size in ipairs({ "small", "large" }) do
    Z.applyTheme("dark", "orange", size)
    section("4K, 1.75x, " .. size .. " text (T.px(10) = " .. tostring(Z.T.px(10)) .. ")")
    road(size .. ", ZeD.Guide.open(0)", function() Z.Guide.open(0) end)
    road(size .. ", the bubble's click", function()
        Z.GuideBubble.st = { shows = 1, toast = { text = "bubble" } }
        Z.GuideBubble.open()
        check(size .. ", the bubble's click: the offer is over, its balloon taken down",
            Z.GuideBubble.st.done == true and Z.GuideBubble.st.why == "opened" and #dropped > 0)
    end)
    road(size .. ", F1", function() Z.Guide.toggle(0) end)
    -- F1 again closes it and the game plays again
    local okC, eC = guarded(size .. ", F1 again", function() Z.Guide.toggle(0) end)
    check(size .. ", F1 again closes the book", okC and bookOf() and not bookOf():isReallyVisible(), eC)
end

Z.applyTheme("dark", "orange", "small")
for _, sz in ipairs({ { 0, 0 }, { 0, 2160 }, { 3840, 0 }, { 1, 1 } }) do
    local tag = sz[1] .. " x " .. sz[2]
    section("the screen at " .. tag .. " (minimized, a resolution change on its way)")
    closeAll()
    Z.Guide.open(0)
    local bk = bookOf()
    SCREEN.w, SCREEN.h = sz[1], sz[2]
    local hung = nil
    for s = 1, spreadsOf(bk) do
        bk.spread = s
        local ok, e = frame(bk, tag .. ": spread " .. s)
        if not ok then hung = e; break end
    end
    check(tag .. ": every spread draws and ends", hung == nil, hung)
    SCREEN.w, SCREEN.h = 3840, 2160
end
do
    local bk = bookOf()
    bk.spread = 1
    local ok = frame(bk, "back at 3840 x 2160")
    check("back at 3840 x 2160: the book draws", ok)
    check("back at 3840 x 2160: the unit is the 4K one again", bk._g and bk._g.u == 1.75, bk._g and bk._g.u)
    closeAll()
end

print(string.format("worst frame: %d instructions (%s); the cap %d", worst, worstAt, LIMIT))
for _, l in ipairs(logs) do print("logged once: " .. l) end
print(string.format("guide_open_freeze_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
