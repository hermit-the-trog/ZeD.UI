-- ZeDUI/tools/qa/rt_kbmap.lua  (Nov 19 2026, QA; tag rt_kbmap): the release test's Keyboard map checks (beta 21,
-- FEATURE_MAP row "Keyboard map"; ZeD_KeyboardMap.lua, the director, Nov 18 2026: "Keyboard display and binding
-- assistance"). Built on rt_kit.lua (the global RT); run after it. grep "ZEDQA rt_kbmap". No pictures.
-- What it checks:
--   1. the window opens from the Character window's own menu (the window box's menu, its "Keyboard map" row fired
--      as a click on it fires it) and sits on screen (RT.bounds);
--   2. KM.read() lists every binding of the game's keyBinding table, in its groups, each with getCore():getKey now;
--      the drawn keyboard (ZeD.Atoms.borderRounded watched, pass-through) edges every bound key in the accent, a
--      clash in the bad color, an unbound key in neither;
--   3. KM.setKey on one harmless binding, the game's "Toggle Music" (no key by default, [Audio]), onto a key no
--      binding uses: getCore():getKey gives it at once; keysB42.ini has its line in the game's format (name=key:n,
--      the rest of the line as it was) and no other line changed; the file read the way MainOptions.loadKeys reads
--      it (string.split on "=", ";" and ":"; the Options key list is built from that reading) gives the new key;
--      the new key is lit on the drawn keyboard;
--   4. a clash: Toggle Music onto a key another binding holds: read() marks it, its key cap and the action boxes are
--      edged in the bad color (getCore():getBadHighlitedColor, the game's Accessibility option); put back, it clears;
--   5. Reset through the window's own mouse handler: the first press asks ("Press again to reset", drawn as a danger
--      button) and changes nothing; a second press within 4 s puts every key back to keyBinding's own, in the game
--      and in keysB42.ini.
-- What it puts back: every binding the director had (KM.setKey for each one changed, then keysB42.ini written back
-- line for line and each line given to the game as MainOptions.loadKeys gives it, so alternates and modifiers come
-- back too); the window closed; the window pair open or shut as found. The run wrapper kbmap_run.ps1 also copies
-- keysB42.ini before the run and puts it back byte for byte after (the director's real key file).
if not RT then
    print("ZEDQA rt_kbmap FAIL the kit (rt_kit.lua) is not loaded")
    print("ZEDQA rt_kbmap VERDICT FAIL 1")
    print("ZEDQA rt_kbmap DONE")
    return
end
local Q = RT.make("rt_kbmap")
Q.maxMs = 600000
local S = { pn = RT.pn }
local H = {}
local KM = ZeD and ZeD.KeyboardMap
local FILE = "keysB42.ini"

-- ===================================================================== helpers
function H.name()
    local n = nil
    pcall(function() n = tostring(KeybindId.TOGGLE_MUSIC:getId()) end)
    return n or "Toggle Music"
end
function H.key(name)
    local c = nil
    pcall(function() c = getCore():getKey(name) end)
    return c or 0
end
-- every binding of the game's table (not the [group] lines): name -> keyBinding's own key
function H.table()
    local out, n, heads = {}, 0, 0
    for _, b in ipairs(keyBinding or {}) do
        local v = b.value and tostring(b.value) or ""
        if v:sub(1, 1) == "[" then heads = heads + 1
        elseif v ~= "" then out[v] = b.key or 0; n = n + 1 end
    end
    return out, n, heads
end
function H.now()
    local out = {}
    for name in pairs(H.table()) do out[name] = H.key(name) end
    return out
end
function H.readLines()
    local t = nil
    pcall(function()
        local r = getFileReader(FILE, false)
        if not r then return end
        t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t
end
function H.writeLines(lines)
    if not lines then return false end
    return pcall(function()
        local w = getFileWriter(FILE, true, false)
        for _, l in ipairs(lines) do w:write(l .. "\r\n") end
        w:close()
    end) and true or false
end
-- one line read as MainOptions.loadKeys reads it (version 2): name, key, altCode, shift, ctrl, alt
function H.parse(line)
    local res = nil
    pcall(function()
        local sp = string.split(line, "=")
        if not (sp[1] and sp[2]) then return end
        local r = { name = sp[1], key = 0, alt = 0, shift = false, ctrl = false, altK = false }
        for _, fv in ipairs(string.split(sp[2], ";")) do
            local kv = string.split(fv, ":")
            if kv[1] == "key" then r.key = tonumber(kv[2]) or 0 end
            if kv[1] == "altCode" then r.alt = tonumber(kv[2]) or 0 end
            if kv[1] == "shift" and kv[2] == "true" then r.shift = true end
            if kv[1] == "ctrl" and kv[2] == "true" then r.ctrl = true end
            if kv[1] == "alt" and kv[2] == "true" then r.altK = true end
        end
        res = r
    end)
    return res
end
-- the key the game's Options reading gives name (MainOptions.loadKeys: the VERSION line, then name=key:...)
function H.optionsRead(lines, name)
    local version, got = 0, nil
    for _, l in ipairs(lines or {}) do
        if l:sub(1, 1) ~= "[" then
            local p = H.parse(l)
            if p and p.name == "VERSION" then version = tonumber(l:sub(9)) or 0 end
            if version >= 2 and p and p.name == name then got = p.key end
        end
    end
    return got, version
end
function H.lineIdx(lines, name)
    local pre = name .. "="
    for i, l in ipairs(lines or {}) do if l:sub(1, #pre) == pre then return i end end
    return nil
end
-- the drawn keyboard's code names (KM.ROWS) -> codes
function H.code(cname)
    local c = nil
    pcall(function() c = Keyboard[cname] end)
    return c
end
-- a key on the drawn keyboard no binding uses (punctuation first: nobody's hand is on it in a test)
function H.freeCap(data)
    local prefer = { "KEY_APOSTROPHE", "KEY_SEMICOLON", "KEY_RBRACKET", "KEY_LBRACKET", "KEY_BACKSLASH", "KEY_SLASH",
                     "KEY_EQUALS", "KEY_MINUS", "KEY_PERIOD", "KEY_COMMA" }
    for _, cn in ipairs(prefer) do
        local c = H.code(cn)
        if c and c ~= 0 and (data.used[c] or 0) == 0 then return c end
    end
    for _, row in ipairs(KM.ROWS or {}) do
        for _, k in ipairs(row) do
            local c = k[3] and H.code(k[3])
            if c and c ~= 0 and k[3] ~= "KEY_ESCAPE" and (data.used[c] or 0) == 0 then return c end
        end
    end
    return nil
end
-- a key on the drawn keyboard that exactly one other binding holds and that is no clash now
function H.heldCap(data, name)
    local best = nil
    for _, row in ipairs(KM.ROWS or {}) do
        for _, k in ipairs(row) do
            local c = k[3] and H.code(k[3])
            if c and c ~= 0 and k[3] ~= "KEY_ESCAPE" and data.used[c] == 1 and not data.clash[c] and H.key(name) ~= c then
                best = best or c
            end
        end
    end
    return best
end
function H.holderOf(data, c)
    for _, g in ipairs(data.groups or {}) do
        for _, r in ipairs(g.rows) do if r.code == c and r.name ~= S.name then return r.name end end
    end
    return nil
end
function H.same3(a, r, g, b)
    return a ~= nil and r ~= nil and math.abs(a[1] - r) < 0.002 and math.abs(a[2] - g) < 0.002 and math.abs(a[3] - b) < 0.002
end
function H.rgb(c)
    if not c then return "not drawn" end
    return string.format("rgb %d %d %d", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end
function H.bad()
    local r, g, b = 0.9, 0.25, 0.25
    pcall(function() local c = getCore():getBadHighlitedColor(); r, g, b = c:getR(), c:getG(), c:getB() end)
    return r, g, b
end
function H.at(x, y, w, h)
    return string.format("%d,%d,%d,%d", math.floor(x), math.floor(y), math.floor(w or 0), math.floor(h or 0))
end
function H.win()
    local w = KM and KM.windows and KM.windows[S.pn]
    local on = false
    pcall(function() on = w ~= nil and w:isReallyVisible() end)
    return on and w or nil
end
function H.hits(id)
    local out = {}
    local w = H.win()
    for _, h in ipairs((w and w._hits) or {}) do if h.id == id then out[#out + 1] = h end end
    return out
end

-- ===================================================================== what the window draws (pass-through)
-- the key caps' edges (ZeD.Atoms.borderRounded on the map, outside its buttons) by place, and its buttons
-- (ZeD.Molecules.drawButton) by place: the last frame's wins
function H.recStart()
    if S.recOn then return end
    S.recOn = true
    S.caps, S.btns = {}, {}
    local A, M = ZeD.Atoms, ZeD.Molecules
    S.brWas, S.dbWas = A.borderRounded, M.drawButton
    A.borderRounded = function(p, x, y, w, h, r, g, b, a, ...)
        if not S.inBtn and S.win ~= nil and p == S.win then S.caps[H.at(x, y, w, h)] = { r, g, b } end
        return S.brWas(p, x, y, w, h, r, g, b, a, ...)
    end
    M.drawButton = function(panel, x, y, w, h, text, variant, pressed, colors, opts)
        if S.win ~= nil and panel == S.win then S.btns[H.at(x, y, 0, 0)] = { text = text, variant = variant, colors = colors } end
        S.inBtn = true
        local ok, err = pcall(S.dbWas, panel, x, y, w, h, text, variant, pressed, colors, opts)
        S.inBtn = false
        if not ok then error(err) end
    end
end
function H.recStop()
    if not S.recOn then return end
    S.recOn = false
    ZeD.Atoms.borderRounded = S.brWas
    ZeD.Molecules.drawButton = S.dbWas
end
function H.recClear() S.caps, S.btns = {}, {} end
-- every key cap drawn: lit (used) in the accent, a clash in the bad color, else neither
function H.capFaults(data)
    local T = ZeD.T
    local ac = T.accent
    local br, bg, bb = H.bad()
    local caps, lit, clash, bad = 0, 0, 0, {}
    for _, h in ipairs(H.hits("cap")) do
        caps = caps + 1
        local col = S.caps[H.at(h.x, h.y, h.w, h.h)]
        local isBad = H.same3(col, br, bg, bb)
        local isAcc = H.same3(col, ac.r, ac.g, ac.b)
        local ok
        if data.clash[h.code] then ok = isBad; clash = clash + 1
        elseif (data.used[h.code] or 0) > 0 then ok = isAcc; lit = lit + 1
        else ok = col ~= nil and not isBad and not isAcc end
        if not ok and #bad < 6 then bad[#bad + 1] = tostring(h.code) .. (col and "" or " (not drawn)") end
    end
    return caps, lit, clash, bad
end
function H.capColor(c)
    for _, h in ipairs(H.hits("cap")) do if h.code == c then return S.caps[H.at(h.x, h.y, h.w, h.h)] end end
    return nil
end
function H.boxOf(name)
    for _, h in ipairs(H.hits("bind")) do if h.name == name then return S.btns[H.at(h.x, h.y, 0, 0)] end end
    return nil
end
function H.boxBad(name)
    local b = H.boxOf(name)
    local e = b and b.colors and b.colors.border
    local br, bg, bb = H.bad()
    return e ~= nil and H.same3({ e.r, e.g, e.b }, br, bg, bb)
end
-- a click on the window's Reset button, through its own mouse handlers
function H.clickReset()
    local w = H.win()
    local r = H.hits("reset")[1]
    if not (w and r) then return false end
    local x, y = r.x + math.floor(r.w / 2), r.y + math.floor(r.h / 2)
    w:onMouseDown(x, y)
    w:onMouseUp(x, y)
    return true
end

-- ===================================================================== 0. as found
Q.step(5, function()
    S.err0 = nil
    pcall(function() S.err0 = getLuaDebuggerErrorCount() end)
    S.name = H.name()
    S.orig = H.now()
    S.file0 = H.readLines()
    S.pairWas = RT.isOpen()
    S.mapWas = H.win() ~= nil
    RT.pairOpen()
    Q.check(KM ~= nil and KM.open ~= nil and KM.read ~= nil and KM.setKey ~= nil and KM.resetAll ~= nil,
        "Keyboard map: ZeD.KeyboardMap is loaded (open, read, setKey, resetAll)")
    Q.say("as found: " .. tostring(S.name) .. " on " .. tostring(S.orig[S.name]) .. ", keysB42.ini " ..
        (S.file0 and (#S.file0 .. " lines") or "missing"))
end)

-- ===================================================================== 1. opened from the window's menu
Q.step(20, function()
    local w = RT.cw()
    pcall(function() w:openWindowMenu() end)
    local m = ZeD.WindowMenu and ZeD.WindowMenu.current
    local it = nil
    local want = ZeD.tr("UI_ZeD_KMap_Title")
    for _, a in ipairs((m and m._ctx and m._ctx.actions) or {}) do if a.name == want then it = a end end
    Q.check(it ~= nil and it.onFire ~= nil, "Keyboard map: the window menu has its Keyboard map row", tostring(want))
    if it then pcall(it.onFire) else pcall(KM.open, S.pn) end
    pcall(function() if ZeD.WindowMenu.current then ZeD.WindowMenu.current:close() end end)
end)
Q.waitFor(5, 200, function() return H.win() ~= nil end, function(ok)
    Q.check(ok, "Keyboard map: its menu row opens the window")
    S.win = H.win()
    H.recStart()
end)
Q.step(15, function()
    if not S.win then return end
    RT.bounds(Q, "the keyboard map")
    -- 2. read(): every binding, in the game's groups, each with its key now
    local data = KM.read()
    local tbl, n, heads = H.table()
    local rows, off = 0, {}
    for _, g in ipairs(data.groups) do
        for _, r in ipairs(g.rows) do
            rows = rows + 1
            if tbl[r.name] == nil or r.code ~= H.key(r.name) then
                if #off < 6 then off[#off + 1] = tostring(r.name) .. "=" .. tostring(r.code) end
            end
        end
    end
    Q.check(rows == n and #data.groups == heads and #off == 0,
        "Keyboard map: read() lists every binding of the game's keyBinding table with its key now",
        rows .. " of " .. n .. " bindings, " .. #data.groups .. " of " .. heads .. " groups" .. ((#off > 0) and (", off: " .. table.concat(off, " ")) or ""))
    local caps, lit, clash, bad = H.capFaults(data)
    Q.check(caps > 60 and lit > 0 and #bad == 0, "Keyboard map: the drawn keyboard lights every bound key and only those",
        caps .. " keys drawn, " .. lit .. " lit, " .. clash .. " clashes" .. ((#bad > 0) and (", wrong: " .. table.concat(bad, " ")) or ""))
    S.new = H.freeCap(data)
    S.other = H.heldCap(data, S.name)
    S.holder = S.other and H.holderOf(data, S.other)
    Q.check(tbl[S.name] ~= nil and S.new ~= nil and S.other ~= nil and S.holder ~= nil,
        "Keyboard map: a free key and a held key to test with", tostring(S.name) .. ": free " .. tostring(S.new) ..
        ", held " .. tostring(S.other) .. " (" .. tostring(S.holder) .. ")")
end)

-- ===================================================================== 3. one binding onto a free key
Q.step(5, function()
    if not (S.win and S.new) then return end
    local before = H.readLines() or {}
    local took = KM.setKey(S.name, S.new)
    Q.check(took and H.key(S.name) == S.new, "Keyboard map: setKey gives the game the new key at once (getCore():getKey)",
        tostring(S.name) .. " on " .. tostring(H.key(S.name)) .. ", wanted " .. tostring(S.new))
    -- (Nov 20 2026, the bug hunt's KM-1: the game's Options keep their own list, MainOptions.keyText, and every
    -- Apply writes it back to the game and to keysB42.ini; a key set in the map must be in that list too, or the
    -- next Apply for anything puts the old key back)
    local kt, seen = nil, 0
    for _, v in ipairs((MainOptions and MainOptions.keyText) or {}) do
        seen = seen + 1
        local nm = nil
        pcall(function() nm = v.txt and v.txt:getName() end)
        if nm == S.name then kt = v end
    end
    if kt then
        Q.check(kt.keyCode == S.new, "Keyboard map: the game's Options key list has the new key too (an Apply there keeps it)",
            "Options list " .. tostring(kt.keyCode) .. ", wanted " .. tostring(S.new))
    else
        Q.skip("the game's Options key list has the new key too", "MainOptions.keyText has no entry for " .. tostring(S.name) .. " (" .. seen .. " entries; the Options screen is not built yet)")
    end
    local now = H.readLines() or {}
    local i0, i1 = H.lineIdx(before, S.name), H.lineIdx(now, S.name)
    local want = S.name .. "=key:" .. tostring(S.new)
    if i0 then
        local pre = S.name .. "=key:" .. tostring(S.orig[S.name])
        local l0 = before[i0]
        if l0:sub(1, #pre) == pre then want = want .. l0:sub(#pre + 1) end
    end
    local others = 0
    if #before > 0 then
        for i = 1, math.max(#before, #now) do
            if i ~= i0 and i ~= i1 and before[i] ~= now[i] then others = others + 1 end
        end
    end
    local vOk = now[1] == ("VERSION=" .. tostring((MainOptions and MainOptions.KEYS_VERSION) or 2))
    Q.check(i1 ~= nil and now[i1] == want and others == 0 and vOk and (#before == 0 or i0 == i1),
        "Keyboard map: keysB42.ini has the new line in the game's format and no other line changed",
        tostring(i1 and now[i1]) .. " (wanted " .. want .. "), " .. others .. " other lines changed, first line " .. tostring(now[1]))
    local got, ver = H.optionsRead(now, S.name)
    Q.check(got == S.new and ver >= 2, "Keyboard map: the game's Options reading of keysB42.ini finds the new key",
        "version " .. tostring(ver) .. ", " .. tostring(got))
    H.recClear()
end)
Q.step(5, function()
    if not (S.win and S.new) then return end
    local T = ZeD.T
    local col = H.capColor(S.new)
    Q.check(H.same3(col, T.accent.r, T.accent.g, T.accent.b), "Keyboard map: the new key is lit on the drawn keyboard",
        H.rgb(col))
end)

-- ===================================================================== 4. a clash, then put back
Q.step(3, function()
    if not (S.win and S.other) then return end
    KM.setKey(S.name, S.other)
    H.recClear()
end)
Q.step(5, function()
    if not (S.win and S.other) then return end
    local data = KM.read()
    Q.check(H.key(S.name) == S.other and data.clash[S.other] == true, "Keyboard map: a key given two jobs is a clash in read()",
        tostring(S.name) .. " and " .. tostring(S.holder) .. " on " .. tostring(S.other))
    local br, bg, bb = H.bad()
    local col = H.capColor(S.other)
    Q.check(H.same3(col, br, bg, bb), "Keyboard map: a clash is drawn in the bad color (getBadHighlitedColor) on its key",
        H.rgb(col) .. ", bad " .. H.rgb({ br, bg, bb }))
    Q.check(H.boxBad(S.name) and H.boxBad(S.holder), "Keyboard map: both clashing actions' key boxes are edged in the bad color",
        tostring(S.name) .. " " .. tostring(H.boxBad(S.name)) .. ", " .. tostring(S.holder) .. " " .. tostring(H.boxBad(S.holder)))
    KM.setKey(S.name, S.new)
    H.recClear()
end)
Q.step(5, function()
    if not (S.win and S.other) then return end
    local data = KM.read()
    local col = H.capColor(S.other)
    local T = ZeD.T
    Q.check(H.key(S.name) == S.new and not data.clash[S.other] and H.same3(col, T.accent.r, T.accent.g, T.accent.b),
        "Keyboard map: the clash clears once the key is put back", "clash " .. tostring(data.clash[S.other]))
end)

-- ===================================================================== 4b. the game's keys while the map listens
-- (Nov 20 2026, the bug hunt's P6: the key that answers the map also did its job in the game. While an action waits
-- for its key the game's Lua key events must be off, GameKeyboard.setDoLuaKeyPressed(false), and back on at every
-- way out. The setter is watched (pass-through) and the window's own _keysOff read; the wait is started with a click
-- on an action's key box through the window's mouse handler, ended by Escape, by a second click, and by closing.)
function H.bindClick(name)
    local w = H.win()
    for _, h in ipairs(H.hits("bind")) do
        if h.name == name then
            local x, y = h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2)
            local was = w.listening
            w:onMouseDown(x, y)
            local down = w._down
            w:onMouseUp(x, y)
            Q.say("click on " .. tostring(name) .. "'s box at " .. x .. "," .. y .. " (body " .. tostring(w:titleBarHeight()) ..
                "+" .. tostring(w._bodyH) .. ", scroll " .. tostring(w.scroll) .. "): down " .. tostring(down) ..
                ", listening " .. tostring(was) .. " -> " .. tostring(w.listening))
            return true
        end
    end
    return false
end
-- (the action's row scrolled into the window's body first: a click outside the body is not taken)
function H.bindShow(name)
    local w = H.win()
    if not w then return end
    local tb = w:titleBarHeight()
    for _, h in ipairs(H.hits("bind")) do
        if h.name == name and (h.y < tb or h.y + h.h > tb + (w._bodyH or 0)) then
            w:scrollBy(h.y - tb - math.floor((w._bodyH or 0) / 3))
        end
    end
end
Q.step(3, function() H.bindShow(S.name) end)
Q.step(5, function()
    if not S.win then return end
    S.gk = { last = nil, n = 0 }
    local ok = pcall(function()
        S.gk.was = GameKeyboard.setDoLuaKeyPressed
        GameKeyboard.setDoLuaKeyPressed = function(v) S.gk.last = v; S.gk.n = S.gk.n + 1; return S.gk.was(v) end
    end)
    S.gk.watched = ok and S.gk.was ~= nil
    Q.check(H.bindClick(S.name), "Keyboard map keys: a click on an action's key box starts the wait", tostring(S.name))
end)
Q.step(10, function()
    if not S.win then return end
    Q.check(S.win.listening == S.name and S.win._keysOff == true, "Keyboard map keys: while the map waits for a key, the game's Lua key events are off",
        "listening " .. tostring(S.win.listening) .. ", keys off " .. tostring(S.win._keysOff) .. ", setter last " .. tostring(S.gk.last))
    if S.gk.watched then Q.check(S.gk.last == false, "Keyboard map keys: GameKeyboard.setDoLuaKeyPressed(false) was called", tostring(S.gk.last)) end
    pcall(function() S.win:onKeyPress(Keyboard.KEY_ESCAPE) end)
end)
Q.step(10, function()
    if not S.win then return end
    Q.check(S.win.listening == nil and not S.win._keysOff and (not S.gk.watched or S.gk.last == true) and H.key(S.name) == S.new,
        "Keyboard map keys: Escape ends the wait, leaves the key as it was, and gives the game its keys back",
        "listening " .. tostring(S.win.listening) .. ", keys off " .. tostring(S.win._keysOff) .. ", setter last " .. tostring(S.gk.last))
    H.bindClick(S.name)
end)
Q.step(10, function() if S.win then H.bindClick(S.name) end end)   -- (a second click on the same box: the wait ends)
Q.step(10, function()
    if not S.win then return end
    Q.check(S.win.listening == nil and not S.win._keysOff and (not S.gk.watched or S.gk.last == true),
        "Keyboard map keys: a second click on the box ends the wait and gives the game its keys back",
        "listening " .. tostring(S.win.listening) .. ", keys off " .. tostring(S.win._keysOff))
    H.bindClick(S.name)
end)
Q.step(10, function()
    if not S.win then return end
    S.gk.offBeforeClose = S.win._keysOff
    pcall(function() S.win:close() end)
end)
Q.step(10, function()
    Q.check(S.gk.offBeforeClose == true and (not S.gk.watched or S.gk.last == true),
        "Keyboard map keys: closing the map mid-wait gives the game its keys back", "setter last " .. tostring(S.gk.last))
    if S.gk.was then pcall(function() GameKeyboard.setDoLuaKeyPressed = S.gk.was end) end
    -- (the map open again for the Reset checks below)
    pcall(KM.open, S.pn)
end)
Q.step(20, function() S.win = H.win() end)

-- ===================================================================== 5. Reset: asks once, then the game's keys
Q.step(5, function()
    if not S.win then return end
    local clicked = H.clickReset()
    Q.check(clicked and S.win._resetAt ~= nil and H.key(S.name) == S.new,
        "Keyboard map: the first Reset press asks and changes nothing yet",
        "clicked " .. tostring(clicked) .. ", " .. tostring(S.name) .. " on " .. tostring(H.key(S.name)))
    H.recClear()
end)
Q.step(5, function()
    if not S.win then return end
    local r = H.hits("reset")[1]
    local b = r and S.btns[H.at(r.x, r.y, 0, 0)]
    local sure = ZeD.tr("UI_ZeD_KMap_ResetSure")
    Q.check(b ~= nil and b.text == sure and b.variant == "danger", "Keyboard map: the Reset button reads Press again to reset",
        b and (tostring(b.text) .. " / " .. tostring(b.variant)) or "not drawn")
    H.clickReset()   -- (at once: a double click)
end)
-- (Nov 20 2026, the bug hunt's P1: a second press at once, a double click, must not wipe the keys; the second press
-- counts from 300 ms after the first)
Q.step(5, function()
    if not S.win then return end
    Q.check(H.key(S.name) == S.new, "Keyboard map: a second Reset press at once (a double click) changes nothing",
        tostring(S.name) .. " on " .. tostring(H.key(S.name)) .. ", was " .. tostring(S.new))
end)
Q.waitMs(500)
Q.step(2, function() if S.win and H.key(S.name) == S.new then H.clickReset() end end)
Q.step(5, function() S.askedAgain = S.win ~= nil and S.win._resetAt ~= nil and H.key(S.name) == S.new end)
Q.waitMs(500)
Q.step(2, function() if S.askedAgain then H.clickReset() end end)   -- (the at-once press had dropped the question: asked again above)
Q.step(5, function()
    if not S.win then return end
    local tbl = H.table()
    local off, n = {}, 0
    for name, def in pairs(tbl) do
        n = n + 1
        if H.key(name) ~= def and #off < 6 then off[#off + 1] = name .. "=" .. tostring(H.key(name)) .. "/" .. tostring(def) end
    end
    Q.check(#off == 0 and S.win._resetAt == nil, "Keyboard map: a second Reset press half a second on puts every key back to the game's own",
        n .. " bindings" .. ((#off > 0) and (", off: " .. table.concat(off, " ")) or ""))
    local lines = H.readLines() or {}
    local bad = {}
    for _, l in ipairs(lines) do
        local p = (l:sub(1, 1) ~= "[") and H.parse(l) or nil
        if p and tbl[p.name] ~= nil and p.key ~= tbl[p.name] and #bad < 6 then bad[#bad + 1] = l end
    end
    Q.check(#lines > 0 and #bad == 0, "Keyboard map: keysB42.ini holds the game's own keys after the reset", table.concat(bad, " | "))
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    H.recStop()
    -- the director's keys: setKey for each binding the test changed (the file and the game)
    S.reset = 0
    for name, c in pairs(S.orig or {}) do
        if H.key(name) ~= c then pcall(KM.setKey, name, c); S.reset = S.reset + 1 end
    end
    -- then the file line for line as found, each line given to the game as MainOptions.loadKeys gives it
    if S.file0 then
        S.fileBack = H.writeLines(S.file0)
        for _, l in ipairs(S.file0) do
            local p = (l:sub(1, 1) ~= "[") and H.parse(l) or nil
            if p and S.orig[p.name] ~= nil then
                pcall(function() getCore():addKeyBinding(p.name, p.key, p.alt, p.shift, p.ctrl, p.altK) end)
            end
        end
    end
    if not S.mapWas then pcall(KM.close, S.pn) end
    pcall(function() if ZeD.WindowMenu.current then ZeD.WindowMenu.current:close() end end)
    if S.pairWas then RT.pairOpen() else RT.pairShut() end
end)
Q.step(10, function()
    local off = {}
    for name, c in pairs(S.orig or {}) do
        if H.key(name) ~= c and #off < 6 then off[#off + 1] = name .. "=" .. tostring(H.key(name)) .. "/" .. tostring(c) end
    end
    Q.check(S.orig ~= nil and #off == 0, "put back: every binding as the director had it (getCore():getKey)",
        tostring(S.reset) .. " set back" .. ((#off > 0) and (", off: " .. table.concat(off, " ")) or ""))
    if S.file0 then
        local now = H.readLines()
        Q.check(now ~= nil and table.concat(now, "\n") == table.concat(S.file0, "\n"), "put back: keysB42.ini line for line as found",
            tostring(now and #now) .. " lines, " .. #S.file0 .. " before")
    else
        Q.skip("put back: keysB42.ini line for line as found", "there was no keysB42.ini before; kbmap_run.ps1 removes the one the test wrote")
    end
    Q.check(S.mapWas or H.win() == nil, "put back: the keyboard map is shut")
    Q.check(RT.isOpen() == S.pairWas, "put back: the windows open or shut as found")
    local e1 = nil
    pcall(function() e1 = getLuaDebuggerErrorCount() end)
    if S.err0 and e1 then Q.check(e1 == S.err0, "the keyboard map ran with no Lua error", (e1 - S.err0) .. " new") end
end)
Q.start()
