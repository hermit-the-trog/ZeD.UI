-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuPlayers.lua
-- ============================================================================
-- THE PAUSE WINDOW'S PLAYERS AND INVITE PAGES. Client-side; two pages of the pause window
-- (MM.pages; the window itself is ZeD_MainMenu.lua's). In game, the pause
-- window's Players and Invite buttons (and the D-pad social wheel's Players) open these in the window itself, where
-- the game would open ISScoreboard and InviteFriends over the screen.
--
--   PLAYERS   who is on the server, from the game's scoreboard (scoreboardUpdate, the OnScoreboardUpdate reply): a row
--             each, as the Admin tab's player rows read (the name, "(you)", the Steam name where the game shows it, the
--             ping). Pick a row: under the list, the game's own actions for that player, each where the scoreboard
--             has it and only for the role that has it (ISScoreboard:doAdminButtons): Mute, Voice mute, Kick, Ban,
--             Ban IP, Teleport, Teleport to you, God mode, Invisible, sent with the game's own commands. Kick and the
--             two bans open ZeD's Admin player card, which asks for a reason; without ZeD's server part they ask
--             first in the band instead (its question in place of the buttons). The band: Back, Refresh.
--   INVITE    the Steam friends the game's own InviteFriends lists, in its order (online, others, offline), each
--             with its state. Pick a friend: Invite in the band (the game's clickInvite: inviteFriend). On a
--             co-op host, Allow / Deny beside it (the game's toggleAllowDeny, its invited.ini kept by its own
--             saveInvitedFile when the page is left).
--
-- The game's two screens are made by MainScreen and stay hidden: their objects carry the data and the calls.
-- The rows are the window's specs, so the mouse and the D-pad move over them as over its buttons.
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/Tr"

ZeD = ZeD or {}
local MM = ZeD.MainMenu
MM.pages = MM.pages or {}

local PL = {}                 -- the file's helpers (a table: Kahlua counts every local in the chunk)
ZeD.PausePlayers = PL
PL.list = PL.list or {}       -- { user, name, steamID, ping, avatar, steamName }, by name
PL.askedAt = 0

local ROW_H = 30              -- design units: a player or friend row
local ASK_EVERY = 5000        -- ms: the scoreboard asked again this often while the page shows
local PAGE_W = 480

local function tr(k, ...) return ZeD.tr(k, ...) end
local function px(n) return ZeD.T.px(n) end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local function now() return getTimestampMs() end
local function fontH(f) return ZeD.TM:getFontHeight(f) end
local function textW(f, s) return ZeD.TM:MeasureStringX(f, s) end
local function words(s)
    local S = ZeD.ServerTab
    s = ZeD.btnCase(s)
    return (S and S.btnWords) and S.btnWords(s) or s
end
local function cap(name)
    local c = Capability and Capability[name]
    if c == nil then return false end   -- (never a nil into the Java call: a call matching no overload upsets Kahlua's call pool)
    return safe(function() return getPlayer():getRole():hasCapability(c) end, false)
end
local function me() return safe(function() return getPlayer():getUsername() end, "") end

-- ---------------------------------------------------------------------------
-- THE SCOREBOARD (the game's reply; ServerTab.lua reads the same event)
-- ---------------------------------------------------------------------------
function PL.steamShown()
    return safe(function()
        return (getSteamScoreboard() or getPlayer():getRole():hasCapability(Capability.GetSteamScoreboard))
            and not getStreamModeActive() and getSteamModeActive()
    end, false)
end

function PL.onScoreboard(usernames, displayNames, steamIDs, pings)
    local out = {}
    pcall(function()
        local steam = getSteamModeActive()
        for i = 0, usernames:size() - 1 do
            local u = tostring(usernames:get(i))
            local d = (displayNames and displayNames:size() > i) and tostring(displayNames:get(i)) or u
            local e = { user = u, name = (d ~= "" and d) or u }
            if pings and pings:size() > i then e.ping = pings:get(i) end
            if steam and steamIDs and steamIDs:size() > i then
                e.steamID = steamIDs:get(i)
                e.steamName = safe(function() return getSteamProfileNameFromSteamID(e.steamID) end, nil)
                e.avatar = safe(function() return getSteamAvatarFromSteamID(e.steamID) end, nil)
            end
            out[#out + 1] = e
        end
    end)
    table.sort(out, function(a, b) return a.name:lower() < b.name:lower() end)
    PL.list = out
    PL.heard = true
end
if Events and Events.OnScoreboardUpdate then Events.OnScoreboardUpdate.Add(PL.onScoreboard) end

function PL.ask(force)
    local t = now()
    if not force and t - PL.askedAt < ASK_EVERY then return end
    PL.askedAt = t
    if scoreboardUpdate then pcall(scoreboardUpdate) end
end

-- ---------------------------------------------------------------------------
-- THE GAME'S ACTIONS FOR A PLAYER (ISScoreboard:onContext, its commands word for word, by username)
-- ---------------------------------------------------------------------------
local function q(s) return '"' .. tostring(s) .. '"' end
local function send(cmd) pcall(SendCommandToServer, cmd) end

-- Kick and the bans: ZeD's Admin player card for that player, which asks for a reason (ZeD_AdminCards.lua, the way chat's
-- Player card opens it). The game resumes and the World window opens on the Admin tab. False without ZeD's server part:
-- then the game's command, after the band's question
function PL.openCard(user)
    local Ad = ZeD.Admin
    if not (Ad and Ad.live and Ad.live() and ZeD_WorldWindow and ZeD_WorldWindow.openTab) then return false end
    Ad.openPlayerNext = user
    if MM.act and MM.act.resume then pcall(MM.act.resume) end
    ZeD_WorldWindow.openTab(0, "admin")
    return true
end

-- the actions for the picked player: { id, text, run, ask (a question first), danger, card (ZeD's player card first) }
function PL.actions(e)
    local out = {}
    if not e then return out end
    local u = e.user
    local mine = u == me()
    if not mine then
        local muted = safe(function() return ISChat.instance:isMuted(u) end, false)
        out[#out + 1] = { id = "mute", text = getText(muted and "UI_Scoreboard_Unmute" or "UI_Scoreboard_Mute"),
            run = function() if ISChat and ISChat.instance then ISChat.instance:mute(u) end end }
        local vmuted = safe(function() return VoiceManager:playerGetMute(u) end, false)
        out[#out + 1] = { id = "voip", text = getText(vmuted and "UI_Scoreboard_VOIPUnmute" or "UI_Scoreboard_VOIPMute"),
            run = function() if VoiceManager then VoiceManager:playerSetMute(u) end end }
        if cap("TeleportToPlayer") then out[#out + 1] = { id = "tp", text = getText("UI_Scoreboard_Teleport"), run = function() send("/teleport " .. q(u)) end } end
        if cap("TeleportPlayerToAnotherPlayer") then
            out[#out + 1] = { id = "tpyou", text = getText("UI_Scoreboard_TeleportToYou"), run = function() send("/teleportplayer " .. q(u) .. " " .. q(me())) end }
        end
        if cap("ToggleGodModEveryone") then out[#out + 1] = { id = "god", text = getText("UI_Scoreboard_GodMod"), run = function() send("/godmodplayer " .. q(u)) end } end
        if cap("ToggleInvisibleEveryone") then out[#out + 1] = { id = "invis", text = getText("UI_Scoreboard_Invisible"), run = function() send("/invisibleplayer " .. q(u)) end } end
        if cap("KickUser") then
            out[#out + 1] = { id = "kick", text = getText("UI_Scoreboard_Kick"), ask = tr("UI_ZeD_Adm_KickAsk", e.name), danger = true, card = true, run = function() send("/kickuser " .. q(u)) end }
        end
        if cap("BanUnbanUser") then
            out[#out + 1] = { id = "ban", text = getText("UI_Scoreboard_Ban"), ask = tr("UI_ZeD_Adm_BanAsk", e.name), danger = true, card = true, run = function() send("/banuser " .. q(u)) end }
            out[#out + 1] = { id = "banip", text = getText("UI_Scoreboard_BanIp"), ask = tr("UI_ZeD_Adm_BanAsk", e.name), danger = true, card = true, run = function() send("/banuser " .. q(u) .. " -ip") end }
        end
    else
        if cap("ToggleGodModHimself") then out[#out + 1] = { id = "god", text = getText("UI_Scoreboard_GodMod"), run = function() send("/godmodplayer " .. q(u)) end } end
        if cap("ToggleInvisibleHimself") then out[#out + 1] = { id = "invis", text = getText("UI_Scoreboard_Invisible"), run = function() send("/invisibleplayer " .. q(u)) end } end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- A LIST OF ROWS IN THE WINDOW: shared by both pages (st = the page's own state on the window)
-- ---------------------------------------------------------------------------
local function pageState(win, key)
    win._pp = win._pp or {}
    local st = win._pp[key]
    if not st then st = { off = 0 }; win._pp[key] = st end
    return st
end

-- how many rows fit: the pause window stays inside 80% of the screen with room for what goes under the list
local function roomFor(y, below)
    local T = ZeD.T
    local avail = getCore():getScreenHeight() * 0.8 - y - px(120) - (below or 0)
    return math.max(3, math.floor(avail / px(ROW_H)))
end

-- the rows as specs, from st.off; returns the y under the list
local function listSpecs(win, add, st, items, y, w, pad, row, idOf, onPick, drawRow, help)
    local rh = px(ROW_H)
    local shown = math.min(#items, st.room)
    st.off = math.max(0, math.min(st.off, #items - shown))
    st.listY, st.listH, st.n, st.shown = y, shown * rh, #items, shown
    local bar = (#items > shown) and ZeD.T.sp.scrollbarW or 0
    st.barX = w - pad - bar
    for i = 1, shown do
        local e = items[st.off + i]
        if e then
            add({ id = idOf(e), x = pad, y = y + (i - 1) * rh, w = w - pad * 2 - bar, h = rh, row = row + i, col = 1,
                  fn = function() onPick(e) end, draw = drawRow, item = e, index = st.off + i, help = help })
        end
    end
    return y + shown * rh, row + shown
end

-- the D-pad past the list's first or last row in sight moves the list, the focus on the next row
local function listJoy(win, st, items, dir, idOf)
    if dir ~= "up" and dir ~= "down" then return false end
    local fid = win.focusId
    local at = nil
    for i = 1, st.shown or 0 do
        local e = items[st.off + i]
        if e and idOf(e) == fid then at = i; break end
    end
    if not at then return false end
    if dir == "down" and at == st.shown and st.off + st.shown < #items then
        st.off = st.off + 1
        win.focusId = idOf(items[st.off + st.shown])
        MM.hoverSound()
        return true
    end
    if dir == "up" and at == 1 and st.off > 0 then
        st.off = st.off - 1
        win.focusId = idOf(items[st.off + 1])
        MM.hoverSound()
        return true
    end
    return false
end

local function listWheel(st, del)
    if not st.n or not st.shown then return end
    st.off = math.max(0, math.min(st.off + ((del > 0) and 1 or -1), st.n - st.shown))
end

-- the bar beside the list when it does not all show (MM.scrollBar: ZeD's own)
local function listBar(win, st, key)
    if not (st.n and st.shown and st.n > st.shown) then return end
    local rh = px(ROW_H)
    MM.scrollBar(win, key, st.barX, st.listY, ZeD.T.sp.scrollbarW, st.listH, st.off * rh, st.n * rh,
        function(v) st.off = math.max(0, math.min(math.floor(v / rh + 0.5), st.n - st.shown)) end, { step = rh })
end

-- a row's look: the wash (picked / hovered), the focus mark, a hairline under it. Returns the text color
local function rowLook(win, b, picked, hot, focus)
    local T = ZeD.T
    local onF = MM.rowLook(win, b.x, b.y, b.w, b.h, picked, hot, focus)
    ZeD.Atoms.drawDividerH(win, b.x, b.y + b.h - T.hair, b.w, false)
    if hot and b.help then ZeD.Help.set(win, b.help) end
    return onF and T.textOnFocus or T.text, onF and T.textOnFocus or T.textDim
end

-- a 32-pixel avatar square, scaled to the row (the game's own Steam picture)
local function drawAvatar(win, tex, x, y, s)
    if not tex then return 0 end
    pcall(function() win:drawTextureScaledAspect(tex, x, y, s, s, 1, 1, 1, 1) end)
    return s + px(8)
end

-- ---------------------------------------------------------------------------
-- PLAYERS
-- ---------------------------------------------------------------------------
local function plId(e) return "pl:" .. e.user end

function PL.drawRow(win, b, hot, focus)
    local T = ZeD.T
    local e = b.item
    local st = pageState(win, "players")
    local tc, dc = rowLook(win, b, st.sel == e.user, hot, focus)
    local f2, f3 = T.fontF2, T.fontF3
    local x = b.x + px(6)
    if PL.steamShown() then x = x + drawAvatar(win, e.avatar, x, b.y + px(2), b.h - px(4)) end
    local ping = e.ping and getText("UI_Ping", tostring(e.ping)) or ""
    local pw = textW(f3, ping)
    local right = b.x + b.w - px(6)
    win:drawText(ping, right - pw, b.y + math.floor((b.h - fontH(f3)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f3)
    local name = (e.user == me()) and tr("UI_ZeD_Adm_NameYou", e.name) or e.name
    local room = right - pw - px(12) - x
    local nw = math.min(textW(f2, name), room)
    win:drawText(ZeD.Atoms.truncateText(name, f2, room), x, b.y + math.floor((b.h - fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
    -- the Steam name, as the game shows it beside the name (only where it shows them)
    if e.steamName and PL.steamShown() and room - nw > px(60) then
        local s = getText("UI_Scoreboard_SteamName", tostring(e.steamName))
        win:drawText(ZeD.Atoms.truncateText(s, f3, room - nw - px(12)), x + nw + px(12), b.y + math.floor((b.h - fontH(f3)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f3)
    end
end

function PL.picked()
    local w = MM.pause
    local st = w and pageState(w, "players")
    if not (st and st.sel) then return nil end
    for _, e in ipairs(PL.list) do if e.user == st.sel then return e end end
    return nil
end

-- A pause-window page, as ZeD_MainMenu.lua calls it: W its width; label its heading; build lays its rows out as
-- specs and returns the y under them and the next row; band returns the band's buttons and its question (nil:
-- none); draw paints what the specs don't; joyDir / wheel take the D-pad and the wheel (true: handled); leave
-- runs on the way out; cancel is B while a question is open.
MM.pages.players = {
    W = PAGE_W,
    label = function() return ZeD.btnCase(getText("UI_mainscreen_scoreboard")) end,
    build = function(win, add, y, w, pad, row)
        local T = ZeD.T
        PL.ask(false)
        local st = pageState(win, "players")
        st.countY = y
        y = y + fontH(T.fontF3) + px(8)
        -- the actions under the list: two to a line
        local e = PL.picked()
        if not e then st.sel = nil end
        local acts = PL.actions(e)
        local lines = math.ceil(#acts / 2)
        local actH = (lines > 0) and (pad + lines * (T.buttonH + px(6))) or 0
        st.room = roomFor(y, actH)
        if #PL.list == 0 then
            st.emptyY = y
            y = y + px(ROW_H)
        else
            st.emptyY = nil
            y, row = listSpecs(win, add, st, PL.list, y, w, pad, row, plId,
                function(p) st.sel = p.user; st.ask = nil; MM.clickSound() end, PL.drawRow, tr("UI_ZeD_MMHelp_PlayerRow"))
        end
        if lines > 0 then
            y = y + pad
            local bw = math.floor((w - pad * 3) / 2)
            for i, a in ipairs(acts) do
                local c = (i - 1) % 2
                if c == 0 then row = row + 1 end
                local by = y + math.floor((i - 1) / 2) * (T.buttonH + px(6))
                add({ id = "act:" .. a.id, text = words(a.text), x = pad + c * (bw + pad), y = by, w = bw, h = T.buttonH, row = row, col = c + 1,
                      variant = "default",
                      fn = function()
                          if a.card and PL.openCard(e.user) then MM.clickSound(); return end
                          if a.ask then st.ask = a; win.focusId = "ask:no"; MM.clickSound(); return end
                          MM.clickSound()
                          a.run()
                          PL.ask(true)
                      end })
            end
            y = y + lines * (T.buttonH + px(6)) - px(6)
        end
        return y + pad, row
    end,
    band = function(win)
        local st = pageState(win, "players")
        local a = st.ask
        if a then
            return { { id = "ask:no", text = getText("UI_btn_cancel"), fn = function() st.ask = nil; win.focusId = "act:" .. a.id; MM.clickSound() end,
                       help = tr("UI_ZeD_MMHelp_Cancel") },
                     { id = "ask:yes", text = words(a.text), variant = "danger", fn = function()
                           st.ask = nil
                           MM.clickSound()
                           a.run()
                           PL.ask(true)
                       end } }, a.ask
        end
        return { { id = "back", text = getText("UI_btn_back"), fn = function() MM.leavePage(win); MM.clickSound() end, help = tr("UI_ZeD_MMHelp_BackPause") },
                 { id = "refresh", text = getText("UI_servers_refresh"), fn = function() MM.clickSound(); PL.ask(true) end, help = tr("UI_ZeD_MMHelp_RefreshPlayers") } }, nil
    end,
    draw = function(win)
        local T = ZeD.T
        local st = pageState(win, "players")
        local pad = px(12)
        local d = T.textDim
        local count = getText("UI_Scoreboard_PlayerConnected", tostring(#PL.list))
        win:drawText(count, pad, st.countY or 0, d.r, d.g, d.b, d.a or 1, T.fontF3)
        if st.emptyY then
            local s = PL.heard and tr("UI_ZeD_MM_NoPlayers") or tr("UI_ZeD_Srv_PlayersWait")
            win:drawText(s, pad, st.emptyY + math.floor((px(ROW_H) - fontH(T.fontF2)) / 2), d.r, d.g, d.b, d.a or 1, T.fontF2)
        end
        listBar(win, st, "pl")
    end,
    joyDir = function(win, dir) return listJoy(win, pageState(win, "players"), PL.list, dir, plId) end,
    wheel = function(win, del) listWheel(pageState(win, "players"), del) end,
    leave = function(win) local st = pageState(win, "players"); st.ask = nil end,
    -- B with Kick or a ban asking: its Cancel, the controller back on the button that asked
    cancel = function(win)
        local st = pageState(win, "players")
        local a = st.ask
        if not a then return false end
        st.ask = nil
        win.focusId = "act:" .. a.id
        return true
    end,
}

-- ---------------------------------------------------------------------------
-- INVITE (the game's InviteFriends object does the work; its list is read for the rows)
-- ---------------------------------------------------------------------------
local IV = {}
PL.invite = IV

function IV.game() return InviteFriends and InviteFriends.instance or nil end

-- the friends, in the game's order: its own fillList (the filter left empty)
function IV.fill(text)
    local g = IV.game()
    if not g then return end
    pcall(function()
        if g.filterEntry then g.filterEntry:setText(text or "") end
        g:fillList()
    end)
end

-- FIND (a friends list can run past 15 or so, so the page always has a find field): the words go into the game's
-- own filter, and its fillList narrows the list as it does on its own screen
function IV.entry(win)
    local e = win._ivFind
    if e then return e end
    e = ISTextEntryBox:new("", 0, 0, 100, 20)
    e:initialise()
    e:instantiate()
    e.zedEntry = true
    e.font = (ZeD.Text and ZeD.Text.entryFont) and ZeD.Text.entryFont() or UIFont.Small
    e.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    e.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    e.onTextChange = function() IV.find(win, e:getInternalText()) end
    win:addChild(e)
    win._ivFind = e
    return e
end
function IV.find(win, text)
    local st = pageState(win, "invite")
    st.find = text or ""
    st.off = 0
    IV.fill(st.find)
end
function IV.hideFind(win)
    local e = win._ivFind
    if e then
        if e.isFocused and e:isFocused() then e:unfocus() end
        e:setVisible(false)
    end
end
-- the find row: its label, the inset box, the field placed in it
function IV.drawFind(win, b, hot, focus)
    local T = ZeD.T
    local label = tr("UI_ZeD_Join_Find")
    local lw = textW(T.fontF2, label) + px(8)
    local c = T.text
    win:drawText(label, b.x, b.y + math.floor((b.h - fontH(T.fontF2)) / 2), c.r, c.g, c.b, c.a or 1, T.fontF2)
    local bx, bw = b.x + lw, b.w - lw
    local base, bs = T.base, T.borderS
    win:drawRect(bx, b.y, bw, b.h, 1, base.r, base.g, base.b)
    win:drawRectBorder(bx, b.y, bw, b.h, bs.a or 1, bs.r, bs.g, bs.b)
    if focus then ZeD.Focus.mark(win, bx, b.y, bw, b.h, MM.focusOpts()) end
    local e = IV.entry(win)
    local eh = fontH(e.font or UIFont.Small) + px(2)
    local ex, ey, ew = bx + px(6), b.y + math.floor((b.h - eh) / 2), bw - px(12)
    if e.x ~= ex or e.y ~= ey then e:setX(ex); e:setY(ey) end
    if e.width ~= ew or e.height ~= eh then e:setWidth(ew); e:setHeight(eh) end
    if not e:isVisible() then e:setVisible(true) end
    if hot then ZeD.Help.set(win, tr("UI_ZeD_MMHelp_FriendFind")) end
end
-- A on the find row: the field takes the keys, or on a controller the game's on-screen keyboard
function IV.pressFind(win)
    local e = IV.entry(win)
    local jd = JoypadState and JoypadState.getMainMenuJoypad and JoypadState.getMainMenuJoypad()
    if jd and OnScreenKeyboard and OnScreenKeyboard.Show then
        local osk = OnScreenKeyboard.Show(jd.player or 0, e, jd)
        if osk then osk.prevFocus = MainScreen and MainScreen.instance; jd.focus = osk; updateJoypadFocus(jd) end
        return
    end
    e:focus()
end

function IV.items()
    local g = IV.game()
    local out = {}
    if not (g and g.listbox) then return out end
    for i, it in ipairs(g.listbox.items or {}) do
        local f = it.item
        if f then
            out[#out + 1] = { index = i, friend = f, name = tostring(it.text or ""), id = safe(function() return tostring(f:getSteamID()) end, tostring(i)) }
        end
    end
    return out
end

local function ivId(e) return "iv:" .. e.id end

local STATE_COLOR = { Online = "positive", Offline = "danger" }
function IV.drawRow(win, b, hot, focus)
    local T = ZeD.T
    local e = b.item
    local st = pageState(win, "invite")
    local tc, dc = rowLook(win, b, st.sel == e.id, hot, focus)
    local f2, f3 = T.fontF2, T.fontF3
    local x = b.x + px(6)
    x = x + drawAvatar(win, safe(function() return e.friend:getAvatar() end, nil), x, b.y + px(2), b.h - px(4))
    local state = safe(function() return tostring(e.friend:getState()) end, "Unknown")
    local word = getText("UI_FriendState_" .. state)
    local g = IV.game()
    local right = b.x + b.w - px(6)
    -- a co-op host's word on this friend: Allow (may join) or Deny, the game's own
    if g and g.isCoopHost then
        local allowed = g.invited and g.invited[safe(function() return e.friend:getSteamID() end, "")] and true or false
        local tag = getText(allowed and "UI_InviteFriends_Allow" or "UI_InviteFriends_Deny")
        local tw = ZeD.Atoms.tagW(tag, true)
        ZeD.Atoms.drawTag(win, right - tw, b.y + math.floor((b.h - px(16)) / 2), tag, allowed and T.positive or T.textDim)
        right = right - tw - px(8)
    end
    local sw = textW(f3, word)
    local dot = px(7)
    local sc = T[STATE_COLOR[state] or "warning"] or T.textDim
    ZeD.Atoms.drawStatusDot(win, right - sw - dot - px(6), b.y + math.floor((b.h - dot) / 2), sc, dot)
    win:drawText(word, right - sw, b.y + math.floor((b.h - fontH(f3)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f3)
    local room = right - sw - dot - px(18) - x
    win:drawText(ZeD.Atoms.truncateText(e.name, f2, room), x, b.y + math.floor((b.h - fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
end

function IV.picked(win)
    local st = pageState(win, "invite")
    if not st.sel then return nil end
    for _, e in ipairs(st.items or {}) do if e.id == st.sel then return e end end
    return nil
end

MM.pages.invite = {
    W = PAGE_W,
    label = function() return ZeD.btnCase(getText("UI_InviteFriends_Title")) end,
    build = function(win, add, y, w, pad, row)
        local T = ZeD.T
        local st = pageState(win, "invite")
        st.items = IV.items()
        if not IV.picked(win) then st.sel = nil end
        st.statusY = y
        y = y + fontH(T.fontF3) + px(8)
        row = row + 1
        add({ id = "iv:find", x = pad, y = y, w = w - pad * 2, h = px(26), row = row, col = 1, draw = IV.drawFind,
              fn = function() IV.pressFind(win) end, help = tr("UI_ZeD_MMHelp_FriendFind") })
        y = y + px(26) + px(8)
        st.room = roomFor(y, 0)
        if #st.items == 0 then
            st.emptyY = y
            y = y + px(ROW_H)
        else
            st.emptyY = nil
            y, row = listSpecs(win, add, st, st.items, y, w, pad, row, ivId,
                function(e) st.sel = e.id; MM.clickSound() end, IV.drawRow, tr("UI_ZeD_MMHelp_FriendRow"))
        end
        return y + pad, row
    end,
    band = function(win)
        local g = IV.game()
        local e = IV.picked(win)
        local btns = { { id = "back", text = getText("UI_btn_back"), fn = function() MM.leavePage(win); MM.clickSound() end, help = tr("UI_ZeD_MMHelp_BackPause") } }
        if g and g.isCoopHost then
            local allowed = e and g.invited and g.invited[safe(function() return e.friend:getSteamID() end, "")]
            btns[#btns + 1] = { id = "allow", text = getText(allowed and "UI_InviteFriends_ButtonDeny" or "UI_InviteFriends_ButtonAllow"), disabled = e == nil,
                fn = function() if e then MM.clickSound(); pcall(g.toggleAllowDeny, g, e.index) end end, help = tr("UI_ZeD_MMHelp_InviteAllow") }
        end
        btns[#btns + 1] = { id = "invite", text = getText("UI_InviteFriends_ButtonInvite"), variant = "primary", disabled = e == nil,
            fn = function()
                if not (e and g and g.listbox) then return end
                MM.clickSound()
                local st = pageState(win, "invite")
                pcall(function()
                    g.listbox.selected = e.index
                    g:clickInvite()
                end)
                st.said, st.saidAt = getText("UI_InviteFriends_Invited", e.name), now()
            end, help = tr("UI_ZeD_MMHelp_Invite") }
        return btns, nil
    end,
    draw = function(win)
        local T = ZeD.T
        local st = pageState(win, "invite")
        local pad = px(12)
        local d = T.textDim
        -- the game's own line after an invitation ("%1 invited!"), for three seconds as the game shows it
        if st.said and now() - (st.saidAt or 0) < 3000 then
            local c = T.positive or T.text
            ZeD.Atoms.drawStatusDot(win, pad, (st.statusY or 0) + math.floor((fontH(T.fontF3) - px(7)) / 2), c, px(7))
            win:drawText(st.said, pad + px(13), st.statusY or 0, T.text.r, T.text.g, T.text.b, T.text.a or 1, T.fontF3)
        end
        if st.emptyY then
            win:drawText(tr((st.find or "") ~= "" and "UI_ZeD_MM_NoFriendsFound" or "UI_ZeD_MM_NoFriends"), pad, st.emptyY + math.floor((px(ROW_H) - fontH(T.fontF2)) / 2), d.r, d.g, d.b, d.a or 1, T.fontF2)
        end
        listBar(win, st, "iv")
    end,
    joyDir = function(win, dir) local st = pageState(win, "invite"); return listJoy(win, st, st.items or {}, dir, ivId) end,
    wheel = function(win, del) listWheel(pageState(win, "invite"), del) end,
    -- the game keeps its invited.ini when its screen goes back: so here, on leaving the page
    leave = function(win)
        local g = IV.game()
        if g and g.saveInvitedFile then pcall(g.saveInvitedFile, g) end
        local st = pageState(win, "invite")
        st.said = nil
        IV.hideFind(win)
    end,
}

-- ---------------------------------------------------------------------------
-- OPENING A PAGE (MM.act.players / MM.act.invite). False: the game's own screen opens instead.
-- ---------------------------------------------------------------------------
--- Show page name ("players" / "invite") in the pause window; false when it cannot
--- (no pause window, Safe mode, or no InviteFriends object yet).
function MM.openPage(name)
    local w = MM.pause
    if not (w and MM.pages[name]) then return false end
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on() then return false end
    if w.page and w.page ~= name then MM.leavePage(w) end
    if name == "players" then
        PL.heard = false
        PL.ask(true)
    elseif name == "invite" then
        if not IV.game() then return false end
        IV.fill(pageState(w, "invite").find)
    end
    local st = pageState(w, name)
    st.off, st.ask = 0, nil
    w.page = name
    w.focusId = nil
    w.confirm = false
    MM.clickSound()
    return true
end

--- A hook for QA scripts and simulations: fill the list as the game's scoreboard reply would.
function PL.qaFill(list) PL.list = list or {}; PL.heard = true end

return PL
