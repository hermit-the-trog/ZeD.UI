-- ZeDUI/tools/qa/bubbles_mono_sim.lua (Nov 11 2026, punch list 158): the balloons' lines in Fira Mono Regular, as said.
-- Loads ZeD_Bubbles.lua with a stand-in ZeD.Text (8 screen px a character at zoom 1 on a 64 face) and checks the case,
-- the measure, the draw call, the box and that RtvFace keeps the 5 x 7 face. Run from the repo root: lua5.1 <this>
function require() end
function getTimestampMs() return 1000 end
ZeD = { upper = string.upper }
local drawn = {}
ZeD.Px = { textWidth = function(s) return #tostring(s) * 6 end, k = function() return 1 end,
           rect = function() end, rects = function() end, text = function(_, s) drawn[#drawn + 1] = { px = s } end }
ZeD.PixelFonts = {}
ZeD.Font = { sdf = { stat = { font = "TitleSDF", face = 64, sdf = true } } }
ZeD.Text = {
    realTM = function() return {} end,
    width = function(f, s, z) return #tostring(s) * 64 * 0.6 * z end,      -- Fira Mono: 0.6 em a character
    draw = function(el, f, s, x, y, z, r, g, b, a, align) drawn[#drawn + 1] = { s = s, f = f, x = x, y = y, z = z, a = a, align = align } end,
}
assert(loadfile("42/media/lua/client/ZeD/ZeD_Bubbles.lua"))()
local B = ZeD.Bubbles
local pass, fail = 0, 0
local function ok(c, m, d) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. m .. (d ~= nil and (" (" .. tostring(d) .. ")") or "")) end end
ok(B.clean("Ahh. That's the stuff.") == "Ahh. That's the stuff.", "the case as said")
ok(B.clean("  <RGB:1,0,0>Hi  [img=x]there ") == "Hi there", "markup off, spaces collapsed, case kept", B.clean("  <RGB:1,0,0>Hi  [img=x]there "))
ok(B.textW("abcde") == math.ceil(5 * 0.6 * B.FONT_PX), "a line measures in Fira Mono at FONT_PX units", B.textW("abcde"))
local sp = B.say(0, "Ahh. That's the stuff.")
ok(sp.text == "Ahh. That's the stuff.", "say keeps the case")
ok(sp.tw <= B.SPEECH_MAXW, "the widest line fits the balloon", sp.tw)
local long = B.say(0, string.rep("word ", 40))
for i, l in ipairs(long.lines) do ok(B.textW(l) <= B.SPEECH_MAXW, "wrapped line " .. i .. " fits") end
ok(B.boxH(1) == B.LINE + (B.PAD - B.TRIM) * 2, "one line's box")
ok(B.boxH(3) - B.boxH(2) == B.LINE, "a line more adds the pitch")
drawn = {}
local cv = { el = {}, ox = 100, oy = 200, k = 2 }
B.drawLine(cv, "Hello", 10, 20, { r = 1, g = 1, b = 1 }, 0.5, "c")
local d = drawn[1]
ok(d and d.s == "Hello" and d.f == ZeD.Font.sdf.stat, "drawn in the Mono Regular entry")
ok(d and d.x == 120 and d.y == 200 + (20 - B.TRIM) * 2, "at the canvas's screen px", d and (d.x .. "," .. d.y))
ok(d and math.abs(d.z - B.FONT_PX * 2 / 64) < 1e-9, "zoom: FONT_PX times k on the 64 face", d and d.z)
ok(d and d.a == 0.5 and d.align == "c", "alpha and alignment pass through")
local lines = B.wrap("one two three four five six seven", 40, true)
local px = true
for _, l in ipairs(lines) do if #l * 6 > 40 and l:find(" ") then px = false end end
ok(px, "pixel wrap measures in the 5 x 7 face")
local src = io.open("42/media/lua/client/ZeD/RtvFace.lua"):read("*a")
ok(src:find("ZeD.Bubbles.wrap(l, maxw, true)", 1, true) ~= nil, "RtvFace's screens wrap in the face they draw in")
-- without ZeD.Text: the 5 x 7 face, as before
ZeD.Text = nil
drawn = {}
B.drawLine({ el = {}, ox = 0, oy = 0, k = 1 }, "x", 0, 0, { r = 1, g = 1, b = 1 }, 1, "l")
ok(drawn[1] and drawn[1].px == "x", "no ZeD.Text: the pixel face draws")
ok(B.textW("abc") == 18, "no ZeD.Text: the pixel face measures")
print(string.format("bubbles_mono_sim: %d pass, %d fail", pass, fail))
os.exit(fail == 0 and 0 or 1)
