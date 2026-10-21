# ZeD-GUI Steam Workshop plan

*Written Oct 20 2026, revised Oct 21 2026 after the description and the thumbnail were settled. The director's brief: plan the Workshop page; the pictures, what it says (not a sales pitch, not a template; talk to the community like the community), getting people installed and running, feedback and bugs and add-on requests, making add-ons (language packs, themes, compatibility, tabs for other mods), which Workshop tools handle what, and how responsible people take over if ZeD's support ends.*

**Settled Oct 20-21:**

- **The name is ZeD-GUI** (ZeroDay Graphical User Interface). "UI" felt too modern; "GUI" fits the era. The Mod ID stays `ZeD_UI`, so saves, settings and server lines don't change. `mod.info`, the Options page title and the Safe mode notes already say ZeD-GUI.
- **The description is final** apart from the Workshop ID, which Steam assigns on the first upload. It's in the director's voice; see section 2.
- **The thumbnail is done:** the *ZNIX USER* magazine cover in pixel art (section 3).
- **ZNIX is ZeD OS's kernel.** The desk's About text says "kernal of ZNIX" (it said Ynix); ZNIX USER is the magazine on the cover.

Companion files:

- `ZeDUI/workshop/workshop_description.bbcode`: the final description, 4,848 of Steam's 8,000 characters. `workshop_description_draft.bbcode` is the first draft, which was rejected as too sales-y; it's kept for the record.
- `ZeDUI/mockups/zed_workshop_page_v2.html`: the page laid out the way Steam shows it.
- `ZeDUI/workshop/thumbnail/`: `preview.png`, the script that draws it, and its font.
- `TRANSLATION_PLAN.md`.

## 1. Who lands on the page, and what each needs

| Who | What they need, in their order |
|---|---|
| A player browsing | What it looks like, then the dealbreakers (build, single or multiplayer, what it breaks), then how to start |
| A player with a problem | Where to report it, what to include, whether it's already known |
| A server admin | Mod ID, Workshop ID, whether every player needs it, multiplayer status |
| A modder | Whether their mod works with ZeD, how to make an add-on, what's stable to build on |
| A translator | What files, what tools, where to send them |
| Someone in two years | Whether it's maintained, and where it went if it isn't |

The description serves the first and third rows directly and routes everyone else to a thread or the repo. 8,000 characters can't hold guides, and guides change more often than the page should.

## 2. The voice

The community talks plainly, a bit dry, and admits what's rough. The best Project Zomboid pages read like a person telling you about the thing they made. My first draft read like sales, so the director wrote the ideas in his own words and the final page was built from them. The rules it follows:

- **Don't sell it.** People install it if they like it. The page explains what it is and gets out of the way: no "elevate", "seamless", "experience", no exclamation marks, no "Features:" wall, no hype.
- **First person, one person.** It's Hermit talking ("I want to hear about it"), opening with "Built for my fellow humans and zombies alike. For the love of the game." and "Doidbros and Buzzlord present".
- **"Hardcore and builder safe" means one thing:** no game balance or systems changed. It only makes things easier to use and more accessible. The page says exactly that.
- **The sections, in order:** what it is → how it's laid out (the two windows) → how you use it (controller and keyboard and mouse as equals) → make it yours → why it looks like this (1993, humanist fonts) → before you install (the dealbreakers) → when it breaks → servers → who made this, and how.
- **The honest part is at the end:** "No one reads this far into a description, so here's the honest part." That's the story (two failed tries for Build 41, recruiting that didn't pan out), well over 300 logged hours, and a straight paragraph on AI: the ideas, systems and design are his; Claude wrote the code to his plans, did the testing and the research; nothing went in untouched; if that doesn't sit right, don't use it.
- **No jokes in the AI paragraph.** That's where skeptics read closely. The Hermit character gets the sign-off after it instead: an inanimate animated object, mad scientist, self-designated boofhead, purveyor of remedies for hobsnobberies, hogwashers and gobblygunks; "AI is the boat. I'm the captain."; "Now get off my lawn."
- **Claims we can back up.** The 300 hours are the logged hours (about 260 on the roadmap through April 12, plus 60-70 in Claude Code since); the real total is higher and the page says so.
- **Lines we left out on purpose:** "(it/that) pronouns" (it reads as a mocking joke to strangers, whatever was meant), "boof" alone (drug slang to many players; "boofhead" means fool), "snake oil" (the exact word AI critics would quote), Ahab and Ishmael.
- **American spelling** ("color", not "colour"), in the page and in the game.
- **Mod ID and Workshop ID in the format admins copy.** It's the community standard, and B42 wants the trailing backslash on the `Mods=` line.
- **The GitHub profile is linked** (github.com/hermit-the-trog). The repo itself will be shared for the right requests later; the page doesn't promise that yet.

## 3. The pictures

**How Steam shows them.** The game's uploader sets one preview picture: a 256 × 256 PNG under 1000 KB, the `preview.png` in the mod folder (ZeD's own upload window checks this). The gallery under it is added on the item's web page ("Add/edit images & videos"): screenshots and YouTube videos. Gallery pictures can't carry captions, so their order tells the story, and the description says what each part is. Pictures inline in the description (`[img]`) need outside hosting that can die; we keep the description text-only and put every picture in the gallery.

**How we shoot them.** 1920 × 1080 in-game captures at UI scale 1, fullscreen, from one good-looking save (daylight, a lived-in house, a car nearby). The default theme (dark, orange accent) everywhere except the theme sheet. No debug overlays, no QA scripts on screen. The QA bridge can stage and capture most of these so they're repeatable after every update.

| # | Picture | Why it's there |
|---|---|---|
| 1 | **The desk** (main menu, monitor on, Continue card) | The first impression: says "1993 Mac" before anyone reads a word |
| 2 | **Both windows open in a real scene** (Character on the left, World on the right, looting a kitchen) | The core of the mod: what you'll stare at most |
| 3 | **An item card with the Progress Band** (reading or cooking, with burn danger) | Shows depth: verbs, NEEDS lines, live progress |
| 4 | **Crafting at a station** (a kiln or the oven's 1993 control panel) | Shows that it covers the new B42 systems, not just inventory |
| 5 | **The HUD in play** (belt, watch, moodles and the action bar mid-queue, MOVING 3/6) | The always-on part, over real gameplay |
| 6 | **Driving** (the dashboard and the car radio up close) | The props: the most distinctive pixel art |
| 7 | **On a controller** (a radial wheel open, footer prompts showing) | Controller players are a big audience and usually ignored |
| 8 | **The theme sheet** (one window in dark, light and high contrast, a strip of the nine accents) | Answers "can I make it not orange" before it's asked |
| 9 | **Vanilla and ZeD side by side, same scene** | Honest comparison; people want it |
| 10 | **Video, 60-90 seconds, no music required** (open game, loot, craft, drive, controller) | Optional; YouTube only. Shows motion: the monitor switching on, the action bar, cards opening |

**The 256 × 256 preview: done.** A 1993 computer-magazine cover in pixel art, chosen from three period mockups (a magazine cover, a FastData-style ad, a software box), then redrawn as pixel art.

- **The masthead is *ZNIX USER*,** a magazine about ZeD OS's kernel. "ZNIX" is filled with bands of the mod's accent colors, after the striped letters on the UNIX Magazine the director shared.
- **ZeD-GUI is the cover story** and the biggest thing on the cover, the way PC Magazine's "50 MHz" outranks its own masthead. That way people browsing read the mod's name first.
- **Under it:** "THE WHOLE INTERFACE, REBUILT.", a green JULY 1993 / BUILD 42 band, three cover lines (2 WINDOWS, PAD/MOUSE, GRID/LIST), and a beige CRT showing a ZeD window.
- **How it's drawn:** on a 128 × 128 grid with a fixed palette and dithered shading, then doubled to 256, so each art pixel is a clean 2 × 2 block. The small text uses the mod's own 3 × 5 and 5 × 7 pixel faces. It's 4 KB.
- **Checked at 92 px** (about Steam's browse grid): ZNIX USER and ZeD-GUI still read.
- **It's installed** as `Zomboid/Workshop/ZeD-UI/preview.png`. The old one, a crop of the desk scene with the game's own menu art on the screen, is backed up in `zed_backups/name_20261020/preview_old`.
- **To change a line or the date,** edit and rerun `ZeDUI/workshop/thumbnail/pixel_znix.py` (it needs `fxc900.ttf` beside it). It rebuilds the picture pixel for pixel.

**The gallery could carry the cover's look,** for example a title card as the first picture. That's optional; the ten screenshots above still do the explaining.

## 4. Getting people installed and running

**On the page:** the "Before you install" list (Build 42 only, single player tested, hides vanilla's windows, adds the watch, English only), and one line on where the settings are (Options, Mods, ZeD-GUI). The step-by-step install from the first draft was cut with the sales tone. Subscribing and turning a mod on is something this audience already knows.

**In the mod**, which matters more because people skip pages:

1. **A first-run card.** On the first launch with ZeD, one small ZeD prompt on the desk: "ZeD-GUI is on. Options > Mods > ZeD-GUI has your theme, scale, moodles and action bar. Bugs and requests go to the Workshop threads (link)." With a "Don't show again" choice. It costs one prompt and saves a hundred comments.
2. **The version where people look.** The desk's About block already shows ZeD's version and the game's. That's what bug reports ask for.
3. **`mod.info` gets a `url=` line** pointing at the Workshop page. The game's mod list (and ZeD's own mod manager, which already has a HOMEPAGE button for it) then links straight there.
4. **Removal is explained.** "Take ZeD off mid-save and the steel watches go with it" is on the page. *To verify before upload: what the game does with a save holding a removed mod's item (expected: the item disappears, the save loads).*

**To verify before upload:** the B42 server line format; whether ZeD needs to be on the server at all (it adds an item and loot, so expected: yes, every player and the server).

## 5. Routing feedback to the right place

**The problem we're solving.** On a busy mod, everything lands in the comments: bug reports with no details, "update pls", compatibility questions, requests, praise. They scroll away, nothing is findable, the author drowns. Inventory ReInvented, a popular inventory mod, ended exactly like that, with its comments full of unanswered update requests until a fork took over.

**The routes:**

| What | Where | Why there |
|---|---|---|
| Thanks, quick questions, chat | Comments | That's what comments are for; they scroll |
| Bug reports | A **Bug reports** discussion thread, with the template in its first post | Threads persist and can be searched; the template gets the details we need |
| Compatibility ("does it work with X") | A **Compatibility** thread whose first post is the living list: works / works with a patch / doesn't | Answers repeat questions once |
| Ideas and requests | A **Requests** thread | Separates "I want" from "it's broken" |
| Add-on makers | An **Add-on makers** thread, linking the guides in the repo | Modders find each other and the docs |
| Translations | A **Translations** thread, linking `TRANSLATING.md` | Translators announce, coordinate, send files |
| What changed | The **Change notes** tab (filled in on every upload) | Steam shows it with dates; the description doesn't need a changelog |
| Code, docs, detailed issues (optional) | A public repo with issues | Better tracking than Steam for code and add-on makers; the handover depends on it (section 8) |

Steam lets the item owner start discussion threads on the item; each thread is linked by name from the description, so their order on the tab doesn't matter.

**The bug template** (first post of the Bug reports thread):

> **Game version:** (title screen, bottom corner)
> **ZeD version:** (desk, ZeD menu, About)
> **Single player or server:**
> **Other mods:** (your list, or a Workshop collection link)
> **What you did / what you expected / what happened:**
> **console.txt:** `C:\Users\(you)\Zomboid\console.txt`, uploaded to a paste site, linked here
> **Screenshot:** if it's something you can see

**In the mod (proposed):**

- **Split "Report a bug".** Today the desk's menu item opens vanilla's bug reporter, so ZeD bugs would go to The Indie Stone. Make it two items: "Report a ZeD bug" opens our Bug reports thread in the Steam overlay; "Report a game bug" keeps vanilla's.
- **A "Copy report" button** next to it: puts the game version, ZeD version, the mod list and the last errors from console.txt on the clipboard, ready to paste. Most of the template, filled in for them.

## 6. Extending ZeD: what's possible today, what needs building first

Mods do strange things, and modders will try things we never planned. What we can do is be clear about what's a supported way in, what's internal (it can change any update), and what replaces something it shouldn't.

| Add-on kind | Today | What it needs before we advertise it |
|---|---|---|
| **Watches** | **Supported.** `ZeD.Watch.register`, guide in `WATCH_ADDON_GUIDE.md`; ZeD's own Timez is built through it | Nothing. Link the guide. |
| **Language packs** | Not yet: ZeD's text isn't in translation files | The translation plan, phases 0-2 and 5 |
| **Context menu icons for a mod's options** | Works by accident: `ZeD.ContextIcons` is a global table keyed by English wording | Key it by translation key (translation plan, Phase 1), document `ZeD.ContextIcons["MyMod_Option"] = "icon-name"` |
| **Container buttons** (a mod's own actions on a container) | **Works:** mods registering vanilla's B42 handlers show in ZeD's button row as words | Document it as the supported route |
| **Object cards** (a card for a mod's world object) | Possible but internal: `ZeD.ObjectCards.register(def)` exists, undocumented | Freeze the def's fields, write a guide with one worked example |
| **Themes** | Not possible cleanly: the theme list in Settings is fixed at load | `ZeD.Themes.register{ id, name, tokens }` and the Settings list built from that registry |
| **Tabs for other mods** (a mod's own panel in the Character or World window) | Not possible: each window's tab list is a private table | `ZeD.Tabs.register{ window, id, label, icon, render, focusables }`, with the contract written down: how it draws, how a controller moves through it, the icon sizes (baked 8-64 px like ZeD's own) |
| **Compatibility patches** (a small mod that makes mod X and ZeD work together) | Possible case by case | Once tabs and object cards are public, most patches become "register mod X's panel as a tab" |

**The rule for add-on makers**, on the Add-on makers thread and in the repo: build on what's documented (`ZeD.Watch`, and later `ZeD.Tabs`, `ZeD.Themes`, `ZeD.ObjectCards`, the translation files). Anything else in `ZeD.*` can change in any update. Don't overwrite ZeD's files from another mod; register instead. If you need a way in that doesn't exist, ask in the thread; that's how the next registry gets built.

**How to make an add-on** (the guide's skeleton): a normal Build 42 mod folder; `require=ZeD_UI` in its `mod.info`; ZeD set as a **Required item** on its Workshop page, so Steam asks subscribers to get ZeD too; one client Lua file that does `require "ZeD/ZeD_Watch"` (or the registry it uses) and calls `register`; test with `-debug`; publish with ZeD's own upload window if you like.

**Order of work** (so the page doesn't promise what isn't there): the translation plan's phases 0-1 → `ZeD.Tabs.register` → `ZeD.Themes.register` → the object card guide → `TRANSLATING.md` and the add-on guides in the repo. Until then the page says "watches today; tabs and themes coming."

## 7. The Workshop's tools, and what each is for

| Tool | Who controls it | What we use it for |
|---|---|---|
| **Title** | Owner | "ZeD-GUI [B42]": the build tag in the title is the community habit and filters people at a glance |
| **Description** (Steam's formatting codes, 8,000 characters) | Owner | `workshop_description.bbcode`: what it is, dealbreakers, routes, the honest part |
| **Preview picture** (256 × 256, under 1000 KB) | Owner, through the game's uploader | The ZNIX USER cover, installed (section 3) |
| **Gallery** (pictures and YouTube videos) | Owner, on the web page | The ten slots (section 3) |
| **Tags** (the game's fixed list) | Owner, in the uploader | Build 42 plus the interface tag; ZeD's upload window shows the game's list |
| **Visibility**: Public, Friends, Unlisted, Private | Owner | **Unlisted** for a test period: anyone with the link, not in search. Then Public |
| **Change notes** (one per upload) | Owner | Every upload gets a short, plain note; the description never carries a changelog |
| **Required items** | Each item's owner | Add-ons list ZeD; Steam prompts subscribers to get it |
| **Discussions** | Owner starts threads; anyone posts | The routes in section 5 |
| **Comments** | Anyone; the owner can delete | Chat and thanks |
| **Contributors** | Owner adds Steam friends | Credit on the page. As far as I can find, they **can't** push updates or edit the page, and Steam has **no way to transfer an item to someone else**. *Worth testing with a second account before relying on either.* |
| **Collections** (anyone can make one) | The collection's owner | A "ZeD-GUI and add-ons" collection, so players and servers subscribe to a known-good set in one click |
| **`mod.info` `url=`** (the game's, not Steam's) | Us | The game's mod list links to the page |

## 8. If ZeD's support ends: how responsible people take over

Steam can't hand the item to someone else, and contributors can't update it. So a takeover always means **a new Workshop item**. The plan makes that clean, legitimate and easy to find.

**Prepare now, while it costs nothing:**

The page already makes the promise in the director's words: "It'll be supported, or up for adoption should something happen to the Hermit", with his GitHub profile linked. The steps below are what make that promise real.

1. **A public repo** (today it's private, to be shared for the right requests) holding everything: the mod, `ZeDUI/tools` (the art pipelines, the tests, the QA bridge), the specs (`STATE.md`, `HOOK_MAP.md`, `GAMEPAD_SPEC.md`, the guides). The docs are already the strongest part of this project; a successor can boot from `STATE.md` the way every session does.
2. **A written permission, before it's needed.** Project Zomboid's community norm is "don't reupload without permission", so a successor needs it in writing. A licence on the repo, plus one paragraph on the page and in the repo, for example: *"If ZeD-GUI goes six months without an update after a game update breaks it, anyone may publish a continuation from the public repo, as long as it credits the original, links back here, and keeps the Mod ID ZeD_UI so saves and servers keep working."* The director picks the licence and the wording.
3. **Name people early, if there are any.** Anyone trusted gets repo access now, so a handover is a decision, not a search. They're listed as contributors on the Workshop page for credit.
4. **Keep the Mod ID forever.** A continuation keeps `id=ZeD_UI` in `mod.info`. Existing saves then load with the new item, and server admins change only the `WorkshopItems=` number.

**When stepping away:**

1. A last upload of the original: the title gets "(continued at …)" or "(unmaintained)", and the description's first line points to the successor and says why.
2. **Optional:** that last upload lists the successor's item as a Required item, so every subscriber gets prompted to subscribe to it. The original's files are emptied in the same upload, so the two can't both load. *Test this on an Unlisted pair first.*
3. A final post in each thread pointing to the successor's threads.
4. The repo's README gets the same notice, and the repo is archived or handed to the successor.

**What happens without this:** the Inventory ReInvented pattern. The item gets pulled or abandoned, the comments fill with unanswered "update pls", and a fork appears that people have to discover from a comment.

## 9. Before the first upload: a checklist

- **Licences** for everything we ship: Fira (SIL Open Font License, fine with credit); Lekton; Chicago; and especially the icon sets. Some come from Flaticon packs, whose free licence requires attribution and limits redistribution. Pulled items are what happen when this is skipped. A credits file in the mod, linked from the page.
- **Brand names.** The props parody real brands ("CaZio"), and the cover parodies computer magazines (ZNIX USER). Keep them parodies: no real logos or mastheads. Same for the Mac look: no Apple marks.
- **Description facts confirmed in game:** removal, the server line, multiplayer status.
- **`mod.info`:** `name=ZeD-GUI` is done. The `description=` line still talks about a "988-entry context menu icon map"; rewrite it in the page's voice. Add `url=`. Decide whether `author=` stays "ZeD Team" (the page credits Doidbros and Buzzlord, and Hermit the Trog).
- **The last "ZeD UI" in the mod:** two Settings tooltips, one Safe mode comment and one console line, left alone on Oct 20 because another session was editing those files.
- **The preview picture:** done (section 3). **The gallery:** still to shoot.
- **The threads** created and linked; the bug template posted.
- **Unlisted first,** a week of friends, then Public.

## 10. Decisions for the director

1. ~~**The credit line.**~~ *Settled Oct 20:* "Doidbros and Buzzlord present", designed by Hermit the Trog. The page says plainly how it was built, with Claude (section 2).
2. **A public repo, or Steam only?** *Partly settled:* the GitHub profile is on the page, and the repo gets shared for the right requests later. Still open: when it goes public, and under what licence. The repo is what makes add-ons, translations and a handover practical.
3. **The licence and the continuation paragraph** (section 8).
4. **A Discord, or not?** Many big mods have one; it's also a moderation job. Steam threads plus the repo cover everything above without it.
5. **Multiplayer status at launch:** test it first, or launch saying "untested" (the page says untested).
6. **Translations in ZeD itself or as separate mods** (from the translation plan).
