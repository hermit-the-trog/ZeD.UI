#!/bin/bash
# Renders the dashboard plates (2x, transparent) and dumps their anchor JSON.
# usage: render_dash_plates.sh   -> 42/media/textures/ZeD/dash/*.png + ZeDUI/tools/plates/out/*.json
ROOT=/c/Users/danie/Zomboid/mods/ZeD-UI
E="/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
PAGE=$(cygpath -m "$ROOT/ZeDUI/tools/plates/plates_dash.html")
OUT=$(cygpath -m "$ROOT/42/media/textures/ZeD/dash"); JOUT="$ROOT/ZeDUI/tools/plates/out"; mkdir -p "$JOUT"
PROF=$(cygpath -m "$ROOT/ZeDUI/tools/plates/edgeprof")
render(){ name="$1"; query="$2"; w="$3"; h="$4"
  "$E" --headless --disable-gpu --hide-scrollbars --no-first-run --user-data-dir="$PROF" --default-background-color=00000000 --force-device-scale-factor=2 --window-size=$w,$h --screenshot="$OUT/$name.png" "file:///$PAGE?$query" >/dev/null 2>&1
  "$E" --headless --disable-gpu --no-first-run --user-data-dir="$PROF" --dump-dom "file:///$PAGE?$query" 2>/dev/null | perl -ne 'if(/ANCHORS_BEGIN(.*?)ANCHORS_END/){ print $1; }' > "$JOUT/$name.json"
  printf '%s %s %s\n' "$name" "$(stat -c %s "$ROOT/42/media/textures/ZeD/dash/$name.png" 2>/dev/null)" "$(wc -c < "$JOUT/$name.json")"
}
for h in arch square trap; do render "body_$h" "layer=body&hood=$h" 800 172; done
for s in analog c4 cadillac toyota; do render "cluster_$s" "layer=cluster&style=$s" 500 76; done
render "switches" "layer=switches" 230 30
for k in luxury sedan sport fleet truck modern; do render "console_$k" "layer=console&kind=$k" 260 134; done
for k in none makeshift; do render "headunit_$k" "layer=headunit&kind=$k" 252 52; done
for k in chrome oval script stencil stamped decal; do render "badge_$k" "layer=badge&kind=$k" 150 12; done
