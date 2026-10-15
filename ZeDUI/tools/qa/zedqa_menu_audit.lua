-- Click audit of the main menu screens (run through the QA bridge at the main menu: copy to Zomboid/Lua/zedqa.lua, bump zedqa.go).
-- Walks every view, lets it render, then checks the click areas of the desk, the bar,
-- the pull-down and the view's window: outside their window, overlapping, zero-sized.
-- Screenshots each step with MM.debugHits on.
local MM = ZeD.MainMenu
MM.debugHits = true
local R = MM.root
local function vwin(view)
    for _, rv in ipairs(MM.views) do if rv.view == view then return R[rv.field] end end
    return nil
end

local function inside(h, x, y, w, hh)
    return h.x >= x - 1 and h.y >= y - 1 and h.x + h.w <= x + w + 1 and h.y + h.h <= y + hh + 1
end
local function overlap(a, b)
    local ix = math.min(a.x + a.w, b.x + b.w) - math.max(a.x, b.x)
    local iy = math.min(a.y + a.h, b.y + b.h) - math.max(a.y, b.y)
    return ix > 1 and iy > 1
end

local function audit(tag)
    local W = MM.activeWindow()
    local out, ov, zero = {}, {}, {}
    local hits = {}
    for _, h in ipairs(W and W._hits or {}) do hits[#hits + 1] = h end
    local wx, wy = W:getAbsoluteX(), W:getAbsoluteY()
    for _, h in ipairs(hits) do
        if h.w <= 0 or h.h <= 0 then zero[#zero + 1] = tostring(h.id) end
        if not inside(h, wx, wy, W.width, W.height) then out[#out + 1] = tostring(h.id) end
    end
    for i = 1, #hits do
        for j = i + 1, #hits do
            local a, b = hits[i], hits[j]
            if not a.disabled and not b.disabled and a.id ~= b.id and overlap(a, b) then
                ov[#ov + 1] = tostring(a.id) .. "~" .. tostring(b.id)
            end
        end
    end
    local cb = W.closeRect and W:closeRect()
    local cbs = cb and (cb.x .. "," .. cb.y .. "," .. cb.w .. " tb=" .. ZeD.T.titleBarH .. " sz=" .. ZeD.T.closeBoxSz) or "-"
    print("ZEDQA AUDIT " .. tag .. " view=" .. tostring(MM.view) .. " hits=" .. #hits .. " close=" .. cbs)
    if #out > 0 then print("ZEDQA AUDIT   outside: " .. table.concat(out, " ", 1, math.min(#out, 30))) end
    if #ov > 0 then print("ZEDQA AUDIT   overlap(" .. #ov .. "): " .. table.concat(ov, " ", 1, math.min(#ov, 30))) end
    if #zero > 0 then print("ZEDQA AUDIT   zero: " .. table.concat(zero, " ")) end
    -- the pull-down, when open
    if MM.ctx.open and R.drop and R.drop:isVisible() then
        local dh = R.drop._hits or {}
        local dov = {}
        for i = 1, #dh do for j = i + 1, #dh do if overlap(dh[i], dh[j]) then dov[#dov + 1] = tostring(dh[i].id) .. "~" .. tostring(dh[j].id) end end end
        print("ZEDQA AUDIT   drop " .. tostring(MM.ctx.open) .. " rows=" .. #dh .. (#dov > 0 and (" overlap: " .. table.concat(dov, " ")) or ""))
    end
end

local steps = {}
local function step(tag, fn, shot) steps[#steps + 1] = { tag = tag, fn = fn, shot = shot ~= false } end

step("main", function() MM.showView("main") end)
for _, m in ipairs(MM.menus()) do
    step("menu_" .. m.key, function() MM.ctx.open = m.key end)
end
step("main_closed", function() MM.ctx.open = nil end, false)
step("load", function() MM.ctx.open = nil; MM.showView("load") end)
step("newgame", function() MM.showView("newgame") end)
step("mods", function() MM.showView("main"); MM.openMods() end)
step("options", function() MM.showView("main"); MM.openOptions() end)
local nOpt = #R.optsWin:pages()
for i = 2, nOpt do step("options_p" .. i, function() R.optsWin.pageIdx = i; R.optsWin.scroll = 0 end) end
step("credits", function() R.optsWin:back(); MM.showView("credits") end)
step("join", function() MM.showView("join") end)
step("host", function() MM.showView("main"); MM.act.host() end)
step("srvset", function() R.hostWin:editSettings() end)
step("srvset_new", function() vwin("srvset"):act("new") end)
step("srvset_back", function() vwin("srvset"):act("back") end, false)
step("host_again", function() vwin("srvset"):act("back") end, false)
step("newgame2", function() R.hostWin:back(); MM.showView("newgame") end, false)
step("spawn", function()
    local nw = R.newWin
    for i, d in ipairs(nw:items()) do if d.mode == "Sandbox" then nw.sel = i end end
    nw:next()
end)
step("sandbox", function() vwin("spawn"):next() end)
step("sandbox_p5", function() local s = vwin("sandbox"); s.pageIdx = 5; s.scroll = 0 end)
step("traits", function() vwin("sandbox"):next() end)
step("looks", function() vwin("traits"):next() end)
step("back_traits", function() vwin("looks"):back() end, false)
step("back_sandbox", function() vwin("traits"):back() end, false)
step("back_spawn", function() vwin("sandbox"):back() end, false)
step("back_newgame", function() vwin("spawn"):back() end, false)
step("end", function() R.newWin:back(); MM.showView("main"); MM.debugHits = false end, false)

local i, wait, audited = 0, 0, true
local function tick()
    if wait > 0 then wait = wait - 1; return end
    if i > 0 and not audited then
        local s = steps[i]
        local ok, err = pcall(audit, s.tag)
        if not ok then print("ZEDQA AUDIT " .. s.tag .. " audit failed: " .. tostring(err)) end
        if s.shot then getCore():TakeFullScreenshot("zqa_" .. string.format("%02d", i) .. "_" .. s.tag) end
        audited = true
        wait = 6   -- (the screenshot is taken on a later frame: the view must not change before it)
        return
    end
    audited = false
    i = i + 1
    local s = steps[i]
    if not s then Events.OnFETick.Remove(tick); print("ZEDQA AUDIT done"); return end
    local ok, err = pcall(s.fn)
    if not ok then print("ZEDQA AUDIT " .. s.tag .. " step failed: " .. tostring(err)) end
    wait = 25
end
Events.OnFETick.Add(tick)
print("ZEDQA AUDIT start steps=" .. #steps)
