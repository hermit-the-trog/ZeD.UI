"""The generator and propane grill cards, outside the game: the real ObjectCards framework and the two card kinds over
mocked vanilla objects. Each generator item gets its plate; the engine switch and the outlet do vanilla's calls with
vanilla's rules; the grill's knob, igniter and cart work; pictures of each for review.
usage: python test_cards.py"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import orgtest as OT          # noqa: E402

FRAME = r'''
local function derive(base, name) local c = {}; c.__index = c; c.Type = name; setmetatable(c, { __index = base }); c.derive = derive; return c end
ISPanel = { derive = derive }
function ISPanel:new(x, y, w, h) return { x = x, y = y, width = w, height = h } end
ISBaseTimedAction = { derive = derive, new = function(self, c) return {} end, stop = function() end, perform = function() end }
ZeD_ScrollbarState = { new = function() return make_scroll() end }
ZeD.Atoms.drawStatusRing = function(p, x, y, c, sz) p:drawRect(x, y, sz, 1, 1, c.r, c.g, c.b) end
ZeD.Atoms.wrapText = function(s) return { s } end
ZeD.btnCase = function(s) return s end
Perks = { Electricity = "Electricity" }
Fluid = { Petrol = "Petrol" }
CharacterStat = { ENDURANCE = "endurance" }
ZeD.Text.draw = function() return 0 end
ZeD.Text.zoomPx = function(px) return 1 end
ZeD.Font = { sdf = {} }

function jlist(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end

-- vanilla's handlers: logged, and they change the mocks the way the game would
ISWorldObjectContextMenu = {
    onActivateGenerator = function(_, on, g, pn) py_log("onActivateGenerator", tostring(on)); g.on = on end,
    onPlugGenerator = function(_, g, pn, plug) py_log("onPlugGenerator", tostring(plug)); g.conn = plug end,
    onFixGenerator = function() py_log("onFixGenerator") end,
    onTakeGenerator = function() py_log("onTakeGenerator") end,
    doAddFuelGenerator = function() py_log("doAddFuelGenerator") end,
}
ISBBQMenu = {
    onToggle = function(_, pn, o) py_log("bbq onToggle"); o.lit = not o.lit end,
    onInsertPropaneTank = function(_, pn, o, tank) py_log("bbq onInsertPropaneTank"); o.tank = true; o.fuel = 900; SPARE = nil end,
    onRemovePropaneTank = function(_, pn, o) py_log("bbq onRemovePropaneTank"); o.tank = false; o.lit = false end,
    FindPropaneTank = function(p, o) return SPARE end,
    onExtinguish = function() end,
}

function make_player(elec)
    local p = {}
    function p:getPerkLevel() return elec and 3 or 0 end
    function p:isRecipeActuallyKnown() return false end
    function p:getPlayerNum() return 0 end
    function p:getInventory() return { getFirstTypeRecurse = function() return nil end, getAllEvalRecurse = function() return jlist({}) end } end
    return p
end
getScriptManager = function() return { FindItem = function(_, t) return { getDisplayName = function() return "Generator (" .. tostring(t) .. ")" end, getNormalTexture = function() return nil end } end } end

function make_generator(itemType)
    local g = { _cls = "IsoGenerator", on = false, conn = false, fuel = 6.5, max = 10, cond = 80, base = 0.02, items = {} }
    function g:getFuel() return self.fuel end
    function g:getMaxFuel() return self.max end
    function g:getFuelPercentage() return self.fuel / self.max * 100 end
    function g:getCondition() return self.cond end
    function g:isActivated() return self.on end
    function g:isConnected() return self.conn end
    function g:getBasePowerConsumption() return self.base end
    function g:getTotalPowerUsing() local t = self.base; for _, it in ipairs(self.items) do t = t + it[2] end; return t end
    function g:getTotalPowerUsingString() return string.format("%.4f L/h", self:getTotalPowerUsing()) end
    function g:getBasePowerConsumptionString() return string.format("%.4f L/h", self.base) end
    function g:getItemsPowered() local l = {}; for _, it in ipairs(self.items) do l[#l + 1] = it[1] .. string.format(" (%.4f L/h)", it[2]) end; return jlist(l) end
    function g:getGeneratorItemType() return itemType end
    function g:getSquare() return { isOutside = function() return true end, getBuilding = function() return nil end, getX = function() return 5 end, getY = function() return 5 end, getZ = function() return 0 end } end
    function g:getObjectIndex() return 1 end
    return g
end

function make_bbq()
    local o = { lit = false, tank = false, fuel = 0 }
    function o:isLit() return self.lit end
    function o:hasPropaneTank() return self.tank end
    function o:hasFuel() return self.tank and self.fuel > 0 end
    function o:getFuelAmount() return self.tank and self.fuel or 0 end
    function o:getTileName() return "Propane Barbecue" end
    function o:getContainer() return { getItems = function() return jlist({}) end } end
    function o:getSpriteName() return "appliances_cooking_01_36" end
    function o:isPropaneBBQ() return true end
    function o:isFireInteractionObject() return true end
    function o:getSquare() return { getObjects = function() return jlist({ o }) end, getX = function() return 6 end, getY = function() return 6 end, getZ = function() return 0 end } end
    function o:getObjectIndex() return 1 end
    return o
end

-- the card: a panel the body draws on, its zones, the controller's focus
function make_card(w, h)
    local c = make_panel(w, h)
    c._zones = {}
    function c:zone(z) self._zones[#self._zones + 1] = z end
    return c
end
'''


class Card:
    def __init__(s, kind):
        s.o = OT.Org([], w=480, h=640)
        s.o.lua(FRAME)
        for f in ("ObjectCards.lua",):
            s.o.L.execute(open(os.path.join(OT.STAGED, f), "rb").read())
        s.o.L.execute(open(os.path.join(OT.SRC, "ObjectCardPower.lua" if kind == "generator" else "ObjectCardFire.lua"), "rb").read())
        s.OC = s.o.g.ZeD.ObjectCards
        s.def_ = s.OC.kinds[kind]
        s.kind = kind

    def show(s, t, player, h=640):
        s.def_.refresh(t, player)
        s.o.new_paint(480, h)
        card = s.o.g.make_card(480, h)
        card._fid = s.o.g.FOCUS_ID
        hh = s.def_.body(card, 10, 10, 460, t, player)
        s.card = card
        return hh

    def zones(s):
        return {z.fid: z for z in s.card._zones.values()}

    def press(s, fid, t, player):
        z = s.zones()[fid]
        if z.run: z.run(s.card, player)
        s.o.ms(200)
        return bool(z.run)


FAILS = []


def check(what, got, want):
    ok = got == want
    print(("  ok   " if ok else "  FAIL ") + f"{what}: {got!r}" + ("" if ok else f" (want {want!r})"))
    if not ok: FAILS.append(what)


def generators():
    for item, want in (("Base.Generator", "gen_red"), ("Base.Generator_Yellow", "gen_yellow"), ("Base.Generator_Blue", "gen_blue"),
                       ("Base.Generator_Old", "gen_old"), ("Mod.SuperGenerator", "gen_red")):
        c = Card("generator")
        g = c.o.g.make_generator(item)
        t = c.o.L.table_from({"obj": g})
        player = c.o.g.make_player(True)
        c.show(t, player)
        tex = sorted(p for p in c.o.paint.cache if "physpx" in p)
        check(f"{item} plate", tex[0].split("/")[-1], want + ".png")
        z = c.zones()
        check(f"{item} plate controls", sorted(k for k in z if k.startswith("gen:")), ["gen:engine", "gen:outlet"])
        check(f"{item} engine while disconnected does nothing", c.press("gen:engine", t, player), False)
        check(f"{item} outlet connects", (c.press("gen:outlet", t, player), bool(g.conn)), (True, True))
        c.show(t, player)
        check(f"{item} engine starts", (c.press("gen:engine", t, player), bool(g.on)), (True, True))
        g.items = c.o.L.table_from([c.o.L.table_from(["Fridge", 0.08]), c.o.L.table_from(["Freezer", 0.08]), c.o.L.table_from(["Lights", 0.04])])
        c.show(t, player)
        texts = [x[0] for x in c.o.paint.texts]
        check(f"{item} run time line", "RUN TIME LEFT" in texts and "29:32 HRS" in texts, True)
        check(f"{item} outlet while running does nothing", c.press("gen:outlet", t, player), False)
        # the load meter: calibrated to vanilla's figures (a fridge and freezer + lights 0.20 L/h above idle = 0.4 of
        # the scale); past full scale the OVERLOAD lamp lights
        ps = c.o.L.eval("ZeD.ObjectCardPower.plateState")
        def load_of(extra_items):
            g.items = c.o.L.table_from([c.o.L.table_from([n, v]) for n, v in extra_items])
            d = c.o.L.table_from({"on": True, "conn": True, "fuel": 6.5, "max": 10, "cond": 80, "base": 0.02,
                                  "total": g.getTotalPowerUsing(g)})
            st = ps(d)
            return round(st.load, 3), bool(st.overload)
        check(f"{item} load: fridge, freezer, lights", load_of([("Fridge", 0.08), ("Freezer", 0.08), ("Lights", 0.04)]), (0.4, False))
        check(f"{item} load: a whole house", load_of([("Fridge and freezer", 0.13), ("Stove", 0.09), ("Washer", 0.09),
                                                     ("Dryer", 0.09), ("TV", 0.03), ("Lights", 0.03)]), (0.92, False))
        check(f"{item} load: two houses pin it and light OVERLOAD", load_of([("Fridge and freezer", 0.26), ("Stove", 0.18),
                                                     ("Washers and dryers", 0.36)]), (1.0, True))
        g.items = c.o.L.table_from([c.o.L.table_from(["Fridge", 0.08]), c.o.L.table_from(["Freezer", 0.08]), c.o.L.table_from(["Lights", 0.04])])
        g.cond = 10
        c.show(t, player)
        c.o.paint.image().save(os.path.join(HERE, "out", f"org_{want}_{item.split('.')[-1]}.png"))
        check(f"{item} engine stops", (c.press("gen:engine", t, player), bool(g.on)), (True, False))
        player2 = c.o.g.make_player(False)
        c.show(t, player2)
        check(f"{item} outlet needs the skill", c.press("gen:outlet", t, player2), False)


def grill():
    c = Card("fire")
    b = c.o.g.make_bbq()
    t = c.def_.resolve(None, b)
    player = c.o.g.make_player(True)
    c.show(t, player)
    check("grill plate controls", sorted(k for k in c.zones() if k.startswith("bbq:")), ["bbq:burner", "bbq:ignite", "bbq:tank"])
    check("grill no tank, none carried: the cart does nothing", c.press("bbq:tank", t, player), False)
    c.o.g.SPARE = c.o.L.table()
    c.show(t, player)
    check("grill a tank carried: the cart takes it", (c.press("bbq:tank", t, player), bool(b.tank)), (True, True))
    c.show(t, player)
    check("grill the igniter lights it", (c.press("bbq:ignite", t, player), bool(b.lit)), (True, True))
    c.show(t, player)
    check("grill the igniter while lit does nothing", c.press("bbq:ignite", t, player), False)
    for _ in range(100):
        c.o.ms(120); c.show(t, player)
    check("grill thermometer warmed up in 12 s", round(t._grillT, 2) > 0.6, True)
    texts = [x[0] for x in c.o.paint.texts]
    check("grill gas line", "15:00 HRS" in texts, True)
    c.o.paint.image().save(os.path.join(HERE, "out", "org_grill_propane.png"))
    check("grill the centre knob shuts it off", (c.press("bbq:burner", t, player), bool(b.lit)), (True, False))
    c.show(t, player)
    check("grill the cart gives the tank back", (c.press("bbq:tank", t, player), bool(b.tank)), (True, False))


if __name__ == "__main__":
    generators()
    grill()
    print(f"{len(FAILS)} failed", FAILS)
    sys.exit(1 if FAILS else 0)
