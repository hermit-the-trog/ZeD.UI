import { useState } from "react";

// ═══════════════════════════════════════════════════════════════════════
// ZeD-UI Item Card — 220w D+E Hybrid
// Sticky head (icon + name + condition + actions) over scroll body with
// always-visible stats and foldable Nutrition / Ingredients / Per-Zone.
// Token values pulled directly from Tokens.lua (dark + orange).
// Mirrors the Visual Catalog v3 component pattern for 1:1 Lua translation.
// ═══════════════════════════════════════════════════════════════════════

// ─── Design Tokens (Dark theme + Orange accent, exact from Tokens.lua) ───
const T = {
  // Surfaces (hex + 0.92 alpha)
  base:    "rgba(12,12,12,0.92)",
  surf1:   "rgba(20,20,20,0.92)",
  surf2:   "rgba(28,28,28,0.92)",
  surf3:   "rgba(36,36,36,0.92)",
  surf4:   "rgba(44,44,44,0.92)",
  // Borders
  border:  "#202020",
  borderS: "#383838",
  // Accent (orange)
  accent:       "#D4922A",
  bright:       "#E8A830",
  hover:        "rgba(212,146,42,0.22)",
  textOnAccent: "#0C0C0C",
  // Text
  text:     "rgba(218,218,218,0.90)",
  textSec:  "rgba(161,161,161,0.65)",
  textDim:  "rgba(161,161,161,0.65)",
  textHead: "rgba(230,230,230,0.92)",
  // Status
  danger:   "#C45A2A",
  warning:  "#C49A2A",
  positive: "#7A9A34",
  info:     "#5A8A9A",
  // Chrome
  grooveDark:  "rgba(0,0,0,0.50)",
  grooveLight: "rgba(255,255,255,0.06)",
  stripe:      "rgba(255,255,255,0.04)",
  // Soiled
  soiledWet:   "rgba(96,176,232,0.9)",
  soiledBlood: "rgba(255,106,106,0.9)",
  soiledDirt:  "rgba(200,152,96,0.9)",
  // Materials
  matLeather: "#B08A5E",
  matDenim:   "#5B8ABF",
  matFabric:  "rgba(255,255,255,0.55)",
  // Fonts (web equivalents)
  fontMono: "'Courier New', Courier, monospace",
  fontSans: "system-ui, -apple-system, 'Segoe UI', sans-serif",
  // Sizes (small preset — matches Tokens.lua small)
  titleBarH:  26,
  buttonH:    22,
  fillBarH:   13,
  closeBoxSz: 13,
  iconBoxSz:  32,
  pad:        10,
  rowH:       16,  // stat row
};

// ─── Shared style fragments ───
const mono = (sz = 10) => ({ fontFamily: T.fontMono, fontSize: sz, lineHeight: 1.2 });
const sans = (sz = 11) => ({ fontFamily: T.fontSans, fontSize: sz, lineHeight: 1.2 });

const labelStyle = {
  ...mono(10),
  textTransform: "uppercase",
  letterSpacing: "0.05em",
  color: T.textSec,
};

const valueStyle = {
  ...sans(11),
  color: T.text,
  textAlign: "right",
};

// ─── Pixel grid helper: draws rects like PZ does ───
function Px({ x, y, w, h, color }) {
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width: w,
        height: h,
        background: color,
      }}
    />
  );
}

// ═══════════════════════════════════════════════════════════════════════
// CHROME PRIMITIVES — match Atoms.lua / Molecules.lua
// ═══════════════════════════════════════════════════════════════════════

// drawWindowTitleBar — striped title bar with close box
function TitleBar({ title = "Item" }) {
  return (
    <div
      style={{
        height: T.titleBarH,
        background: T.surf2,
        borderBottom: `1px solid ${T.borderS}`,
        position: "relative",
        overflow: "hidden",
        display: "flex",
        alignItems: "center",
      }}
    >
      {/* Horizontal stripes (4px interval) */}
      {Array.from({ length: 7 }, (_, i) => (
        <div
          key={i}
          style={{
            position: "absolute",
            left: 0,
            right: 0,
            top: i * 4,
            height: 1,
            background: T.stripe,
          }}
        />
      ))}
      {/* Close box */}
      <div
        style={{
          position: "relative",
          width: T.closeBoxSz,
          height: T.closeBoxSz,
          background: T.surf2,
          border: `1px solid ${T.borderS}`,
          margin: "0 8px",
          zIndex: 1,
          flexShrink: 0,
        }}
      />
      {/* Title */}
      <span
        style={{
          ...mono(11),
          color: T.textHead,
          textTransform: "uppercase",
          letterSpacing: "0.12em",
          zIndex: 1,
        }}
      >
        {title}
      </span>
    </div>
  );
}

// drawIcon — bordered icon box (placeholder ‹emoji›)
function IconBox({ glyph }) {
  return (
    <div
      style={{
        width: T.iconBoxSz,
        height: T.iconBoxSz,
        background: T.surf3,
        border: `1px solid ${T.border}`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: 18,
        flexShrink: 0,
      }}
    >
      {glyph}
    </div>
  );
}

// drawFillBar — condition / freshness / generic ratio bar
function FillBar({ ratio, tone = "good" }) {
  const tones = {
    good: { color: T.positive },
    warn: { color: T.warning },
    bad:  { color: T.danger },
  };
  const c = tones[tone];
  return (
    <div
      style={{
        flex: "1 1 auto",
        height: T.fillBarH,
        background: T.surf3,
        border: `1px solid ${T.border}`,
        position: "relative",
        minWidth: 30,
      }}
    >
      <div
        style={{
          position: "absolute",
          left: 0,
          top: 0,
          bottom: 0,
          width: `${Math.max(0, Math.min(100, ratio * 100))}%`,
          background: c.color,
          opacity: 0.55,
        }}
      />
    </div>
  );
}

// drawBarRow — label + bar + percent (one row)
function BarRow({ label, ratio, tone }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
      <span style={{ ...labelStyle, flex: "0 0 auto" }}>{label}</span>
      <FillBar ratio={ratio} tone={tone} />
      <span style={{ ...sans(11), color: T.text, flex: "0 0 32px", textAlign: "right" }}>
        {Math.round(ratio * 100)}%
      </span>
    </div>
  );
}

// drawStatRow — label : value (one row)
function StatRow({ label, value, valueColor }) {
  return (
    <div
      style={{
        display: "flex",
        justifyContent: "space-between",
        alignItems: "baseline",
        padding: "1px 0",
      }}
    >
      <span style={labelStyle}>{label}</span>
      <span style={{ ...valueStyle, color: valueColor || T.text }}>{value}</span>
    </div>
  );
}

// drawButton — 22px square with 1px border
function Button({ glyph, active = false, greyed = false }) {
  return (
    <span
      style={{
        width: T.buttonH,
        height: T.buttonH,
        background: "transparent",
        border: `1px solid ${active ? T.accent : T.borderS}`,
        color: active ? T.accent : T.text,
        ...mono(11),
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        opacity: greyed ? 0.42 : 1,
        cursor: "pointer",
      }}
    >
      {glyph}
    </span>
  );
}

// drawActionStrip — toggles left, verbs right
function ActionStrip({ toggles, verbs }) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        gap: 4,
      }}
    >
      <div style={{ display: "flex", gap: 3 }}>
        {toggles.map((t, i) => (
          <Button key={i} {...t} />
        ))}
      </div>
      <div style={{ display: "flex", gap: 3 }}>
        {verbs.map((v, i) => (
          <Button key={i} {...v} />
        ))}
      </div>
    </div>
  );
}

// drawBadge — alert pill (Equipped / Dirty / Cooked / etc.)
function Badge({ text, variant = "warning" }) {
  const colors = {
    danger:   T.danger,
    warning:  T.warning,
    info:     T.info,
    positive: T.positive,
    accent:   T.accent,
  };
  const c = colors[variant];
  return (
    <span
      style={{
        ...mono(9),
        textTransform: "uppercase",
        letterSpacing: "0.06em",
        padding: "2px 5px",
        border: `1px solid ${c}`,
        background: "rgba(255,255,255,0.04)",
        color: c,
      }}
    >
      {text}
    </span>
  );
}

// ═══════════════════════════════════════════════════════════════════════
// DISCLOSURE — foldable section with triangle indicator
// State persists per item TYPE (not per item) — caller passes open/setOpen.
// In Lua: ZeD.WinState modData by item category key.
// ═══════════════════════════════════════════════════════════════════════
function Disclosure({ label, count, open, onToggle, children }) {
  return (
    <>
      <div
        onClick={onToggle}
        style={{
          display: "flex",
          alignItems: "center",
          gap: 6,
          ...mono(10),
          textTransform: "uppercase",
          letterSpacing: "0.08em",
          color: T.textSec,
          cursor: "pointer",
          padding: "6px 0",
          borderTop: `1px solid ${T.border}`,
          userSelect: "none",
        }}
      >
        <span style={{ fontSize: 8, color: T.accent, width: 8, display: "inline-block" }}>
          {open ? "▼" : "▶"}
        </span>
        <span>{label}</span>
        {count != null && (
          <span style={{ marginLeft: "auto", color: T.textDim, fontSize: 9 }}>{count}</span>
        )}
      </div>
      {open && <div style={{ padding: "4px 0 6px" }}>{children}</div>}
    </>
  );
}

// ═══════════════════════════════════════════════════════════════════════
// PER-ZONE BLOCK (clothing detail zone content)
// Renders inside the Per-Zone Detail disclosure body.
// ═══════════════════════════════════════════════════════════════════════
function ZoneDock({ flag, flagColor }) {
  return (
    <div style={{ display: "flex", alignItems: "stretch", height: 18, flex: "0 0 auto" }}>
      <span
        style={{
          ...mono(9),
          textTransform: "uppercase",
          padding: "0 5px",
          border: `1px solid ${T.borderS}`,
          borderRight: "none",
          display: "flex",
          alignItems: "center",
          background: "rgba(255,255,255,0.02)",
          color: flagColor,
        }}
      >
        {flag}
      </span>
      <span
        style={{
          width: 18,
          height: 18,
          background: "transparent",
          border: `1px solid ${T.borderS}`,
          color: T.text,
          ...mono(10),
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        🪡
      </span>
    </div>
  );
}

function ZoneBlock({ name, pct, dock, soiled, isFirst }) {
  return (
    <div
      style={{
        padding: "4px 0",
        borderTop: isFirst ? "none" : `1px dashed ${T.border}`,
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 4, marginBottom: 2 }}>
        <span
          style={{
            ...mono(9),
            textTransform: "uppercase",
            letterSpacing: "0.05em",
            color: T.textSec,
            flex: "1 1 auto",
          }}
        >
          {name}
        </span>
        <span
          style={{
            ...sans(10),
            color: T.text,
            flex: "0 0 auto",
            paddingRight: dock ? 4 : 0,
          }}
        >
          {pct}%
        </span>
        {dock && <ZoneDock flag={dock.flag} flagColor={dock.color} />}
      </div>
      {soiled && (
        <div style={{ display: "flex", gap: 6, ...mono(9) }}>
          {soiled.blood != null && (
            <span style={{ color: T.soiledBlood }}>🩸 {soiled.blood}%</span>
          )}
          {soiled.dirt != null && (
            <span style={{ color: T.soiledDirt }}>🟤 {soiled.dirt}%</span>
          )}
          {soiled.wet != null && (
            <span style={{ color: T.soiledWet }}>💧 {soiled.wet}%</span>
          )}
        </div>
      )}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════
// NUTRITION FACTS BODY (lives inside the Nutrition disclosure)
// ═══════════════════════════════════════════════════════════════════════
function NutritionFacts({ rows }) {
  return (
    <div>
      <div style={{ height: 2, background: T.borderS, margin: "2px 0" }} />
      {rows.map((row, i) => (
        <div key={i}>
          <StatRow label={row.label} value={row.value} />
          {i < rows.length - 1 && (
            <div style={{ height: 1, background: T.border }} />
          )}
        </div>
      ))}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════
// THE STICKY HEAD — icon + name | condition | action strip
// ═══════════════════════════════════════════════════════════════════════
function StickyHead({ icon, name, bar, toggles, verbs }) {
  return (
    <div
      style={{
        background: T.surf2,
        padding: T.pad,
        borderBottom: `1px solid ${T.borderS}`,
        display: "flex",
        flexDirection: "column",
        gap: 6,
      }}
    >
      {/* Row 1: icon + name */}
      <div style={{ display: "flex", gap: 8, alignItems: "flex-start" }}>
        <IconBox glyph={icon} />
        <div
          style={{
            flex: "1 1 auto",
            minWidth: 0,
            display: "flex",
            alignItems: "center",
            minHeight: T.iconBoxSz,
          }}
        >
          <span
            style={{
              ...sans(13),
              color: T.text,
              fontWeight: 500,
              wordWrap: "break-word",
            }}
          >
            {name}
          </span>
        </div>
      </div>
      {/* Row 2: condition / freshness bar */}
      {bar && <BarRow {...bar} />}
      {/* Row 3: action strip */}
      <ActionStrip toggles={toggles} verbs={verbs} />
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════
// THE WINDOW SHELL
// ═══════════════════════════════════════════════════════════════════════
function CardWindow({ children }) {
  return (
    <div
      style={{
        width: 220,
        background: T.surf1,
        border: `1px solid ${T.borderS}`,
        display: "flex",
        flexDirection: "column",
      }}
    >
      <TitleBar title="Item" />
      {children}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════
// CARD VARIANTS — one per item category
// In production this is a single ZeD_ItemCard with switch on category.
// Keeping them split here so each is a clean reference for Lua porting.
// ═══════════════════════════════════════════════════════════════════════

function ClothingCard({ open, toggleFold }) {
  return (
    <CardWindow>
      <StickyHead
        icon="🧥"
        name="Leather Jacket"
        bar={{ label: "Cond.", ratio: 0.62, tone: "warn" }}
        toggles={[
          { glyph: "★", active: true },
          { glyph: "⊘" },
          { glyph: "✕" },
        ]}
        verbs={[
          { glyph: "🪡" },
          { glyph: "🛏", greyed: true },
        ]}
      />
      <div style={{ padding: T.pad }}>
        {/* Alerts strip — small inline badges at top of body */}
        <div style={{ display: "flex", gap: 4, flexWrap: "wrap", padding: "2px 0 6px" }}>
          <Badge text="Equipped" variant="accent" />
          <Badge text="Dirty" variant="warning" />
        </div>
        {/* Stats — always open */}
        <StatRow label="Body loc." value="Torso" />
        <StatRow label="Bite def." value="68%" />
        <StatRow label="Scratch" value="82%" />
        <StatRow label="Move pen." value="+0.4" valueColor={T.warning} />
        <StatRow label="Fabric" value="Leather" />
        <StatRow label="Category" value="Clothing" />
        <StatRow label="Weight" value="2.5 kg" />
        {/* Per-Zone Detail — folded by default */}
        <Disclosure
          label="Per-Zone Detail"
          count={5}
          open={open.zones}
          onToggle={() => toggleFold("zones")}
        >
          <ZoneBlock
            isFirst
            name="Torso"
            pct={82}
            dock={{ flag: "Leather", color: T.matLeather }}
            soiled={{ blood: 5, dirt: 2 }}
          />
          <ZoneBlock
            name="L. Sleeve"
            pct={20}
            dock={{ flag: "Torn", color: T.danger }}
            soiled={{ blood: 15, dirt: 23 }}
          />
          <ZoneBlock name="R. Sleeve" pct={100} />
        </Disclosure>
      </div>
    </CardWindow>
  );
}

function FoodCard({ open, toggleFold }) {
  const nutritionRows = [
    { label: "Serving", value: "0.8 kg" },
    { label: "Calories", value: "420" },
    { label: "Total Fat", value: "12g" },
    { label: "Carbs", value: "38g" },
    { label: "Protein", value: "22g" },
  ];
  return (
    <CardWindow>
      <StickyHead
        icon="🍲"
        name="Beef Stew"
        bar={{ label: "Fresh.", ratio: 0.78, tone: "good" }}
        toggles={[{ glyph: "★" }, { glyph: "⊘" }, { glyph: "✕" }]}
        verbs={[{ glyph: "🍴" }]}
      />
      <div style={{ padding: T.pad }}>
        <div style={{ display: "flex", gap: 4, flexWrap: "wrap", padding: "2px 0 6px" }}>
          <Badge text="Cooked" variant="positive" />
        </div>
        <StatRow label="Hunger" value="−45" valueColor={T.positive} />
        <StatRow label="Thirst" value="−12" valueColor={T.positive} />
        <StatRow label="Boredom" value="−8" valueColor={T.positive} />
        <StatRow label="Status" value="Cooked" valueColor={T.positive} />
        <StatRow label="Category" value="Food" />
        <StatRow label="Weight" value="0.8 kg" />
        <Disclosure
          label="Nutrition Facts"
          open={open.nutrition}
          onToggle={() => toggleFold("nutrition")}
        >
          <NutritionFacts rows={nutritionRows} />
        </Disclosure>
        <Disclosure
          label="Ingredients"
          count={5}
          open={open.ingredients}
          onToggle={() => toggleFold("ingredients")}
        >
          <div
            style={{
              ...mono(9),
              lineHeight: 1.45,
              color: T.text,
            }}
          >
            <span
              style={{
                color: T.textSec,
                textTransform: "uppercase",
                letterSpacing: "0.05em",
              }}
            >
              Items:{" "}
            </span>
            Beef, Potato, Carrot, Onion, Salt
          </div>
          <div style={{ marginTop: 4 }}>
            <StatRow label="Cook time" value="35 min" />
          </div>
        </Disclosure>
      </div>
    </CardWindow>
  );
}

function WeaponCard() {
  // No disclosures — weapons have no fold-worthy content.
  // This is the leanest the card ever needs to be.
  return (
    <CardWindow>
      <StickyHead
        icon="🔧"
        name="Crowbar"
        bar={{ label: "Cond.", ratio: 0.88, tone: "good" }}
        toggles={[{ glyph: "★" }, { glyph: "⊘" }, { glyph: "✕" }]}
        verbs={[{ glyph: "🔨" }, { glyph: "🪚" }]}
      />
      <div style={{ padding: T.pad }}>
        <StatRow label="Damage" value="0.6 − 1.2" />
        <StatRow label="Speed" value="Normal" />
        <StatRow label="Range" value="1.2" />
        <StatRow label="Crit" value="8%" />
        <StatRow label="Knockback" value="0.3" />
        <StatRow label="Tree dmg" value="35" />
        <StatRow label="Category" value="Weapon" />
        <StatRow label="Weight" value="2.4 kg" />
      </div>
    </CardWindow>
  );
}

// ═══════════════════════════════════════════════════════════════════════
// ROOT — toggle between item types, manage fold state per type
// ═══════════════════════════════════════════════════════════════════════
export default function App() {
  const [type, setType] = useState("clothing");

  // Fold state — per item TYPE, simulating modData persistence.
  // In Lua: ZeD.WinState.itemCardFolds[itemType][sectionKey] = bool
  const [folds, setFolds] = useState({
    clothing: { zones: false },
    food:     { nutrition: false, ingredients: false },
  });

  const toggleFold = (key) => {
    setFolds((prev) => ({
      ...prev,
      [type]: { ...prev[type], [key]: !prev[type][key] },
    }));
  };

  return (
    <div
      style={{
        background: "#0a0a0a",
        minHeight: "100vh",
        padding: 24,
        fontFamily: T.fontSans,
        color: T.text,
      }}
    >
      <h1
        style={{
          ...mono(14),
          textTransform: "uppercase",
          letterSpacing: "0.12em",
          color: T.accent,
          marginBottom: 6,
        }}
      >
        Item Card · 220w D+E Hybrid
      </h1>
      <div
        style={{
          ...mono(10),
          color: T.textSec,
          textTransform: "uppercase",
          letterSpacing: "0.08em",
          marginBottom: 32,
        }}
      >
        Sticky head · Stats open · Folds persist per item type
      </div>

      {/* Toggle bar */}
      <div style={{ display: "flex", gap: 8, marginBottom: 24, alignItems: "center" }}>
        <span
          style={{
            ...mono(10),
            color: T.textDim,
            textTransform: "uppercase",
            letterSpacing: "0.08em",
            marginRight: 4,
          }}
        >
          Item Type:
        </span>
        {["clothing", "food", "weapon"].map((t) => {
          const active = type === t;
          return (
            <button
              key={t}
              onClick={() => setType(t)}
              style={{
                ...mono(10),
                textTransform: "uppercase",
                letterSpacing: "0.08em",
                background: active ? T.accent : T.surf2,
                border: `1px solid ${active ? T.accent : T.borderS}`,
                color: active ? T.textOnAccent : T.text,
                padding: "6px 12px",
                cursor: "pointer",
              }}
            >
              {t}
            </button>
          );
        })}
      </div>

      {/* Card stage */}
      <div style={{ display: "flex", gap: 32, alignItems: "flex-start", flexWrap: "wrap" }}>
        {type === "clothing" && (
          <ClothingCard open={folds.clothing} toggleFold={toggleFold} />
        )}
        {type === "food" && <FoodCard open={folds.food} toggleFold={toggleFold} />}
        {type === "weapon" && <WeaponCard />}
      </div>
    </div>
  );
}
