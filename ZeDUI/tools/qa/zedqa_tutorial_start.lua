-- ZeDUI/tools/qa/zedqa_tutorial_start.lua  (Nov 6 2026, QA): the main menu's Tutorial, started by the game's own call. The game clears the mod list for it, so Lua resets and the
-- bridge goes with it: batch_tutorial.ps1 reads the console and takes the desktop picture. grep "ZEDQA tut".
print("ZEDQA tut starting the Tutorial")
MainScreen.startTutorial()
print("ZEDQA tut DONE")
