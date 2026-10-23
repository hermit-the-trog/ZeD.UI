# Steam discussion threads (Workshop item 3824968485)

How to make each one: open the item's page in Steam, click the Discussions tab, click Start a New Discussion, paste the title and the post below, and post it. To pin a thread, open it and use Sticky in its options (the item owner sees this option). Steam discussions accept the same [b] [list] [*] codes as the description.

Make Bug reports, Compatibility and Translations now. Requests and Add-on makers can wait for the public release; the tester description does not mention them.

The repo is private, so these posts do not link to it.

---

## 1. Bug reports (sticky)

Title: Bug reports

[b]One post per problem.[/b] Include:
[list]
[*][b]Versions:[/b] the ZeD-GUI version and the game version. Both are in the desk's ZeD menu, under About.
[*][b]Single player or a server.[/b]
[*][b]Other mods:[/b] your mod list, or a link to your Workshop collection.
[*][b]What you did, what you expected, and what happened.[/b]
[*][b]console.txt:[/b] C:\Users\(you)\Zomboid\console.txt on Windows, ~/Zomboid/console.txt on Linux and macOS. The game replaces this file each time it starts, so copy it before you restart. Upload it to a paste site and post the link.
[*][b]A screenshot[/b], if the problem is something you can see.
[/list]
[b]Safe mode:[/b] if ZeD-GUI stops you from playing, turn on Options, ZeD setup, Safe mode. The game's own screens return. Say so in your report.

Play without the -debug launch option unless asked. With it, the game stops on every Lua error, including errors from other mods.

---

## 2. Compatibility (sticky)

Title: Compatibility with other mods

This thread keeps the list of mods tested with ZeD-GUI.

[b]How ZeD-GUI works with other mods[/b]
[list]
[*]Mods that use the game's own systems work: context menu options, container buttons, items and recipes.
[*]Buttons that other mods add to the game's inventory and character windows do not show while ZeD-GUI is on, because those windows are replaced.
[*]Other mods that replace the whole interface do not work together with ZeD-GUI.
[*]The desk's Mods screen lists conflicts between your mods (two mods with the same file, item or recipe) and which copy the game uses.
[/list]

[b]To add a mod to the list[/b], reply with the mod's name, its Workshop link, and what happened: it works, it works with a problem (say which), or it does not work.

[b]Works[/b]
(none tested yet)

[b]Works with a problem[/b]
(none yet)

[b]Does not work[/b]
(none yet)

---

## 3. Translations (sticky)

Title: Translations

ZeD-GUI's own text is in two files, so it can be translated without touching any code or fonts. Where the game already has a word or phrase, ZeD-GUI uses the game's translation, so item names, body parts, skills, traits, moodles and recipes are already translated.

[b]The files[/b]
After you subscribe, they are in your Steam folder under steamapps/workshop/content/108600/3824968485/mods/ZeD-UI/42/media/lua/shared/Translate/EN/:
[list]
[*]UI.json: every phrase ZeD-GUI draws, about 2,400.
[*]ItemName.json: the name of the Timez watch, two lines.
[/list]

[b]How to translate[/b]
[olist]
[*]Copy the files into a folder for your language next to EN, with the game's language code: FR, DE, RU, PL, PTBR, and so on.
[*]Save as UTF-8. Change only the text on the right of each line. Do not change the key on the left, the quotes or the commas.
[*]Keep the %1, %2, %3 and %4 markers. The game puts a number or a name there. You can move them to suit your grammar.
[*]A quote mark inside a phrase is written \". A new line is \n. A percent sign is written %%.
[*]A phrase you leave untranslated shows in English, so a partial file works.
[/olist]

[b]Space limits[/b]
Some phrases have a fixed space. The action bar labels (the keys that start with UI_ZeD_Act_) fit 14 capital letters. Ask in this thread for the full list of phrases with their limits.

[b]Checking your work[/b]
Switch the game to your language and open the screens. Options, ZeD setup, "Test language (stretched text)" makes every phrase longer, which shows where space is tight.

[b]Sending a translation[/b]
Post here with a link to your files. Translations sent here are included in ZeD-GUI, and translators are credited on this page. You can also publish your own mod with the Translate folder and require ZeD_UI.

---

## 4. Requests (public release)

Title: Requests

Post one request per reply. Describe what you want to do in the game, and where in the interface you expected to do it.

Bugs go in the Bug reports thread.

Every request is read. There is no promise that a request will be built.

---

## 5. Add-on makers (public release)

Title: Add-on makers

This thread is for people who make mods that work with ZeD-GUI.

[b]The rules[/b]
[list]
[*]Build on what is documented. Today that is the watch registration (ZeD.Watch) and the translation files. Anything else in ZeD.* can change in any update.
[*]Do not overwrite ZeD-GUI's files from another mod. Register instead.
[*]If you need a way in that does not exist, ask here.
[/list]

[b]Watches[/b]
A watch add-on is a separate mod that requires ZeD_UI and adds watches on the same controls. One watch needs: the item script (both wrists), the wrist clothing XML with its own GUID, the ground model, a 32 x 32 inventory icon, the item name in ItemName.json, a loot table entry, the face picture (the plate) and one registration call. Ask here for the full guide.
