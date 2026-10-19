-- ZeDUI/tools/qa/zedqa_titlevideo.lua  (Oct 19 2026)
-- At the main menu: plays vanilla's Build 42 title video (title_screen_background.bik)
-- full screen, undimmed, over everything, and captures frames for the main menu colour
-- grade (director: "color grade our main menu graphic to match the game's current
-- vanilla main menu graphic"). Then removes itself and captures ZeD's desk for
-- comparison. Screenshots zqa_tv_<n>.png, zqa_tv_desk.png. grep "ZEDQA tv".
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local ok, vid = pcall(getVideo, "title_screen_background.bik", 1280, 720)
if not (ok and vid) then print("ZEDQA tv no video"); return end
local P = ISUIElement:new(0, 0, sw, sh)
P:initialise(); P:instantiate()
P.javaObject:setConsumeMouseEvents(false)
P.render = function(self)
    self:drawRect(0, 0, sw, sh, 1, 0, 0, 0)
    vid:RenderFrame()
    self:drawTextureScaled(vid, 0, 0, sw, sh, 1, 1, 1, 1)
end
P:addToUIManager()
P:setAlwaysOnTop(true)
local n, shots = 0, { [90] = 1, [240] = 2, [420] = 3, [600] = 4, [780] = 5 }
local function t()
    n = n + 1
    if shots[n] then pcall(function() getCore():TakeFullScreenshot("zqa_tv_" .. shots[n] .. ".png") end); print("ZEDQA tv frame " .. shots[n]) end
    if n == 800 then P:removeFromUIManager() end
    if n == 840 then pcall(function() getCore():TakeFullScreenshot("zqa_tv_desk.png") end) end
    if n == 850 then print("ZEDQA tv DONE"); Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
print("ZEDQA tv start")
