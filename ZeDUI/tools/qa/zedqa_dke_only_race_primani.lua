-- ZeDUI/tools/qa/zedqa_dke_only_race_primani.lua  (Nov 1 2026, punch list 42 e.)
-- Sets the dash key test (zedqa_dash_keys_edge.lua) to run the two cars that read START with the key in
-- on the Deck runs of Nov 1, race and primani, and nothing else. Run it right before dke in a manifest;
-- dke reads and clears the global. grep "ZEDQA dko".
ZeD_QA_DKE_ONLY = { race = true, primani = true }
print("ZEDQA dko dke limited to race and primani | DONE")
