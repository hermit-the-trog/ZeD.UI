-- ZeDUI/tools/qa/sb_menu.lua  (Nov 25 2026, QA; tag sb_menu): MAIN MENU ONLY, pushed through the QA bridge. The
-- scroll bars' edges on the main menu's boxed lists, the main menu's half of sb_edges.lua (the director: a scroll bar's
-- outer edge shares the frame's line, one line on the right, top and bottom, no gap and no doubled line; Build's fix
-- fix/scrollbars c5e964b54). bx_desktop.lua's pictures are the desktops with every window closed, so none shows a list.
-- For each screen reachable from the main menu without starting a game: Saves ("load", when there are saves), Mods,
-- Options, Join, Host, Server settings ("srvset"), New game, and the new game's World, Spawn and Traits windows (these
-- stand in for the game's own screens; each is tried, and left at once with a SKIP when it does not come up or throws):
--   * every bar that draws is recorded (ZeD_ScrollbarState.draw wrapped for the run, put back at the end)
--   * a STATE line for the screen's bar (the first bar drawn on its window): x, y, width, arrowH, height, the in* flags,
--     reserveBottom, the caller's own width; CHECK its width is T.sp.scrollbarW
--   * a picture Zomboid/Screenshots/sb_menu_<screen>_<w>x<h>.png and one RECT line per bar drawn in that frame
--     ("ZEDQA sb_menu RECT pic=... bar=... x= y= w= h= hl= aH= rb= ... line= frame="), for sb_judge.py
--   A screen whose list fits shows no bar: a NOTE says so and its picture is still taken.
-- Nothing is pressed inside a screen. Each is left the menu bar's way (MM.showView("main")), never by its Back, which can
-- reload Lua (bx_menu.lua's K.back); Join lets go of the server list it asked Steam for, as Join's own Back does.
-- What it puts back: the main window up with no menu open, the debug console shown again, the lightning let go, the
-- bar's draw and the pointer the game's own.
-- Run (never while the game runs; the runner checks Lua/zedqa.lock itself), with $env:ZEDQA_NOSTEAM = "1" first:
--   4K fullscreen at UI scale 1.75:
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/zed_only_mods.txt `
--        -Script ZeDUI/tools/qa/sb_menu.lua -Tag sb_menu -TimeoutSec 300
--   1280x800 window: the same with -Width 1280 -Height 800 (score the first run's pictures before it: they are
--   overwritten only when the size is the same, the names carry it)
-- Score: python -I sb_judge.py --pics <Zomboid/Screenshots> --console <Zomboid/console.txt> --tag sb_menu --crops <folder>
-- Lines: "ZEDQA sb_menu PASS ..." / "FAIL ..." / "SKIP ..." / "NOTE ..." / "STATE ..." / "RECT ...", then "VERDICT PASS n"
-- or "VERDICT FAIL n", then DONE. grep "ZEDQA sb_menu".
local TAG = "sb_menu"
local MM = ZeD and ZeD.MainMenu
local S = { pass = 0, fail = 0, skips = 0, stages = {}, si = 1, maxMs = 240000, start = getTimestampMs(), frame = 0,
            shots = {}, rectN = 0, cons = {}, HEX = "0123456789abcdef" }
local K = {}

function K.say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
function K.check(ok, what, detail)
    if ok then S.pass = S.pass + 1 else S.fail = S.fail + 1 end
    K.say((ok and "PASS " or "FAIL ") .. what .. ((detail ~= nil and detail ~= "") and (" | " .. tostring(detail)) or ""))
    return ok and true or false
end
function K.skip(what, why) S.skips = S.skips + 1; K.say("SKIP " .. what .. " | " .. tostring(why)) end
function K.note(s) K.say("NOTE " .. tostring(s)) end

-- ---- the stages, on the clock (bx_desktop.lua's): after(ms, fn) runs fn ms after the stage before it (three frames
-- at least); waitFor(cond, maxMs, fn) runs fn(true) once cond is true, fn(false) after maxMs; mark() is where the
-- put-back starts (out of time: the queue jumps there)
function K.after(ms, fn) S.stages[#S.stages + 1] = { ms = ms, fn = fn } end
function K.waitFor(cond, maxMs, fn) S.stages[#S.stages + 1] = { ms = maxMs, cond = cond, fn = fn } end
function K.mark() S.markAt = #S.stages + 1 end

-- ---- small things (bx_menu.lua's, bx_desktop.lua's)
function K.ms() return MainScreen and MainScreen.instance end
function K.errs() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function K.i(v) local x = tonumber(v); if x == nil then return "?" end; return tostring(math.floor(x + 0.5)) end
function K.n(v) local x = tonumber(v); if x == nil then return 0 end; return math.floor(x + 0.5) end
function K.sizeTag() return getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight() end
function K.hex2(v)
    local n = math.floor((tonumber(v) or 0) * 255 + 0.5)
    if n < 0 then n = 0 elseif n > 255 then n = 255 end
    local hi = math.floor(n / 16)
    local lo = n - hi * 16
    return string.sub(S.HEX, hi + 1, hi + 1) .. string.sub(S.HEX, lo + 1, lo + 1)
end
function K.hexC(c) if type(c) ~= "table" then return "none" end; return K.hex2(c.r) .. K.hex2(c.g) .. K.hex2(c.b) end
function K.win(view)
    local r = MM.root
    if not r then return nil end
    if view == "main" then return r.win end
    if view == "load" then return r.loadWin end
    if view == "newgame" then return r.newWin end
    if view == "mods" then return r.modsWin end
    if view == "options" then return r.optsWin end
    for _, rv in ipairs(MM.views or {}) do if rv.view == view then return r[rv.field] end end
    return nil
end
function K.up(view)
    local w = K.win(view)
    return MM.view == view and w ~= nil and w:isVisible() and true or false
end
function K.show(view)
    if view == "mods" then MM.openMods() elseif view == "options" then MM.openOptions() else MM.showView(view) end
end
function K.leave(view)
    if view == "join" then pcall(function() if getSteamModeActive() then steamReleaseInternetServersRequest() end end) end
    MM.ctx.open = nil
    pcall(MM.showView, "main")
end
-- the debug console hidden for the pictures (bx_desktop.lua's)
function K.hideConsole()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if e and e:isVisible() and e:getClass():getSimpleName() == "UIDebugConsole" then
                S.cons[#S.cons + 1] = e
                e:setVisible(false)
            end
        end
    end)
end
function K.showConsole()
    local n, bad = 0, 0
    for _, e in ipairs(S.cons) do
        n = n + 1
        local vis = false
        pcall(function() e:setVisible(true); vis = e:isVisible() and true or false end)
        if not vis then bad = bad + 1 end
    end
    S.cons = {}
    return n, bad
end
-- the lightning held off (bx_desktop.lua's)
function K.holdZap()
    local z = MM._life and MM._life.zap
    if not z then return end
    if S.zapAt == nil then S.zapAt = z.nextAt or 0 end
    z.t0 = nil; z.nextAt = 1e15
end
function K.freeZap()
    local z = MM._life and MM._life.zap
    if z and S.zapAt ~= nil then z.nextAt = S.zapAt end
end

-- ---- every bar's draw recorded (sb_edges.lua's)
function K.spyOn()
    if S.spy then return true end
    local SB = ZeD_ScrollbarState
    if type(SB) ~= "table" or type(rawget(SB, "draw")) ~= "function" then return false end
    local sp = { own = rawget(SB, "draw"), recs = {} }
    SB.draw = function(self, panel)
        if type(self) == "table" and self.visible and type(panel) == "table" then
            local ok, e = pcall(K.spyRec, sp, self, panel)
            if not ok and not sp.said then sp.said = true; K.say("ERR the bar recorder threw: " .. tostring(e)) end
        end
        return sp.own(self, panel)
    end
    S.spy = sp
    return true
end
function K.spyOff()
    local sp = S.spy
    if not sp then return end
    S.spy = nil
    if type(ZeD_ScrollbarState) == "table" then ZeD_ScrollbarState.draw = sp.own end
end
function K.spyRec(sp, sb, panel)
    local T = ZeD.T
    local hl = T.px(1)
    local r = { sb = sb, panel = panel, frame = S.frame, x = sb.x or 0, y = sb.y or 0, w = sb.width or 0, h = sb.height or 0,
                aH = sb.arrowH or 0, rb = sb.reserveBottom or 0, inR = sb.inRight and true or false,
                inT = sb.inTop and true or false, inB = sb.inBottom and true or false,
                rawW = rawget(sb, "width"), rawA = rawget(sb, "arrowH"), hl = hl }
    r.ax, r.ay = panel:getAbsoluteX(), panel:getAbsoluteY()
    r.xs, r.ys = 0, 0
    if type(panel.getXScroll) == "function" then r.xs = panel:getXScroll() or 0 end
    if type(panel.getYScroll) == "function" then r.ys = panel:getYScroll() or 0 end
    r.pw = (type(panel.getWidth) == "function") and panel:getWidth() or nil
    r.ph = (type(panel.getHeight) == "function") and panel:getHeight() or nil
    local outR = r.inR and 0 or hl
    local outT = r.inT and 0 or hl
    local outB = (r.inB or r.rb > 0) and 0 or hl
    if r.pw and r.x + r.w + outR > r.pw then outR = 0 end
    if r.y - outT < 0 then outT = 0 end
    if r.ph and r.y + r.h + outB > r.ph then outB = 0 end
    r.outR, r.outT, r.outB = outR, outT, outB
    r.sx = K.n(r.ax + r.xs + r.x)
    r.sy = K.n(r.ay + r.ys + r.y)
    sp.recs[sb] = r
end
function K.drawn()
    local sp = S.spy
    if not sp then return {} end
    local top = -1
    for _, r in pairs(sp.recs) do if r.frame > top then top = r.frame end end
    local out = {}
    if top < S.frame - 30 then return out end   -- (front-end ticks, not frames: a little room)
    for _, r in pairs(sp.recs) do if r.frame == top then out[#out + 1] = r end end
    table.sort(out, function(a, b) return a.sx * 100000 + a.sy < b.sx * 100000 + b.sy end)
    return out
end
function K.nameOf(r)
    for _, own in ipairs({ r.panel, MM.root }) do
        local bars = own and own._zedBars
        if type(bars) == "table" then
            for key, b in pairs(bars) do if b == r.sb then return (string.gsub("menu:" .. tostring(key), "[^%w:%-%.]", "_")) end end
        end
    end
    return (string.gsub("bar@" .. tostring(r.panel.Type or "panel"), "[^%w:%-%.@]", "_"))
end
-- is panel the window or inside it
function K.inside(panel, win)
    local p, n = panel, 0
    while p ~= nil and n < 12 do
        if p == win then return true end
        local par = nil
        pcall(function() par = p.parent end)
        p, n = par, n + 1
    end
    return false
end
function K.printRects(pic, target)
    local T = ZeD.T
    local line, frame = K.hexC(T.borderS), K.hexC(T.border)
    local recs = K.drawn()
    for i, r in ipairs(recs) do
        S.rectN = S.rectN + 1
        K.say("RECT pic=" .. pic .. " bar=" .. K.nameOf(r) .. " target=" .. ((target and r.sb == target.sb) and 1 or 0) .. ((i == 1) and " first=1" or "")
            .. " x=" .. r.sx .. " y=" .. r.sy .. " w=" .. K.i(r.w) .. " h=" .. K.i(r.h) .. " hl=" .. K.i(r.hl) .. " aH=" .. K.i(r.aH)
            .. " rb=" .. K.i(r.rb) .. " inR=" .. (r.inR and 1 or 0) .. " inT=" .. (r.inT and 1 or 0) .. " inB=" .. (r.inB and 1 or 0)
            .. " outR=" .. K.i(r.outR) .. " outT=" .. K.i(r.outT) .. " outB=" .. K.i(r.outB) .. " line=" .. line .. " frame=" .. frame)
    end
    if #recs == 0 then K.note(pic .. ": no bar drew in the frame before the picture") end
end

-- ---- one screen: shown, settled, read, pictured, left
function K.screen(view, label, guard)
    local st = {}
    K.after(300, function()
        st.off = nil
        if view == "load" and not MM.hasSaves() then st.off = true; K.skip(label, "no saves here"); return end
        if view ~= "mods" and view ~= "options" and view ~= "load" and view ~= "newgame" and not MM.hasView(view) then
            st.off = true; K.skip(label, "the desk has no " .. view .. " view"); return
        end
        st.e0 = K.errs()
        MM.ctx.open = nil
        local ok, e = pcall(K.show, view)
        if not ok then st.off = true; K.skip(label, "showing it threw: " .. tostring(e)); K.leave(view) end
    end)
    K.waitFor(function() return st.off or K.up(view) end, 3000, function(met)
        if st.off then return end
        if not met then st.off = true; K.skip(label, "it did not come up (view " .. tostring(MM.view) .. ")"); K.leave(view) end
    end)
    K.after(700, function()
        if st.off then return end
        K.hideConsole()
        local e1 = K.errs()
        if guard and st.e0 and e1 and e1 > st.e0 then
            st.off = true
            K.skip(label, (e1 - st.e0) .. " Lua error(s) as it showed outside its own flow (it stands in for the game's own screen); left at once")
            K.leave(view)
            return
        end
        local win = K.win(view)
        st.rec = nil
        local recs = K.drawn()
        for _, r in ipairs(recs) do if not st.rec and K.inside(r.panel, win) then st.rec = r end end
        if not st.rec then
            K.note(label .. ": no bar on it here (its list fits); " .. #recs .. " bar(s) drew elsewhere")
            return
        end
        local r = st.rec
        local tok = ZeD.T.sp.scrollbarW
        K.say("STATE " .. view .. ": bar " .. K.nameOf(r) .. " x=" .. K.i(r.x) .. " y=" .. K.i(r.y) .. " width=" .. K.i(r.w) .. " arrowH=" .. K.i(r.aH)
            .. " height=" .. K.i(r.h) .. " reserveBottom=" .. K.i(r.rb) .. " inRight=" .. tostring(r.inR) .. " inTop=" .. tostring(r.inT)
            .. " inBottom=" .. tostring(r.inB) .. " | caller's width " .. tostring(r.rawW) .. ", arrowH " .. tostring(r.rawA)
            .. " | draws past R/T/B " .. K.i(r.outR) .. "/" .. K.i(r.outT) .. "/" .. K.i(r.outB) .. " | panel " .. tostring(r.panel.Type)
            .. " at " .. K.i(r.ax) .. "," .. K.i(r.ay) .. " " .. K.i(r.pw) .. "x" .. K.i(r.ph) .. " | screen " .. r.sx .. "," .. r.sy
            .. " | token " .. K.i(tok) .. ", hairline " .. K.i(r.hl))
        K.check(math.abs((tonumber(r.w) or -1) - tok) < 0.5, label .. ": the bar's width is T.sp.scrollbarW",
            "width " .. K.i(r.w) .. " (the caller's own " .. tostring(r.rawW) .. "), token " .. K.i(tok))
    end)
    K.after(100, function()
        if st.off then return end
        local name = "sb_menu_" .. view .. "_" .. K.sizeTag()
        local ok, e = pcall(function() getCore():TakeFullScreenshot(name .. ".png") end)
        if ok then
            S.shots[#S.shots + 1] = name .. ".png"
            K.note("picture Zomboid/Screenshots/" .. name .. ".png | " .. label)
            K.printRects(name, st.rec)
        else K.note("the picture " .. name .. " was not taken: " .. tostring(e)) end
    end)
    K.after(1800, function()   -- (a 4K picture stalls the frames about 1.5 s)
        if st.off then return end
        K.leave(view)
    end)
    K.waitFor(function() return MM.view == "main" end, 3000, function(met)
        if not met then K.note(label .. ": the main window did not come back (view " .. tostring(MM.view) .. ")"); pcall(MM.showView, "main") end
    end)
end

-- =========================================================================================================
local function tickFn()
    S.frame = S.frame + 1
    if MM and not S.zapFree then pcall(K.holdZap) end
    local s = S.stages[S.si]
    if not s then Events.OnFETick.Remove(tickFn); return end
    local now = getTimestampMs()
    if S.markAt and S.si < S.markAt and now - S.start > S.maxMs then
        S.fail = S.fail + 1
        K.say("ERR out of time at stage " .. S.si .. " of " .. #S.stages .. ": on to the put-back")
        S.si = S.markAt; S.t0 = nil
        return
    end
    if not S.t0 then S.t0 = now; S.n = 0 end
    S.n = S.n + 1
    local el = now - S.t0
    local go, met = false, false
    if s.cond then
        if S.n >= 2 then
            local ok, r = pcall(s.cond)
            met = ok and r and true or false
            if not ok and not s.said then s.said = true; K.say("ERR stage " .. S.si .. " (its wait): " .. tostring(r)); S.fail = S.fail + 1 end
        end
        go = met or el >= s.ms
    else
        go = el >= s.ms and S.n >= 3
    end
    if not go then return end
    S.si = S.si + 1
    S.t0 = nil
    local ok, e = pcall(s.fn, met)
    if not ok then S.fail = S.fail + 1; K.say("ERR stage " .. (S.si - 1) .. ": " .. tostring(e)) end
end

if not (MM and MM.root and MM.showView and MM.openMods and MM.openOptions and MM.hasView and ZeD.T and ZeD.T.sp) then
    K.after(100, function() S.fail = S.fail + 1; K.say("ERR ZeD's main menu is not up: nothing was done") end)
else
    K.after(100, function()
        S.errs0 = K.errs()
        S.view0 = MM.view
        S.pad0 = MM.forceGamepad
        MM.forceGamepad = false
        MM.ctx.open = nil
        pcall(MM.showView, "main")
        local spied = K.spyOn()
        K.check(spied, "ZeD_ScrollbarState.draw can be watched (every bar's draw recorded)")
        if not spied then S.si = S.markAt or S.si end   -- (nothing to record: on to the put-back)
        K.say("found: view " .. tostring(S.view0) .. ", theme " .. tostring(ZeD.currentBase) .. ", text " .. tostring(ZeD.currentSize)
            .. ", token T.sp.scrollbarW " .. K.i(ZeD.T.sp.scrollbarW) .. ", hairline " .. K.i(ZeD.T.px(1)) .. ", screen " .. K.sizeTag()
            .. ", UI scale " .. tostring(ZeD.T.scale))
    end)
    K.screen("load", "Saves (Load game)", false)
    K.screen("mods", "Mods", false)
    K.screen("options", "Options", false)
    K.screen("join", "Join (the server list)", false)
    K.screen("host", "Host", true)
    K.screen("srvset", "Server settings", true)
    K.screen("newgame", "New game", false)
    K.screen("world", "New game: World", true)
    K.screen("spawn", "New game: Spawn", true)
    K.screen("traits", "New game: Traits", true)
end
K.mark()
K.after(300, function()
    K.spyOff()
    MM.forceGamepad = S.pad0
    if MM then MM.ctx.open = nil; MM.deskAt, MM.deskBack = nil, nil end
    pcall(MM.showView, "main")
    S.consN, S.consBad = K.showConsole()
    S.zapFree = true
    K.freeZap()
end)
K.after(400, function()
    K.check(MM.view == "main" and K.up("main") and MM.ctx.open == nil, "put back: the main window up, no menu open", "view " .. tostring(MM.view))
    K.check((S.consBad or 0) == 0, "put back: the debug console shown again (" .. tostring(S.consN or 0) .. " hidden for the pictures)")
    K.check(S.spy == nil and MM.forceGamepad == S.pad0, "put back: the bar's draw and the input lock the game's own again")
    local n = K.errs()
    if n ~= nil and S.errs0 ~= nil then K.say("Lua errors counted during the run: " .. (n - S.errs0)) end
    K.say("pictures: " .. #S.shots .. " (" .. table.concat(S.shots, " ") .. "), RECT lines: " .. S.rectN)
end)
K.after(300, function()
    K.say("end: " .. S.pass .. " pass, " .. S.fail .. " fail, " .. S.skips .. " skipped; " .. math.floor((getTimestampMs() - S.start) / 1000) .. " s")
    K.say(S.fail > 0 and ("VERDICT FAIL " .. S.fail) or ("VERDICT PASS " .. S.pass))
    K.say("DONE")
end)
Events.OnFETick.Add(tickFn)
K.say("start (" .. #S.stages .. " stages)")
