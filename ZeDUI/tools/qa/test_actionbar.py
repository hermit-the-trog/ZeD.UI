"""ZeD_ActionBar.lua outside the game: the real module with the mod's real pixel faces and pixel shelf
(PixelFonts.lua, ZeD_PixelParts.lua) under LuaJIT, the engine stubbed: timed actions, the queue, the clock.
Plays the scenarios through the hooks and the per-frame state, checks what the bar says, and renders both
modes to PNG for the eye. usage: python test_actionbar.py [ZeD_ActionBar.lua]"""
import os, sys
import numpy as np
from PIL import Image
import lupa.luajit21 as lj

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "ZeD_ActionBar.lua")
UP = "/mnt/user-data/uploads/ZeD-UI/42/media/lua/client/ZeD"
FAILS = []
def check(what, ok, detail=""):
    print(("  ok   " if ok else "  FAIL ") + what + ("" if ok else "  " + str(detail)))
    if not ok: FAILS.append(what)

STUB = r'''
ZeD = {}
CLOCK = 1000000
function getTimestampMs() return CLOCK end
function instanceof(o, c) return type(o) == "table" and o._class == c end
Events = setmetatable({}, { __index = function(t, k) local e = { Add = function() end }; t[k] = e; return e end })
function require() end
function print() end
-- theme tokens (Tokens.lua, dark + orange)
local function hx(h, a) local n = tonumber(h:sub(2), 16); return { r = math.floor(n / 65536) % 256 / 255, g = math.floor(n / 256) % 256 / 255, b = n % 256 / 255, a = a or 1 } end
ZeD.T = { base = hx("#0C0C0C", .92), surf1 = hx("#141414", .92), surf2 = hx("#1C1C1C", .92), surf3 = hx("#242424", .92),
          borderS = hx("#383838"), text = { r = .855, g = .855, b = .855, a = .90 }, positive = hx("#7A9A34"),
          accent = hx("#D4922A"), accentBright = hx("#E8A830") }
function ZeD.colorSync(t, s, a) t.r, t.g, t.b, t.a = s.r, s.g, s.b, a or s.a end
ZeD.Settings = { actionBarOption = { v = 1, getValue = function(self) return self.v end } }
ZeD.Scale = { root = function() return 1 end }
-- vanilla's base action and queue, as far as the module touches them
ISBaseTimedAction = {}
ISBaseTimedAction.__index = ISBaseTimedAction
function ISBaseTimedAction:derive(t) local c = setmetatable({}, { __index = self }); c.Type = t; c.__index = c; return c end
function ISBaseTimedAction:create()
    local me = self
    self.action = { delta = 0, started = false, useBar = (self.useProgressBar ~= false),
                    setUseProgressBar = function(a, v) a.useBar = v end }
end
function ISBaseTimedAction:getJobDelta() return self.action.delta end
function ISBaseTimedAction:isStarted() return self.action and self.action.started end
function ISBaseTimedAction:perform() ISTimedActionQueue.getTimedActionQueue(self.character):onCompleted(self) end
function ISBaseTimedAction:stop() ISTimedActionQueue.getTimedActionQueue(self.character):resetQueue() end
function ISBaseTimedAction:begin() self:create(); self.action.started = true end
ISTimedActionQueue = { queues = {} }
ISTimedActionQueue.__index = ISTimedActionQueue
function ISTimedActionQueue.getTimedActionQueue(chr)
    local q = ISTimedActionQueue.queues[chr]
    if not q then q = setmetatable({ queue = {}, character = chr }, ISTimedActionQueue); ISTimedActionQueue.queues[chr] = q end
    return q
end
function ISTimedActionQueue:onCompleted(a)
    for i, v in ipairs(self.queue) do if v == a then table.remove(self.queue, i); break end end
    if self.queue[1] then self.queue[1]:begin() end
end
function ISTimedActionQueue:resetQueue() for k in pairs(self.queue) do self.queue[k] = nil end end
function queueAdd(chr, a) local q = ISTimedActionQueue.getTimedActionQueue(chr); table.insert(q.queue, a); if #q.queue == 1 then a:begin() end end
-- a character and actions
PLAYER = { _class = "IsoPlayer", isLocalPlayer = function() return true end, getPlayerNum = function() return 0 end }
function mkAction(typ, maxTime, item, extra)
    local cls = ISBaseTimedAction:derive(typ)
    local o = setmetatable({}, cls); o.Type = typ; o.character = PLAYER; o.maxTime = maxTime
    if item then o.item = { getDisplayName = function() return item end } end
    for k, v in pairs(extra or {}) do o[k] = v end
    return o
end
-- the UI side: ZeD_Panel / ISUIElement, drawing into a list of rects
ISUIElement = { drawRect = function(self, x, y, w, h, a, r, g, b) table.insert(self._rects, { x, y, w, h, a, r, g, b }) end }
ZeD_Panel = { derive = function(self, n) local c = setmetatable({}, { __index = self }); c.__index = c; return c end,
              new = function(self, x, y, w, h) return { x = x, y = y, width = w, height = h, _rects = {} } end }
ZeD_Panel.__index = ZeD_Panel
'''

def load(mode=1):
    L = lj.LuaRuntime(unpack_returned_tuples=True)
    L.execute(STUB)
    L.execute(open(os.path.join(UP, "PixelFonts.lua"), encoding="latin-1").read())
    L.execute(open(os.path.join(UP, "ZeD_PixelParts.lua"), encoding="latin-1").read())
    L.execute(open(SRC).read())
    L.execute(f"ZeD.Settings.actionBarOption.v = {mode}")
    return L

def state(L):
    st = L.eval("ZeD.ActionBar.state(PLAYER, 0)")
    if st is not None: L.execute("ZeD.ActionBar._last[0] = ZeD.ActionBar.state(PLAYER, 0)")
    return st

def vtext(L, st):
    return tuple(L.globals().ZeD.ActionBar.verboseText(st))

print("hooks and vanilla's bar")
L = load()
L.execute("A = mkAction('ISReadABook', 300, 'The Herbalist'); queueAdd(PLAYER, A)")
check("the engine's bar is switched off at create", L.eval("A.action.useBar") is False)
check("ZeD's bar wanted for a normal action", L.eval("A._zedBar") is True)
L.execute("B = mkAction('ISAttachItemHotbar', 30, 'Hammer', { useProgressBar = false }); B:create()")
check("vanilla's useProgressBar = false keeps no bar", L.eval("B._zedBar") is False)
L.execute("C = mkAction('ISForageAction', 100, nil); C:create()")
check("foraging (switches itself off in start) keeps no bar", L.eval("C._zedBar") is False)

print("reading: walk there, read, done")
L = load()
L.execute("W = mkAction('ISWalkToTimedAction', -1); R = mkAction('ISReadABook', 300, 'The Herbalist'); queueAdd(PLAYER, W); queueAdd(PLAYER, R)")
st = state(L)
check("walking first", st.phase == "walk" and st.label == "WALKING" and st.next == "READING", (st.phase, st.next))
check("verbose while walking: WALKING / THEN READING", vtext(L, st) == ("WALKING", "", "THEN READING", ""), vtext(L, st))
L.execute("W:perform()")
check("a walk that arrives is not an end", L.eval("ZeD.ActionBar._ends[0]") is None)
L.execute("R.action.delta = 0.62")
st = state(L)
check("reading at 62%", st.phase == "work" and st.label == "READING" and abs(st.frac - .62) < 1e-9 and st.qn == 1)
check("verbose: READING / THE HERBALIST 62%", vtext(L, st) == ("READING", "", "THE HERBALIST", "62%"), vtext(L, st))
L.execute("R.action.delta = 1; R:perform()")
e = L.eval("ZeD.ActionBar._ends[0]")
check("done when the book is finished", e is not None and e.st.phase == "done", e and e.st.phase)
check("verbose done: DONE / THE HERBALIST 100%", vtext(L, e.st) == ("DONE", "", "THE HERBALIST", "100%"), vtext(L, e.st))

print("ripping 12 sheets: one job")
L = load()
L.execute("""RS = {} for i = 1, 12 do RS[i] = mkAction('ISRipClothing', 120, 'Sheet'); queueAdd(PLAYER, RS[i]) end""")
st = state(L)
check("1 of 12 at the start", st.qi == 0 and st.qn == 12, (st.qi, st.qn))
check("ISRipClothing labelled RIPPING", st.label == "RIPPING CLOTHING" or st.label == "RIPPING", st.label)
for i in range(1, 4):
    L.execute(f"RS[{i}].action.delta = 1; RS[{i}]:perform()")
    check(f"rip {i} done is not the job's end", L.eval("ZeD.ActionBar._ends[0]") is None)
    st = state(L)
L.execute("RS[4].action.delta = 0.4")
st = state(L)
check("the 4th of 12, 40% into it", st.qi == 3 and st.qn == 12 and abs(st.frac - .4) < 1e-9, (st.qi, st.qn, st.frac))
check("verbose: <label> 4/12 / SHEET 40%", vtext(L, st)[1:] == ("4/12", "SHEET", "40%"), vtext(L, st))
L.execute("ISTimedActionQueue.getTimedActionQueue(PLAYER).queue[1]:stop()")
e = L.eval("ZeD.ActionBar._ends[0]")
check("STOP mid-job: stopped, grey, at the 4th", e is not None and e.st.phase == "stopped" and e.st.qi == 3, e and e.st.phase)
check("verbose stopped: STOPPED 4/12 / SHEET 40%", vtext(L, e.st) == ("STOPPED", "4/12", "SHEET", "40%"), vtext(L, e.st))

print("looting: walks between items of the same kind")
L = load()
L.execute("""Q = { mkAction('ISInventoryTransferAction', 50, 'Hammer'), mkAction('ISWalkToTimedAction', -1),
              mkAction('ISInventoryTransferAction', 50, 'Battery'), mkAction('ISInventoryTransferAction', 50, 'Socks') }
              for _, a in ipairs(Q) do queueAdd(PLAYER, a) end""")
st = state(L)
check("1 of 3 (the walk between does not count or break the job)", st.qi == 0 and st.qn == 3 and st.item == "HAMMER", (st.qi, st.qn, st.item))
L.execute("Q[1].action.delta = 1; Q[1]:perform()")
check("moving on to the walk is not the end", L.eval("ZeD.ActionBar._ends[0]") is None)
st = state(L)
check("walking between: phase walk, THEN MOVING", st.phase == "walk" and st.next == "MOVING", (st.phase, st.next))
L.execute("Q[2]:perform()")
st = state(L)
check("after the walk: 2 of 3, BATTERY", st.qi == 1 and st.qn == 3 and st.item == "BATTERY", (st.qi, st.qn, st.item))

print("resting: no end, quiet")
L = load()
L.execute("RE = mkAction('ISRestAction', -1); queueAdd(PLAYER, RE)"); state(L)
L.execute("CLOCK = CLOCK + 42000")
st = state(L)
check("no end: no percent, the time so far", st.noend and vtext(L, st) == ("RESTING", "", "", "0:42"), vtext(L, st))
L.execute("RE:stop()")
e = L.eval("ZeD.ActionBar._ends[0]")
check("getting up: gone, no flash", e is not None and e.st.phase == "gone", e and e.st.phase)

print("B42's merged transfer: one action, a list of steps")
L = load()
L.execute("""T = mkAction('ISInventoryTransferAction', 50, 'Sheet')
    T.queueList = { { items = { T.item } } }
    O = {} for i = 2, 6 do O[i] = mkAction('ISInventoryTransferAction', 50, 'Item' .. i); queueAdd(PLAYER, O[i]) end
    ISTimedActionQueue.getTimedActionQueue(PLAYER).queue = { T, O[2], O[3], O[4], O[5], O[6] }
    T:begin()
    -- vanilla's merge at the first perform: the queued transfers move into T's list
    function mergeStep()
        local q = ISTimedActionQueue.getTimedActionQueue(PLAYER).queue
        while q[2] do table.insert(T.queueList, { items = { q[2].item } }); table.remove(q, 2) end
        table.remove(T.queueList, 1)
        if T.queueList[1] then T.item = T.queueList[1].items[1]; T.action.delta = 0 else T:perform() end
    end""")
st = state(L)
check("merged: 1 of 6 before the merge", st.qi == 0 and st.qn == 6, (st.qi, st.qn))
for i in range(3): L.execute("mergeStep()"); st = state(L)
L.execute("T.action.delta = 0.5"); st = state(L)
check("merged: the 4th of 6 after three steps, ITEM4", st.qi == 3 and st.qn == 6 and st.item == "ITEM4", (st.qi, st.qn, st.item))
L.execute("table.insert(T.queueList, { items = { T.item, T.item } })"); st = state(L)
check("two more queued mid-job: the total grows to 8", st.qi == 3 and st.qn == 8, (st.qi, st.qn))
check("no end yet while steps remain", L.eval("ZeD.ActionBar._ends[0]") is None)

print("instant and unstarted")
L = load()
L.execute("I = mkAction('ISOpenCloseDoor', 1); queueAdd(PLAYER, I)")
check("an instant action (maxTime 1) shows nothing", state(L) is None)
L.execute("ISTimedActionQueue.getTimedActionQueue(PLAYER):resetQueue(); X = mkAction('ISReadABook', 300, 'Book'); X:create()")
L.execute("X:stop()")
check("stopping an action that never started is no end", L.eval("ZeD.ActionBar._ends[0]") is None)

print("labels for every vanilla action")
L = load()
acts = open("/tmp/acts_all.txt").read().split()
labels = {a: L.eval(f"ZeD.ActionBar.LABELS['{a}'] or ZeD.ActionBar.autoLabel('{a}')") for a in acts}
font57 = set(L.eval("(function() local t = {} for k in pairs(ZeD.PixelFonts['57']) do if #k == 1 and k:byte() < 128 then t[#t+1] = k end end return table.concat(t) end)()"))
bad = [a for a, l in labels.items() if not l or any(ch not in font57 for ch in l)]
check(f"{len(labels)} labels, every letter in the 5 x 7 face", not bad, bad[:8])
long_ = [(a, l) for a, l in labels.items() if L.eval(f"ZeD.Px.textWidth('{l}', '57', 1)") > 84]
check("no label wider than 84 units (14 letters)", not long_, long_[:6])
auto = [a for a in acts if L.eval(f"ZeD.ActionBar.LABELS['{a}']") is None]
check("every vanilla action has a written label", not auto, auto[:8])
for name, want in (("ISRepairGunAction", "REPAIRING GUN"), ("MyModOvenThing", "WORKING"), ("ISChopLogsAction", "CHOPPING LOGS"),
                   ("ISSitOnStool", "SITTING ON") , ("ISFixRadioFromKit", "FIXING RADIO")):
    got = L.eval(f"ZeD.ActionBar.autoLabel('{name}')")
    check(f"a mod's {name} -> {want}", got == want or (want == "SITTING ON" and got == "SITTING"), got)
open(os.path.join(HERE, "labels.txt"), "w").write("\n".join(f"{a:40s} {l}" for a, l in sorted(labels.items())))
check("a category prefix goes: Book: Far From Home -> FAR FROM HOME", L.eval("ZeD.ActionBar.clean('Book: Far From Home')") == "FAR FROM HOME",
      L.eval("ZeD.ActionBar.clean('Book: Far From Home')"))
check("item names cleaned to the 3 x 5 face, 16 letters", L.eval("ZeD.ActionBar.clean('Bob\\'s Big Book of Wörds')") == "BOB'S BIG BOOK..",
      L.eval("ZeD.ActionBar.clean('Bob\\'s Big Book of Wörds')"))

# ---- render both modes for the eye -------------------------------------------------
def render(mode, st, a=1.0, ms=0):
    L2 = load(mode)
    L2.execute("LAYER = { _rects = {}, drawRect = function(self, x, y, w, h, a, r, g, b) ISUIElement.drawRect(self, x, y, w, h, a * (self._zedAlpha or 1), r, g, b) end }")
    L2.globals().ST = L2.table_from(st)
    fn = "drawSimple" if mode == 2 else "drawVerbose"
    L2.execute(f"""local AB = ZeD.ActionBar
        AB._dim = {{}}; ZeD.colorSync(AB._dim, ZeD.T.text, ZeD.T.text.a * 0.55)
        AB._legend = {{}}; ZeD.colorSync(AB._legend, ZeD.T.text, ZeD.T.text.a * 0.70)
        local st = {{}} for k, v in pairs(ST) do st[k] = v end
        W, H = {'AB.sizeSimple()' if mode == 2 else 'AB.sizeVerbose(st)'}
        AB.{fn}(ZeD.Px.canvas(LAYER, 0, 0, 1), ZeD.T, st, {a}, {ms})""")
    W, H = L2.eval("W"), L2.eval("H")
    img = np.zeros((H, W, 4), np.float32)
    bg = np.array([0.18, 0.14, 0.09])
    out = np.tile(bg, (H, W, 1))
    for r in L2.eval("LAYER._rects").values():
        x, y, w, h, al, rr, gg, bb = [r[i] for i in range(1, 9)]
        out[int(y):int(y + h), int(x):int(x + w)] = out[int(y):int(y + h), int(x):int(x + w)] * (1 - al) + np.array([rr, gg, bb]) * al
    return Image.fromarray((out.clip(0, 1) * 255).astype(np.uint8))

def lt(d): return L.table_from(d)
cases = [
    ("working", {"phase": "work", "label": "READING", "item": "THE HERBALIST", "noend": False, "frac": .62, "qi": 0, "qn": 1, "el": 0}),
    ("queue", {"phase": "work", "label": "RIPPING", "item": "SHEET", "noend": False, "frac": .4, "qi": 3, "qn": 12, "el": 0}),
    ("no end", {"phase": "work", "label": "RESTING", "item": "", "noend": True, "frac": 0, "qi": 0, "qn": 1, "el": 42}),
    ("walking", {"phase": "walk", "label": "WALKING", "next": "READING", "item": "", "noend": True, "frac": 0, "qi": 0, "qn": 1, "el": 0}),
    ("done", {"phase": "done", "label": "READING", "item": "THE HERBALIST", "noend": False, "frac": 1, "qi": 0, "qn": 1, "el": 0}),
    ("stopped", {"phase": "stopped", "label": "READING", "item": "THE HERBALIST", "noend": False, "frac": .62, "qi": 0, "qn": 1, "el": 0}),
]
Lr = load()
rows = []
for name, d in cases:
    imgs = [render(m, d, ms=200) for m in (2, 1)]
    rows.append(imgs)
Z = 4
cw = max(i.width for r in rows for i in r) * Z + 20
ch = max(i.height for r in rows for i in r) * Z + 16
sheet = Image.new("RGB", (cw * 2, ch * len(rows)), (11, 10, 8))
for ri, r in enumerate(rows):
    for ci, im in enumerate(r):
        sheet.paste(im.resize((im.width * Z, im.height * Z), Image.NEAREST), (ci * cw + 10, ri * ch + 8))
sheet.save(os.path.join(HERE, "lua_render.png"))
print(f"{len(FAILS)} failed", FAILS)
