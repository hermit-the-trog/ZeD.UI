# Outside review of 0.3.0-beta6a (Claude on the director's Mac, 42.21), Nov 7 2026: QA's check on 42.22.2

The review text is in this session's chat; this file keeps each finding, where it is, and what QA checked here.

## New
1. **Medium: every weapon kill is filed as an explosion; the Journal header counts those kills twice.** KillTracker.lua:154 sets `isExplosion = weapon:isInstantExplosion()`. On 42.22.2 the bytecode is the same as 42.21's: true when the weapon has no timer, no sensor and no remote, so true for a bat, an axe, bare hands. tally() (line 117) then files the kill under explosion, and JournalTab.lua:393 adds explosion kills to getZombieKills(), which already counts them. Fix idea from the review: a real explosive is `getExplosionPower() > 0 or getExplosionRange() > 0` (or isExplosive(), present on 42.22.2); and don't add fire, car and explosion kills on top of the engine's count. Beta 6a made this reachable: in beta 6 the hit handler errored first.
2. **Design: Check stats opens the game's own Player Stats window**, and everything edited there (Add XP, traits, profession, names, weight, warning points, user logs) is the game's UI. ZeD_AdminCards.lua:1212 calls it a stopgap. With it: the Admin tab's list of the game's remaining windows (AdminTab.lua:86-111). A scope call for the director.
3. **Low: firearm facts throw "tried to call nil" in formatFirearm** (ItemCard.lua:86). getAmmoType() returns an AmmoType object on 42.22.2 too (javap), so `at:match` fails. It is reached by the recipe preview card and the item card outside drawer mode; the drawer card for a pistol is fine. Since beta 5. Fix: tostring(at), or the ammo item from the AmmoType.
4. **Low: turning ZeD-GUI off and on in ZeD's Mods screen leaves ZeD picks off** (the new require=\ZeD_UI in ZeD_Picks/42/mod.info). The band says a mod is off; nothing offers picks back.
5. **Low: a held second safehouse Accept says "That invitation no longer stands"** (ZeD_Claims.lua:438) while the invitation stays valid. A "wait" message fits.
6. **Low: claims log reads a release plus another player's claim of the same building within 5 s as an owner change** (ZeD_ServerClaims.lua:184), since houses are keyed by corner now.
7. **Plausible: safe-mode hand-back skips the join-in-flight guard** (ZeD_Claims.lua:748), one packet's window.
8. **Plausible, MP: a reused zombie object can misfile a kill as fire** (KillTracker.lua:190); already in punch list 97.

## Still open, from the review's tables
RT to run closes a tap/toggle wheel (beta 6 #11, not fixed). Offline Player card still served to a role with CanSeePlayersStats only. Steam ID check covers about 8 neighbours. Community eviction, split-screen, OnObjectHighlighted, the beta 5 carry-overs: as in punch list 97.

## Confirmed fixed on the Mac (42.21) that QA saw here too
Server fonts, safehouse invitations online and offline, mute on every stream, tow refusal, Check stats stacking, ticket Back, clothing values, Ranch page. The review also confirms on 42.21: breakConstraint(ZZ) is the only overload there, and every engine call the hot fix added exists with the right arity.
