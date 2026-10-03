# M3 Status (Act 2)

Against `docs/04-milestone-3.md`. Act 2 can be played start to finish in greybox on every difficulty combination (`tests/integration/test_act2_critical_path.gd`).

| Task | Status | Notes |
|---|---|---|
| M3-01 P06–P13 logic + tests | ✅ | 14 puzzles pass the Puzzle DoD tests. P07 configs are BFS-verified. |
| M3-02 Items, documents, tapes, strings | ✅ draft | 413 keys in EN + fr_CA. French still needs native review. |
| M3-03 Close-up UIs | ✅ placeholder look | |
| M3-04 Greybox rooms + renders | ✅ | `tools/greybox/build_act2.gd` (table-driven), 1976 variants for W02–W04 |
| M3-05 Persistent objects | ✅ | P09 drawing: hidden behind the radiator in 1976, found in 1998 |
| M3-06 Act 2 AI + save/restore | ✅ | Patrol starts in G09; `StalkerDirector.snapshot()/restore()` |
| M3-07 Satchel | ✅ | P08 reward, 8 slots |
| M3-08 Act 2 critical path, 9 combinations | ✅ | |
| M3-09 Act 2 resource pack + loading screen | ⏳ | Loader exists (M2). Splitting the export makes sense once final art makes Act 2 heavy. The current full build is about 15 MB compressed. |

## Design decisions made here (all marked "proposed" in the plan)

- The E05 lockbox (code from P08) holds the **valve wheel** P07 needs, so P08 → P07 forms a chain.
- The Memory Anchors open specific rooms: Photograph → G06 and W02, Ribbon → W03, Cylinder → W04.
- P13 also unlocks the Kitchen ↔ Boiler Room shortcut (one-way, from below).
- The build ends at the G09 elevator once the power is on (Act 3 starts there in M4).

## Open

- AI tuning in Act 2 needs real playtests: patrol speed, how often he passes through puzzle-adjacent open rooms (E04, E05), and the search time.
- G07 has no reason to visit beyond a document and the patrol. It is planned as the stalker arena, so it may need a pickup to justify going in.
