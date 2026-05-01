import { useState, useEffect } from "react";

// ═══════════════════════════════════════════════════════════════════════
// ZeD-UI Visual Catalog v3.0 — Coded Atomics Only
// Pixel-perfect replicas of every atom, molecule, and organism
// currently shipping in the mod library Lua files.
// Token values pulled directly from Tokens.lua (dark + orange).
// ═══════════════════════════════════════════════════════════════════════

// ─── Design Tokens (Dark theme + Orange accent, exact from Tokens.lua) ───
const T = {
  // Surfaces (hex + 0.92 alpha)
  base: "rgba(12,12,12,0.92)",       // #0C0C0C
  surf1: "rgba(20,20,20,0.92)",      // #141414
  surf2: "rgba(28,28,28,0.92)",      // #1C1C1C
  surf3: "rgba(36,36,36,0.92)",      // #242424
  surf4: "rgba(44,44,44,0.92)",      // #2C2C2C
  // Borders
  border: "#202020",                  // soft dividers
  borderS: "#383838",                 // strong structural
  // Accent (orange)
  accent: "#D4922A",
  bright: "#E8A830",
  hover: "rgba(212,146,42,0.22)",
  textOnAccent: "#0C0C0C",
  // Text
  text: "rgba(218,218,218,0.90)",     // 0.855*255≈218
  textSec: "rgba(161,161,161,0.65)",  // 0.63*255≈161
  textDim: "rgba(161,161,161,0.65)",
  textHead: "rgba(230,230,230,0.92)", // 0.90*255≈230
  // Status
  danger: "#C45A2A",
  warning: "#C49A2A",
  positive: "#7A9A34",
  info: "#5A8A9A",
  // Chrome
  chromeHi: "rgba(255,255,255,1.0)",
  chromeSh: "rgba(0,0,0,1.0)",
  grooveDark: "rgba(0,0,0,0.50)",
  grooveLight: "rgba(255,255,255,0.06)",
  stripe: "rgba(255,255,255,0.04)",
  // Soiled
  soiledWet: "rgba(96,176,232,0.9)",
  soiledBlood: "rgba(255,106,106,0.9)",
  soiledDirt: "rgba(200,152,96,0.9)",
  // Materials
  matLeather: "#B08A5E",
  matDenim: "#5B8ABF",
  matFabric: "rgba(255,255,255,0.55)",
  // Thermal
  tempCold: "rgb(60,120,220)",
  tempCool: "rgb(60,180,140)",
  tempNorm: "rgb(120,200,80)",
  tempWarm: "rgb(220,180,50)",
  tempHot: "rgb(220,80,40)",
  // Opacities
  badgeBgA: 0.10,
  selectionA: 0.18,
  scrollThumbA: 0.30,
  ridgeLightA: 0.40,
  ridgeDarkA: 0.20,
  disabledAlpha: 0.42,
  // Fonts (web equivalents)
  fontMono: "'Courier New', Courier, monospace",
  fontSans: "system-ui, -apple-system, 'Segoe UI', sans-serif",
  // Sizes (small preset)
  titleBarH: 26,
  rowH: 30,
  buttonH: 26,
  tabH: 24,
  inputH: 26,
  fillBarH: 13,
  checkboxSz: 13,
  closeBoxSz: 13,
  contentPad: 10,
  colGap: 12,
};

// 9 accent colors from Tokens.lua
const ACCENTS = [
  { name: "Red",     hex: "#CC4444", bright: "#EE6666" },
  { name: "Orange",  hex: "#D4922A", bright: "#E8A830" },
  { name: "Yellow",  hex: "#CCAA22", bright: "#EEDD44" },
  { name: "Green",   hex: "#44AA44", bright: "#66CC66" },
  { name: "Blue",    hex: "#4488CC", bright: "#66AAEE" },
  { name: "PZ Teal", hex: "#47A18C", bright: "#5CC4AA" },
  { name: "Purple",  hex: "#8855BB", bright: "#AA77DD" },
  { name: "Pink",    hex: "#DD5588", bright: "#FF77AA" },
  { name: "None",    hex: "#888888", bright: "#AAAAAA" },
];

// ─── Shared styles ───
const mono = (sz = 11) => ({ fontFamily: T.fontMono, fontSize: sz, lineHeight: 1 });
const sans = (sz = 14) => ({ fontFamily: T.fontSans, fontSize: sz, lineHeight: 1 });
const sectionTitle = { ...mono(9), color: T.accent, letterSpacing: "0.12em", textTransform: "uppercase", marginBottom: 6 };
const sectionWrap = { marginBottom: 28 };
const sampleBox = { background: T.surf1, border: `1px solid ${T.borderS}`, padding: 12, borderRadius: 0 };
const label = { ...mono(8), color: T.textDim, textTransform: "uppercase", letterSpacing: "0.08em", marginTop: 6 };

// ─── Pixel grid helper: draws rects like PZ does ───
const Px = ({ x, y, w, h, color }) => (
  <div style={{ position: "absolute", left: x, top: y, width: w, height: h, background: color }} />
);

// ═══════════════════════════════════════════════════════════════════════
//  SECTION: TOKENS
// ═══════════════════════════════════════════════════════════════════════

function TokenSurfaces() {
  const surfs = [
    { name: "base", color: T.base },
    { name: "surf1", color: T.surf1 },
    { name: "surf2", color: T.surf2 },
    { name: "surf3", color: T.surf3 },
    { name: "surf4", color: T.surf4 },
  ];
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>SURFACE STACK</div>
      <div style={{ display: "flex", gap: 2 }}>
        {surfs.map(s => (
          <div key={s.name} style={{ width: 64, height: 48, background: s.color, border: `1px solid ${T.borderS}`, display: "flex", alignItems: "flex-end", justifyContent: "center", padding: 3 }}>
            <span style={{ ...mono(7), color: T.textDim }}>{s.name}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function TokenBorders() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>BORDERS</div>
      <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
        <div style={{ width: 80, height: 32, border: `1px solid ${T.border}`, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <span style={{ ...mono(7), color: T.textDim }}>border</span>
        </div>
        <div style={{ width: 80, height: 32, border: `1px solid ${T.borderS}`, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <span style={{ ...mono(7), color: T.textDim }}>borderS</span>
        </div>
      </div>
    </div>
  );
}

function TokenStatus() {
  const st = [
    { name: "danger", color: T.danger },
    { name: "warning", color: T.warning },
    { name: "positive", color: T.positive },
    { name: "info", color: T.info },
  ];
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>STATUS COLORS</div>
      <div style={{ display: "flex", gap: 8 }}>
        {st.map(s => (
          <div key={s.name} style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <div style={{ width: 14, height: 14, background: s.color, border: `1px solid ${T.borderS}` }} />
            <span style={{ ...mono(8), color: T.textDim }}>{s.name}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function TokenAccents() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>9 ACCENT COLORS</div>
      <div style={{ display: "flex", gap: 2 }}>
        {ACCENTS.map(a => (
          <div key={a.name} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 2 }}>
            <div style={{ width: 36, height: 20, background: a.hex }} />
            <div style={{ width: 36, height: 10, background: a.bright }} />
            <span style={{ ...mono(6), color: T.textDim }}>{a.name}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function TokenThermal() {
  const stops = [T.tempCold, T.tempCool, T.tempNorm, T.tempWarm, T.tempHot];
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>THERMAL SPECTRUM</div>
      <div style={{ height: 16, display: "flex" }}>
        {stops.map((c, i) => (
          <div key={i} style={{ flex: 1, background: c }} />
        ))}
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", marginTop: 2 }}>
        <span style={{ ...mono(7), color: T.textDim }}>COLD</span>
        <span style={{ ...mono(7), color: T.textDim }}>HOT</span>
      </div>
    </div>
  );
}

function TokenText() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>TYPOGRAPHY VOICES</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 6, ...sampleBox }}>
        <div style={{ ...sans(14), color: T.textHead }}>Heading — Chicago 14px (sans, head voice)</div>
        <div style={{ ...sans(14), color: T.text }}>Body text — Geneva 14px (sans, content voice)</div>
        <div style={{ ...mono(11), color: T.accent, textTransform: "uppercase", letterSpacing: "0.1em" }}>CHROME LABEL — ATKINSON MONO 11PX</div>
        <div style={{ ...sans(14), color: T.textSec }}>Secondary text — muted content</div>
        <div style={{ ...mono(11), color: T.textDim, textTransform: "uppercase", letterSpacing: "0.1em" }}>DIM CHROME — STRUCTURAL LABELS</div>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  SECTION: ATOMS — Atoms.lua draw helpers
// ═══════════════════════════════════════════════════════════════════════

function AtomLabels() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>LABELS — drawHeading / drawBody / drawSecondary / drawTextRight</div>
      <div style={{ ...sampleBox, display: "flex", flexDirection: "column", gap: 4 }}>
        <div style={{ ...mono(11), color: T.textHead, textTransform: "uppercase", letterSpacing: "0.1em" }}>HEADING (mono, uppercase, textHead)</div>
        <div style={{ ...sans(14), color: T.text }}>Body text (sans, mixed case, text)</div>
        <div style={{ ...mono(11), color: T.textSec, textTransform: "uppercase", letterSpacing: "0.1em" }}>SECONDARY (mono, uppercase, textSec→accent)</div>
        <div style={{ display: "flex", justifyContent: "space-between" }}>
          <span style={{ ...sans(14), color: T.text }}>Left label</span>
          <span style={{ ...sans(14), color: T.text }}>Right-aligned value</span>
        </div>
      </div>
    </div>
  );
}

function AtomDividers() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>DIVIDERS — drawDividerH / drawDividerV</div>
      <div style={{ ...sampleBox, display: "flex", flexDirection: "column", gap: 12 }}>
        <div>
          <div style={{ height: 1, background: T.border }} />
          <div style={label}>Horizontal — border color, 1px</div>
        </div>
        <div>
          <div style={{ height: 1, background: T.borderS }} />
          <div style={label}>Horizontal — borderS (strong)</div>
        </div>
        <div style={{ display: "flex", gap: 12, alignItems: "center", height: 32 }}>
          <div style={{ width: 1, height: "100%", background: T.border }} />
          <span style={label}>Vertical — border</span>
          <div style={{ width: 1, height: "100%", background: T.borderS }} />
          <span style={label}>Vertical — borderS</span>
        </div>
      </div>
    </div>
  );
}

function AtomDrawBorder() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>SELECTIVE BORDER — drawBorder &#123;top, right, bottom, left&#125;</div>
      <div style={{ ...sampleBox, display: "flex", gap: 12 }}>
        {[
          { edges: { borderTop: `1px solid ${T.borderS}`, borderBottom: `1px solid ${T.borderS}` }, label: "top+bottom" },
          { edges: { borderLeft: `1px solid ${T.borderS}`, borderRight: `1px solid ${T.borderS}` }, label: "left+right" },
          { edges: { border: `1px solid ${T.borderS}` }, label: "all edges" },
          { edges: { borderBottom: `1px solid ${T.borderS}` }, label: "bottom only" },
        ].map((b, i) => (
          <div key={i} style={{ width: 72, height: 36, background: T.surf2, display: "flex", alignItems: "center", justifyContent: "center", ...b.edges }}>
            <span style={{ ...mono(7), color: T.textDim }}>{b.label}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function AtomIcon() {
  const sizes = [16, 24, 32, 48];
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>ICON CONTAINER — drawIcon (centered, clamped)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 12, alignItems: "flex-end" }}>
        {sizes.map(sz => (
          <div key={sz} style={{ width: sz, height: sz, background: T.surf3, border: `1px solid ${T.border}`, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <span style={{ ...mono(7), color: T.textDim }}>{sz}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function AtomFillBar() {
  // drawFillBar: graduated color >0.6=positive, >0.3=warning, else danger
  const fills = [
    { pct: 1.0, color: T.positive, label: "100%" },
    { pct: 0.75, color: T.positive, label: "75% (>0.6 = positive)" },
    { pct: 0.45, color: T.warning, label: "45% (>0.3 = warning)" },
    { pct: 0.15, color: T.danger, label: "15% (<0.3 = danger)" },
  ];
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>FILL BAR — drawFillBar (graduated color)</div>
      <div style={{ ...sampleBox, display: "flex", flexDirection: "column", gap: 6 }}>
        {fills.map((f, i) => (
          <div key={i}>
            <div style={{ position: "relative", height: T.fillBarH, background: T.surf3, border: `1px solid ${T.borderS}` }}>
              <div style={{ position: "absolute", left: 1, top: 1, bottom: 1, width: `${f.pct * 100}%`, background: f.color }} />
            </div>
            <div style={label}>{f.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function AtomGradientBar() {
  // drawGradientBar: 5-stop thermal with white needle
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>GRADIENT BAR — drawGradientBar (thermal + needle)</div>
      <div style={sampleBox}>
        <div style={{ position: "relative", height: T.fillBarH, background: `linear-gradient(to right, ${T.tempCold}, ${T.tempCool}, ${T.tempNorm}, ${T.tempWarm}, ${T.tempHot})`, border: `1px solid ${T.borderS}` }}>
          <div style={{ position: "absolute", left: "60%", top: 0, width: 2, height: "100%", background: "#FFFFFF" }} />
        </div>
        <div style={label}>White needle at current temperature position</div>
      </div>
    </div>
  );
}

function AtomBarSegs() {
  // drawBarSegs: multi-segment stacked bar
  const segs = [
    { pct: 0.35, color: T.matLeather, label: "Leather" },
    { pct: 0.25, color: T.matDenim, label: "Denim" },
    { pct: 0.15, color: T.matFabric, label: "Fabric" },
  ];
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>BAR SEGMENTS — drawBarSegs (stacked multi-material)</div>
      <div style={sampleBox}>
        <div style={{ display: "flex", height: T.fillBarH, background: T.surf3, border: `1px solid ${T.borderS}`, overflow: "hidden" }}>
          {segs.map((s, i) => (
            <div key={i} style={{ width: `${s.pct * 100}%`, height: "100%", background: s.color }} />
          ))}
        </div>
        <div style={{ display: "flex", gap: 12, marginTop: 4 }}>
          {segs.map((s, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 4 }}>
              <div style={{ width: 8, height: 8, background: s.color }} />
              <span style={{ ...mono(7), color: T.textDim }}>{s.label}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function AtomCheckbox() {
  const [checked, setChecked] = useState(false);
  const sz = T.checkboxSz;
  // PZ draws X via 1px rects along diagonals (no drawLine)
  const renderX = () => {
    const rects = [];
    for (let i = 2; i < sz - 2; i++) {
      rects.push(<Px key={`a${i}`} x={i} y={i} w={1} h={1} color={T.textOnAccent} />);
      rects.push(<Px key={`b${i}`} x={sz - 1 - i} y={i} w={1} h={1} color={T.textOnAccent} />);
    }
    return rects;
  };
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>CHECKBOX — drawCheckbox (X via 1px diagonal rects)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 16, alignItems: "center" }}>
        <div onClick={() => setChecked(!checked)} style={{ cursor: "pointer", display: "flex", gap: 8, alignItems: "center" }}>
          <div style={{ position: "relative", width: sz, height: sz, background: checked ? T.accent : T.surf3, border: `1px solid ${T.borderS}` }}>
            {checked && renderX()}
          </div>
          <span style={{ ...mono(11), color: T.text }}>{checked ? "CHECKED" : "UNCHECKED"}</span>
        </div>
        <div style={{ display: "flex", gap: 8, alignItems: "center", opacity: T.disabledAlpha }}>
          <div style={{ width: sz, height: sz, background: T.surf3, border: `1px solid ${T.borderS}` }} />
          <span style={{ ...mono(11), color: T.text }}>DISABLED</span>
        </div>
      </div>
      <div style={label}>Click to toggle — no drawLine in PZ, X built from pixel rects</div>
    </div>
  );
}

function AtomBadge() {
  const badges = [
    { text: "DEFAULT", color: T.accent },
    { text: "DANGER", color: T.danger },
    { text: "WARNING", color: T.warning },
    { text: "POSITIVE", color: T.positive },
    { text: "INFO", color: T.info },
    { text: "DIM", color: T.textDim },
  ];
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>BADGE — drawBadge (uppercase mono, tinted bg, outline)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 8, flexWrap: "wrap" }}>
        {badges.map((b, i) => (
          <div key={i} style={{
            ...mono(9),
            color: b.color,
            textTransform: "uppercase",
            letterSpacing: "0.08em",
            padding: "2px 6px",
            background: b.color + "1A", // ~0.10 alpha
            border: `1px solid ${b.color}`,
          }}>
            {b.text}
          </div>
        ))}
      </div>
    </div>
  );
}

function AtomTooltip() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>TOOLTIP — ZeD_Tooltip (ISPanel:derive, surf2 bg, lines array)</div>
      <div style={{ ...sampleBox, display: "inline-flex" }}>
        <div style={{ background: T.surf2, border: `1px solid ${T.borderS}`, padding: "6px 8px", display: "flex", flexDirection: "column", gap: 2, maxWidth: 240 }}>
          <div style={{ ...sans(14), color: T.textHead }}>Kitchen Knife</div>
          <div style={{ ...sans(14), color: T.text }}>A sharp chef's knife</div>
          <div style={{ ...mono(11), color: T.accent, textTransform: "uppercase" }}>1.2 KG · BLADE</div>
        </div>
      </div>
    </div>
  );
}

function AtomScrollbar() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>SCROLLBAR — drawScrollTrack / drawScrollThumb / drawScrollArrow</div>
      <div style={{ ...sampleBox, display: "flex", gap: 24, alignItems: "flex-start" }}>
        {/* Vertical scrollbar */}
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
          <div style={{ position: "relative", width: 14, height: 120, background: T.surf2, border: `1px solid ${T.borderS}` }}>
            {/* Up arrow zone */}
            <div style={{ height: 14, display: "flex", alignItems: "center", justifyContent: "center", borderBottom: `1px solid ${T.border}` }}>
              <span style={{ ...mono(8), color: T.textDim }}>▲</span>
            </div>
            {/* Track */}
            <div style={{ position: "absolute", left: 2, top: 30, width: 10, height: 40, background: `rgba(212,146,42,${T.scrollThumbA})`, border: `1px solid ${T.borderS}` }} />
            {/* Down arrow zone */}
            <div style={{ position: "absolute", bottom: 0, width: "100%", height: 14, display: "flex", alignItems: "center", justifyContent: "center", borderTop: `1px solid ${T.border}` }}>
              <span style={{ ...mono(8), color: T.textDim }}>▼</span>
            </div>
          </div>
          <div style={label}>Default</div>
        </div>
        {/* Hover state */}
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
          <div style={{ position: "relative", width: 14, height: 120, background: T.surf2, border: `1px solid ${T.borderS}` }}>
            <div style={{ height: 14, display: "flex", alignItems: "center", justifyContent: "center", borderBottom: `1px solid ${T.border}` }}>
              <span style={{ ...mono(8), color: T.accent }}>▲</span>
            </div>
            <div style={{ position: "absolute", left: 2, top: 30, width: 10, height: 40, background: `rgba(212,146,42,0.20)`, border: `1px solid ${T.accent}` }} />
            <div style={{ position: "absolute", bottom: 0, width: "100%", height: 14, display: "flex", alignItems: "center", justifyContent: "center", borderTop: `1px solid ${T.border}` }}>
              <span style={{ ...mono(8), color: T.textDim }}>▼</span>
            </div>
          </div>
          <div style={label}>Hover</div>
        </div>
        {/* Drag state */}
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
          <div style={{ position: "relative", width: 14, height: 120, background: T.surf2, border: `1px solid ${T.borderS}` }}>
            <div style={{ height: 14, display: "flex", alignItems: "center", justifyContent: "center", borderBottom: `1px solid ${T.border}` }}>
              <span style={{ ...mono(8), color: T.textDim }}>▲</span>
            </div>
            <div style={{ position: "absolute", left: 2, top: 30, width: 10, height: 40, background: `rgba(212,146,42,${T.scrollThumbA})`, border: `1px solid ${T.bright}` }} />
            <div style={{ position: "absolute", bottom: 0, width: "100%", height: 14, display: "flex", alignItems: "center", justifyContent: "center", borderTop: `1px solid ${T.border}` }}>
              <span style={{ ...mono(8), color: T.textDim }}>▼</span>
            </div>
          </div>
          <div style={label}>Drag</div>
        </div>
      </div>
      <div style={label}>ZeD_ScrollbarState — pure state+draw object, NOT ISPanel</div>
    </div>
  );
}

function AtomFocusRing() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>FOCUS RING — drawFocusRing (dashed standard, solid 2px HC)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 20 }}>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
          <div style={{ width: 80, height: 36, background: T.surf3, border: `2px dashed ${T.accent}`, borderImage: "none" }} />
          <div style={label}>Standard (dashed)</div>
        </div>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
          <div style={{ width: 80, height: 36, background: T.surf3, border: `2px solid ${T.accent}` }} />
          <div style={label}>High Contrast (solid 2px)</div>
        </div>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  SECTION: ATOM EXTENSIONS — AtomExtensions.lua (System 7 chrome)
// ═══════════════════════════════════════════════════════════════════════

function AtomRounded() {
  // ROUND_RADIUS = {2, 1}: row 0 inset 2px, row 1 inset 1px
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>ROUNDED — fillRounded / borderRounded (ROUND_RADIUS &#123;2, 1&#125;)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 16, alignItems: "center" }}>
        {/* fillRounded: pixel-art rounded rect */}
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
          <div style={{ position: "relative", width: 80, height: 28 }}>
            {/* Row 0: inset 2px each side */}
            <Px x={2} y={0} w={76} h={1} color={T.surf3} />
            {/* Row 1: inset 1px each side */}
            <Px x={1} y={1} w={78} h={1} color={T.surf3} />
            {/* Middle rows: full width */}
            <Px x={0} y={2} w={80} h={24} color={T.surf3} />
            {/* Row N-2: inset 1px */}
            <Px x={1} y={26} w={78} h={1} color={T.surf3} />
            {/* Row N-1: inset 2px */}
            <Px x={2} y={27} w={76} h={1} color={T.surf3} />
          </div>
          <div style={label}>fillRounded</div>
        </div>
        {/* borderRounded */}
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
          <div style={{ position: "relative", width: 80, height: 28 }}>
            {/* Top edge */}
            <Px x={2} y={0} w={76} h={1} color={T.borderS} />
            <Px x={1} y={1} w={1} h={1} color={T.borderS} />
            <Px x={78} y={1} w={1} h={1} color={T.borderS} />
            {/* Left/Right edges */}
            <Px x={0} y={2} w={1} h={24} color={T.borderS} />
            <Px x={79} y={2} w={1} h={24} color={T.borderS} />
            {/* Bottom edge */}
            <Px x={1} y={26} w={1} h={1} color={T.borderS} />
            <Px x={78} y={26} w={1} h={1} color={T.borderS} />
            <Px x={2} y={27} w={76} h={1} color={T.borderS} />
          </div>
          <div style={label}>borderRounded</div>
        </div>
      </div>
    </div>
  );
}

function AtomDoubleRounded() {
  // borderDoubleRounded: outer + inner at (x+2, y+3, w-4, h-6)
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>DOUBLE ROUNDED — borderDoubleRounded (outer + inner offset)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 16 }}>
        <div style={{ position: "relative", width: 100, height: 32 }}>
          {/* Outer border */}
          <Px x={2} y={0} w={96} h={1} color={T.borderS} />
          <Px x={1} y={1} w={1} h={1} color={T.borderS} />
          <Px x={98} y={1} w={1} h={1} color={T.borderS} />
          <Px x={0} y={2} w={1} h={28} color={T.borderS} />
          <Px x={99} y={2} w={1} h={28} color={T.borderS} />
          <Px x={1} y={30} w={1} h={1} color={T.borderS} />
          <Px x={98} y={30} w={1} h={1} color={T.borderS} />
          <Px x={2} y={31} w={96} h={1} color={T.borderS} />
          {/* Inner border at (x+2, y+3, w-4, h-6) */}
          <Px x={4} y={3} w={92} h={1} color={T.borderS} />
          <Px x={3} y={4} w={1} h={1} color={T.borderS} />
          <Px x={96} y={4} w={1} h={1} color={T.borderS} />
          <Px x={2} y={5} w={1} h={22} color={T.borderS} />
          <Px x={97} y={5} w={1} h={22} color={T.borderS} />
          <Px x={3} y={27} w={1} h={1} color={T.borderS} />
          <Px x={96} y={27} w={1} h={1} color={T.borderS} />
          <Px x={4} y={28} w={92} h={1} color={T.borderS} />
        </div>
        <div style={{ display: "flex", flexDirection: "column", justifyContent: "center" }}>
          <div style={label}>System 7 button chrome</div>
          <div style={{ ...mono(7), color: T.textDim, marginTop: 2 }}>inner = (x+2, y+3, w-4, h-6)</div>
        </div>
      </div>
    </div>
  );
}

function AtomGroove() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>GROOVE — drawGroove (2px recessed channel)</div>
      <div style={sampleBox}>
        <div style={{ height: 1, background: T.grooveDark }} />
        <div style={{ height: 1, background: T.grooveLight }} />
        <div style={label}>grooveDark (rgba 0,0,0,0.50) + grooveLight (rgba 1,1,1,0.06)</div>
      </div>
    </div>
  );
}

function AtomGrowBox() {
  // drawGrowBox: surf2 bg + borderS border + 3 diagonal ridge pairs
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>GROW BOX — drawGrowBox (surf2 + ridges)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 16, alignItems: "center" }}>
        <div style={{ position: "relative", width: 16, height: 16, background: T.surf2, border: `1px solid ${T.borderS}` }}>
          {/* 3 diagonal ridge pairs (light + shadow) */}
          {[0, 4, 8].map(offset => (
            <div key={offset}>
              <Px x={12 - offset} y={13} w={1} h={1} color={`rgba(255,255,255,${T.ridgeLightA})`} />
              <Px x={13 - offset} y={12} w={1} h={1} color={`rgba(255,255,255,${T.ridgeLightA})`} />
              <Px x={13 - offset} y={13} w={1} h={1} color={`rgba(0,0,0,${T.ridgeDarkA})`} />
            </div>
          ))}
        </div>
        <span style={{ ...mono(8), color: T.textDim }}>Bottom-right window corner</span>
      </div>
    </div>
  );
}

function AtomCloseBox() {
  const [hov, setHov] = useState(false);
  const sz = T.closeBoxSz;
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>CLOSE BOX — drawCloseBox (square + X glyph, hover state)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 16, alignItems: "center" }}>
        <div
          onMouseEnter={() => setHov(true)}
          onMouseLeave={() => setHov(false)}
          style={{ position: "relative", width: sz, height: sz, background: hov ? T.surf4 : T.surf2, border: `1px solid ${T.borderS}`, cursor: "pointer" }}
        >
          {/* X glyph via 1px rects */}
          {Array.from({ length: sz - 4 }, (_, i) => i + 2).map(i => (
            <div key={i}>
              <Px x={i} y={i} w={1} h={1} color={hov ? T.accent : T.textDim} />
              <Px x={sz - 1 - i} y={i} w={1} h={1} color={hov ? T.accent : T.textDim} />
            </div>
          ))}
        </div>
        <span style={{ ...mono(8), color: T.textDim }}>Hover to see accent state</span>
      </div>
    </div>
  );
}

function AtomTriangles() {
  // Disclosure triangles (texture-based in PZ, CSS approximations here)
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>TRIANGLES — drawTriangleRight / Down / Up / Left</div>
      <div style={{ ...sampleBox, display: "flex", gap: 16, alignItems: "center" }}>
        {[
          { dir: "right", border: `6px solid transparent`, main: `borderLeft: 8px solid ${T.textDim}` },
          { dir: "down", border: `6px solid transparent`, main: `borderTop: 8px solid ${T.textDim}` },
          { dir: "up", border: `6px solid transparent`, main: `borderBottom: 8px solid ${T.textDim}` },
          { dir: "left", border: `6px solid transparent`, main: `borderRight: 8px solid ${T.textDim}` },
        ].map((t, i) => (
          <div key={i} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
            <div style={{
              width: 0, height: 0,
              borderTop: t.dir === "down" ? `8px solid ${T.textDim}` : t.dir === "up" ? "none" : "6px solid transparent",
              borderBottom: t.dir === "up" ? `8px solid ${T.textDim}` : t.dir === "down" ? "none" : "6px solid transparent",
              borderLeft: t.dir === "right" ? `8px solid ${T.textDim}` : t.dir === "left" ? "none" : "6px solid transparent",
              borderRight: t.dir === "left" ? `8px solid ${T.textDim}` : t.dir === "right" ? "none" : "6px solid transparent",
            }} />
            <span style={{ ...mono(7), color: T.textDim }}>{t.dir}</span>
          </div>
        ))}
      </div>
      <div style={label}>Texture-based in PZ (rt.png, dn.png, up.png, lf.png)</div>
    </div>
  );
}

function AtomStatusDots() {
  // 5x5 pixel-art circle: read, partial, mastered, unread
  const Dot = ({ fill, border: bdr, label: lbl }) => (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
      <div style={{ position: "relative", width: 5, height: 5 }}>
        {/* 5x5 pixel circle pattern:
            .XXX.
            XXXXX
            XXXXX
            XXXXX
            .XXX.  */}
        {fill && <>
          <Px x={1} y={0} w={3} h={1} color={fill} />
          <Px x={0} y={1} w={5} h={3} color={fill} />
          <Px x={1} y={4} w={3} h={1} color={fill} />
        </>}
        {bdr && <>
          <Px x={1} y={0} w={3} h={1} color={bdr} />
          <Px x={0} y={1} w={1} h={3} color={bdr} />
          <Px x={4} y={1} w={1} h={3} color={bdr} />
          <Px x={1} y={4} w={3} h={1} color={bdr} />
        </>}
      </div>
      <span style={{ ...mono(7), color: T.textDim }}>{lbl}</span>
    </div>
  );
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>STATUS DOT — drawStatusDot (5x5 pixel-art circle)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 20 }}>
        <Dot fill={T.positive} label="read" />
        <Dot fill={T.warning} label="partial" />
        <Dot fill={T.textDim} label="mastered" />
        <Dot border={T.textDim} label="unread" />
      </div>
    </div>
  );
}

function AtomPillButton() {
  const [active, setActive] = useState(false);
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>PILL BUTTON — drawPillButton (1px rounded toggle)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 12 }}>
        <div onClick={() => setActive(!active)} style={{
          cursor: "pointer",
          ...mono(9),
          textTransform: "uppercase",
          letterSpacing: "0.08em",
          padding: "3px 10px",
          borderRadius: 10,
          background: active ? T.accent : "transparent",
          color: active ? T.textOnAccent : T.textDim,
          border: `1px solid ${active ? T.accent : T.borderS}`,
        }}>
          {active ? "ACTIVE" : "INACTIVE"}
        </div>
        <div style={{
          ...mono(9), textTransform: "uppercase", letterSpacing: "0.08em",
          padding: "3px 10px", borderRadius: 10,
          background: "transparent", color: T.textDim,
          border: `1px solid ${T.borderS}`, opacity: T.disabledAlpha,
        }}>
          DISABLED
        </div>
      </div>
      <div style={label}>Click to toggle — active fills accent, inactive shows border only</div>
    </div>
  );
}

function AtomLegendSwatch() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>LEGEND SWATCH — drawLegendSwatch (8×14 color rect)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 12, alignItems: "center" }}>
        {[
          { color: T.matLeather, label: "Leather" },
          { color: T.matDenim, label: "Denim" },
          { color: T.matFabric, label: "Fabric" },
          { color: T.positive, label: "Full" },
        ].map((s, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 4 }}>
            <div style={{ width: 8, height: 14, background: s.color, border: `1px solid ${T.borderS}` }} />
            <span style={{ ...mono(8), color: T.textDim }}>{s.label}</span>
          </div>
        ))}
        <div style={{ display: "flex", alignItems: "center", gap: 4, opacity: 0.45 }}>
          <div style={{ width: 8, height: 14, background: T.textDim, border: `1px solid ${T.borderS}` }} />
          <span style={{ ...mono(8), color: T.textDim }}>Ghost</span>
        </div>
      </div>
    </div>
  );
}

function AtomStatusLabel() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>STATUS LABEL — drawStatusLabel (colored text indicators)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 12 }}>
        <span style={{ ...mono(11), color: T.danger, textTransform: "uppercase" }}>CRITICAL</span>
        <span style={{ ...mono(11), color: T.warning, textTransform: "uppercase" }}>WARNING</span>
        <span style={{ ...mono(11), color: T.positive, textTransform: "uppercase" }}>GOOD</span>
        <span style={{ ...mono(11), color: T.info, textTransform: "uppercase" }}>INFO</span>
      </div>
    </div>
  );
}

function AtomResizeRidges() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>RESIZE RIDGES — drawResizeRidges (3 diagonal pairs)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 16, alignItems: "center" }}>
        <div style={{ position: "relative", width: 16, height: 16 }}>
          {/* 3 ridge pairs: light line + dark shadow, diagonal from bottom-left to top-right */}
          {[0, 4, 8].map(offset => (
            <div key={offset}>
              <Px x={14 - offset} y={14} w={1} h={1} color={`rgba(255,255,255,${T.ridgeLightA})`} />
              <Px x={14 - offset - 1} y={14} w={1} h={1} color={`rgba(0,0,0,${T.ridgeDarkA})`} />
              <Px x={14} y={14 - offset} w={1} h={1} color={`rgba(255,255,255,${T.ridgeLightA})`} />
              <Px x={14} y={14 - offset - 1} w={1} h={1} color={`rgba(0,0,0,${T.ridgeDarkA})`} />
            </div>
          ))}
        </div>
        <span style={{ ...mono(8), color: T.textDim }}>Light + shadow pairs at 0.40 / 0.20 alpha</span>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  SECTION: MOLECULES — Molecules.lua composed components
// ═══════════════════════════════════════════════════════════════════════

function MolButton() {
  const [dangerPhase, setDangerPhase] = useState(0);
  useEffect(() => {
    const id = setInterval(() => setDangerPhase(p => (p + 0.05) % (Math.PI * 2)), 50);
    return () => clearInterval(id);
  }, []);
  const dangerAlpha = 0.08 + (0.25 - 0.08) * ((Math.sin(dangerPhase) + 1) / 2);

  const Btn = ({ children, danger, disabled }) => (
    <div style={{
      position: "relative",
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      height: T.buttonH,
      padding: "0 16px",
      background: danger ? `rgba(196,90,42,${dangerAlpha})` : T.surf3,
      border: `1px solid ${T.borderS}`,
      borderRadius: 2,
      ...mono(11),
      color: danger ? T.danger : T.textHead,
      textTransform: "uppercase",
      letterSpacing: "0.08em",
      cursor: disabled ? "default" : "pointer",
      opacity: disabled ? T.disabledAlpha : 1,
    }}>
      {/* Inner border (double-rounded) */}
      <div style={{ position: "absolute", inset: "2px 2px 3px 2px", border: `1px solid ${T.borderS}`, borderRadius: 1, pointerEvents: "none" }} />
      {children}
    </div>
  );

  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>BUTTON — drawButton / ZeD_Button (borderDoubleRounded chrome)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 12, flexWrap: "wrap" }}>
        <Btn>DEFAULT</Btn>
        <Btn danger>DROP (DANGER PULSE)</Btn>
        <Btn disabled>DISABLED</Btn>
      </div>
      <div style={label}>Danger button pulses via sin() between 0.08–0.25 alpha</div>
    </div>
  );
}

function MolListRow() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>LIST ROW — drawListRow (icon + text + meta, hover/selected)</div>
      <div style={{ ...sampleBox, display: "flex", flexDirection: "column", gap: 0 }}>
        {[
          { state: "default", bg: "transparent", textColor: T.text },
          { state: "hover", bg: T.surf4, textColor: T.text },
          { state: "selected", bg: T.hover, textColor: T.bright },
        ].map((r, i) => (
          <div key={i} style={{
            display: "flex", alignItems: "center", gap: 8,
            height: T.rowH, padding: "0 8px",
            background: r.bg,
            borderBottom: `1px solid ${T.border}`,
          }}>
            <div style={{ width: 24, height: 24, background: T.surf3, border: `1px solid ${T.border}`, flexShrink: 0 }} />
            <span style={{ ...sans(14), color: r.textColor, flex: 1 }}>Item Name</span>
            <span style={{ ...mono(9), color: T.textDim, textTransform: "uppercase" }}>0.5 KG</span>
            <span style={{ ...mono(7), color: T.textDim, textTransform: "uppercase" }}>{r.state}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function MolTab() {
  const [active, setActive] = useState(0);
  const tabs = ["HEALTH", "SKILLS", "PROT", "THERMAL", "JOURNAL", "IDENTITY", "INFO"];
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>TAB — drawTab (System 6: active has no bottom border)</div>
      <div style={sampleBox}>
        <div style={{ display: "flex", borderBottom: `1px solid ${T.borderS}` }}>
          {tabs.map((t, i) => (
            <div
              key={i}
              onClick={() => setActive(i)}
              style={{
                ...mono(9),
                textTransform: "uppercase",
                letterSpacing: "0.08em",
                padding: "6px 12px",
                color: active === i ? T.accent : T.textDim,
                background: active === i ? T.surf1 : "transparent",
                borderTop: active === i ? `1px solid ${T.borderS}` : "1px solid transparent",
                borderLeft: active === i ? `1px solid ${T.borderS}` : "1px solid transparent",
                borderRight: active === i ? `1px solid ${T.borderS}` : "1px solid transparent",
                borderBottom: active === i ? `1px solid ${T.surf1}` : "none",
                marginBottom: active === i ? -1 : 0,
                cursor: "pointer",
              }}
            >
              {t}
            </div>
          ))}
        </div>
      </div>
      <div style={label}>Click tabs — active tab's bottom border matches window bg (System 6 trick)</div>
    </div>
  );
}

function MolTitleBar() {
  const [hov, setHov] = useState(false);
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>TITLE BAR — drawWindowTitleBar (stripes + close box + stat chips)</div>
      <div style={sampleBox}>
        <div style={{
          display: "flex", alignItems: "center",
          height: T.titleBarH,
          background: T.surf2,
          borderBottom: `1px solid ${T.borderS}`,
          position: "relative",
          overflow: "hidden",
        }}>
          {/* Horizontal stripes (4px interval) */}
          {Array.from({ length: 7 }, (_, i) => (
            <div key={i} style={{ position: "absolute", left: 0, right: 0, top: i * 4, height: 1, background: T.stripe }} />
          ))}
          {/* Close box */}
          <div
            onMouseEnter={() => setHov(true)}
            onMouseLeave={() => setHov(false)}
            style={{ position: "relative", width: T.closeBoxSz, height: T.closeBoxSz, background: hov ? T.surf4 : T.surf2, border: `1px solid ${T.borderS}`, margin: "0 8px", cursor: "pointer", zIndex: 1, flexShrink: 0 }}
          >
            {Array.from({ length: T.closeBoxSz - 4 }, (_, i) => i + 2).map(i => (
              <div key={i}>
                <Px x={i} y={i} w={1} h={1} color={hov ? T.accent : T.textDim} />
                <Px x={T.closeBoxSz - 1 - i} y={i} w={1} h={1} color={hov ? T.accent : T.textDim} />
              </div>
            ))}
          </div>
          {/* Title */}
          <span style={{ ...mono(11), color: T.textHead, textTransform: "uppercase", letterSpacing: "0.12em", zIndex: 1 }}>CHARACTER</span>
          {/* Stat chips */}
          <div style={{ marginLeft: "auto", display: "flex", gap: 8, paddingRight: 8, zIndex: 1 }}>
            <span style={{ ...mono(9), color: T.danger, textTransform: "uppercase" }}>♥ 62%</span>
            <span style={{ ...mono(9), color: T.warning, textTransform: "uppercase" }}>⚡ 45%</span>
          </div>
        </div>
      </div>
    </div>
  );
}

function MolStatChip() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>STAT CHIP — drawStatChip (icon + value, status color)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 12 }}>
        {[
          { icon: "♥", value: "62%", color: T.danger },
          { icon: "⚡", value: "45%", color: T.warning },
          { icon: "💧", value: "88%", color: T.positive },
          { icon: "🍖", value: "71%", color: T.text },
        ].map((c, i) => (
          <span key={i} style={{ ...mono(9), color: c.color, textTransform: "uppercase" }}>
            {c.icon} {c.value}
          </span>
        ))}
      </div>
    </div>
  );
}

function MolSectionHeader() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>SECTION HEADER — drawSectionHeader (groove + label)</div>
      <div style={sampleBox}>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <span style={{ ...mono(11), color: T.accent, textTransform: "uppercase", letterSpacing: "0.1em", whiteSpace: "nowrap" }}>UPPER BODY</span>
          <div style={{ flex: 1 }}>
            <div style={{ height: 1, background: T.grooveDark }} />
            <div style={{ height: 1, background: T.grooveLight }} />
          </div>
        </div>
      </div>
    </div>
  );
}

function MolStatRow() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>STAT ROW — drawStatRow (label + value, right-aligned)</div>
      <div style={{ ...sampleBox, display: "flex", flexDirection: "column", gap: 0 }}>
        {[
          { label: "STRENGTH", value: "7", color: T.text },
          { label: "FITNESS", value: "4", color: T.warning },
          { label: "CARPENTRY", value: "9", color: T.positive },
        ].map((r, i) => (
          <div key={i} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", height: 22, padding: "0 8px", borderBottom: `1px solid ${T.border}` }}>
            <span style={{ ...mono(11), color: T.textDim, textTransform: "uppercase" }}>{r.label}</span>
            <span style={{ ...sans(14), color: r.color }}>{r.value}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function MolStatBarRow() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>STAT BAR ROW — drawStatBarRow (label + fill bar + value)</div>
      <div style={{ ...sampleBox, display: "flex", flexDirection: "column", gap: 4 }}>
        {[
          { label: "SPRINTING", pct: 0.72, color: T.positive },
          { label: "LIGHTFOOT", pct: 0.35, color: T.warning },
          { label: "COOKING", pct: 0.12, color: T.danger },
        ].map((r, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 8, height: 22, padding: "0 8px" }}>
            <span style={{ ...mono(9), color: T.textDim, textTransform: "uppercase", width: 90 }}>{r.label}</span>
            <div style={{ flex: 1, height: T.fillBarH, background: T.surf3, border: `1px solid ${T.borderS}`, position: "relative" }}>
              <div style={{ position: "absolute", left: 1, top: 1, bottom: 1, width: `${r.pct * 100}%`, background: r.color }} />
            </div>
            <span style={{ ...mono(9), color: T.textDim, width: 32, textAlign: "right" }}>{Math.round(r.pct * 100)}%</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function MolTextInput() {
  const [focused, setFocused] = useState(false);
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>TEXT INPUT — ZeD_TextInput (cursor blink, surf1 bg, borderEdges)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 12 }}>
        <div
          onClick={() => setFocused(!focused)}
          style={{
            width: 200, height: T.inputH,
            background: T.surf1,
            border: `1px solid ${focused ? T.accent : T.borderS}`,
            display: "flex", alignItems: "center", padding: "0 6px",
            cursor: "text",
          }}
        >
          <span style={{ ...sans(14), color: T.text }}>Search inventory...</span>
          {focused && <span style={{ ...sans(14), color: T.accent, animation: "blink 1s step-end infinite" }}>│</span>}
        </div>
        <style>{`@keyframes blink { 50% { opacity: 0; } }`}</style>
      </div>
      <div style={label}>Click to toggle focus — 500ms cursor blink in game</div>
    </div>
  );
}

function MolSearchField() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>SEARCH FIELD — ZeD_SearchField ("/" icon + text entry)</div>
      <div style={sampleBox}>
        <div style={{
          display: "flex", alignItems: "center", gap: 6,
          width: 220, height: T.inputH,
          background: T.surf1,
          border: `1px solid ${T.borderS}`,
          padding: "0 6px",
        }}>
          <span style={{ ...mono(11), color: T.textDim }}>/</span>
          <span style={{ ...sans(14), color: T.textSec }}>Filter items...</span>
        </div>
      </div>
    </div>
  );
}

function MolActionStrip() {
  const [fav, setFav] = useState(false);
  const [protect, setProtect] = useState(true);
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>ACTION STRIP — drawActionStrip (icon toggle buttons)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 2 }}>
        {[
          { icon: "★", label: "FAV", active: fav, onClick: () => setFav(!fav) },
          { icon: "🛡", label: "PROT", active: protect, onClick: () => setProtect(!protect) },
          { icon: "✕", label: "UNWANT", active: false, onClick: () => {} },
        ].map((a, i) => (
          <div key={i} onClick={a.onClick} style={{
            display: "flex", alignItems: "center", justifyContent: "center",
            width: 28, height: 28,
            background: a.active ? T.hover : "transparent",
            border: `1px solid ${a.active ? T.accent : T.borderS}`,
            cursor: "pointer",
          }}>
            <span style={{ fontSize: 14, opacity: a.active ? 1 : 0.5 }}>{a.icon}</span>
          </div>
        ))}
      </div>
      <div style={label}>Click toggles — fav/protect/unwanted states</div>
    </div>
  );
}

function MolVerbStrip() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>VERB STRIP — drawVerbStrip (right-aligned action buttons)</div>
      <div style={{ ...sampleBox, display: "flex", justifyContent: "flex-end", gap: 4 }}>
        {["EQUIP", "DROP", "EAT"].map((v, i) => (
          <div key={i} style={{
            ...mono(9), textTransform: "uppercase", letterSpacing: "0.08em",
            padding: "4px 10px",
            background: v === "DROP" ? `rgba(196,90,42,0.12)` : T.surf3,
            border: `1px solid ${T.borderS}`,
            color: v === "DROP" ? T.danger : T.textHead,
            cursor: "pointer",
          }}>
            {v}
          </div>
        ))}
      </div>
    </div>
  );
}

function MolDock() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>DOCK — drawDock (button-with-flag: condition bar + label)</div>
      <div style={{ ...sampleBox, display: "flex", gap: 12 }}>
        {[
          { label: "WET", color: T.soiledWet, pct: 0.6 },
          { label: "BLOOD", color: T.soiledBlood, pct: 0.9 },
          { label: "DIRT", color: T.soiledDirt, pct: 0.3 },
        ].map((d, i) => (
          <div key={i} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 2 }}>
            <div style={{ position: "relative", width: 48, height: T.fillBarH, background: T.surf3, border: `1px solid ${T.borderS}` }}>
              <div style={{ position: "absolute", left: 1, top: 1, bottom: 1, width: `${d.pct * 100}%`, background: d.color }} />
            </div>
            <span style={{ ...mono(7), color: d.color, textTransform: "uppercase" }}>{d.label}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function MolDataRow() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>DATA ROW — drawDataRow (2-column key/value)</div>
      <div style={{ ...sampleBox, display: "flex", flexDirection: "column", gap: 0 }}>
        {[
          { key: "WEIGHT", val: "1.2 kg" },
          { key: "CONDITION", val: "87%" },
          { key: "TYPE", val: "Blade" },
        ].map((r, i) => (
          <div key={i} style={{ display: "flex", height: 22, borderBottom: `1px solid ${T.border}`, padding: "0 8px", alignItems: "center" }}>
            <span style={{ ...mono(9), color: T.textDim, textTransform: "uppercase", width: 100 }}>{r.key}</span>
            <span style={{ ...sans(14), color: T.text }}>{r.val}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function MolBodyBg() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>BODY BG — drawBodyBg (surf1 fill + borderS frame)</div>
      <div style={{ width: 240, height: 60, background: T.surf1, border: `1px solid ${T.borderS}`, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <span style={{ ...mono(9), color: T.textDim }}>CONTENT AREA</span>
      </div>
    </div>
  );
}

function MolZoneRow() {
  return (
    <div style={sectionWrap}>
      <div style={sectionTitle}>ZONE ROW + PROT ZONE PAIR — drawZoneRow / drawProtZonePair</div>
      <div style={{ ...sampleBox, display: "flex", flexDirection: "column", gap: 4 }}>
        {[
          { zone: "HEAD", bite: 0.8, scratch: 0.6 },
          { zone: "TORSO", bite: 0.95, scratch: 0.9 },
          { zone: "LEGS", bite: 0.4, scratch: 0.3 },
        ].map((z, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 8, height: 24, padding: "0 8px" }}>
            <span style={{ ...mono(9), color: T.textDim, textTransform: "uppercase", width: 60 }}>{z.zone}</span>
            <div style={{ flex: 1, display: "flex", gap: 4 }}>
              <div style={{ flex: 1, height: 10, background: T.surf3, border: `1px solid ${T.border}`, position: "relative" }}>
                <div style={{ position: "absolute", left: 1, top: 1, bottom: 1, width: `${z.bite * 100}%`, background: z.bite > 0.6 ? T.positive : z.bite > 0.3 ? T.warning : T.danger }} />
              </div>
              <div style={{ flex: 1, height: 10, background: T.surf3, border: `1px solid ${T.border}`, position: "relative" }}>
                <div style={{ position: "absolute", left: 1, top: 1, bottom: 1, width: `${z.scratch * 100}%`, background: z.scratch > 0.6 ? T.positive : z.scratch > 0.3 ? T.warning : T.danger }} />
              </div>
            </div>
          </div>
        ))}
        <div style={{ display: "flex", gap: 8, padding: "0 8px" }}>
          <span style={{ ...mono(7), color: T.textDim, marginLeft: 68 }}>BITE</span>
          <span style={{ ...mono(7), color: T.textDim, flex: 1, textAlign: "center" }}>SCRATCH</span>
        </div>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  MAIN CATALOG
// ═══════════════════════════════════════════════════════════════════════

export default function ZeDCatalog() {
  return (
    <div style={{
      background: T.base,
      color: T.text,
      minHeight: "100vh",
      padding: 24,
      fontFamily: T.fontSans,
    }}>
      {/* Header */}
      <div style={{ marginBottom: 32 }}>
        <div style={{ ...mono(11), color: T.accent, textTransform: "uppercase", letterSpacing: "0.15em" }}>ZED-UI VISUAL CATALOG V3.0</div>
        <div style={{ ...sans(14), color: T.textSec, marginTop: 4 }}>Coded atomics only — pixel-perfect replicas from Tokens.lua, Atoms.lua, AtomExtensions.lua, Molecules.lua</div>
        <div style={{ ...mono(8), color: T.textDim, marginTop: 2 }}>DARK THEME · ORANGE ACCENT · SMALL TEXT PRESET</div>
      </div>

      {/* ─── TOKENS ─── */}
      <div style={{ ...mono(11), color: T.bright, textTransform: "uppercase", letterSpacing: "0.15em", marginBottom: 16, paddingBottom: 4, borderBottom: `1px solid ${T.accent}` }}>
        TOKENS — Tokens.lua
      </div>
      <TokenSurfaces />
      <TokenBorders />
      <TokenStatus />
      <TokenAccents />
      <TokenThermal />
      <TokenText />

      {/* ─── ATOMS ─── */}
      <div style={{ ...mono(11), color: T.bright, textTransform: "uppercase", letterSpacing: "0.15em", marginBottom: 16, paddingBottom: 4, borderBottom: `1px solid ${T.accent}`, marginTop: 32 }}>
        ATOMS — Atoms.lua
      </div>
      <AtomLabels />
      <AtomDividers />
      <AtomDrawBorder />
      <AtomIcon />
      <AtomFillBar />
      <AtomGradientBar />
      <AtomBarSegs />
      <AtomCheckbox />
      <AtomBadge />
      <AtomTooltip />
      <AtomScrollbar />
      <AtomFocusRing />

      {/* ─── ATOM EXTENSIONS ─── */}
      <div style={{ ...mono(11), color: T.bright, textTransform: "uppercase", letterSpacing: "0.15em", marginBottom: 16, paddingBottom: 4, borderBottom: `1px solid ${T.accent}`, marginTop: 32 }}>
        ATOM EXTENSIONS — AtomExtensions.lua (System 7 Chrome)
      </div>
      <AtomRounded />
      <AtomDoubleRounded />
      <AtomGroove />
      <AtomGrowBox />
      <AtomCloseBox />
      <AtomTriangles />
      <AtomStatusDots />
      <AtomPillButton />
      <AtomLegendSwatch />
      <AtomStatusLabel />
      <AtomResizeRidges />

      {/* ─── MOLECULES ─── */}
      <div style={{ ...mono(11), color: T.bright, textTransform: "uppercase", letterSpacing: "0.15em", marginBottom: 16, paddingBottom: 4, borderBottom: `1px solid ${T.accent}`, marginTop: 32 }}>
        MOLECULES — Molecules.lua
      </div>
      <MolButton />
      <MolListRow />
      <MolTab />
      <MolTitleBar />
      <MolStatChip />
      <MolSectionHeader />
      <MolStatRow />
      <MolStatBarRow />
      <MolTextInput />
      <MolSearchField />
      <MolActionStrip />
      <MolVerbStrip />
      <MolDock />
      <MolDataRow />
      <MolBodyBg />
      <MolZoneRow />

      {/* Footer */}
      <div style={{ marginTop: 48, paddingTop: 12 }}>
        <div style={{ height: 1, background: T.grooveDark }} />
        <div style={{ height: 1, background: T.grooveLight }} />
        <div style={{ ...mono(8), color: T.textDim, marginTop: 8 }}>
          ZEROID DAY USER INTERFACE · MICROTOSH SYSTEM 7.1.2 · BUILD 42 · CODED ATOMICS ONLY
        </div>
      </div>
    </div>
  );
}