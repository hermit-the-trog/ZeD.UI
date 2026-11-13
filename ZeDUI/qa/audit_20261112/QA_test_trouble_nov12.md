# QA's test-trouble notes, Nov 12 2026 (for the audit plan)
- Animals sit in a small fenced pen on the drag strip, so every walk hops a fence. Move them to a real farm.
- The far walk-up is flaky.
- The "0 animals" zone beside "1 Hen" is probably the hen's spawn spot.
- The ram row was out of view at 4K and in German.
- The blue "QA Pen" overlay shows in the Radio and Vehicle captures.
- ZeD's console was left open from saved positions in every capture (the prelude now closes it).
- Summer Car needed Strength 5 and a forced ECU flag to stage.
- The director, Nov 12: sessions open with windows in the wrong place from saved positions, so screenshots aren't accurate; tests that shift windows leave them shifted for the next test. Plan: the prelude puts every window at its default layout once at session start (the layout reset, plus close the console). Any test that moves, resizes, pins or folds a window snapshots the layout first and puts it back when it ends, on error too. That's instant, with no full reset after every test and no added time. Screenshot steps check the layout is the default before capturing.
