-- ZeDUI/tools/qa/zedqa_menu_note.lua  (Nov 5 2026, QA; e5129c44, punch list 86): the change note on the corkboard. The headings
-- from the version strings; a picture of the note as it is (this copy's version reads DEV), with a forced BETA 4 heading, on a
-- lamp dip, and with a line over ten characters. Everything is put back. Pictures zqa_nte_<WxH>_<n>.png. grep "ZEDQA nte".
local function say(s) print("ZEDQA nte " .. tostring(s)) end
local MM = ZeD.MainMenu
local SZ = getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight()
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_nte_" .. SZ .. "_" .. n .. ".png") end) end
local orig = MM.drawNote
local keepLine, keepV = ZeD.MenuNote[1], MM.zedVersion
local gotDip, L0 = false, nil
MM.drawNote = function(p, L, dipped)
    L0 = L
    orig(p, L, dipped)
    if dipped and WANT_DIP and not gotDip then gotDip = true; WANT_DIP = nil; shot("dip"); say("a lamp dip caught") end
end
local plan, i, n = {}, 1, 0
local function add(frames, fn) plan[#plan + 1] = { f = frames, fn = fn } end
add(60, function()
    for _, v in ipairs({ "0.3.0-beta4", "0.3.0-beta3a", "1.0.0", "0.3.0-t2", "1242300k", "" }) do say("heading of '" .. v .. "': " .. tostring(MM.noteHeading(v))) end
    say("this copy reads " .. tostring(MM.noteHeading(MM.zedVersion())) .. " (version " .. tostring(MM.zedVersion()) .. ")")
    say(string.format("the desk at multiple %s, origin %s,%s, screen %s, lean %s", tostring(L0 and L0.s), tostring(L0 and L0.ox), tostring(L0 and L0.oy), SZ, tostring(L0 and L0.lean)))
    say("the note's left edge on screen " .. tostring(L0 and (L0.ox + 52 * L0.s)) .. ", right edge " .. tostring(L0 and (L0.ox + 92 * L0.s)))
    shot("dev")
    MM.zedVersion = function() return "0.3.0-beta4" end
    MM._note = nil
end)
add(20, function() shot("beta4"); ZeD.MenuNote[1] = "ABCDEFGHIJKLMNOP"; MM._note = nil end)
add(20, function() shot("cut"); ZeD.MenuNote[1] = keepLine; MM._note = nil; WANT_DIP = true end)
local waited = 0
local function drive()
    local st = plan[i]
    if not st then
        waited = waited + 1
        if gotDip or waited > 60 * 45 then
            if not gotDip then say("no lamp dip within 45 s") end
            Events.OnFETick.Remove(drive)
            WANT_DIP = nil
            MM.zedVersion = keepV; MM._note = nil
            MM.drawNote = orig
            say("DONE")
        end
        return
    end
    n = n + 1
    if n < st.f then return end
    n = 0; i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnFETick.Add(drive)
