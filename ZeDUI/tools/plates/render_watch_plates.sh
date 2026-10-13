#!/bin/bash
ROOT=/c/Users/danie/Zomboid/mods/ZeD-UI
E="/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
PAGE=$(cygpath -m "$ROOT/ZeDUI/tools/plates/plates_watch.html")
OUT=$(cygpath -m "$ROOT/42/media/textures/ZeD/watch"); JOUT="$ROOT/ZeDUI/tools/plates/out_watch"; mkdir -p "$JOUT"
PROF=$(cygpath -m "$ROOT/ZeDUI/tools/plates/edgeprof")
render(){ name="$1"; query="$2"; w="$3"; h="$4"
  "$E" --headless --disable-gpu --hide-scrollbars --no-first-run --user-data-dir="$PROF" --default-background-color=00000000 --force-device-scale-factor=2 --window-size=$w,$h --screenshot="$OUT/$name.png" "file:///$PAGE?$query" >/dev/null 2>&1
  "$E" --headless --disable-gpu --no-first-run --user-data-dir="$PROF" --dump-dom "file:///$PAGE?$query" 2>/dev/null | perl -ne 'if(/ANCHORS_BEGIN(\{.*\})ANCHORS_END/){ print $1; }' > "$JOUT/$name.json"
  printf '%s %s %s\n' "$name" "$(stat -c %s "$ROOT/42/media/textures/ZeD/watch/$name.png" 2>/dev/null)" "$(wc -c < "$JOUT/$name.json")"
}
for v in black red dress gold; do render "digital_$v" "kind=digital&variant=$v" 124 176; done
for v in black brown gold military; do render "classic_$v" "kind=classic&variant=$v" 150 176; done
render "expensive" "kind=expensive" 150 176
