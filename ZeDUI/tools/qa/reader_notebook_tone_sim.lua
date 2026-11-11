-- ZeDUI/tools/qa/reader_notebook_tone_sim.lua (Nov 11 2026, QA's Mac shoot): a print read in the reader, then a
-- notebook in the same window, must not lay the print's paper tone (a grey box) over the notebook.
-- Loads ZeD_Reader's prerender and render with stand-ins. Run from the repo root: lua5.1 <this>
local f = assert(io.open("42/media/lua/client/ZeD/ZeD_Reader.lua")); local src = f:read("*a"); f:close()
local pass, fail = 0, 0
local function ok(c, m) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. m) end end
local function cut(name)
    local a = src:find("function ZeD_Reader:" .. name .. "()", 1, true); assert(a, name)
    local b = src:find("\nend\n", a, true)
    return src:sub(a, b + 4)
end
local hidden, toned, vrender = 0, 0, 0
local env = {
    ZeD = { T = {}, paperToneOver = function() toned = toned + 1 end },
    P = { vanillaHide = function() hidden = hidden + 1 end, vanillaRender = function() vrender = vrender + 1 end },
    ZeD_Window = { render = function() end },
    ZeD_Reader = {},
}
local chunk = "local ZeD, P, ZeD_Window, ZeD_Reader = ...\n" .. cut("prerender") .. "\n" .. cut("render") .. "\nreturn ZeD_Reader"
local R = assert(loadstring(chunk))(env.ZeD, env.P, env.ZeD_Window, env.ZeD_Reader)
local r = setmetatable({ mode = "notebook", _vanillaPage = true, _pageTone = { x = 10, y = 26, w = 400, h = 600 },
    place = function() end, prerenderNotebook = function() return "nb" end }, { __index = R })
ok(r:prerender() == "nb", "a notebook draws the notebook")
ok(r._vanillaPage == false and r._pageTone == nil and hidden == 1, "the print's page left from before is taken off")
r:render()
ok(toned == 0 and vrender == 0, "no paper tone and no print page over the notebook")
r._vanillaPage, r._pageTone = true, { x = 0, y = 0, w = 1, h = 1 }
r:render()
ok(toned == 0, "render alone never tones a notebook")
r.mode = "print"
r:render()
ok(toned == 1 and vrender == 1, "a print still gets its tone")
print(string.format("reader_notebook_tone_sim: %d pass, %d fail", pass, fail))
os.exit(fail == 0 and 0 or 1)
