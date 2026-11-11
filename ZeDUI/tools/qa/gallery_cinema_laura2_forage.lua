CLAU2_ONLY = "forage"; print("ZEDQA clonly forage"); local n=0; local function f() n=n+1; if n<5 then return end; Events.OnTick.Remove(f); print("ZEDQA clonly DONE") end; Events.OnTick.Add(f)
