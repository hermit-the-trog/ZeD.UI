# QA archive

Test scripts retired in the Nov 12 2026 test cleanup (plan: `ZeDUI/qa/PLAN_test_cleanup_20261112.md`, section 4, "DROP"). Each was a one-off, a picture-only script, a shipped per-beta checklist, or a test that could not fail for a real reason.

Nothing in this folder is run. No manifest, runner or batch file points here. Nothing was deleted: the files are only moved, so the git history of each one is intact.

To bring a script back, move it up one folder with git, then add it to a manifest again:

    git mv ZeDUI/tools/qa/archive/zedqa_<name>.lua ZeDUI/tools/qa/zedqa_<name>.lua

Move its own manifest (`<name>.txt`) or runner (`.ps1`) back the same way. A script that was archived with its own manifest keeps the same file name here.
