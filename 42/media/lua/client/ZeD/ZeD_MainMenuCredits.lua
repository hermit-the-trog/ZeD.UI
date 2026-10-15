-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuCredits.lua
-- ============================================================================
-- CREDITS ON THE MONITOR (HOOK_MAP row 26; director, Oct 14 2026: menus
-- delegated, no mockups)
--
-- Vanilla's credits (CreditsRoleGroup / CreditsRole, the translators, the
-- studio logos) as end titles rolling up a framed box in a ZeD window: each
-- group's title in the heading face, its logo tinted to the theme, each role
-- in the mono label face, the names in the body face, all centred. The strip
-- is a 1993 transport: BACK | <<  PAUSE / PLAY  >>. The wheel moves the roll
-- by hand. Vanilla's CreditsScreen:setVisible(true) is redirected here.
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui

-- design units
local SPEED = 36                  -- pixels a second at normal speed
local FAST, REWIND = 6, -3        -- multiples of it
local GROUP_GAP, ROLE_GAP, LOGO_H, FADE_H = 64, 26, 110, 40

local function headFont()
    local T = ZeD.T
    local hf = ZeD.Font.sdf.head
    return hf, 20 * (T.scale or 1) / (hf.face or 64)
end

-- vanilla's credits as lines: { kind = "group" | "role" | "name" | "logo", text | tex }
local function creditLines()
    local lines = {}
    local function add(kind, v) lines[#lines + 1] = { kind = kind, text = (kind ~= "logo") and v or nil, tex = (kind == "logo") and v or nil } end
    -- the opening: vanilla's own words and the studio's logo
    local start = getText("credits_start") or ""
    local img = start:match("<IMAGECENTRE:([^>]+)>")
    local words = UI.plain(start:gsub("<IMAGECENTRE:[^>]+>", ""))
    if words ~= "" then add("group", words) end
    if img then add("logo", img) end
    local ok = pcall(function()
        local groups = CreditsRoleGroup.getAll()
        for i = 0, groups:size() - 1 do
            local g = groups:get(i)
            add("group", getText(g:getTitle()))
            if g:getLogo() then add("logo", g:getLogo()) end
            local roles = g:getRoles()
            for j = 0, roles:size() - 1 do
                local role = roles:get(j)
                if role == CreditsRole.LOCALIZATION then
                    local langs = {}
                    for lang, list in pairs(CreditsRole.getTranslatorCredits()) do langs[#langs + 1] = { lang = tostring(lang), list = list } end
                    table.sort(langs, function(a, b) return a.lang < b.lang end)
                    for _, l in ipairs(langs) do
                        add("role", l.lang)
                        for k = 0, l.list:size() - 1 do add("name", tostring(l.list:get(k))) end
                    end
                else
                    local title = getTextOrNull(role:getTitle()) or ""
                    if title ~= "" then add("role", title) end
                    local names = role:getNames()
                    for k = 0, names:size() - 1 do add("name", tostring(names:get(k):getName())) end
                end
            end
        end
    end)
    if not ok then print("[ZeD] credits: could not read the credits list") end
    add("group", getText("credits_spiffos_url"))
    return lines
end

-- ============================================================================
ZeD_MMCredits = ZeD_MMWindow:derive("ZeD_MMCredits")

function ZeD_MMCredits:new()
    local o = ZeD_MMWindow.new(self, "credits")
    o.noResetControl = true
    o.roll = 0
    o.mode = "play"       -- "play" | "pause" | "fast" | "rewind"
    return o
end

function ZeD_MMCredits:onShow()
    self.lines = self.lines or creditLines()
    self.roll = nil   -- (set on the first frame: the titles start a third of the way up, not below an empty box)
    self.mode = "play"
    self._t = nil
    self.focusId = "play"
end

function ZeD_MMCredits:setMode(m)
    if self.mode == m then m = "play" end   -- a second press on << or >> goes back to playing
    self.mode = m
    MM.clickSound()
end

function ZeD_MMCredits:togglePause()
    if self.mode == "pause" then self.mode = "play" else self.mode = "pause" end
    MM.clickSound()
end

function ZeD_MMCredits:back()
    MM.clickSound()
    MM.showView("main")
end

-- lays the lines out once per width (heights in window pixels)
function ZeD_MMCredits:layout(w)
    local T = ZeD.T
    local key = w .. ":" .. tostring(T.fontF2) .. ":" .. tostring(T.scale)
    if self._layoutKey == key then return self._total end
    self._layoutKey = key
    local hf, z = headFont()
    local headH = math.floor(ZeD.Text.height(hf, z))
    local y = 0
    local prev = nil
    for _, l in ipairs(self.lines or {}) do
        if l.kind == "group" then
            if prev then y = y + T.px(GROUP_GAP) end
            l.y, l.h = y, headH
            y = y + headH + T.px(14)
        elseif l.kind == "logo" then
            l.y, l.h = y, T.px(LOGO_H)
            y = y + l.h + T.px(16)
        elseif l.kind == "role" then
            if prev and prev.kind ~= "group" and prev.kind ~= "logo" then y = y + T.px(ROLE_GAP) end
            l.y, l.h = y, MM.fontH(T.fontF1)
            y = y + l.h + T.px(8)
        else
            l.y, l.h = y, MM.fontH(T.fontF2)
            y = y + l.h + T.px(4)
        end
        prev = l
    end
    self._total = y
    return y
end

function ZeD_MMCredits:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local w, h = UI.placeOnTube(self)
    self.lines = self.lines or creditLines()
    self.title = "Project Zomboid  +  Credits"
    self.titleStats = {}
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = T.px(U.STRIP_BTN_H) + T.px(U.STRIP_PAD_Y) * 2
    local stripY = h - self:footerHeight() - stripH
    local bx, by, bw, bh = pad, tb + pad, w - pad * 2, stripY - tb - pad * 2
    UI.insetBox(self, bx, by, bw, bh)
    local vy, vh = by + T.px(1), bh - T.px(2)
    local total = self:layout(bw)

    -- the roll: the titles enter at the bottom and leave at the top; it stops on the last line
    local t = MM.now()
    local dt = self._t and math.min(0.1, (t - self._t) / 1000) or 0
    self._t = t
    local mult = 1
    if self.mode == "pause" then mult = 0 elseif self.mode == "fast" then mult = FAST elseif self.mode == "rewind" then mult = REWIND end
    if self.roll == nil then self.roll = math.floor(vh * 0.35) end
    self.roll = self.roll + dt * T.px(SPEED) * mult
    local maxRoll = total + math.floor(vh / 2)
    if self.roll >= maxRoll then self.roll = maxRoll; if self.mode ~= "rewind" then self.mode = "pause" end end
    if self.roll <= 0 then self.roll = 0; if self.mode == "rewind" then self.mode = "play" end end
    self._box = { x = bx, y = vy, w = bw, h = vh }

    local top = vy + vh - self.roll   -- the first line's place
    local cx = bx + math.floor(bw / 2)
    local hf, z = headFont()
    local tc, ac = T.textHead, T.accent
    local f1, f2 = T.fontF1, T.fontF2
    self:setStencilRect(bx + T.px(1), vy, bw - T.px(2), vh)
    for _, l in ipairs(self.lines) do
        local ly = top + (l.y or 0)
        if ly + (l.h or 0) > vy and ly < vy + vh then
            if l.kind == "group" then
                local tw = ZeD.Text.width(hf, l.text, z)
                ZeD.Text.draw(self, hf, l.text, cx - math.floor(tw / 2), ly, z, tc.r, tc.g, tc.b, tc.a or 1, "l")
            elseif l.kind == "logo" then
                local tex = l.tex and getTexture(l.tex) or nil
                if tex then
                    local lw = math.min(bw - T.px(40), T.px(LOGO_H) * 2)
                    self:drawTextureScaledAspect(tex, cx - math.floor(lw / 2), ly, lw, l.h, 1, tc.r, tc.g, tc.b)
                end
            elseif l.kind == "role" then
                local text = string.upper(l.text)
                self:drawText(text, cx - math.floor(MM.textW(f1, text) / 2), ly, ac.r, ac.g, ac.b, ac.a or 1, f1)
            else
                local c = T.text
                self:drawText(l.text, cx - math.floor(MM.textW(f2, l.text) / 2), ly, c.r, c.g, c.b, c.a or 1, f2)
            end
        end
    end
    -- the edges fade into the box (stepped, as a 1993 screen would)
    local b = T.base
    local steps = 8
    local fh = T.px(FADE_H)
    for i = 0, steps - 1 do
        local a = 1 - (i / steps)
        local sh = math.ceil(fh / steps)
        self:drawRect(bx + T.px(1), vy + i * sh, bw - T.px(2), sh, a, b.r, b.g, b.b)
        self:drawRect(bx + T.px(1), vy + vh - (i + 1) * sh, bw - T.px(2), sh, a, b.r, b.g, b.b)
    end
    self:clearStencilRect()

    -- the transport
    UI.stripSpecs(self, stripY, w, 1000,
        { { "back", "BACK", function() self:back() end } },
        { { "rewind", "<<", function() self:setMode("rewind") end, (self.mode == "rewind") and "primary" or "default" },
          { "play", (self.mode == "pause") and "PLAY" or "PAUSE", function() self:togglePause() end },
          { "fast", ">>", function() self:setMode("fast") end, (self.mode == "fast") and "primary" or "default" } })
    self._stripY, self._stripH = stripY, stripH
end

function ZeD_MMCredits:render()
    UI.drawStripAndButtons(self, self._stripY, self._stripH, nil)
    ZeD_Window.render(self)
end

-- CONTROLLER + KEYS + WHEEL ------------------------------------------------------------
function ZeD_MMCredits:joyA() self:togglePause() end
function ZeD_MMCredits:joyB() self:back() end
function ZeD_MMCredits:joyX() self:setMode("fast") end
function ZeD_MMCredits:joyY() self:setMode("rewind") end
function ZeD_MMCredits:joyDir(dir)
    if dir == "up" or dir == "down" then
        self.roll = math.max(0, (self.roll or 0) + ((dir == "down") and 1 or -1) * ZeD.T.px(80))
        return
    end
    ZeD_MMWindow.joyDir(self, dir)
end

function ZeD_MMCredits:getFooterPrompts()
    if not MM.gamepad() then return nil end
    return { { glyph = "A", label = (self.mode == "pause") and "Play" or "Pause" }, { glyph = "X", label = "Fast" },
             { glyph = "Y", label = "Rewind" }, { glyph = "B", label = "Back" } }
end

function ZeD_MMCredits:keyEscape() self:back(); return true end
function ZeD_MMCredits:keyOther(key)
    if key == Keyboard.KEY_SPACE or key == Keyboard.KEY_RETURN then self:togglePause(); return true end
    if key == Keyboard.KEY_RIGHT then self:setMode("fast"); return true end
    if key == Keyboard.KEY_LEFT then self:setMode("rewind"); return true end
    return false
end

function ZeD_MMCredits:close() self:back() end

function ZeD_MMCredits:wheel(del)
    self.roll = math.max(0, (self.roll or 0) + del * ZeD.T.px(48))
    return true
end
function ZeD_MMCredits:onMouseWheel(del) return MM.wheel(del) end

local _wheel = MM.wheel
function MM.wheel(del)
    if MM.view == "credits" and MM.root and MM.root.creditsWin then return MM.root.creditsWin:wheel(del) end
    return _wheel(del)
end

-- on the desk as the "credits" view; vanilla's creditsScreen:setVisible(true) lands here
MM.addView("credits", "creditsWin", function() return ZeD_MMCredits:new() end, "creditsScreen")
