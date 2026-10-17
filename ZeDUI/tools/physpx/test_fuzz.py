"""Presses every control of every appliance plate in random order, power cut and restored, time passing: no Lua error,
the heat always on a stop, the timer in range, every display readout fitting its glass."""
import os, sys, random
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import test_appliance as TA

OVEN_TEMPS = {0, 50, 100, 150, 200, 250, 300}
MW = {50, 70, 90, 110, 130}
bad = 0
for pid in TA.TILES:
    rnd = random.Random(hash(pid) & 0xffff)
    for celsius in (False, True):
        v = TA.View(pid, celsius=celsius, hour=rnd.randrange(24), minute=rnd.randrange(60))
        ids = list(v.zones())
        for step in range(400):
            r = rnd.random()
            try:
                if r < 0.05:
                    v.stove.powered = not v.stove.powered; v.render()
                elif r < 0.15:
                    v.tick(rnd.choice([1, 30, 61, 600, 3700]))
                elif r < 0.2:
                    v.o.ms(rnd.choice([500, 7000, 21000])); v.render()
                else:
                    z = v.zones()
                    if not z: v.render(); continue
                    i = rnd.choice(list(z))
                    if z[i].kind == "turn" and rnd.random() < 0.5: v.wheel(i, rnd.random() < 0.5)
                    else: v.click(i, rnd.choice([-1, 1]))
            except Exception as e:
                print("ERROR", pid, step, e); bad += 1; break
            ps = v.ps()
            temps = MW if pid.startswith("mw_") else OVEN_TEMPS
            if v.stove.temp not in temps and v.stove.temp != 0:
                print("BAD heat", pid, v.stove.temp); bad += 1; break
            cap = 3600 if pid.startswith("mw_") else 7200
            if not (0 <= v.stove.timer - v.stove.isRunningFor(v.stove) <= cap + 1) and v.stove.timer != 0:
                print("BAD timer", pid, v.stove.timer, v.stove.isRunningFor(v.stove)); bad += 1; break
            txt = ps.mwText if pid.startswith("mw_") else ps.vfdText
            cells = len([c for c in str(txt) if c != "."])
            if cells > 5:
                print("BAD readout", pid, txt); bad += 1; break
        print(f"{pid:16s} celsius={celsius} 400 steps, heat {v.stove.temp}, timer {v.stove.timer}, readout {txt!r}")
print("problems:", bad)
sys.exit(1 if bad else 0)
