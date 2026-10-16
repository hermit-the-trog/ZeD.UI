-- ZeDUI/tools/qa/zedqa_menu_nav.lua  (Oct 15 2026)
-- Controller audit of the main menu screens (QA bridge at the main menu: copy
-- to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA NAV").
-- Director: "Controller navigation freedom of movement in menus is crucial.
-- Check for menus that dont highlight active list item."
-- For each screen (the click audit's walk), with the controller forced on:
--   * reach: from the first control, the D-pad (the screen's own joyDir, Options
--     and Sandbox through the plain move so values are not nudged) walks the
--     whole graph; controls it never reaches are listed;
--   * moves: every control's four neighbours (Right from a list row should
--     reach the buttons beside the list, etc.), logged compactly;
--   * highlight: each control in sight gets the focus, one frame later the
--     window must have painted the focus fill (alpha 0.55) over it; misses listed.
-- Screenshots a few focused states per screen.
local MM = ZeD.MainMenu
local R = MM.root
local function say(s) print("ZEDQA NAV " .. tostring(s)) end
local function vwin(view)
    for _, rv in ipairs(MM.views) do if rv.view == view then return R[rv.field] end end
    return nil
end
MM.forceGamepad = true

local steps = {}
local function step(tag, fn) steps[#steps + 1] = { tag = tag, fn = fn } end
step("main", function() MM.showView("main") end)
step("load", function() MM.showView("load") end)
step("newgame", function() MM.showView("newgame") end)
step("mods", function() MM.showView("main"); MM.openMods() end)
step("options", function() MM.showView("main"); MM.openOptions() end)
step("credits", function() R.optsWin:back(); MM.showView("credits") end)
step("join", function() MM.showView("join") end)
step("host", function() MM.showView("main"); MM.act.host() end)
step("srvset", function() R.hostWin:editSettings() end)
step("newgame2", function() vwin("srvset"):act("back"); R.hostWin:back(); MM.showView("newgame") end)
step("spawn", function()
    local nw = R.newWin
    for i, d in ipairs(nw:items()) do if d.mode == "Sandbox" then nw.sel = i end end
    nw:next()
end)
step("sandbox", function() vwin("spawn"):next() end)
step("traits", function() vwin("sandbox"):next() end)
step("looks", function() vwin("traits"):next() end)
step("end", function()
    vwin("looks"):back(); vwin("traits"):back(); vwin("sandbox"):back(); vwin("spawn"):back()
    R.newWin:back(); MM.showView("main"); MM.forceGamepad = false
end)

local PLAIN = { options = true, sandbox = true, looks = true }   -- their Left / Right nudge values: walk with the plain move

-- the focus fills a window paints (alpha 0.55), caught as it draws
local caught = {}
local function watch(W)
    if W._navWatch then return end
    W._navWatch = true
    local orig = ISUIElement.drawRect
    W.drawRect = function(self, x, y, w, h, a, r, g, b)
        if a and a > 0.5 and a < 0.6 then caught[#caught + 1] = { x = x, y = y, w = w, h = h } end
        return orig(self, x, y, w, h, a, r, g, b)
    end
end
local function covered(rect)
    for _, c in ipairs(caught) do
        local ix = math.min(rect.x + rect.w, c.x + c.w) - math.max(rect.x, c.x)
        local iy = math.min(rect.y + rect.h, c.y + c.h) - math.max(rect.y, c.y)
        if ix > 0 and iy > 0 and ix * iy >= 0.3 * rect.w * rect.h then return true end
    end
    return false
end

local function walk(tag, W)
    local specs = {}
    for _, s in ipairs(W._specs or {}) do if not s.disabled then specs[#specs + 1] = s end end
    if #specs == 0 then say(tag .. " no controls"); return {} end
    local saved = { focusId = W.focusId, sel = W.sel, scroll = W.scroll, psel = W.psel, oSel = W.oSel, jcol = W.jcol, jidx = W.jidx }
    local move = PLAIN[tag] and ZeD_MMWindow.joyDir or W.joyDir
    local rows = W:focusRows()
    local start = rows[1] and rows[1][1] and rows[1][1].id
    local seen, queue, edges = {}, { start }, {}
    seen[start] = true
    local n = 0
    while #queue > 0 and n < 400 do
        n = n + 1
        local id = table.remove(queue, 1)
        local e = {}
        for _, d in ipairs({ "up", "down", "left", "right" }) do
            W.focusId = id
            if W.jcol then pcall(function() W:setJoyFromId(id) end) end
            pcall(move, W, d)
            local to = W.focusId
            e[#e + 1] = d:sub(1, 1) .. "=" .. tostring(to == id and "-" or to)
            if to and not seen[to] then seen[to] = true; queue[#queue + 1] = to end
        end
        edges[#edges + 1] = tostring(id) .. " [" .. table.concat(e, " ") .. "]"
    end
    for k, v in pairs(saved) do W[k] = v end
    local missing = {}
    for _, s in ipairs(specs) do if not seen[s.id] then missing[#missing + 1] = tostring(s.id) end end
    say(string.format("%s controls=%d reached=%d%s", tag, #specs, #specs - #missing, #missing > 0 and (" UNREACHED: " .. table.concat(missing, " ", 1, math.min(#missing, 25))) or ""))
    for i = 1, math.min(#edges, 60) do say("   " .. edges[i]) end
    -- the controls in sight, for the highlight check
    local inSight = {}
    for _, s in ipairs(specs) do
        local r = W:specRect(s)
        if r then inSight[#inSight + 1] = { id = s.id, rect = r } end
    end
    return inSight
end

-- the state machine: show a screen, walk it, then focus each control in sight a frame at a time
local si, phase, wait = 0, "next", 0
local W, tag, list, li, misses
local function tick()
    if wait > 0 then wait = wait - 1; return end
    if phase == "next" then
        si = si + 1
        local s = steps[si]
        if not s then Events.OnFETick.Remove(tick); say("done"); return end
        local ok, err = pcall(s.fn)
        if not ok then say(s.tag .. " step failed: " .. tostring(err)) end
        if s.tag == "end" then phase = "next"; wait = 5; return end
        tag = s.tag
        phase = "walk"; wait = 25
    elseif phase == "walk" then
        W = MM.activeWindow()
        if not W then say(tag .. " no window"); phase = "next"; return end
        watch(W)
        local ok, res = pcall(walk, tag, W)
        if not ok then say(tag .. " walk failed: " .. tostring(res)); phase = "next"; return end
        list, li, misses = res, 0, {}
        phase = "focus"
    elseif phase == "focus" then
        if li > 0 then
            local c = list[li]
            if not covered(c.rect) then misses[#misses + 1] = c.id end
            if li == 2 or li == math.floor(#list / 2) then getCore():TakeFullScreenshot("zqa_nav_" .. tag .. "_" .. li .. ".png") end
        end
        li = li + 1
        if li > #list or li > 80 then
            say(string.format("%s highlight: %d in sight, %d without the focus fill%s", tag, #list, #misses,
                #misses > 0 and (": " .. table.concat(misses, " ", 1, math.min(#misses, 25))) or ""))
            W.focusId = nil
            phase = "next"; wait = 2
            return
        end
        W.focusId = list[li].id
        caught = {}
        wait = 2
    end
end
Events.OnFETick.Add(tick)
say("start screens=" .. #steps)
