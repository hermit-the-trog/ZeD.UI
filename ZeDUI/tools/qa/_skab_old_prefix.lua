-- sets the capture prefix for zedqa_skills_ab.lua (the OLD file run); DONE a tick later, as the runner counts it
SKAB_PREFIX = "sko"
local function t() print("ZEDQA skabp DONE"); Events.OnTick.Remove(t) end
Events.OnTick.Add(t)
