-- ZeDUI/tools/qa/zedqa_grid_off.lua  (Oct 30 2026, QA; director, Oct 30: the QA save's grid "switch it off")
-- The QA save with no grid power: the sandbox's ElecShutModifier to 0 (the power is shut from the start)
-- and the world's power flag off. Tests that need power raise both for their run and put back what they
-- found, so after this they put back "off". The game writes both when it saves on the way out.
-- grep "ZEDQA grid".
local so = getSandboxOptions()
local o = so and so:getOptionByName("ElecShutModifier")
local was, hydroWas = o and o:getValue(), getWorld():isHydroPowerOn()
if o then o:setValue(0); pcall(function() so:toLua() end) end
getWorld():setHydroPowerOn(false)
print(string.format("ZEDQA grid ElecShutModifier %s -> %s | power on %s -> %s", tostring(was), tostring(o and o:getValue()),
    tostring(hydroWas), tostring(getWorld():isHydroPowerOn())))
local n = 0
local function later() n = n + 1; if n < 30 then return end; Events.OnTick.Remove(later); print("ZEDQA grid DONE") end
Events.OnTick.Add(later)
