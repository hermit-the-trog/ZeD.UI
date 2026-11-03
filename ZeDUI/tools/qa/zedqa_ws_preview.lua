-- ZeDUI/tools/qa/zedqa_ws_preview.lua  (Nov 3 2026, QA; Build's e3ed7aed: the Workshop preview at 512 x 512)
-- MAIN MENU ONLY, pushed by ws_preview_run.ps1. Opens ZeD's Workshop upload page on the ZeD-UI folder and reads its
-- preview line as formTop draws it: the picture's size, the dot (green when the game takes the size) and the words.
-- Also asks the game's own uploader rule when it can be reached. Looks only: the page is shut with Back, nothing is
-- saved and Upload is never pressed. grep "ZEDQA wsp"; shot zqa_wsp_page.png.
local MM = ZeD and ZeD.MainMenu
local function say(s) print("ZEDQA wsp " .. tostring(s)) end
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
if not (MM and MM.showView) then say("ERR ZeD's main menu is not loaded"); say("DONE"); return end
local Q, qi, wait = {}, 1, nil
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function W() return MM.root and MM.root.workshopWin end

step(2, function()
    pcall(function() Mouse.setXY(getCore():getScreenWidth() - 4, getCore():getScreenHeight() - 4) end)
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    MM.showView("workshop")
end)
step(40, function()
    local w = W()
    if not check(w ~= nil and w:isVisible(), "the Workshop upload page opens") then return end
    local names = {}
    for i, it in ipairs(w.items or {}) do
        local n = tostring(it:getFolderName()); names[#names + 1] = n
        if n == "ZeD-UI" and w.sel ~= i then w:pick(i) end
    end
    say("folders: " .. table.concat(names, ", "))
end)
step(40, function()
    local w = W()
    if not w then return end
    local it = w:item()
    check(it ~= nil and tostring(it:getFolderName()) == "ZeD-UI", "the page is on the ZeD-UI folder")
    local tex = w._pvTex
    local tw, th = tex and tex:getWidthOrig(), tex and tex:getHeightOrig()
    say("preview " .. tostring(it and it:getPreviewImage()) .. ": " .. tostring(tw) .. " x " .. tostring(th))
    check(tw == 512 and th == 512, "the picture reads 512 x 512")
    local good = tex and tw == th and (tw == 256 or tw == 512)
    check(good, "the dot is green (a size the game takes)")
    local words = ZeD.tr("UI_ZeD_Workshop_PictureOk", tw, th)
    say("the words: " .. tostring(words))
    check(tostring(words):find("512 x 512", 1, true) ~= nil and tostring(words):find("1000 KB", 1, true) ~= nil,
        "the words name 512 x 512 and the 1000 KB limit")
    local ok, v = pcall(function() return it:validatePreviewImage(it:getPreviewImage()) end)
    say("the game's own check (SteamWorkshopItem.validatePreviewImage): " .. (ok and tostring(v) or ("not reached: " .. tostring(v))))
    if ok and type(v) == "boolean" then check(v, "the game's uploader takes the picture") end
    local blk = w:blocker()
    say("what keeps it from going up: " .. tostring(blk or "nothing"))
    pcall(function() getCore():TakeFullScreenshot("zqa_wsp_page.png") end)
    say("shot zqa_wsp_page")
end)
step(10, function()
    local w = W()
    if w then pcall(function() w:back() end) end
    if fails == 0 then say("summary: all " .. passes .. " PASS") else say("summary: " .. fails .. " of " .. (passes + fails) .. " checks FAIL") end
end)
step(20, function() say("DONE") end)

local function tick()
    local s = Q[qi]
    if not s then Events.OnFETick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnFETick.Add(tick)
say("start")
