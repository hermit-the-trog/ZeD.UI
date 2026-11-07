-- ZeDUI/tools/qa/mp_clip_report.lua  (Nov 7 2026, QA): what mp_clip_hook.lua counted since it was set or last reported. grep "ZEDQA mcr".
local c = ZEDQA_CLIPS
if not c then print("ZEDQA mcr ERR no hook"); print("ZEDQA mcr DONE"); return end
local w = {}
for k, v in pairs(c.worst) do w[#w + 1] = k .. "=" .. v end
print(string.format("ZEDQA mcr %d frames counted: %d left clips in the Character window, %d in the World window%s", c.frames, c.char, c.world,
    #w > 0 and (" (" .. table.concat(w, ", ") .. ")") or ""))
print("ZEDQA mcr " .. ((c.char + c.world == 0 and c.frames > 0) and "PASS" or "FAIL") .. " every frame ends with the clips it began with")
c.char, c.world, c.frames, c.worst = 0, 0, 0, {}
print("ZEDQA mcr DONE")
