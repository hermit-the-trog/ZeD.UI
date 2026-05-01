# ZeD-UI — Steam Workshop Page Draft

> **Status:** Coming Soon — hype build, not subscribable yet
> **Visual assets:** Pull from HTML mockups (token reference, two-windows, equipped, multicontainer)
> **Tone:** Confident, direct, zero corporate. Speaks to the PZ community as builders, not consumers.

---

## PAGE STRUCTURE

Steam Workshop pages use BBCode. Below is the full copy draft with section markers and visual placement notes. Each `[VISUAL]` tag indicates where a screenshot or mockup capture should go.


---


## 1. BUILD COMPATIBILITY BANNER

```
Build Support: B42.16+ (Build 42 only)
Status: In Development — Coming Soon
```

Short, up top, no ambiguity. People scan for this first.


---


## 2. HERO STATEMENT

ZeD-UI replaces Project Zomboid's entire interface. Not a skin. Not a reshade. A complete UI built from the ground up.

Zero Day User Interface. Running on ZeD.UI 7.1.2b — a hacked kernel inspired by a fictional 1993-era operating system that never existed but should have. Think Microtosh System 7.1.2 from an alternate timeline where the desktop wars went differently. Hard geometry, visible window chrome, pixel-precise borders. Every panel, every list, every button has been redesigned from scratch using a component architecture that reads theme data fresh every single frame.

If you've ever wished PZ's interface felt like it was designed by someone who actually thinks about hierarchy, affordance, and information architecture — that's what this is.

> **Design note:** This opening needs to land three things: the "not a skin" distinction, the ZeD.UI kernel lore (gives it personality without being cringe), and the architectural confidence. Every other UI mod in the Workshop is a skin or overlay. We're the only ground-up rebuild.


---


## 3. SCREENSHOT CAROUSEL

[VISUAL: 3-5 mockup captures, ordered for maximum impact]

1. **Character Window with drawer open** — shows the full chrome, tab strip, item card in drawer, inventory list, container strip. The money shot.
2. **Two Windows side by side** — Character Window + World Window facing inward. Shows the "four objects on screen" philosophy.
3. **Theme showcase** — same window in 3-4 different accent colors (Amber, Blue, Red, Mono). Proves the theme system isn't theoretical.
4. **Token reference** — the component library grid showing atoms, molecules, typography. Signals "this is engineered, not hacked together."
5. **Item Card close-up** — nutrition stacking, condition bars, badges, rename field. The detail that makes people stop scrolling.

> **Asset source:** Capture these from the HTML mockups at `/mockups/`. Open each in a browser, set viewport to 1920x1080, screenshot. For the theme showcase, use the token reference mockup and swap accent variables.


---


## 4. WHAT MAKES THIS DIFFERENT

### This is not a UI skin.

Most UI mods for Project Zomboid restyle the existing panels — new colors, new fonts, adjusted spacing. The vanilla code runs underneath, and you get a fresh coat of paint on the same architecture.

ZeD-UI throws all of that away.

Every panel is rebuilt from scratch using a hierarchical component library: Tokens (colors, spacing, typography) feed into Atoms (borders, buttons, checkboxes) which compose into Molecules (scroll lists, tab strips, action bars) which assemble into Organisms (the Item Card, the Character Window, the inventory list). The entire system reads its theme data fresh every frame — change your accent color and everything updates instantly, everywhere, with zero stale state.

The result is an interface that actually works like a designed system instead of a collection of panels that happen to be next to each other.


---


## 5. FEATURE PILLARS

### Two Windows. That's It.

[VISUAL: Two-windows mockup, annotated]

The entire PZ game interface collapses into two mirrored windows:

**Character Window** — "me and my stuff." Inventory, equipment, health, skills, protection, thermal status, journal, identity. Everything about your survivor in one window with a tab strip and a drawer.

**World Window** — "the world and its stuff." Loot containers, crafting, building, foraging, fishing, animal husbandry. Everything you can interact with in the world, mirrored layout.

Four draggable objects on your HUD: Character Window, World Window, minimap, watch. No docked panels. No floating button strips. No UI clutter competing for your attention during a helicopter event.

Lists face inward. Drawers face outward. Drag and drop between windows is natural across the center gap.

---

### Gamepad-Native. Not Gamepad-Tolerant.

[VISUAL: Gamepad button badge examples overlaid on UI elements]

ZeD-UI is built by a gamepad player. Not adapted for one after the fact — designed for one from day one.

Every interaction in ZeD-UI works with a controller. Tab switching, drawer navigation, item selection, drag and drop, context menus, action strip verbs — all of it is reachable without touching a mouse. Button badges update live to match your controller (Xbox, PlayStation, Steam Deck). Focus states are visible and unambiguous — you always know where you are.

Most PZ UI mods treat gamepad as a footnote or a known limitation. We treat it as a first-class input method because for a lot of players, it's the only input method. If you play PZ on the couch, on a Steam Deck, or with accessibility controllers — this mod was designed with you sitting in the chair.

---

### The Drawer Kills Tooltips

[VISUAL: Drawer open with Item Card, showing snap-back workflow]

Tooltips are gone. Not hidden — eliminated.

Select an item and the drawer opens with a full Item Card: icon, name (click to rename), condition bar, weight, category, nutrition breakdown, protection stats, status alerts. Everything you need to know, laid out with actual visual hierarchy instead of crammed into a floating rectangle.

Select a tab — Health, Equipment, Skills — and the drawer shows that content instead. The killer feature is snap-back: click the Health tab, see your wounds. Click a bandage in your inventory, the drawer swaps to the bandage's Item Card with "Apply Bandage" in the action strip. Apply it, and the drawer snaps back to Health showing the wound now bandaged. You never lost context. You just reached for a tool.

---

### 80+ Theme Combinations (300+ at Launch)

[VISUAL: Grid of accent color previews — 3x3 or similar]

Three base themes: Dark, Light, High Contrast.
Nine accent colors: Red, Orange, Yellow, Green, Blue, Teal, Purple, Pink, Mono.
Three text sizes: Small, Medium, Large.
Colorblind correction modes coming: Protanopia, Deuteranopia, Tritanopia, Achromatopsia.

81 base configurations. 324 when colorblind modes ship at launch. Switch at runtime — no restart, no reload. Every component reads the theme table fresh every frame. Change your accent from Amber to Blue and the entire interface updates instantly.

---

### Microtosh System 7.1.2 — A Fictional OS for a Fictional Apocalypse

[VISUAL: Close-up of window chrome — title bar stripes, close box, grow box, groove dividers]

ZeD.UI 7.1.2b is a hacked kernel running a fictional operating system from 1993. Microtosh System 7.1.2 — the desktop OS from the timeline where the competition built something worth stealing. Striped title bars. Close boxes. Grow boxes with diagonal ridges. Groove dividers. WindowShade (double-click the title bar to roll the window up). Hard geometry everywhere — zero border radius on structural containers, pixel-precise 1px borders.

This isn't nostalgia cosplay. The early-90s desktop visual language solved real problems that modern flat design forgot: every element communicates its function through its appearance. A striped title bar says "this is a window you can move." A grow box says "drag here to resize." A close box says "click to dismiss." No ambiguity. No guessing. No mystery meat navigation.

We cherry-pick from across the Microtosh lineage — System 6, 7.1.5, 7.5, OS 9 — wherever a later version solved a problem better. But everything gets dressed in 7.1.2 clothes. The result is a UI that feels like it was running on hardware that died in 1993 and somehow survived the Knox Event.

---

### Dual Typography

Two font voices, one rule: monospace is the system talking, sans-serif is content.

**Fira Mono** handles all chrome: window titles, labels, categories, metadata, timestamps, button text. When you see monospace, the interface is speaking to you.

**Fira Sans** handles all content: item descriptions, body text, tooltips, user-generated names. When you see sans-serif, you're reading game data.

Font hierarchy comes from caps and color, never from size. Three sizes — Small, Medium, Large — and that clean switch replaces every granular font slider you've seen in other mods.

---

### Hand-Built Context Menu Icons

[VISUAL: Grid sample of context menu icons, showing variety across categories]

Every right-click action gets a visual identity. Vanilla Project Zomboid already ships some genuinely great isometric icons — so we use them. Where vanilla doesn't cover an action, we build custom icons from scratch in the same iso style. No third-party icon packs. No mismatched aesthetic. Everything looks like it belongs in the same game because it does.

When you right-click a bandage and see the medical cross, or right-click a plank and see the hammer — that's not decoration. That's reducing the time between "I want to do something" and finding it in a list of twelve verbs.

---

### Nobody Gets Left Out

This isn't a feature. It's a rule. Every accessibility feature ships before release — not after, not in a patch, not "when we get to it." Before.

**Colorblind modes on day one.** Protanopia, Deuteranopia, Tritanopia, Achromatopsia. Not a filter overlay — purpose-built palettes integrated into the theme system. Every accent color, every status indicator, every health bar is designed to be readable in every mode.

**Dyslexia-friendly typography option.** A dedicated text rendering mode that improves readability for dyslexic players. Because if your font choice locks someone out of reading item descriptions during a siege, your font choice is wrong.

**Zero added flashes. Zero distracting animations.** The UI doesn't blink at you, pulse at you, bounce, or shake unless it's communicating something critical. No gratuitous motion. No "juice" that triggers photosensitivity or competes with the game for your attention. The interface is calm. The zombies are not. That's the correct division of labor.

**High Contrast as a base theme.** Not a toggle buried in a submenu — one of three base themes built with the same care as Dark and Light. Surface alpha at 0.95 for maximum separation.

**Minimum 4.5:1 contrast ratio** for all standard text. 3:1 for large text and UI components. Three font sizes — Small, Medium, Large — because a clean switch is more useful than a slider nobody can calibrate while zombies are breaking down the door.

**Full gamepad and alternative controller support.** Every screen, every interaction, every menu is navigable without a mouse. (See the Gamepad section above.)

Built to Xbox Accessibility Guidelines and Game Accessibility Guidelines standards. Not because we had to. Because it sucks being the person who gets overlooked. Games are for everyone. That includes the people most games forget about.

---

### Built for Modders

[VISUAL: Token reference showing the component architecture grid]

ZeD-UI isn't a black box. The component architecture — Tokens, Atoms, Molecules, Organisms — is a public system that other mods can build on top of.

Need a custom settings panel for your mod? Use the same atoms and molecules ZeD-UI uses internally. Need to match the visual language without reverse-engineering styles? Read the token table. The theme system is global and reactive — your mod's UI stays in sync automatically.

More documentation on the modder API is coming as we approach release.


---


## 6. CURRENT STATUS

ZeD-UI is in active development. Here's where things stand:

**Working in-game now:**
- Complete token/theme system (81 base configurations, 324 with colorblind modes at launch)
- 16 atoms, 16 molecules, 7 organisms coded and tested
- Character Window shell with full chrome, tab strip, drawer, container strip
- Item Card with 10 category formatters, responsive layout, inline rename
- Inventory list renderer with grouped rows, scrolling, multi-select, column sorting, expand/collapse
- Drag and drop with ghost card thumbnails
- Context menu integration (vanilla compatibility preserved)
- Vanilla inventory keybind takeover (seamless toggle)
- Context menu icons (vanilla + custom iso-style handbuilt)

**Coming next:**
- World Window implementation (mirrored architecture)
- Moodle bar with smart gravity
- Action strip batch verbs (Repair All, Wash All, Pad All)
- Remaining panel replacements (crafting, character info, HUD elements)
- CaZio watch system
- Custom cursor set and gamepad badge graphics
- Full modder API documentation

**What to expect at launch:**
- Complete replacement of all major PZ interface panels
- Full controller/gamepad support — every screen, every interaction
- All accessibility features: colorblind modes, dyslexia support, high contrast, zero-flash policy
- Settings panel with search, per-section reset, intercepted vanilla settings
- Mod settings schema system (declare your mod's settings, we generate the UI)


---


## 7. COMPATIBILITY AND REQUIREMENTS

**Build:** 42.16+ (Build 42 only)
**Dependencies:** None — ZeD-UI is standalone
**Conflicts:** Will conflict with any mod that modifies the same vanilla UI panels. Detailed compatibility list will be published at release.
**Performance:** Designed for zero-allocation rendering where possible. Theme reads are table lookups, not function calls.
**Multiplayer:** Supported — per-player theme settings, all rendering is client-side.


---


## 8. CREDITS

**Design Direction** — Dude (ZeD Team)
**Development** — Claude (ZeD Team)
**Icons** — Vanilla Project Zomboid icons + custom hand-built iso icons
**Typography** — Fira Mono, Fira Sans (Mozilla / The Fira Project)

---


## NOTES FOR DUDE

### Visual asset checklist
- [ ] Capture Character Window mockup at 1920x1080 (primary hero image)
- [ ] Capture Two Windows layout mockup
- [ ] Generate 4-6 accent color variants from token reference
- [ ] Capture Item Card detail view
- [ ] Capture context menu icon grid (may need a dedicated layout for this)
- [ ] Create or capture component architecture overview (atoms/molecules grid)

### Decisions still needed
- **Mod name styling:** "ZeD-UI" or "ZeD UI" (mod.info currently says "ZeD UI" without hyphen)
- **Workshop tags:** Which Steam tags to apply (UI, Overhaul, Quality of Life, Accessibility?)
- **poster.png:** Need the Workshop thumbnail image (Workshop standard is 268x268 or 637x358)
- **Changelog format:** How to structure the Change Notes tab once we start publishing updates
- **Discord/community link:** Do we want a Discord or community hub linked from the page?

### What Clean UI does that we should consider
- Numbered screenshot callouts (1-8 labeled points on a single image) — very effective for "here's what changed" communication
- Pinned bug report thread in Discussions
- Clear dependency callout with linked mod tile
- Controller support caveat section
- Explicit "mods to unsubscribe" conflict list

### What we do that Clean UI doesn't
- Ground-up architecture (not a skin)
- Full theme system with colorblind modes
- Accessibility as architecture
- Component library for other modders
- System 7 visual language (unique aesthetic identity)
- Dual typography system
- Drawer-based information architecture (no tooltips)
- "Two Windows" information architecture
