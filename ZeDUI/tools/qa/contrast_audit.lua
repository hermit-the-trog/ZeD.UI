-- ZeDUI/tools/qa/contrast_audit.lua  (Nov 20 2026, QA): a static check, no game. Every base theme x accent x
-- status set through ZeD.buildColors (Tokens.lua), then the contrast of every text color on every surface it is
-- drawn on, composited as the game draws it (text alpha over the surface, the surface over a mid-gray world where
-- it is see-through). Prints one line per pair under its floor and a summary.
-- Run (LuaJIT or Lua 5.1, from the repo root):
--   lua ZeDUI/tools/qa/contrast_audit.lua
-- Floors: body and secondary text 4.5 : 1, dim and grayed text 3.0 : 1, an accent used as words 3.0 : 1 (large or
-- bold), words on an accent or status fill 4.5 : 1.
UIFont = setmetatable({}, { __index = function(_, k) return k end })
dofile("42/media/lua/shared/ZeD/Tokens.lua")

local function lin(v) return (v <= 0.03928) and (v / 12.92) or (((v + 0.055) / 1.055) ^ 2.4) end
local function lum(c) return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b) end
local function over(top, under, a)
    a = a or top.a or 1
    return { r = top.r * a + under.r * (1 - a), g = top.g * a + under.g * (1 - a), b = top.b * a + under.b * (1 - a), a = 1 }
end
local function ratio(fg, bg)
    local a, b = lum(fg), lum(bg)
    if a < b then a, b = b, a end
    return (a + 0.05) / (b + 0.05)
end
-- the world behind a see-through surface: the worst case of a dark night street and a bright noon lawn
local WORLDS = { { r = 0.05, g = 0.05, b = 0.06, a = 1 }, { r = 0.55, g = 0.60, b = 0.45, a = 1 } }

local bases = { "dark", "light", "hicon" }
local accents = {}
for k in pairs(ZeD.AccentColors) do accents[#accents + 1] = k end
table.sort(accents)
local statuses = { "standard", "cb" }
local SURFS = { "base", "surf1", "surf2", "surf3", "surf4" }
local TEXTS = {
    { "text", 4.5 }, { "textHead", 4.5 }, { "textSec", 4.5 }, { "textDim", 3.0 },
    { "accentText", 4.5 }, { "positiveText", 4.5 }, { "dangerText", 4.5 }, { "warningText", 4.5 }, { "infoText", 4.5 },
    -- (the raw status and accent colors: dots, tags and lamps, never words; 3 : 1 as a graphic)
    { "accent", 3.0 }, { "positive", 3.0 }, { "danger", 3.0 }, { "warning", 3.0 }, { "info", 3.0 },
    { "markBlue", 3.0 }, { "markRed", 3.0 }, { "markGold", 3.0 },
}
local bad, n = {}, 0
local function note(key, line) if not bad[key] then bad[key] = line end end

for _, b in ipairs(bases) do
    for _, a in ipairs(accents) do
        for _, s in ipairs(statuses) do
            local T = {}
            local ok, err = pcall(ZeD.buildColors, T, b, a, s)
            if not ok then print("ERR buildColors " .. b .. " " .. a .. " " .. s .. ": " .. tostring(err)); break end
            for _, sn in ipairs(SURFS) do
                local surf = T[sn]
                if surf then
                    for _, w in ipairs(WORLDS) do
                        -- (Light and High contrast draw solid: applyTheme forces it; only Dark is see-through)
                        local bg = over(surf, w, (b == "dark") and (surf.a or 1) or 1)
                        for _, tx in ipairs(TEXTS) do
                            local c = T[tx[1]]
                            if type(c) == "table" and c.r then
                                n = n + 1
                                local r = ratio(over(c, bg, c.a or 1), bg)
                                if r < tx[2] then
                                    note(table.concat({ b, a, s, tx[1], sn }, "|"),
                                        string.format("%-6s %-7s %-8s %-12s on %-5s %.2f : 1 (floor %.1f)", b, a, s, tx[1], sn, r, tx[2]))
                                end
                                -- grayed text: the same color at the theme's disabled alpha
                                if tx[1] == "text" and T.disabledAlpha then
                                    local rd = ratio(over(c, bg, (c.a or 1) * T.disabledAlpha), bg)
                                    if rd < 3.0 then
                                        note(table.concat({ b, a, s, "disabled", sn }, "|"),
                                            string.format("%-6s %-7s %-8s %-12s on %-5s %.2f : 1 (floor 3.0)", b, a, s, "text grayed", sn, rd))
                                    end
                                end
                            end
                        end
                        -- a selected row: the accent at selectionA over the surface, body text on it
                        if T.accent and T.selectionA and T.text then
                            local sel = over(T.accent, bg, T.selectionA)
                            local r = ratio(over(T.text, sel, T.text.a or 1), sel)
                            if r < 4.5 then
                                note(table.concat({ b, a, s, "sel", sn }, "|"),
                                    string.format("%-6s %-7s %-8s %-12s on %-5s %.2f : 1 (floor 4.5)", b, a, s, "text/selected", sn, r))
                            end
                        end
                        -- a colored folder row (ZeD_MMMods.FOLDER_TINT_A 0.18): every accent's wash under body text
                        for _, fa in ipairs(accents) do
                            local set = ZeD.AccentColors[fa]
                            local tone = set[(b == "light") and "light" or "dark"] or set.dark
                            if tone and tone.accent and T.text then
                                local wash = over(tone.accent, bg, 0.18)
                                local r = ratio(over(T.text, wash, T.text.a or 1), wash)
                                if r < 4.5 then
                                    note(table.concat({ b, "folder", fa, sn }, "|"),
                                        string.format("%-6s folder %-7s wash, text on %-5s %.2f : 1 (floor 4.5)", b, fa, sn, r))
                                end
                            end
                        end
                    end
                end
            end
            -- words on the accent fill (a primary button, a lit tab)
            if T.accent and T.textOnAccent then
                local r = ratio(T.textOnAccent, T.accent)
                if r < 4.5 then
                    note(table.concat({ b, a, s, "onAccent" }, "|"),
                        string.format("%-6s %-7s %-8s textOnAccent on accent %.2f : 1 (floor 4.5)", b, a, s, r))
                end
            end
        end
    end
end
local lines = {}
for _, l in pairs(bad) do lines[#lines + 1] = l end
table.sort(lines)
for _, l in ipairs(lines) do print(l) end
print(string.format("contrast_audit: %d pairs checked, %d under their floor", n, #lines))
