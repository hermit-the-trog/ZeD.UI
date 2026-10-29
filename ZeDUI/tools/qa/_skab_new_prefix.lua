-- sets the capture prefix for zedqa_skills_ab.lua (the NEW file run); DONE a tick later, as the runner counts it
SKAB_PREFIX = "skn"
local function t() print("ZEDQA skabq DONE"); Events.OnTick.Remove(t) end
Events.OnTick.Add(t)
