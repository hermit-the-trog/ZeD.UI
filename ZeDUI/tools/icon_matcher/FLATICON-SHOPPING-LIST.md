# Flaticon Shopping List — Fuzzy Icon Refinements

Status as of S111 close. All 978 context entries + 197 fluids are covered, but many
use generic reuse icons where a specific Flaticon download would read sharper.

**Download convention** — save each PNG with the **target filename** in the rightmost
column (bare lowercase-hyphen, 512×512 white-on-transparent matches the pack style),
drop into `ZeDUI/tools/icon_matcher/vanilla-icons/`, run `11-sync-all.ps1`, then tell me
which names landed and I'll wire the Lua.

Ordered by visual impact — how often players see the icon × how fuzzy the current pick is.

---

## Tier 1 — High visibility, frequently seen

### Paint colors (12 entries — all currently `paint-bucket`)
When painting walls/signs, 12 color choices all show the same bucket. Needs per-color swatch.

| Entry | Flaticon search | Target filename |
|---|---|---|
| Black | `black square`, `color palette black` | `color-black` |
| Red | `red swatch`, `color dot red` | `color-red` |
| Blue | `blue swatch` | `color-blue` |
| Green | `green swatch` | `color-green` |
| Yellow | `yellow swatch` | `color-yellow` |
| Orange | `orange swatch` | `color-orange` |
| Purple | `purple swatch` | `color-purple` |
| Pink | `pink swatch` | `color-pink` |
| Brown | `brown swatch` | `color-brown` |
| Cyan | `cyan swatch` | `color-cyan` |
| Turquoise | `turquoise swatch` | `color-turquoise` |
| Grey | `grey swatch` | `color-grey` |
| White | `white swatch` (outline style) | `color-white` |

*Tip: if Flaticon has a single "paint palette" icon with distinct color dots in different colored variants, grab all 13 at once.*

### Equipment slots — primary/secondary already covered. Remaining:
| Entry | Flaticon search | Target filename |
|---|---|---|
| Equip on Back | `backpack slot`, `equip back` | `equip-back` |
| Equip Belt Left | `belt loop left`, `holster left` | `equip-belt-left` |
| Equip Belt Right | `belt loop right`, `holster right` | `equip-belt-right` |
| Holster | `pistol holster` | `holster-pistol` |

### Ammo/gun-type variants (complement the `new/` icons)
| Entry | Flaticon search | Target filename |
|---|---|---|
| ContextMenu_NoBullets | `empty magazine`, `no ammo` | `no-ammo` |
| Combine Ammo | `bullets stacked`, `ammo merge` | `ammo-combine` |
| Check Ammo | `magnifying glass bullet`, `ammo check` | `ammo-check` |
| Attach Bayonet | `bayonet`, `rifle bayonet` | `bayonet` |
| Unload (gun) | `magazine down arrow` | `mag-eject` |
| Rack (firearm) | `pump shotgun action` | `rack-action` |

### Furniture variants (currently all generic `table` / `shelves`)
| Entry | Flaticon search | Target filename |
|---|---|---|
| Large Table | `dining table`, `long table` | `table-large` |
| Small Table | `end table`, `small side table` | `table-small` |
| Table with Drawer | `desk drawer`, `table drawer` | `table-drawer` |
| Bookcase | `bookcase`, `library shelf` | `bookcase` |
| Small Bookcase | `small bookshelf` | `bookcase-small` |
| Double Shelves | `wide shelves`, `shelving unit` | `shelves-double` |
| Metal Counter | `kitchen counter metal` | `counter-metal` |
| Metal Counter Corner | `counter corner` | `counter-corner` |
| Small Locker | `school locker small` | `locker-small` |
| Big Locker | `tall locker` | `locker-big` |
| Metal Crate | `metal crate`, `storage crate` | `crate-metal` |
| Metal Drum | `oil drum`, `steel barrel` | `drum-metal` |

---

## Tier 2 — Specific semantic gaps

### Animal / hutch / farming
| Entry | Flaticon search | Target filename | Replaces |
|---|---|---|---|
| Hutch (generic) | `chicken coop`, `hutch cage` | `hutch` | `dog` |
| Hutch Info | same | `hutch-info` | — |
| AnimalInfo | `clipboard animal`, `pet records` | `animal-info` | `info-guide` |
| Shear (sheep) | `sheep shears`, `wool clippers` | `sheep-shears` | `scissors` |
| MakeChum / Bait Chum | `fish bait bucket` | `chum-bucket` | `fish-bones` |
| ButcheringHook | `meat hook`, `butcher hook` | `butcher-hook` | `knife` |
| DetachAnimal | `cut leash`, `untie rope` | `untie` | `paw` |

### Gardening
| Entry | Flaticon search | Target filename | Replaces |
|---|---|---|---|
| Rake | `garden rake` | `rake` | `shovel` |
| Hoe | `garden hoe` | `hoe` | — |
| Dig Furrow | `dig trench`, `furrow shovel` | `furrow-dig` | `shovel` |
| Compost / Composter | `compost bin`, `compost pile` | `compost-bin` | `poo` |
| GetCompost | `compost scoop`, `garden soil` | `compost-scoop` | `poo` |

### Cooking / food specifics
| Entry | Flaticon search | Target filename | Replaces |
|---|---|---|---|
| FoodType_Stock | `stock pot`, `broth pot` | `stock-broth` | `pot` |
| FoodType_Thickener | `flour bag`, `corn starch` | `thickener-flour` | `bag-seedling` |
| FoodType_Dressing | `salad dressing`, `vinaigrette` | `dressing` | `sauce` |
| FoodType_Spread | `butter knife spread`, `jam spread` | `spread` | `Butter` |
| FoodType_Garnish | `garnish herbs`, `parsley garnish` | `garnish` | `leaf` |
| FoodType_Roe | `fish roe`, `caviar` | `roe` | `egg` |
| FoodType_Poultry | `whole chicken raw` | `poultry` | `chicken-bucket` |
| FoodType_Greens | `leafy greens`, `spinach bunch` | `greens` | `leaf` |
| FoodType_Insect | `edible insect`, `cricket bowl` | `insect-food` | `bug` |

### Blacksmith / metal work
| Entry | Flaticon search | Target filename | Replaces |
|---|---|---|---|
| Anvil | `blacksmith anvil` | `anvil` | `hammer-crash` |
| UseBellows | `blacksmith bellows` | `bellows` | `flame` |
| Stone Furnace | `stone kiln`, `forge furnace` | `furnace-stone` | `grill-hot-alt` |
| Metal Welding | already `welding` | — | — |

### Fire mode dials
| Entry | Flaticon search | Target filename | Replaces |
|---|---|---|---|
| FireMode_Single | `semi-auto toggle`, `selector single` | `firemode-single` | `gun-shooting` |
| FireMode_Burst | `burst-fire 3-round` | `firemode-burst` | `burst` |
| FireMode_Auto | `full-auto selector` | `firemode-auto` | `gun-shooting` |

### Masonry / building
| Entry | Flaticon search | Target filename | Replaces |
|---|---|---|---|
| Masonry | `brick trowel`, `mason tool` | `mason-trowel` | `hammer` |
| Plaster | `plaster trowel`, `wall plaster` | `plaster-trowel` | `paint-roller` |
| PaintSign | `paint sign`, `hand-painted sign` | `paint-sign` | `paint-roller` |
| NeedBrush | `paintbrush` | `paintbrush` | — |

### Vehicle
| Entry | Flaticon search | Target filename | Replaces |
|---|---|---|---|
| VehicleHorn | `car horn`, `steering horn` | `car-horn` | `bullhorn` |
| VehicleLightbar | `police lightbar`, `roof siren` | `lightbar` | `siren-on` |

---

## Tier 3 — Clothing patterns (7 entries — all currently `fabric`)

Low player exposure (sewing kits). Only grab if you want to polish:

| Entry | Flaticon search | Target filename |
|---|---|---|
| BeigeStripe | `beige stripe pattern`, `pinstripe fabric` | `pattern-stripe-beige` |
| BlackFloral | `black floral pattern` | `pattern-floral-black` |
| Light_BlueStripe | `blue pinstripe fabric` | `pattern-stripe-blue` |
| Light_GreenDiamond | `diamond pattern green`, `argyle green` | `pattern-diamond-green` |
| GreenFloral | `green floral pattern` | `pattern-floral-green` |
| PinkChevron | `pink chevron pattern` | `pattern-chevron-pink` |
| PinkFloral | `pink floral pattern` | `pattern-floral-pink` |

---

## Tier 4 — Body part placement (for rings/bracelets/tattoos)

Currently all use generic `hand` (arm) or `hiking-boot` (leg). 20 entries.
Ideal would be per-limb anatomical icons. Only needed if you plan to display
tattoo-placement or jewelry-location menus a lot.

| Entry | Flaticon search | Target filename |
|---|---|---|
| L/R Middle Finger | `hand middle finger` | `finger-middle` |
| L/R Ring Finger | `hand ring finger`, `wedding ring finger` | `finger-ring` |
| L/R Wrist | `wrist bracelet` | `wrist` |
| L/R Forearm | `forearm tattoo` | `forearm` |
| L/R Upper Arm | `upper arm muscle` | `upper-arm` |
| L/R Shoulder | `shoulder anatomy` | `shoulder` |
| L/R Shin | `shin bone`, `calf front` | `shin` |
| L/R Thigh | `thigh anatomy` | `thigh` |
| L/R Knee | `knee joint` | `knee` |
| L/R Elbow | `elbow joint` | `elbow` |

*Note: left/right share one icon each; the resolver doesn't need mirror variants.*

---

## Workflow when you grab a batch

1. Save each PNG to `ZeDUI/tools/icon_matcher/vanilla-icons/` using the target filename.
2. Run `11-sync-all.ps1`.
3. Tell me the list of filenames that landed, and I'll update the Lua mappings to point to them.

Alternative: open `vanilla-catalog.html`, find the new icons in the library, and click-assign them to the action rows yourself. Export, paste into Lua, rerun chain.
