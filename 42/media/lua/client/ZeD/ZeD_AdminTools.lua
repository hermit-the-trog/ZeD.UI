-- ZeD-UI/42/media/lua/client/ZeD/ZeD_AdminTools.lua
-- ============================================================================
-- THE SERVER TOOLS' CARDS (ZeDUI/VANILLA_WINDOWS_20261107.md, C10, C12, C13; the director, Nov 7: every admin tool becomes
-- a ZeD card). The Admin tab's More tools open these in place of the game's windows:
--   Statistics     ISStatisticsUI: the game's own numbers for this client and the server (performance, network,
--                  characters), read-only, while the card shows. The game sends them only while asked (its toggle)
--   PvP log        ISPVPLogToolUI: the game's own PvP log in the Log card's look (ZeD_LogCards.lua's lines). Pick a line for
--                  Go there; Send to chat and Write to file are the server's options; Clear behind the foot's confirm
--   Climate        ISAdminWeather: the climate's admin values as ticks and sliders, Apply in the foot (the game's own send);
--                  the weather's triggers below (stop, storm, tropical storm, blizzard, a weather period of a strength)
-- Every act is the game's own call, gated on the game's own capability. A control that cannot be used stays on the card,
-- gray, and says why. All text is drawn with drawText. Simple mode draws these same cards.
--
-- The slider (aslide) is a card item of its own: the label and value, then - , the track and + . The mouse sets it on the
-- track, the controller steps it with - and + (a twentieth of its range).
--
-- QA: AT.qaOpen(win, st, kind), AT._P.qaStats / qaEvents / qaClimate hold made-up numbers; admin_tools_sim.lua walks them.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_Admin"
require "ZeD/ZeD_TicketCards"
require "ZeD/ZeD_AdminCards"
require "ZeD/ZeD_LogCards"

ZeD = ZeD or {}
ZeD.AdminTools = ZeD.AdminTools or {}
local AT = ZeD.AdminTools
local M = ZeD.Admin
local AC = ZeD.AdminCards
local TC = ZeD.TicketCards
local D, B = TC._D, TC._B
local F = AC._F

local STATS_IDLE_MS = 2000       -- no frame of the statistics card for this long: the game's numbers are switched off
local READ_MS = 1000             -- the PvP log and the climate are read this often while their card shows
local ASK_PVP_MS = 10000         -- the PvP log is asked of the server this often

local P = {}                     -- the cards' parts (a table: Kahlua counts every local in the chunk)
AT._P = P
P.seq = 0

local function tr(k, ...) return ZeD.tr(k, ...) end
local function px(n) return ZeD.T.px(n) end
local function now() return getTimestampMs() end
local function words(s) local S = ZeD.ServerTab; return (S and S.btnWords) and S.btnWords(s) or s end
function P.bump() P.seq = P.seq + 1 end

-- a number as the card shows it: whole numbers whole, the rest to one place
function P.num(v)
    if type(v) ~= "number" then
        if v == nil then return "-" end
        return tostring(v)
    end
    if v == math.floor(v) and math.abs(v) < 1e15 then return string.format("%d", v) end
    return string.format("%.1f", v)
end

-- ---------------------------------------------------------------------------
-- THE SLIDER ITEM
-- ---------------------------------------------------------------------------
-- it: label, text() (the value in words), get(), set(v), min, max, step (the mouse's snap), c = { id, help, live }
function P.snap(it, v)
    if it.step and it.step > 0 then v = it.min + math.floor((v - it.min) / it.step + 0.5) * it.step end
    v = math.max(it.min, math.min(it.max, v))
    return math.floor(v * 1e4 + 0.5) / 1e4
end

function P.stepOf(it) return (it.max - it.min) / 20 end

TC.items.aslide = {
    gap = 2,
    layout = function(win, it, w)
        local T = ZeD.T
        local M2 = ZeD.Molecules
        it.dn = it.dn or { id = it.c.id .. ":dn", text = "-", help = it.c.help }
        it.up = it.up or { id = it.c.id .. ":up", text = "+", help = it.c.help }
        it.dn.w, it.dn.h = M2.buttonW("-"), T.buttonH - px(4)
        it.up.w, it.up.h = it.dn.w, it.dn.h
        -- (set here, not in draw: a stop under the fold is never drawn, and the controller can still press it)
        it.dn.run = function()
            it.set(P.snap(it, it.get() - P.stepOf(it)))
            P.bump()
        end
        it.up.run = function()
            it.set(P.snap(it, it.get() + P.stepOf(it)))
            P.bump()
        end
        return ZeD.TM:getFontHeight(T.fontF2) + px(2) + it.dn.h + px(4)
    end,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        local T, A = ZeD.T, ZeD.Atoms
        local c = it.c
        if c.live then c.live(c) end
        it.dn.disabled, it.dn.why = c.disabled, c.why
        it.up.disabled, it.up.why = c.disabled, c.why
        if not c.disabled then
            local v = it.get()
            if v <= it.min + 1e-9 then it.dn.disabled, it.dn.why = true, tr("UI_ZeD_Adm_SlideLeast") end
            if v >= it.max - 1e-9 then it.up.disabled, it.up.why = true, tr("UI_ZeD_Adm_SlideMost") end
        end
        local f2h = ZeD.TM:getFontHeight(T.fontF2)
        local a = c.disabled and T.disabledAlpha or 1
        local tc = T.text
        local value = it.text()
        local vw = ZeD.TM:MeasureStringX(T.fontF2, value)
        panel:drawText(A.truncateText(it.label, T.fontF2, math.max(px(20), w - vw - px(12))), x, dy, tc.r, tc.g, tc.b, (tc.a or 1) * a, T.fontF2)
        local vc = T.textDim
        panel:drawText(value, x + w - vw, dy, vc.r, vc.g, vc.b, (vc.a or 1) * a, T.fontF2)
        local by = dy + f2h + px(2)
        F.drawCtl(panel, win, t, it.dn, x, by, mx, my, ctx)
        F.drawCtl(panel, win, t, it.up, x + w - it.up.w, by, mx, my, ctx)
        local tx = x + it.dn.w + px(10)
        local tw = math.max(px(20), w - it.dn.w - it.up.w - px(20))
        local span = math.max(1e-6, it.max - it.min)
        local frac = (math.max(it.min, math.min(it.max, it.get())) - it.min) / span
        local bh = A.fillBarCompactH()
        local cy = by + math.floor(it.dn.h / 2)
        A.drawSmoothBar(panel, tx, cy - math.floor(bh / 2), tw, frac, false, nil, bh)
        local thW, thH = px(10), it.dn.h
        local thX = tx + math.floor(frac * tw) - math.floor(thW / 2)
        local hov = mx ~= nil and mx >= tx and mx < tx + tw and my >= by and my < by + it.dn.h
        local tb = (hov and not c.disabled) and (T.accentBright or T.accent) or T.surf4 or T.borderS
        panel:drawRect(thX, by, thW, thH, a, tb.r, tb.g, tb.b)
        A.frame(panel, thX, by, thW, thH, T.borderS)
        if hov and (c.why or c.help) then ZeD.Help.set(win, c.why or c.help) end
        -- the track, for the mouse: set from where it was pressed
        it.track = it.track or { id = c.id .. ":track" }
        local tr0 = it.track
        tr0.disabled, tr0.why = c.disabled, c.why
        tr0.run = function()
            local pmx = panel:getMouseX()
            local f = math.max(0, math.min(1, (pmx - tx) / math.max(1, tw)))
            it.set(P.snap(it, it.min + f * span))
            P.bump()
        end
        ctx.hits[#ctx.hits + 1] = { x = tx, y = by, w = tw, h = it.dn.h, c = tr0 }
    end,
    stops = function(it, x0, dy, w, add)
        local by = dy + ZeD.TM:getFontHeight(ZeD.T.fontF2) + px(2)
        local yy = it.y + ZeD.TM:getFontHeight(ZeD.T.fontF2) + px(2)
        add(it.dn, x0, by, it.dn.w, it.dn.h, yy)
        add(it.up, x0 + w - it.up.w, by, it.up.w, it.up.h, yy)
    end,
}

-- astat: a row of three, the name and two numbers (this client, the server), right-aligned as the game draws them
TC.items.astat = {
    layout = function(win, it, w)
        local T = ZeD.T
        local f = it.head and T.fontF1 or T.fontF2
        return ZeD.TM:getFontHeight(f) + px(4)
    end,
    draw = function(panel, win, t, it, x, dy, w)
        local T, A = ZeD.T, ZeD.Atoms
        local f = it.head and T.fontF1 or T.fontF2
        if it.band then
            local hv = T.hover
            panel:drawRect(x, dy, w, it.h, hv.a or 0.1, hv.r, hv.g, hv.b)
        end
        local colW = math.floor(w / 4)
        local c1, c2 = x + w - colW - px(4), x + w - px(4)
        local lc = it.head and T.textHead or T.text
        local nc = it.head and T.textHead or T.text
        local ty = dy + px(2)
        panel:drawText(A.truncateText(it.label, f, math.max(px(20), w - 2 * colW - px(12))), x + px(4), ty, lc.r, lc.g, lc.b, lc.a or 1, f)
        A.drawTextRight(panel, A.truncateText(it.a, f, colW - px(8)), c1, ty, f, nc)
        A.drawTextRight(panel, A.truncateText(it.b, f, colW - px(8)), c2, ty, f, nc)
        if it.head then A.drawDividerH(panel, x, dy + it.h - T.hair, w, false) end
    end,
}

-- ---------------------------------------------------------------------------
-- STATISTICS (ISStatisticsUI)
-- ---------------------------------------------------------------------------
-- the game's own names in its tables, with ZeD's words; a line in the table's place where the game draws one
P.STATS = {
    { id = "perf", key = "UI_ZeD_Adm_StatPerf", lfn = "getPerformanceLocal", rfn = "getPerformanceRemote", rows = {
        { "memory-free", "UI_ZeD_Adm_StatMemFree" }, { "memory-used", "UI_ZeD_Adm_StatMemUsed" }, { "memory-total", "UI_ZeD_Adm_StatMemTotal" },
        { "memory-max", "UI_ZeD_Adm_StatMemMax" }, { "fps", "UI_ZeD_Adm_StatFps" } } },
    { id = "net", key = "UI_ZeD_Adm_StatNet", lfn = "getNetworkLocal", rfn = "getNetworkRemote", rows = {
        { "received-packets", "UI_ZeD_Adm_StatRxP" }, { "sent-packets", "UI_ZeD_Adm_StatTxP" }, { "received-bytes", "UI_ZeD_Adm_StatRxKb" },
        { "sent-bytes", "UI_ZeD_Adm_StatTxKb" }, { "last-actual-bytes-received", "UI_ZeD_Adm_StatRakRx" }, { "last-actual-bytes-sent", "UI_ZeD_Adm_StatRakTx" },
        { "last-user-message-bytes-resent", "UI_ZeD_Adm_StatRakResent" }, { "packet-loss-last-second", "UI_ZeD_Adm_StatRakLoss" },
        { "voip-received", "UI_ZeD_Adm_StatVoipRx" }, { "voip-sent", "UI_ZeD_Adm_StatVoipTx" } } },
    { id = "game", key = "UI_ZeD_Adm_StatGame", lfn = "getGameLocal", rfn = "getGameRemote", rows = {
        { "players", "UI_ZeD_Adm_StatPlayers" }, { "animals-objects", "UI_ZeD_Adm_StatAnimObj" }, { "animals-instances", "UI_ZeD_Adm_StatAnimInst" },
        { "animals-owned", "UI_ZeD_Adm_StatAnimOwned" }, { "zombies-total", "UI_ZeD_Adm_StatZedTotal" }, { "zombies-loaded", "UI_ZeD_Adm_StatZedLoaded" },
        { "zombies-simulated", "UI_ZeD_Adm_StatZedSim" }, { "zombies-culled", "UI_ZeD_Adm_StatZedCulled" } } },
}

-- the game's statistics flow only while asked: its own toggle, once on and once off
function P.statsSwitch(on)
    if (P.statsOn == true) == (on == true) then return end
    P.statsOn = on
    if P.qaStats then return end
    local ok, err = pcall(toggleStatisticsTransmission)
    if not ok then ZeD.logOnce("statistics: toggle", err) end
end

function P.readTable(fnName)
    if P.qaStats then return P.qaStats[fnName] end
    local fn = _G[fnName]
    if not fn then return nil end
    local ok, t = pcall(fn)
    return ok and t or nil
end

function P.statOf(t, name)
    if not t then return nil end
    local ok, v = pcall(function() return t[name] end)
    if ok then return v end
    return nil
end

function AT.openStats(win, st)
    F.push(win, st, { kind = "stats", from = "adm:b:more:statistics", hide = {} })
    P.statsSeen = now()
    P.statsSwitch(true)
end

function P.statsItems(win, st, t, card)
    local items = {}
    B.sub(items, tr("UI_ZeD_Adm_StatLine"))
    local client, server = tr("UI_ZeD_Adm_StatClient"), tr("UI_ZeD_Adm_StatServer")
    for _, sec in ipairs(P.STATS) do
        if card.hide[sec.id] ~= true then
            local lt, rt = P.readTable(sec.lfn), P.readTable(sec.rfn)
            items[#items + 1] = { k = "astat", head = true, label = tr(sec.key), a = client, b = server }
            for i, row in ipairs(sec.rows) do
                items[#items + 1] = { k = "astat", label = tr(row[2]), a = P.num(P.statOf(lt, row[1])), b = P.num(P.statOf(rt, row[1])), band = (i % 2) == 1 }
            end
        end
    end
    -- the game's three ticks: which tables show
    local ticks = {}
    for _, sec in ipairs(P.STATS) do
        local id = sec.id
        ticks[#ticks + 1] = { id = "sh:" .. id, style = "tick", text = tr(sec.key), on = card.hide[id] ~= true, help = tr("UI_ZeD_Adm_HelpStatShow"),
            run = function()
                card.hide[id] = (card.hide[id] ~= true) or nil
                P.bump()
            end }
    end
    B.label(items, tr("UI_ZeD_Adm_StatShow"))
    F.flow(items, ticks)
    return items
end

TC.kinds.stats = {
    data = function() return true end,
    tick = function(win, st, t, card)
        P.statsSeen = now()
        if not P.statsOn then P.statsSwitch(true) end
        -- (the numbers change every second: the card's words are built again as often)
        local s = math.floor(now() / READ_MS)
        if card.sec ~= s then
            card.sec = s
            P.bump()
        end
    end,
    key = function(t, card)
        local parts = { tostring(P.seq) }
        for _, sec in ipairs(P.STATS) do parts[#parts + 1] = tostring(card.hide[sec.id]) end
        return table.concat(parts, ":")
    end,
    title = function() return getText("IGUI_AdminPanel_HeaderShowStatistics") end,
    help = function() return tr("UI_ZeD_Adm_HelpStatisticsCard") end,
    items = function(win, st, t, card) return P.statsItems(win, st, t, card) end,
    foot = function() return { main = {} } end,
    back = function() P.statsSwitch(false) end,
}

-- ---------------------------------------------------------------------------
-- THE PVP LOG (ISPVPLogToolUI)
-- ---------------------------------------------------------------------------
P.events = {}
function P.readEvents()
    local out = {}
    if P.qaEvents then
        out = P.qaEvents
    else
        pcall(function()
            local list = PVPLogTool.getEvents()
            for i = 0, list:size() - 1 do
                local e = list:get(i)
                if e:isSet() then
                    out[#out + 1] = { s = i, text = tostring(e:getText() or ""), t = tostring(e.timestamp or ""),
                        x = math.floor(e:getX()), y = math.floor(e:getY()), z = math.floor(e:getZ()) }
                end
            end
        end)
    end
    local sig = {}
    for i, e in ipairs(out) do sig[i] = e.t .. "|" .. e.text end
    sig = table.concat(sig, ";")
    P.events = out
    if sig ~= P.eventsSig then
        P.eventsSig = sig
        P.bump()
    end
end

-- the server's options for the log, as the game's window reads them, and what this card set since
function P.optOn(card, name)
    if card.opts[name] ~= nil then return card.opts[name] end
    local ok, v = pcall(function() return getServerOptions():getBoolean(name) end)
    return ok and v == true
end

function AT.openPvp(win, st, from)
    F.push(win, st, { kind = "pvplog", from = from or "adm:b:more:pvplog", opts = {} })
    P.pvpAskAt, P.pvpReadAt = nil, nil
end

function P.pvpLine(st, card, e)
    local open = card.sel == e.s
    local text = e.text
    local it = { k = "lline", kindK = "pvp", tag = ZeD.upper(tr("UI_ZeD_Log_Kind_pvp")), who = "", text = text,
        metaText = tr("UI_ZeD_Adm_PvpPlace", e.x, e.y, e.z), col = { e.t }, open = open,
        c = { id = "pv:" .. e.s, help = tr("UI_ZeD_Log_HelpLine"), run = function()
            if card.sel == e.s then card.sel = nil else card.sel = e.s end
            P.bump()
        end } }
    if open then
        local place = { x = e.x, y = e.y, z = e.z }
        it.btns = { ctls = { { id = "pvgo:" .. e.s, text = tr("UI_ZeD_Tk_GoThere"), help = tr("UI_ZeD_Log_HelpGo"),
            live = function(c) D.liveGo(c) end, run = function() D.goThere(st, place) end } } }
        it.btns.ctls[1].live(it.btns.ctls[1])
    end
    return it
end

function P.pvpItems(win, st, t, card)
    local items = {}
    -- the server's two options, for a role that may change them
    local opts = {}
    for _, o in ipairs({ { "PVPLogToolChat", "IGUI_PVPLogTool_SendToChat" }, { "PVPLogToolFile", "IGUI_PVPLogTool_WriteToFile" } }) do
        local name = o[1]
        opts[#opts + 1] = F.gate({ id = "po:" .. name, style = "tick", text = words(getText(o[2])), on = P.optOn(card, name), help = tr("UI_ZeD_Adm_HelpPvpOpt"),
            run = function()
                local v = not P.optOn(card, name)
                card.opts[name] = v
                card.changed = true
                SendCommandToServer("/changeoption " .. name .. " \"" .. tostring(v) .. "\"")
                P.bump()
            end }, "ChangeAndReloadServerOptions")
    end
    F.flow(items, opts)
    local list = P.events
    B.label(items, tr("UI_ZeD_Log_Title"), tostring(#list))
    if #list == 0 then B.sub(items, tr("UI_ZeD_Adm_PvpNone")) end
    -- newest first, as the Log card has them
    for i = #list, 1, -1 do
        local it = P.pvpLine(st, card, list[i])
        it.c.land = i == #list
        items[#items + 1] = it
    end
    return items
end

TC.kinds.pvplog = {
    data = function() return true end,
    tick = function(win, st, t, card)
        local clock = now()
        if not P.qaEvents and M.can("PVPLogTool") and (not P.pvpAskAt or clock - P.pvpAskAt >= ASK_PVP_MS) then
            P.pvpAskAt = clock
            pcall(requestPVPEvents)
        end
        if not P.pvpReadAt or clock - P.pvpReadAt >= READ_MS then
            P.pvpReadAt = clock
            P.readEvents()
        end
    end,
    key = function(t, card) return table.concat({ tostring(P.seq), tostring(card.sel), tostring(M.seq) }, ":") end,
    title = function() return words(getText("IGUI_AdminPanel_PVPLogTool")) end,
    help = function(t)
        if t.confirm then return tr("UI_ZeD_Adm_HelpPvpClear") end
        return tr("UI_ZeD_Adm_HelpPvp")
    end,
    items = function(win, st, t, card) return P.pvpItems(win, st, t, card) end,
    flag = function(panel, win, t, card, data, x, y, w, bar)
        local T = ZeD.T
        ZeD.Atoms.drawTextRight(panel, tr("UI_ZeD_Adm_PvpCount", #P.events), x + w - px(10), y - bar + math.floor((bar - ZeD.TM:getFontHeight(T.fontF3)) / 2), T.fontF3, T.textDim)
        return 0
    end,
    foot = function(win, st, t, card)
        if t.confirm then
            return { question = tr("UI_ZeD_Adm_PvpClearAsk"), main = {
                D.btn("cno", tr("UI_ZeD_Tk_KeepIt"), function(ww)
                    t.confirm = nil
                    D.focusId(ww, st, "tk:pvclear")
                end, nil, tr("UI_ZeD_Adm_HelpPvpKeep")),
                D.btn("cyes", words(getText("UI_chat_Clear")), function(ww)
                    t.confirm = nil
                    local ok, err = pcall(clearPVPEvents)
                    if not ok then ZeD.logOnce("pvp log: clear", err) end
                    card.sel = nil
                    P.pvpReadAt = nil
                    D.flash(t, tr("UI_ZeD_Adm_PvpCleared"))
                    P.bump()
                    D.focusId(ww, st, "tk:back")
                end, "danger", tr("UI_ZeD_Adm_HelpPvpClear")) } }
        end
        local b = D.btn("pvclear", words(getText("UI_chat_Clear")), function(ww)
            t.confirm = true
            D.focusId(ww, st, "tk:cno")
        end, "danger", tr("UI_ZeD_Adm_HelpPvpClear"))
        if not M.can("PVPLogTool") then D.disable(b, M.why("PVPLogTool"))
        elseif #P.events == 0 then D.disable(b, tr("UI_ZeD_Adm_PvpNone")) end
        return { lead = { b }, main = {} }
    end,
    cancel = function(win, st, t, card)
        if not t.confirm then return false end
        t.confirm = nil
        D.focusId(win, st, "tk:pvclear")
        return true
    end,
    -- (the game's window reloads the options as it closes, for a role that may: a changed tick is live for every client)
    back = function(win, st, t, card)
        if card.changed and M.can("ChangeAndReloadServerOptions") then SendCommandToServer("/reloadoptions") end
    end,
}

-- ---------------------------------------------------------------------------
-- CLIMATE CONTROL (ISAdminWeather: its Climate page and its Weather page)
-- ---------------------------------------------------------------------------
-- the game's indexes (ISAdmPanelClimate.lua)
P.FL = { desat = 0, light = 1, night = 2, precip = 3, temp = 4, fog = 5, wind = 6, clouds = 8, ambient = 9, day = 11 }
P.TEMP_MIN, P.TEMP_MAX = -40, 40

function P.clim()
    if P.qaClimate then return P.qaClimate end
    local ok, c = pcall(getClimateManager)
    return ok and c or nil
end

function P.maxWind()
    local c = P.clim()
    local ok, v = pcall(function() return c:getMaxWindspeedKph() end)
    return (ok and type(v) == "number" and v > 0) and v or 120
end

-- the admin values as the game holds them now
function P.readClimate()
    local c = P.clim()
    if not c then return nil end
    local d = {}
    local ok = pcall(function()
        local function fl(i) return c:getClimateFloat(i) end
        local kph = P.maxWind()
        d.wind = { on = fl(P.FL.wind):isEnableAdmin(), v = fl(P.FL.wind):getAdminValue() * kph }
        d.clouds = { on = fl(P.FL.clouds):isEnableAdmin(), v = fl(P.FL.clouds):getAdminValue() }
        d.fog = { on = fl(P.FL.fog):isEnableAdmin(), v = fl(P.FL.fog):getAdminValue() }
        local snow = c:getClimateBool(0)
        d.precip = { on = fl(P.FL.precip):isEnableAdmin(), v = fl(P.FL.precip):getAdminValue(), snow = snow:isEnableAdmin() and snow:getAdminValue() }
        d.temp = { on = fl(P.FL.temp):isEnableAdmin(), v = fl(P.FL.temp):getAdminValue() }
        d.dark = { on = fl(P.FL.day):isEnableAdmin(), v = 1 - fl(P.FL.day):getAdminValue() }
        d.desat = { on = fl(P.FL.desat):isEnableAdmin(), v = fl(P.FL.desat):getAdminValue() }
        local col = c:getClimateColor(0)
        local ext, int = col:getAdminValue():getExterior(), col:getAdminValue():getInterior()
        d.light = { on = fl(P.FL.light):isEnableAdmin(),
            ext = { ext:getRedFloat() * 255, ext:getGreenFloat() * 255, ext:getBlueFloat() * 255, ext:getAlphaFloat() * 255 },
            int = { int:getRedFloat() * 255, int:getGreenFloat() * 255, int:getBlueFloat() * 255, int:getAlphaFloat() * 255 } }
    end)
    if not ok then return nil end
    -- (values the game holds out of the sliders' range are shown at their ends)
    d.temp.v = math.max(P.TEMP_MIN, math.min(P.TEMP_MAX, d.temp.v))
    return d
end

function P.copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = P.copy(v) end
    return o
end

function P.same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then
        if type(a) == "number" then return math.abs(a - b) < 1e-3 end
        return a == b
    end
    for k, v in pairs(a) do
        if not P.same(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

-- the card's values: the draft once anything changed, else the game's
function P.view(card)
    return card.d or card.live
end

-- a change starts the draft from what shows
function P.edit(card)
    if not card.d then card.d = P.copy(card.live) end
    return card.d
end

-- Apply: every admin value written, then the game's own send (ISAdmPanelClimate's Apply)
function P.applyClimate(d)
    local c = P.clim()
    if not (c and d) then return false end
    local ok, err = pcall(function()
        local function fl(i) return c:getClimateFloat(i) end
        local function set(i, on, v)
            fl(i):setEnableAdmin(on and true or false)
            fl(i):setAdminValue(v)
        end
        set(P.FL.wind, d.wind.on, d.wind.v / P.maxWind())
        set(P.FL.clouds, d.clouds.on, d.clouds.v)
        set(P.FL.fog, d.fog.on, d.fog.v)
        set(P.FL.precip, d.precip.on, d.precip.v)
        -- (snow follows the precipitation's tick, as the game's window has it)
        local snow = c:getClimateBool(0)
        snow:setEnableAdmin(d.precip.on and true or false)
        snow:setAdminValue(d.precip.on and d.precip.snow and true or false)
        set(P.FL.temp, d.temp.on, d.temp.v)
        set(P.FL.day, d.dark.on, 1 - d.dark.v)
        set(P.FL.night, d.dark.on, d.dark.v)
        set(P.FL.ambient, d.dark.on, 1 - d.dark.v)
        set(P.FL.desat, d.desat.on, d.desat.v)
        fl(P.FL.light):setEnableAdmin(d.light.on and true or false)
        local col = c:getClimateColor(0)
        col:setEnableAdmin(d.light.on and true or false)
        local e, i = d.light.ext, d.light.int
        col:setAdminValueExterior(e[1] / 255, e[2] / 255, e[3] / 255, e[4] / 255)
        col:setAdminValueInterior(i[1] / 255, i[2] / 255, i[3] / 255, i[4] / 255)
        c:transmitClientChangeAdminVars()
    end)
    if not ok then ZeD.logOnce("climate: apply", err) end
    return ok
end

function AT.openClimate(win, st, from)
    local card = { kind = "climate", from = from or "adm:b:more:climate", dur = 24, str = 0.8, front = 0 }
    card.live = P.readClimate()
    F.push(win, st, card)
    local c = P.clim()
    if c and not P.qaClimate then pcall(function() c:transmitRequestAdminVars() end) end
end

local CAP = "ClimateManager"

function P.tick(card, key, text, help)
    return { k = "atick", text = text, c = F.gate({ id = "ct:" .. key, on = P.view(card)[key].on, help = help,
        run = function()
            local d = P.edit(card)
            d[key].on = not d[key].on
            P.bump()
        end }, CAP) }
end

function P.slide(card, key, label, min, max, step, fmt, field, idx)
    local function get()
        local v = P.view(card)[key]
        if idx then return v[field][idx] end
        return v[field or "v"]
    end
    local function set(x)
        local d = P.edit(card)
        if idx then d[key][field][idx] = x else d[key][field or "v"] = x end
    end
    return { k = "aslide", label = label, min = min, max = max, step = step, get = get, set = set, text = function() return fmt(get()) end,
        c = F.gate({ id = "cs:" .. key .. (idx and (":" .. field .. idx) or ""), help = tr("UI_ZeD_Adm_HelpSlide") }, CAP) }
end

function P.f2(v) return string.format("%.2f", v) end
function P.int(v) return string.format("%d", math.floor(v + 0.5)) end

function P.climateItems(win, st, t, card)
    local items = {}
    local v = P.view(card)
    if not v then
        B.sub(items, tr("UI_ZeD_Srv_PlayersWait"))
        return items
    end
    if not M.can(CAP) then B.sub(items, M.why(CAP)) end
    B.label(items, getText("IGUI_Adm_Weather_Climate"))
    B.sub(items, getText("IGUI_Adm_Weather_ClimateEnabledInfo"))
    local kph = P.maxWind()
    items[#items + 1] = P.tick(card, "wind", getText("IGUI_climate_Windspeed"), tr("UI_ZeD_Adm_HelpClimTick"))
    items[#items + 1] = P.slide(card, "wind", getText("IGUI_climate_Windspeed"), 0, kph, 1, function(x) return tr("UI_ZeD_Adm_Kph", P.int(x)) end)
    items[#items + 1] = P.tick(card, "clouds", getText("IGUI_climate_Clouds"), tr("UI_ZeD_Adm_HelpClimTick"))
    items[#items + 1] = P.slide(card, "clouds", getText("IGUI_climate_Clouds"), 0, 0.35, 0.01, P.f2)
    items[#items + 1] = P.tick(card, "fog", getText("IGUI_climate_Fog"), tr("UI_ZeD_Adm_HelpClimTick"))
    items[#items + 1] = P.slide(card, "fog", getText("IGUI_climate_Fog"), 0, 1, 0.01, P.f2)
    items[#items + 1] = P.tick(card, "precip", getText("IGUI_climate_Precipitation"), tr("UI_ZeD_Adm_HelpClimTick"))
    items[#items + 1] = P.slide(card, "precip", getText("IGUI_climate_Precipitation"), 0, 1, 0.01, P.f2)
    items[#items + 1] = { k = "atick", text = getText("IGUI_climate_PrecipitationIsSnow"), c = F.gate({ id = "ct:snow", on = v.precip.snow == true,
        help = tr("UI_ZeD_Adm_HelpSnow"),
        run = function()
            local d = P.edit(card)
            d.precip.snow = not d.precip.snow
            P.bump()
        end }, CAP, function()
            if not P.view(card).precip.on then return tr("UI_ZeD_Adm_SnowNeedsPrecip") end
            return nil
        end) }
    items[#items + 1] = P.tick(card, "temp", getText("IGUI_climate_Temperature"), tr("UI_ZeD_Adm_HelpClimTick"))
    items[#items + 1] = P.slide(card, "temp", getText("IGUI_climate_Temperature"), P.TEMP_MIN, P.TEMP_MAX, 1, function(x)
        return tr("UI_ZeD_Adm_TempCF", P.int(x), P.int(x * 9 / 5 + 32))
    end)
    items[#items + 1] = P.tick(card, "dark", getText("IGUI_climate_Darkness"), tr("UI_ZeD_Adm_HelpClimTick"))
    items[#items + 1] = P.slide(card, "dark", getText("IGUI_climate_Darkness"), 0, 1, 0.01, P.f2)
    items[#items + 1] = P.tick(card, "desat", getText("IGUI_climate_Desaturation"), tr("UI_ZeD_Adm_HelpClimTick"))
    items[#items + 1] = P.slide(card, "desat", getText("IGUI_climate_Desaturation"), 0, 1, 0.01, P.f2)
    -- DAYLIGHT: the light's color, outside and inside
    items[#items + 1] = P.tick(card, "light", getText("IGUI_climate_Daylight"), tr("UI_ZeD_Adm_HelpClimTick"))
    local names = { "UI_ZeD_Adm_Red", "UI_ZeD_Adm_Green", "UI_ZeD_Adm_Blue", "UI_ZeD_Adm_Alpha" }
    for _, side in ipairs({ { "ext", "UI_ZeD_Adm_Outside" }, { "int", "UI_ZeD_Adm_Inside" } }) do
        B.label(items, tr(side[2]))
        for i, n in ipairs(names) do
            items[#items + 1] = P.slide(card, "light", tr(n), 0, 255, 1, P.int, side[1], i)
        end
    end
    -- THE WEATHER: these act at once, as the game's Weather page does
    P.weatherItems(items, st, t, card)
    return items
end

-- the game's own sends from its Weather page (a client's: the server runs them). Each call named in full, with the
-- argument types it takes (javap: float hours; float strength and int front)
P.SEND = {
    stop = function(c) c:transmitStopWeather() end,
    storm = function(c, card) c:transmitTriggerStorm(card.dur) end,
    tropical = function(c, card) c:transmitTriggerTropical(card.dur) end,
    blizzard = function(c, card) c:transmitTriggerBlizzard(card.dur) end,
    generate = function(c, card) c:transmitGenerateWeather(card.str, math.floor(card.front)) end,
}

function P.weather(what, card)
    local c = P.clim()
    if not c then return false end
    local ok, err = pcall(P.SEND[what], c, card)
    if not ok then ZeD.logOnce("climate: " .. what, err) end
    return ok
end

function P.weatherLine()
    local c = P.clim()
    local s = getText("IGUI_climate_weather_none")
    pcall(function()
        local wp = c:getWeatherPeriod()
        if wp and wp:isRunning() then
            s = tr("UI_ZeD_Adm_WeatherNow", P.num(math.floor(wp:getDuration() * 10 + 0.5) / 10), P.int(wp:getTotalProgress() * 100))
        end
    end)
    return s
end

function P.weatherItems(items, st, t, card)
    B.label(items, getText("IGUI_Adm_Weather_Weather"))
    items[#items + 1] = { k = "sub", text = P.weatherLine(), liveText = P.weatherLine }
    local function act(id, label, help, what)
        return F.gate({ id = id, text = words(getText(label)), help = help,
            run = function()
                if P.weather(what, card) then D.flash(TC.qaState(st), tr("UI_ZeD_Adm_WeatherSent")) end
            end }, CAP)
    end
    F.flow(items, { act("wstop", "IGUI_climate_StopWeather", tr("UI_ZeD_Adm_HelpWeatherStop"), "stop") })
    B.sub(items, getText("IGUI_climate_TriggerInfo"))
    items[#items + 1] = { k = "aslide", label = getText("IGUI_climate_TriggerPretext"), min = 4, max = 240, step = 1,
        get = function() return card.dur end, set = function(x) card.dur = x end,
        -- (the game adds an hour of lead-in and an hour of lead-out: the window says the whole, as the game's does)
        text = function() return tr("UI_ZeD_Adm_Hours", P.int(card.dur + 2)) end,
        c = F.gate({ id = "wdur", help = tr("UI_ZeD_Adm_HelpWeatherDur") }, CAP) }
    F.flow(items, {
        act("wstorm", "IGUI_climate_TriggerStorm", tr("UI_ZeD_Adm_HelpWeatherTrigger"), "storm"),
        act("wtrop", "IGUI_climate_TriggerTropical", tr("UI_ZeD_Adm_HelpWeatherTrigger"), "tropical"),
        act("wbliz", "IGUI_climate_TriggerBlizzard", tr("UI_ZeD_Adm_HelpWeatherTrigger"), "blizzard"),
    })
    B.sub(items, getText("IGUI_climate_CustomInfo"))
    items[#items + 1] = { k = "aslide", label = getText("IGUI_climate_StrengthPretext"), min = 0.1, max = 1, step = 0.01,
        get = function() return card.str end, set = function(x) card.str = x end, text = function() return P.f2(card.str) end,
        c = F.gate({ id = "wstr", help = tr("UI_ZeD_Adm_HelpWeatherStr") }, CAP) }
    F.flow(items, {
        { id = "wf:0", style = "chip", text = getText("IGUI_climate_WarmFront"), on = card.front == 0, help = tr("UI_ZeD_Adm_HelpWeatherFront"),
            run = function() card.front = 0; P.bump() end },
        { id = "wf:1", style = "chip", text = getText("IGUI_climate_ColdFront"), on = card.front == 1, help = tr("UI_ZeD_Adm_HelpWeatherFront"),
            run = function() card.front = 1; P.bump() end },
    })
    F.flow(items, { act("wgen", "IGUI_climate_Generate", tr("UI_ZeD_Adm_HelpWeatherGen"), "generate") })
end

function P.climApplyBtn(win, st, t, card)
    local b = D.btn("capply", words(getText("IGUI_PlayerStats_ReloadOptions")), function(ww)
        if P.applyClimate(card.d) then
            card.d = nil
            card.live = P.readClimate() or card.live
            D.flash(t, tr("UI_ZeD_Adm_ClimateSent"))
            P.bump()
        end
    end, "primary", tr("UI_ZeD_Adm_HelpClimApply"))
    if not M.can(CAP) then D.disable(b, M.why(CAP))
    elseif not card.d or P.same(card.d, card.live) then D.disable(b, tr("UI_ZeD_Adm_NothingToSave")) end
    return b
end

TC.kinds.climate = {
    data = function(card) return true end,
    tick = function(win, st, t, card)
        local clock = now()
        if not card.readAt or clock - card.readAt >= READ_MS then
            card.readAt = clock
            local live = P.readClimate()
            if live and not P.same(live, card.live) then
                card.live = live
                P.bump()
            end
        end
    end,
    -- (the draft's every value is in the key: a press on - or + builds the card's words again)
    key = function(t, card)
        local function sig(d)
            if not d then return "-" end
            local parts = {}
            for _, k in ipairs({ "wind", "clouds", "fog", "precip", "temp", "dark", "desat" }) do
                parts[#parts + 1] = tostring(d[k].on) .. "=" .. string.format("%.3f", d[k].v)
            end
            parts[#parts + 1] = tostring(d.precip.snow) .. tostring(d.light.on) .. table.concat(d.light.ext, ",") .. table.concat(d.light.int, ",")
            return table.concat(parts, ";")
        end
        return table.concat({ tostring(P.seq), tostring(M.seq), sig(card.d), sig(card.live), tostring(card.dur), tostring(card.str), tostring(card.front) }, ":")
    end,
    title = function() return words(getText("IGUI_Adm_Weather_ClimateControl")) end,
    help = function(t, card) return tr("UI_ZeD_Adm_HelpClimate") end,
    items = function(win, st, t, card) return P.climateItems(win, st, t, card) end,
    foot = function(win, st, t, card)
        local changed = card.d ~= nil and not P.same(card.d, card.live)
        local main = {}
        if changed then
            main[#main + 1] = D.btn("crevert", tr("UI_ZeD_Adm_Revert"), function(ww)
                card.d = nil
                P.bump()
                D.focusId(ww, st, "tk:back")
            end, nil, tr("UI_ZeD_Adm_HelpClimRevert"))
        end
        main[#main + 1] = P.climApplyBtn(win, st, t, card)
        return { status = changed and tr("UI_ZeD_Adm_NotApplied") or nil, main = main }
    end,
    padX = function(win, st, t, card)
        local b = P.climApplyBtn(win, st, t, card)
        return { label = b.label, run = b.run, disabled = b.disabled, why = b.why }
    end,
}

-- ---------------------------------------------------------------------------
-- OPENING, from the Admin tab's More tools
-- ---------------------------------------------------------------------------
function AT.open(win, st, kind)
    if not (win and st) then return false end
    st.screen = nil
    if kind == "statistics" then AT.openStats(win, st)
    elseif kind == "pvplog" then AT.openPvp(win, st)
    elseif kind == "climate" then AT.openClimate(win, st)
    elseif kind == "users" and ZeD.AdminUsers then ZeD.AdminUsers.open(win, st, "adm:tk:sum:users")
    elseif kind == "sandbox" and ZeD.SandboxIG and ZeD.SandboxIG.openServer then return ZeD.SandboxIG.openServer()
    elseif kind == "zones" and ZeD.AdminZones then ZeD.AdminZones.open(win, st, "zones")
    elseif kind == "nonpvp" and ZeD.AdminZones then ZeD.AdminZones.open(win, st, "nonpvp")
    elseif kind == "safezone" and ZeD.AdminZones then ZeD.AdminZones.open(win, st, "safe")
    else return false end
    return true
end

-- the statistics flow stops when their card is gone: the tab closed, the window shut
if not AT.hooked then
    AT.hooked = true
    if Events and Events.OnTick then
        Events.OnTick.Add(function()
            if P.statsOn and P.statsSeen and now() - P.statsSeen >= STATS_IDLE_MS then P.statsSwitch(false) end
        end)
    end
end

-- ---------------------------------------------------------------------------
-- QA
-- ---------------------------------------------------------------------------
function AT.qaOpen(win, st, kind)
    st.card = nil
    AT.open(win, st, kind)
end

return AT
