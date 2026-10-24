"""Builds ZeDUI/mockups/zed_dpad_wheels_v2.html (v1 Oct 24, v2 Oct 23 2026: right stick points, Light on Down, Vehicle a World slice).

The director: radial menus for the gamepad, one per D-pad direction, replacing the
game's D-pad wheels. Left = Character, Right = World, Up = Social, Down = quick
settings and actions. Reuses the approved wheel look and its pictures from
zed_wheels_v1.html (the context strip's paper cells on a ring, the bubble above),
and adds ZeD icons from 42/media/textures/ZeD/icons and TabIcons.

Run on the PC's Linux shell (needs Pillow):  python3 build_dpad_wheels.py
"""
import base64
import io
import json
import os
import re

from PIL import Image

ROOT = os.path.expanduser("~/mnt/ZeD-UI")
V1 = os.path.join(ROOT, "ZeDUI/mockups/zed_wheels_v1.html")
OUT = os.path.join(ROOT, "ZeDUI/mockups/zed_dpad_wheels_v2.html")
ICONS = os.path.join(ROOT, "42/media/textures/ZeD/icons")
TABS = os.path.join(ROOT, "42/media/textures/ZeD/TabIcons")

v1 = open(V1, encoding="utf-8").read()


def grab(name):
    m = re.search(r"const " + name + r" = (\{.*?\});\n", v1, re.S)
    return m.group(1)


ZI = json.loads(grab("ZI"))
VI = json.loads(grab("VI"))
BG = {k: v for k, v in re.findall(r'(\w+):"([^"]+)"', grab("BG")) if k in ("foot", "car")}


def png64(path, size=48):
    im = Image.open(path).convert("RGBA")
    im.thumbnail((size, size), Image.LANCZOS)
    c = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    c.paste(im, ((size - im.width) // 2, (size - im.height) // 2), im)
    b = io.BytesIO()
    c.save(b, "PNG", optimize=True)
    return base64.b64encode(b.getvalue()).decode()


NEW_ICONS = {
    "apple": "apple-whole.png", "can": "can-food.png", "bread": "bread.png",
    "bottle": "bottle.png", "juice": "cooking-053-juice.png", "whiskey": "bottle-droplet.png",
    "drink": "water-045-drink.png", "pill": "medication-005-capsule.png",
    "pills2": "medication-025-dosage.png", "meds": "medication.png",
    "bandage": "bandage-wound.png", "gauze": "gauze-bandage.png", "spray": "medication-043-spray.png",
    "needle": "needle.png", "smoke": "smoking.png", "book": "books.png",
    "reader": "book-open-reader.png", "magazine": "library-049-magazine.png",
    "flier": "magazine_r.png", "bed": "bed.png", "alarm": "home-055-alarm-clock.png",
    "radio": "survival-077-radio.png", "shirt": "fi-br-shirt-long-sleeve.png",
    "hood": "hood-cloak.png", "mask": "face-mask.png", "hat": "hat-cowboy.png",
    "boot": "hiking-boot.png", "gun": "gun.png", "knife2": "military-005-knife.png",
    "sit": "sitting-ground.png", "chair": "chair.png", "settings": "settings.png",
    "question": "question.png", "chat": "text-box-dots.png", "handshake": "handshake.png",
    "wave": "fi-br-hand-wave.png", "fist": "fi-br-hand-back-fist.png", "flag": "flag.png",
    "smile": "smile.png", "walk": "person-walking-arrow-right.png", "generator": "doomsday-007-generator.png",
    "stairs": "stairs.png", "backpack": "backpack.png", "campfire": "campfire.png",
    "fast": "rabbit-fast.png", "point": "fi-br-hand-back-point-right.png", "gears": "gears.png",
}
for k, f in NEW_ICONS.items():
    p = os.path.join(ICONS, f)
    if os.path.isfile(p):
        ZI[k] = png64(p)
    else:
        print("missing icon", f)

for t in ("loot", "equipment", "health", "thermal", "identy", "journal", "skills", "radio",
          "craft", "build", "move", "map", "forage", "farm", "vehicle"):
    ZI["tab-" + t] = png64(os.path.join(TABS, t + "-tab-white_48.png"))

HTML = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ZeD-UI — D-pad wheels v2</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Fira+Mono:wght@400;500;700&family=Fira+Sans:wght@400;500;600;700&family=Fira+Sans+Condensed:wght@400;600&display=swap" rel="stylesheet">
<style>
/* ============================================================================
   ZeD-UI — the D-pad wheels, mockup v1 (Oct 24 2026)
   The director: "radial menus for gamepad ... one for the character window
   (D-pad Left) ... a world menu (D-pad Right) with the same premise. Up for
   social. Down for quick settings and actions like sitting on things ... These
   would replace the game's radials."
   The look is the approved wheel (zed_wheels_v1.html, Oct 15): the context
   strip's paper cells on a ring, the pointed cell in the accent, stipple when a
   slice can't be done, the corner triangle on a slice that opens a wheel, the
   System 7 bubble above naming the pointed slice. Geometry is the engine's:
   slice 1 centred at 12 o'clock, clockwise, 360/n each. Every number is a
   design unit (1 px at 1080p). Fira only, no emoji.
   ============================================================================ */
:root {
  --base:#C6C6C6; --text:rgba(12,12,12,.95);
  --accent:#6B5F0A; --accentBright:#998811; --onAccent:#F2F0EC;
  --ink:#141414; --paper:#F2F2F2;
  --mono:'Fira Mono',monospace; --sans:'Fira Sans',sans-serif; --cond:'Fira Sans Condensed',sans-serif;
}
* { margin:0; padding:0; box-sizing:border-box; }
body { background:#0b0a08; color:#d8d8d8; font-family:var(--sans); padding:22px 24px 60px; }
.banner { font-family:var(--mono); font-size:11px; letter-spacing:2px; color:#cfc6a8; text-transform:uppercase; }
h1 { font-family:var(--cond); font-weight:600; font-size:24px; color:#f0ece0; margin:4px 0 6px; }
.lede { font-size:13px; line-height:1.55; color:#b9b4a6; max-width:1060px; }
.controls { display:flex; flex-wrap:wrap; gap:14px 22px; margin:16px 0 14px; align-items:flex-start; }
.ctl { display:flex; flex-direction:column; gap:5px; }
.ctl > span { font-family:var(--mono); font-size:10px; letter-spacing:1.5px; color:#8f8a7c; text-transform:uppercase; }
.seg { display:flex; flex-wrap:wrap; gap:4px; max-width:1240px; }
.seg button { font-family:var(--mono); font-size:11px; color:#d8d4c8; background:#1c1b18; border:1px solid #3a3832; padding:4px 9px; cursor:pointer; }
.seg button.on { background:#d8c070; color:#111; border-color:#d8c070; }
.seg button:disabled { opacity:.35; cursor:default; }
.swatches { display:flex; gap:4px; }
.swatches button { width:20px; height:20px; border:1px solid #3a3832; cursor:pointer; }
.swatches button.on { outline:2px solid #f0ece0; outline-offset:1px; }
.stage-wrap { overflow:auto; padding-bottom:6px; }
.stage { position:relative; width:1280px; height:780px; border:1px solid #2a2924; background:#20301a 0 0 / 1280px 780px no-repeat; overflow:hidden; cursor:crosshair; user-select:none; }
.caption { font-family:var(--mono); font-size:11px; color:#8f8a7c; margin-top:8px; max-width:1240px; line-height:1.5; min-height:34px; }
.caption b { color:#efe6c4; font-weight:500; }

/* the wheel: the context strip's cells on a ring */
.ring { position:absolute; border:1px solid rgba(20,20,20,.55); border-radius:50%; pointer-events:none; }
.hub { position:absolute; width:7px; height:7px; background:var(--paper); border:1px solid var(--ink); }
.cell { position:absolute; background:var(--paper); border:1px solid var(--ink); box-shadow:2px 2px 0 0 var(--ink); display:flex; align-items:center; justify-content:center; }
.cell .ic { display:block; background:var(--ink); -webkit-mask:var(--ic) center / contain no-repeat; mask:var(--ic) center / contain no-repeat; }
.cell img.pic { display:block; object-fit:contain; }
.cell.active { background:var(--accent); border-color:var(--accentBright); }
.cell.active .ic { background:var(--onAccent); }
.cell.off::after { content:""; position:absolute; inset:0; background:repeating-linear-gradient(45deg, rgba(20,20,20,.3) 0 1px, transparent 1px 4px); }
.cell.off .ic, .cell.off img.pic { opacity:.5; }
.cell.off.active::after { background:repeating-linear-gradient(45deg, rgba(242,242,242,.5) 0 1px, transparent 1px 4px); }
.cell.sub::before { content:""; position:absolute; right:1px; bottom:1px; border-left:5px solid transparent; border-bottom:5px solid var(--ink); z-index:1; }
.cell.sub.active::before { border-bottom-color:var(--paper); }
.cell.back .ic { background:var(--accent); }
.cell.back.active .ic { background:var(--onAccent); }
.cell.open { border-style:dashed; background:rgba(242,242,242,.55); box-shadow:none; }
.cell .n { position:absolute; right:2px; top:0; font:700 9px/11px var(--mono); color:var(--ink); }
.cell.active .n { color:var(--onAccent); }

/* the strip's bubble: System 7 light whatever the theme */
.bubble { position:absolute; background:#fff; border:1px solid #000; box-shadow:2px 2px 0 0 #000; color:#000; padding:5px 10px 6px; font-family:var(--sans); text-align:center; white-space:nowrap; pointer-events:none; }
.bubble .t { font-weight:700; font-size:13px; line-height:17px; display:flex; align-items:center; justify-content:center; gap:6px; }
.bubble .t.wrap { white-space:normal; max-width:300px; display:block; text-align:left; } .bubble .t.wrap .dot { margin-right:6px; vertical-align:1px; }
.bubble .s { font-weight:500; font-size:12px; line-height:16px; color:#222; }
.bubble .k { font-family:var(--mono); font-weight:700; font-size:10px; letter-spacing:1.5px; color:#555; }
.bubble::after { content:""; position:absolute; left:50%; bottom:-7px; transform:translateX(-50%); border-left:7px solid transparent; border-right:7px solid transparent; border-top:7px solid #000; }
.bubble::before { content:""; position:absolute; left:50%; bottom:-5px; transform:translateX(-50%); border-left:6px solid transparent; border-right:6px solid transparent; border-top:6px solid #fff; z-index:1; }
.dot { display:inline-block; width:7px; height:7px; border-radius:50%; background:#B23A16; flex:none; }

/* the breadcrumb under the ring: which wheel, and where in it */
.crumb { position:absolute; transform:translateX(-50%); font:700 10px/14px var(--mono); letter-spacing:1.5px; color:#f2f2f2; background:rgba(20,20,20,.82); border:1px solid #000; padding:1px 7px; white-space:nowrap; pointer-events:none; }

/* the D-pad glyph and the footer prompts (ZeD's footer strip) */
.pad { position:absolute; left:28px; bottom:56px; pointer-events:none; }
.prompts { position:absolute; transform:translateX(-50%); height:24px; padding:0 10px; background:rgba(20,20,20,.82); border:1px solid #000; display:flex; align-items:center; gap:16px; font:500 11px/24px var(--mono); color:#e8e4d8; pointer-events:none; white-space:nowrap; }
.prompts .g { display:inline-block; min-width:18px; height:16px; line-height:14px; text-align:center; border:1px solid #e8e4d8; margin-right:6px; padding:0 3px; font-weight:700; font-size:10px; }
.toast { position:absolute; left:50%; transform:translateX(-50%); top:470px; background:#fff; color:#000; border:1px solid #000; box-shadow:2px 2px 0 0 #000; font:600 12px/16px var(--sans); padding:4px 10px; pointer-events:none; }

/* notes */
.notes { max-width:1100px; margin-top:26px; display:grid; gap:24px; }
.notes h2 { font-family:var(--cond); font-weight:600; font-size:18px; color:#f0ece0; margin-bottom:8px; }
.notes p, .notes li { font-size:13px; line-height:1.6; color:#c4bfb1; }
.notes ol, .notes ul { padding-left:20px; } .notes li { margin-bottom:8px; } .notes b { color:#efe6c4; font-weight:600; }
.rec { display:inline-block; font-family:var(--mono); font-size:10px; letter-spacing:1px; color:#111; background:#d8c070; padding:0 5px; margin-right:6px; }
.alt { display:inline-block; font-family:var(--mono); font-size:10px; letter-spacing:1px; color:#111; background:#9ab0c4; padding:0 5px; margin-right:6px; }
table.parity { border-collapse:collapse; width:100%; font-size:12px; }
table.parity th, table.parity td { border:1px solid #34322c; padding:5px 8px; text-align:left; vertical-align:top; color:#c4bfb1; line-height:1.45; }
table.parity th { font-family:var(--mono); font-size:10px; letter-spacing:1px; color:#d8c070; background:#17160f; text-transform:uppercase; }
.map4 { display:grid; grid-template-columns:repeat(4, 1fr); gap:10px; }
.map4 > div { border:1px solid #34322c; padding:8px 10px; background:#12110d; }
.map4 h3 { font:700 11px/16px var(--mono); letter-spacing:1.5px; color:#d8c070; text-transform:uppercase; margin-bottom:4px; }
.map4 p { font-size:12px; line-height:1.5; }
</style>
</head>
<body>
<div class="banner">ZeD-UI · in game · the controller's D-pad wheels · mockup v2</div>
<h1>D-pad wheels</h1>
<p class="lede">Four wheels, one per D-pad direction, in place of the game's D-pad wheels. <b style="color:#efe6c4">Left</b> is you (the Character window's things), <b style="color:#efe6c4">Right</b> is the world around you (the World window's things), <b style="color:#efe6c4">Up</b> is social, <b style="color:#efe6c4">Down</b> is here and now. Hold the direction with your left thumb, point with the right stick, let go of the D-pad to take. (The D-pad and the left stick both sit under the left thumb on PlayStation and Xbox pads, so the right stick points.) A slice that opens more (the corner triangle) swaps the ring in place, with Back as its last slice, as the game's emote wheel does. Every slice keeps its place; one that can't be done right now is stippled and the bubble says why. Point with the mouse to try it; click to take or to open. The arrow keys switch wheels; Escape backs out.</p>

<div class="controls">
  <div class="ctl"><span>Wheel (arrow keys)</span><div class="seg" id="ctlWheel"></div></div>
  <div class="ctl"><span>Slices, Left and Right</span><div class="seg" id="ctlN"></div></div>
  <div class="ctl"><span>Scene</span><div class="seg" id="ctlScene"></div></div>
  <div class="ctl"><span>Accent</span><div class="swatches" id="ctlAccent"></div></div>
  <div class="ctl"><span>Zoom</span><div class="seg" id="ctlZoom"></div></div>
</div>
<div class="stage-wrap"><div class="stage" id="stage"></div></div>
<div class="caption" id="caption"></div>

<section class="notes">
  <div>
    <h2>The four wheels at a glance</h2>
    <div class="map4" id="map4"></div>
  </div>
  <div>
    <h2>Decisions for you</h2>
    <ol>
      <li><span class="rec">RECOMMEND</span><b>Eight slices on Left and Right, with wheels inside.</b> Eight is what a thumb hits without looking (the four D-pad directions and the four between). Your Character list is twelve things, so four of them share a slice: <b>Medicine and first aid</b> is one slice, and <b>Use</b> holds smoking, reading, the watch and the radio. Switch <i>Slices</i> to 12 to see the other way: every thing one flick away, like a clock face, but each slice is a 30 degree target instead of 45.</li>
      <li><span class="rec">RECOMMEND</span><b>Places never move.</b> The game's wheels add a slice only when it applies, so Drink sits somewhere else every time. Here every slice keeps its place and reads as off when there's nothing to do ("Nothing to drink on you."). Muscle memory beats a shorter wheel.</li>
      <li><span class="rec">RECOMMEND</span><b>Things you carry are picked in the second wheel,</b> one slice per kind, the best first, "x4" when there are more, as the quick-use wheel does today (food spoiling soonest first, water before drinks with a downside). The pick runs the game's own action, with its rules.</li>
      <li><span class="rec">RECOMMEND</span><b>Letting go on a slice with a triangle opens its wheel and keeps it open</b> until you pick, or B backs out one level. Letting go anywhere else takes the slice. One rule for all four.</li>
      <li><span class="rec">SETTLED</span><b>Point with the right stick.</b> The left thumb holds the D-pad, so the right thumb points (director, Oct 23). While a wheel is open the right stick doesn't aim and doesn't hide the windows; aiming comes back once the stick is centred.</li>
      <li><span class="rec">SETTLED</span><b>In a car, Vehicle is a World slice</b> (director, Oct 23), live in and next to a car. The game put the vehicle wheel on Up, which is now Social.</li>
      <li><span class="rec">SETTLED</span><b>Down's eighth slice is Light</b> (director, Oct 23): the brightest light you carry, on or off, without opening a wheel inside. The game had it on D-pad Left; it leaves Weapons. Down gathers what has no home today: the stick-click wheel (crouch, sit, auto-walk) can't be reached because ZeD never binds the stick clicks, the Back button's game speed and zoom, and the help.</li>
      <li><b>When the wheels open.</b> Only when no window has focus, as the game does. With a window focused, the D-pad keeps moving focus (GAMEPAD_SPEC); nothing changes there. The Back button's wheel stays as it is.</li>
    </ol>
  </div>
  <div>
    <h2>Every slice the game's D-pad wheels have, and where it goes</h2>
    <table class="parity">
      <tr><th style="width:22%">The game's wheel</th><th style="width:38%">Slices</th><th>In ZeD</th></tr>
      <tr><td><b>D-pad Left</b></td><td>Each weapon you carry; the best light (toggle)</td><td>Left, Weapons; the light on Down, Light</td></tr>
      <tr><td><b>D-pad Up</b></td><td>The vehicle wheel in or next to a car; else the animal wheel next to a tame animal</td><td>Right, Vehicle and Animal (live only when they apply)</td></tr>
      <tr><td><b>D-pad Down</b></td><td>Emotes: Friendly, Hostile, Group, Signal, Shout</td><td>Up, Social, the same groups and gestures</td></tr>
      <tr><td><b>D-pad Right</b></td><td>World map; mini-map show and focus; designated zones; rooms editor; survival guide</td><td>Right, Map and Zones; the survival guide on Down, Help</td></tr>
      <tr><td><b>ZeD's quick use</b> (on D-pad Right today)</td><td>Eat, Drink, Smoke, Take pills, Read, Treat wounds</td><td>Left, each its own slice (or in Use)</td></tr>
      <tr><td><b>Stick-click wheel</b></td><td>Crouch, Sit, Auto-walk (unreachable: ZeD never binds the stick clicks)</td><td>Down: Sit, Crouch, Auto-walk</td></tr>
      <tr><td><b>Back button wheel</b></td><td>Player info, crafting, building, zoom, game speed, move furniture, search mode, investigate</td><td>Stays. Its game speed and zoom are also on Down; crafting, building, furniture, search on Right.</td></tr>
    </table>
  </div>
</section>

<script>
const ZI = __ZI__;
const VI = __VI__;
const BG = __BG__;
const ACCENTS = { red:["#7A1A1A","#AA3333"], orange:["#7A5010","#B07818"], yellow:["#6B5F0A","#998811"], green:["#1F5A1F","#2E7A2E"], blue:["#1A3F6B","#2A5A99"], teal:["#1A5548","#257A66"], purple:["#4A2A6B","#663D99"], pink:["#7A1F44","#A8305F"], mono:["#3A3A3A","#555555"] };
const S = { wheel:"char", n:8, scene:"foot", accent:"yellow", zoom:1, path:[], point:-1, toast:"", toastT:0 };
const $ = id => document.getElementById(id);
const CX = 640, CY = 250;

// ---------------------------------------------------------------------------
// Scenes: what is live. foot = on foot at the Fossoil, the wagon parked beside you
// ---------------------------------------------------------------------------
const SCENES = {
  foot:   { label:"On foot, by the wagon", bg:"foot", inCar:false, nearCar:true,  animal:false, mp:false },
  car:    { label:"In the driver's seat",  bg:"car",  inCar:true,  nearCar:true,  animal:false, mp:false },
  animal: { label:"By a tame cow",         bg:"foot", inCar:false, nearCar:false, animal:true,  mp:false },
  mp:     { label:"On a server",           bg:"foot", inCar:false, nearCar:true,  animal:false, mp:true  },
};
// need: a scene flag the slice needs (prefix ! = must be false); why: what the bubble says when it isn't live
function live(sl) {
  if (sl.off) return false;
  if (!sl.need) return true;
  const sc = SCENES[S.scene];
  return sl.need.split(",").some(n => n[0] === "!" ? !sc[n.slice(1)] : !!sc[n]);
}

// ---------------------------------------------------------------------------
// The slices. t = name, s = the line under it, z = ZeD icon, v = the game's own picture,
// sub = the wheel it opens, off = never live in this scene set (with why), do = what taking it does
// ---------------------------------------------------------------------------
const TAB = (t, z, w) => ({ t, s:w + " window", z:"tab-" + z, do:"Opens the " + w + " window on " + t + "." });
const CHAR_TABS = { title:"Character tabs", slices:[
  TAB("Loot","loot","Character"), TAB("Equipment","equipment","Character"), TAB("Health","health","Character"), TAB("Thermal","thermal","Character"),
  TAB("ID","identy","Character"), TAB("Journal","journal","Character"), TAB("Skills","skills","Character"), TAB("Radio","radio","Character") ] };
const WEAPONS = { title:"Weapons", slices:[
  { t:"Crowbar", s:"In your hands", z:"fi-br-wrench-alt", do:"Already in your hands." },
  { t:"Hunting Knife", s:"Belt, slot 3", z:"knife", do:"Equips the Hunting Knife." },
  { t:"Baseball Bat x3", s:"The best of three", z:"hammer", do:"Equips the Baseball Bat in the best condition." },
  { t:"M9 Pistol", s:"Belt, slot 2 · 15 rounds", z:"gun", do:"Equips the M9 Pistol." },
  { t:"JS-2000 Shotgun", s:"On your back · empty", z:"gun", do:"Equips the JS-2000 Shotgun." },
  { t:"Hands free", s:"Put weapons away", z:"backpack", do:"Unequips both hands." } ] };
const EAT = { title:"Eat", slices:[
  { t:"Apple x4", s:"Fresh · eat first", z:"apple", do:"Eats an apple (the one spoiling soonest)." },
  { t:"Bread", s:"Fresh", z:"bread", do:"Eats the bread." },
  { t:"Canned Corn x2", z:"can", off:true, why:"Canned Corn: needs a can opener." },
  { t:"Crisps", s:"Unhappy +5", z:"fi-br-picking-box", do:"Eats the crisps." } ] };
const DRINK = { title:"Drink", slices:[
  { t:"Water Bottle", s:"0.6 L · water", z:"bottle", do:"Drinks a thirst-sized sip of water." },
  { t:"Orange Soda", s:"Fizzy", z:"juice", do:"Drinks the soda." },
  { t:"Whiskey", s:"Drunk +", z:"whiskey", do:"Drinks the whiskey." } ] };
const MEDS = [
  { t:"Painkillers x2", s:"Pain", z:"pill", do:"Takes a painkiller." },
  { t:"Vitamins", s:"Tired", z:"pills2", do:"Takes a vitamin." } ];
const FIRST = [
  { t:"Bandage left hand", s:"Scratch · bleeding", z:"bandage", do:"Bandages the scratch on the left hand." },
  { t:"Disinfect", s:"Left hand", z:"spray", do:"Disinfects the left hand." },
  { t:"Splint", z:"gauze", off:true, why:"No fracture." },
  { t:"Health tab", s:"Every wound", z:"tab-health", do:"Opens the Character window on Health." } ];
const MEDICINE = { title:"Medicine", slices:MEDS.concat([{ t:"Health tab", s:"Every wound", z:"tab-health", do:"Opens the Character window on Health." }]) };
const FIRSTAID = { title:"First aid", slices:FIRST };
const MEDBOTH = { title:"Medicine and first aid", slices:MEDS.concat(FIRST) };
const CLOTHING = { title:"Clothing", slices:[
  { t:"Hood up", s:"Hoodie", z:"hood", do:"Puts the hoodie's hood up." },
  { t:"Mask on", s:"Dust mask", z:"mask", do:"Puts the dust mask on." },
  { t:"Cap off", s:"Baseball cap", z:"hat", do:"Takes the cap off." },
  { t:"Jacket: zip up", s:"Varsity jacket", z:"shirt", do:"Zips the jacket up." },
  { t:"Equipment tab", s:"Everything you wear", z:"tab-equipment", do:"Opens the Character window on Equipment." } ] };
const SMOKE = { title:"Smoke", slices:[
  { t:"Cigarettes x14", s:"Lighter in your pocket", z:"smoke", do:"Lights a cigarette." } ] };
const READ = { title:"Read", slices:[
  { t:"Mechanics, Vol. 3", s:"Skill book · Mechanics", z:"magazine", do:"Reads Mechanics, Vol. 3." },
  { t:"Mammals", s:"Book · unhappy -", z:"book", do:"Reads Mammals." },
  { t:"Flier: A1 Hay", s:"Read again", z:"flier", do:"Opens the flier in the reader." } ] };
const WATCH = { title:"Watch", slices:[
  { t:"Open the watch", s:"Digital, steel", z:"clock", do:"Opens the full watch." },
  { t:"Light", s:"Three seconds", z:"lightbulb-on", do:"Lights the watch." },
  { t:"Alarm", s:"7:00 · on", z:"alarm", do:"Sets the alarm." },
  { t:"Stopwatch", z:"sports-day-049-stopwatch", do:"Starts the stopwatch." } ] };
const RADIO = { title:"Radio", slices:[
  { t:"Turn on", s:"Walkie-talkie", z:"radio", do:"Turns the walkie-talkie on." },
  { t:"Channel 98.2", s:"Knox Talk", z:"fm-radio", do:"Tunes to 98.2." },
  { t:"Radio tab", s:"Every radio you carry", z:"tab-radio", do:"Opens the Character window on Radio." } ] };
const USE = { title:"Use", slices:[
  { t:"Smoke", z:"smoke", sub:SMOKE }, { t:"Read", z:"reader", sub:READ },
  { t:"Watch", z:"clock", sub:WATCH }, { t:"Radio", z:"radio", sub:RADIO } ] };
const SLEEP = { t:"Sleep", z:"bed", off:true, why:"Not tired enough to sleep." };

// the World wheel
const WTAB = (t, z) => TAB(t, z, "World");
const WORLD_TABS = { title:"World tabs", slices:[
  WTAB("Loot","loot"), WTAB("Crafting","craft"), WTAB("Building","build"), WTAB("Furniture","move"), WTAB("Maps","map"),
  WTAB("Foraging","forage"), WTAB("Animals","farm"), WTAB("Radio","radio"), WTAB("Vehicle","vehicle") ] };
const MAP = { title:"Map", slices:[
  { t:"World map", z:"crafting-game-037-map", v:"mapon", do:"Opens the World window on Maps." },
  { t:"Mini-map", s:"Show", z:"fi-br-map-point", do:"Shows the mini-map." },
  { t:"Mini-map", s:"Centre on you", z:"map-marker", do:"Centres the mini-map on you." } ] };
const VEH_IN = [
  { t:"Switch seat", z:"fi-br-person-seat", do:"Moves to another seat." },
  { t:"Start engine", z:"engine", off:true, why:"No key. You need Electrical level 1 and Mechanics level 2 to hotwire." },
  { t:"Headlights", s:"Turn on", z:"lightbulb-on", do:"Turns the headlights on." },
  { t:"Heater", s:"Turn on", z:"fire-flame-curved", do:"Turns the heater on." },
  { t:"Horn", z:"bullhorn", do:"Sounds the horn." },
  { t:"Radio", s:"Up close", z:"fm-radio", do:"Opens the car radio up close." },
  { t:"Vehicle tab", s:"Parts and condition", z:"tab-vehicle", do:"Opens the World window on Vehicle." },
  { t:"Get out", z:"exit", do:"Gets out of the car." } ];
const VEH_OUT = [
  { t:"Get in", s:"Driver's seat", z:"fi-br-person-seat", do:"Gets in the driver's seat." },
  { t:"Add gasoline", s:"Gas can, 4 L", z:"gas-pump", v:"refuel", do:"Pours the gas can into the tank." },
  { t:"Open door", s:"Front left", z:"door-closed", do:"Opens the front left door." },
  { t:"Lock doors", z:"fi-br-lock", do:"Locks every door." },
  { t:"Trunk", s:"Open the loot", z:"fi-br-picking-box", do:"Opens the World window on Loot, the trunk's column." },
  { t:"Vehicle tab", s:"Parts and condition", z:"tab-vehicle", do:"Opens the World window on Vehicle." } ];
function vehicleSub() { return { title:"Vehicle", slices: SCENES[S.scene].inCar ? VEH_IN : VEH_OUT }; }
const ANIMAL = { title:"Animal · Cow", slices:[
  { t:"Pet", z:"hand", do:"Pets the cow." }, { t:"Milk", s:"Bucket in hand", z:"milk", do:"Milks the cow." },
  { t:"Attach rope", z:"knot-rope", do:"Ties a rope to the cow." }, { t:"Pick up", z:"fi-br-picking-box", off:true, why:"Too heavy to pick up." },
  { t:"Animal info", z:"info", do:"Opens the World window on Animals." } ] };
const CRAFT = { title:"Craft and build", slices:[
  { t:"Crafting", s:"Workbench, 2 tiles", z:"tab-craft", do:"Opens the World window on Crafting, at the workbench." },
  { t:"Building", z:"tab-build", do:"Opens the World window on Building." },
  { t:"Move furniture", z:"tab-move", do:"Opens the World window on Furniture." } ] };
const SEARCH = { title:"Search", slices:[
  { t:"Search mode", s:"Turn on", z:"eye", v:"search", do:"Turns search mode on." },
  { t:"Investigate area", s:"Foraging tab", z:"fi-br-magnifying-glass-wave", do:"Opens the World window on Foraging." },
  { t:"Pick up", s:"Dandelions", z:"fi-br-picking-box", do:"Picks up the dandelions you found." } ] };
const POWER = { title:"Lights and power", slices:[
  { t:"Ceiling lights", s:"Turn off", z:"lightbulb-on", do:"Turns the room's lights off." },
  { t:"Generator", z:"generator", off:true, why:"No generator nearby." },
  { t:"Campfire", z:"campfire", off:true, why:"No fire nearby." } ] };
const ZONES = { title:"Zones and rooms", slices:[
  { t:"Designated zones", s:"Animals tab", z:"map-marker", v:"zone", do:"Opens the World window on Animals, zones." },
  { t:"Rooms editor", z:"stairs", do:"Opens the rooms editor." } ] };

// Social
const EM = (t, v, z) => ({ t, v, z:z || "hand", do:"Plays " + t + "." });
const FRIENDLY = { title:"Friendly", slices:[ EM("Wave Hi", null, "wave"), EM("Bye", null, "wave"), EM("Clap", null, "hand"), EM("Thumbs Up","thumbsup"), EM("Thank You", null, "smile") ] };
const HOSTILE = { title:"Hostile", slices:[ EM("Insult", null, "fist"), EM("Stop","freeze"), EM("Surrender", null, "hand"), EM("Thumbs Down","thumbsdown") ] };
const GROUP = { title:"Group", slices:[ EM("Follow Me","followme"), EM("Come Here","comefromfront"), EM("Yes","yes"), EM("No", null, "fist"), EM("Shrug", null, "question"), EM("Undecided", null, "question") ] };
const SIGNAL = { title:"Signal", slices:[ EM("Cease Fire","ceasefire"), EM("Ok","yes"), EM("Move Out","moveout"), EM("Freeze","freeze"), EM("Follow Behind","followbehind"), EM("Fire","fire"), EM("Come","comefromfront"), EM("Salute","salute") ] };

// Down: here and now
const SIT = { title:"Sit", slices:[
  { t:"Sit on the ground", z:"sit", v:"sit", do:"Sits on the ground." },
  { t:"Sit on: Office Chair", s:"1 tile away", z:"chair", do:"Walks to the office chair and sits." },
  { t:"Lie down", z:"bed", off:true, why:"No bed in reach." } ] };
const SPEED = { title:"Game speed", slices:[
  { t:"Pause", z:"clock", v:"pause", do:"Pauses the game." },
  { t:"Play", s:"Normal speed", z:"clock", do:"Normal speed." },
  { t:"Fast forward", s:"x2", z:"fast", v:"ff2", do:"Fast forward." },
  { t:"Wait", s:"Fastest", z:"fast", do:"Fastest speed." } ] };
const ZOOM = { title:"Zoom", slices:[
  { t:"Zoom in", s:"75 percent", z:"magnifying-glass-eye", v:"zoomin", do:"Zooms in." },
  { t:"Zoom out", s:"125 percent", z:"magnifying-glass-eye", v:"zoomout", do:"Zooms out." } ] };
const VIEW = { title:"View", slices:[
  { t:"Hide the interface", s:"Until you press again", z:"eye", do:"Hides the interface." },
  { t:"Reset windows", s:"Both windows, the footer's R", z:"rotate-left", do:"Puts both windows back where they start." },
  { t:"Text size", s:"Large", z:"settings", do:"Switches to large text." },
  { t:"Options", s:"ZeD setup", z:"gears", do:"Opens Options on ZeD setup." } ] };
const HELP = { title:"Help", slices:[
  { t:"Survival guide", z:"info-guide", do:"Opens the survival guide." },
  { t:"Controller map", s:"What every button does", z:"question", do:"Shows the controller map." } ] };

// the four wheels, in 8 and (Left / Right) 12 slices
const WHEELS = {
  char: { label:"Character", dir:"left", key:"ArrowLeft",
    s8: [ { t:"Tabs", s:"Character window", z:"tab-loot", sub:CHAR_TABS }, { t:"Weapons", z:"knife", sub:WEAPONS },
          { t:"Eat", z:"apple", sub:EAT }, { t:"Drink", z:"drink", sub:DRINK },
          { t:"Medicine and first aid", z:"bandage", sub:MEDBOTH }, SLEEP,
          { t:"Clothing", z:"shirt", sub:CLOTHING }, { t:"Use", s:"Smoke · Read · Watch · Radio", z:"backpack", sub:USE } ],
    s12:[ { t:"Tabs", s:"Character window", z:"tab-loot", sub:CHAR_TABS }, { t:"Weapons", z:"knife", sub:WEAPONS },
          { t:"Clothing", z:"shirt", sub:CLOTHING }, { t:"Eat", z:"apple", sub:EAT }, { t:"Drink", z:"drink", sub:DRINK },
          { t:"Medicine", z:"pill", sub:MEDICINE }, { t:"First aid", z:"bandage", sub:FIRSTAID }, { t:"Smoke", z:"smoke", sub:SMOKE },
          { t:"Read", z:"reader", sub:READ }, SLEEP, { t:"Watch", z:"clock", sub:WATCH }, { t:"Radio", z:"radio", sub:RADIO } ] },
  world: { label:"World", dir:"right", key:"ArrowRight",
    s8: [ { t:"Tabs", s:"World window", z:"tab-craft", sub:WORLD_TABS }, { t:"Map", z:"crafting-game-037-map", sub:MAP },
          { t:"Vehicle", z:"car-mechanic", sub:"vehicle", need:"nearCar,inCar", why:"No vehicle in reach." },
          { t:"Animal", z:"cow", sub:ANIMAL, need:"animal", why:"No tame animal in reach." },
          { t:"Craft and build", z:"carpentry-015-toolbox", sub:CRAFT }, { t:"Search", z:"fi-br-magnifying-glass-wave", sub:SEARCH },
          { t:"Lights and power", z:"lightbulb-on", sub:POWER }, { t:"Zones and rooms", z:"map-marker", sub:ZONES } ],
    s12:[ { t:"Tabs", s:"World window", z:"tab-craft", sub:WORLD_TABS }, { t:"Map", z:"crafting-game-037-map", sub:MAP },
          { t:"Vehicle", z:"car-mechanic", sub:"vehicle", need:"nearCar,inCar", why:"No vehicle in reach." },
          { t:"Animal", z:"cow", sub:ANIMAL, need:"animal", why:"No tame animal in reach." },
          CRAFT.slices[0], CRAFT.slices[1], CRAFT.slices[2],
          SEARCH.slices[0], SEARCH.slices[1], { t:"Lights and power", z:"lightbulb-on", sub:POWER },
          ZONES.slices[0], ZONES.slices[1] ] },
  social: { label:"Social", dir:"up", key:"ArrowUp",
    s8: [ { t:"Friendly", v:"thumbsup", z:"smile", sub:FRIENDLY }, { t:"Hostile", v:"thumbsdown", z:"fist", sub:HOSTILE },
          { t:"Group", v:"followme", z:"handshake", sub:GROUP }, { t:"Signal", v:"moveout", z:"flag", sub:SIGNAL },
          { t:"Shout", z:"bullhorn", do:"Shouts." },
          { t:"Chat", s:"Type to the server", z:"chat", need:"mp", why:"On a server only.", do:"Opens the chat." },
          { t:"Safety", s:"Fighting other players: off", z:"fi-br-lock", need:"mp", why:"On a server only.", do:"Turns safety off." },
          { t:"Players", s:"Who's on", z:"handshake", need:"mp", why:"On a server only.", do:"Shows who's on the server." } ] },
  now: { label:"Here and now", dir:"down", key:"ArrowDown",
    s8: [ { t:"Sit", z:"sit", v:"sit", sub:SIT }, { t:"Crouch", s:"Toggle", z:"walk", v:"crouch", do:"Crouches." },
          { t:"Auto-walk", s:"Toggle", z:"walk", v:"autowalk", do:"Walks on until you move the stick." },
          { t:"Game speed", z:"clock", v:"pause", sub:SPEED, need:"!mp", why:"On a server the server sets the time." },
          { t:"Zoom", z:"magnifying-glass-eye", v:"zoomin", sub:ZOOM },
          { t:"View", s:"Interface and windows", z:"eye", sub:VIEW }, { t:"Help", z:"info-guide", sub:HELP },
          { t:"Light", s:"Flashlight: turn on", z:"lightbulb-on", do:"Turns the flashlight on (the brightest light you carry)." } ] },
};
const ORDER = ["char", "world", "social", "now"];
const DIRGLYPH = { left:"◀", right:"▶", up:"▲", down:"▼" };

// the wheel on screen now (the path walks into subs)
function current() {
  const w = WHEELS[S.wheel];
  let wheel = { title:w.label, slices: (S.n === 12 && w.s12) ? w.s12 : w.s8 };
  const crumbs = [w.label];
  for (const i of S.path) {
    const sl = wheel.slices[i];
    let sub = sl.sub === "vehicle" ? vehicleSub() : sl.sub;
    wheel = { title:sub.title, slices: sub.slices.concat([{ t:"Back", back:true, z:"arrow-left" }]) };
    crumbs.push(sub.title);
  }
  return { wheel, crumbs };
}

function angleOf(i, n) { return -90 + i * 360 / Math.max(n, 2); }
function pol(r, deg) { const a = deg * Math.PI / 180; return [CX + r * Math.cos(a), CY + r * Math.sin(a)]; }
const CELL = 33, ICON = 24;
function radius(n) { return Math.max(CELL * 1.9, n * (CELL + 8) / (2 * Math.PI)); }

function picHTML(sl, px) {
  if (sl.v && VI[sl.v] && !sl.zOnly) return `<img class="pic" src="data:image/png;base64,${VI[sl.v]}" style="width:${px}px;height:${px}px">`;
  const z = ZI[sl.z] ? sl.z : "info";
  return `<span class="ic" style="width:${px}px;height:${px}px;--ic:url(data:image/png;base64,${ZI[z]})"></span>`;
}

function padSVG(dir) {
  const on = "var(--accentBright)", off = "#e8e4d8";
  const arm = (d, x, y, w, h) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${d === dir ? on : "rgba(20,20,20,.75)"}" stroke="${off}" stroke-width="1.5"/>`;
  return `<svg class="pad" width="76" height="92" viewBox="0 0 76 92">
    ${arm("up",27,2,22,24)}${arm("down",27,50,22,24)}${arm("left",3,26,24,24)}${arm("right",49,26,24,24)}
    <rect x="27" y="26" width="22" height="24" fill="rgba(20,20,20,.75)" stroke="${off}" stroke-width="1.5"/>
    <text x="38" y="88" text-anchor="middle" font-family="Fira Mono" font-size="10" font-weight="700" fill="${off}" letter-spacing="1.5">HOLD</text></svg>`;
}

function render() {
  const rs = document.documentElement.style, ac = ACCENTS[S.accent];
  rs.setProperty("--accent", ac[0]); rs.setProperty("--accentBright", ac[1]);
  const st = $("stage");
  st.style.zoom = S.zoom;
  st.style.backgroundImage = `url(data:image/jpeg;base64,${BG[SCENES[S.scene].bg]})`;
  const { wheel, crumbs } = current();
  const sl = wheel.slices, n = sl.length, r = radius(n);
  let h = `<div class="ring" style="left:${CX - r}px;top:${CY - r}px;width:${2 * r}px;height:${2 * r}px"></div>`;
  h += `<div class="hub" style="left:${CX - 3.5}px;top:${CY - 3.5}px"></div>`;
  sl.forEach((s, i) => {
    const [x, y] = pol(r, angleOf(i, n));
    const isLive = s.back || live(s);
    const cls = ["cell", i === S.point ? "active" : "", isLive ? "" : "off", s.sub ? "sub" : "", s.back ? "back" : "", s.open ? "open" : ""].join(" ");
    h += `<div class="${cls}" style="left:${Math.round(x - CELL / 2)}px;top:${Math.round(y - CELL / 2)}px;width:${CELL}px;height:${CELL}px">${picHTML(s, ICON)}</div>`;
  });
  // the bubble above: the pointed slice, else the wheel's name
  let content;
  if (S.point >= 0 && sl[S.point]) {
    const p = sl[S.point];
    if (!p.back && !live(p)) content = `<div class="t wrap"><span class="dot"></span>${p.why || "Can't be done right now."}</div>`;
    else content = `<div class="t">${p.t}</div>` + (p.s ? `<div class="s">${p.s}</div>` : "");
  } else content = `<div class="k">${DIRGLYPH[WHEELS[S.wheel].dir]} ${wheel.title.toUpperCase()}</div>`;
  h += `<div class="bubble" id="bub" style="left:${CX}px;top:${CY - r - CELL / 2 - 14}px">${content}</div>`;
  h += `<div class="crumb" style="left:${CX}px;top:${CY + r + CELL / 2 + 12}px">${crumbs.join("  ›  ").toUpperCase()}</div>`;
  h += padSVG(WHEELS[S.wheel].dir);
  const deep = S.path.length > 0;
  h += `<div class="prompts" style="left:${CX}px;top:${CY + r + CELL / 2 + 36}px">${deep ? "" : `<span><span class="g">${DIRGLYPH[WHEELS[S.wheel].dir]}</span>hold</span>`}<span><span class="g">RS</span>point</span><span><span class="g">${deep ? "A" : "↑"}</span>${deep ? "take" : "let go of " + DIRGLYPH[WHEELS[S.wheel].dir] + ": take"}</span><span><span class="g">B</span>${deep ? "back" : "close"}</span></div>`;
  if (S.toast && Date.now() - S.toastT < 2600) h += `<div class="toast">${S.toast}</div>`;
  st.innerHTML = h;
  const b = $("bub");
  if (b) { b.style.left = (CX - b.offsetWidth / 2) + "px"; b.style.top = (parseFloat(b.style.top) - b.offsetHeight) + "px"; }
  caption();
}

function caption() {
  const w = WHEELS[S.wheel], { wheel } = current();
  const live_n = wheel.slices.filter(s => s.back || live(s)).length;
  const notes = {
    char: "Left: you. Everything the Character window holds, one flick from the world. Eat, Drink and the rest fill a second wheel with what you carry, the best first.",
    world: "Right: the world around you. The World window's tabs, the map, and what's in reach: a vehicle, a tame animal, a station, the lights.",
    social: "Up: social. The game's emote groups and gestures, Shout, and on a server the chat, safety and the player list.",
    now: "Down: here and now. Stance and movement (sit, crouch, auto-walk), time and view, help, and the light you carry.",
  };
  $("caption").innerHTML = `<b>${DIRGLYPH[w.dir]} ${w.label}</b> · ${SCENES[S.scene].label} · ${wheel.slices.length} slices, ${live_n} live. ${S.path.length ? "Inside " + wheel.title + ": Back is the last slice, as the game's emote wheel puts it." : notes[S.wheel]}`;
}

function pointAt(ev) {
  const st = $("stage"), rc = st.getBoundingClientRect();
  const x = (ev.clientX - rc.left) / S.zoom, y = (ev.clientY - rc.top) / S.zoom;
  const dx = x - CX, dy = y - CY;
  if (Math.hypot(dx, dy) < 14) return -1;            // the dead zone round the hub
  const n = current().wheel.slices.length;
  const deg = (Math.atan2(dy, dx) * 180 / Math.PI + 90 + 360) % 360;
  return Math.round(deg / (360 / n)) % n;
}
function take() {
  const { wheel } = current();
  const sl = wheel.slices[S.point];
  if (!sl) return;
  if (sl.back) { S.path.pop(); S.point = -1; render(); return; }
  if (!live(sl)) return;
  if (sl.sub) { S.path.push(S.point); S.point = -1; render(); return; }
  S.toast = sl.do || (sl.t + "."); S.toastT = Date.now();
  S.path = []; S.point = -1; render();
  setTimeout(render, 2700);
}

function seg(id, items, cur, fn) { $(id).innerHTML = items.map(([k, l, dis]) => `<button data-k="${k}" class="${k === cur ? "on" : ""}" ${dis ? "disabled" : ""}>${l}</button>`).join(""); $(id).querySelectorAll("button").forEach(b => b.onclick = () => fn(b.dataset.k)); }
function setWheel(k) { S.wheel = k; S.path = []; S.point = -1; render(); sync(); }
function sync() {
  seg("ctlWheel", ORDER.map(k => [k, DIRGLYPH[WHEELS[k].dir] + " " + WHEELS[k].label]), S.wheel, setWheel);
  const has12 = !!WHEELS[S.wheel].s12;
  seg("ctlN", [["8","8 slices"],["12","12 slices", !has12]], String(S.n), k => { S.n = +k; S.path = []; S.point = -1; render(); sync(); });
  seg("ctlScene", Object.keys(SCENES).map(k => [k, SCENES[k].label]), S.scene, k => { S.scene = k; S.path = []; S.point = -1; render(); sync(); });
  seg("ctlZoom", [["1","1x (1080p)"],["1.5","1.5x"],["2","2x (4K)"]], String(S.zoom), k => { S.zoom = +k; render(); sync(); });
  $("ctlAccent").innerHTML = Object.keys(ACCENTS).map(k => `<button title="${k}" data-k="${k}" class="${k === S.accent ? "on" : ""}" style="background:${ACCENTS[k][0]}"></button>`).join("");
  $("ctlAccent").querySelectorAll("button").forEach(b => b.onclick = () => { S.accent = b.dataset.k; render(); sync(); });
}
function map4() {
  $("map4").innerHTML = ORDER.map(k => {
    const w = WHEELS[k], list = (S.n === 12 && w.s12 ? w.s12 : w.s8).map(s => s.t).join(" · ");
    return `<div><h3>${DIRGLYPH[w.dir]} ${w.label}</h3><p>${list}</p></div>`;
  }).join("");
}

$("stage").addEventListener("mousemove", ev => { const p = pointAt(ev); if (p !== S.point) { S.point = p; render(); } });
$("stage").addEventListener("mouseleave", () => { S.point = -1; render(); });
$("stage").addEventListener("click", ev => { S.point = pointAt(ev); take(); });
document.addEventListener("keydown", ev => {
  const k = ORDER.find(o => WHEELS[o].key === ev.key);
  if (k) { ev.preventDefault(); setWheel(k); map4(); return; }
  if (ev.key === "Escape") { if (S.path.length) S.path.pop(); S.point = -1; render(); }
});
location.hash.slice(1).split("&").forEach(kv => {
  const [k, v] = kv.split("=");
  if (k === "wheel" && WHEELS[v]) S.wheel = v;
  if (k === "n") S.n = +v;
  if (k === "scene" && SCENES[v]) S.scene = v;
  if (k === "path") S.path = v.split(",").map(Number);
  if (k === "point") S.point = +v;
  if (k === "zoom") S.zoom = +v;
  if (k === "shot") document.body.classList.add("shot");
});
const _sync = sync; sync = function () { _sync(); map4(); };
sync();
document.fonts.ready.then(render);
render();
</script>
<style>.shot { padding:0; } .shot .banner, .shot h1, .shot .lede, .shot .controls, .shot .notes, .shot .caption { display:none; } .shot .stage { border:none; }</style>
</body>
</html>
"""

html = (HTML.replace("__ZI__", json.dumps(ZI))
            .replace("__VI__", json.dumps(VI))
            .replace("__BG__", json.dumps(BG)))
open(OUT, "w", encoding="utf-8", newline="\n").write(html)
print("wrote", OUT, len(html) // 1024, "KB;", len(ZI), "icons")
