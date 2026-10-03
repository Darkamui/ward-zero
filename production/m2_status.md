# M2 Status

Against `docs/03-milestone-2.md`. All systems are built and covered by headless tests. Tuning values are the plan's starting numbers until playtests replace them.

| Task | Status | Evidence |
|---|---|---|
| M2-01 Difficulty rules | ✅ | `game/data/tuning/*.tres`, `test_difficulty.gd` (Observer recovery, Committed cassettes, autosave) |
| M2-02 Easy/Hard clues | ✅ (P03 Hard = Normal for now) | `test_documents.gd` Hard/Easy tests over 20 seeds |
| M2-03 Room-graph simulation + noise | ✅ | `StalkerSim`, `test_stalker_sim.gd` |
| M2-04 3D entry, sight, chase, lose, door follow | ✅ | `ManInWhite`, `StalkerDirector`, `test_stalker_ai.gd` |
| M2-05 Hiding + breath-hold | ✅ | `HidingSpot`, `BreathCheck`, `HidingHud` |
| M2-06 Composure + Sedatives + effects | ✅ (no audio yet) | `ComposureSystem`, glints, `wz_composure` shader |
| M2-07 Map | ✅ | `MapUi`, `MapStatus`, `test_map.gd` |
| M2-08 Pack loader | ✅ loader, ⏳ web check | `PackLoader`, `test_pack_loader.gd`. Act packs and a loading screen come with Act 2 (M3). |
| M2-09 Test level | ✅ | `tests/levels/stalker/` (not exported). F9 then T in a debug build. |
| M2-10 Act 1 on 9 combinations | ✅ | `test_act1_on_every_difficulty_combination` |

## Notes

- The AI is off in Act 1 (scripted-only zone, GDD §5.2). M3 turns it on for Act 2 with `StalkerDirector.activate(route)` from an enter trigger, using the East/West wing patrol routes.
- When he follows the player through a door during a chase, he is announced with the same 3 s telegraph as every entry (rule R9). That makes "goes through doors after a short delay" exactly 3 s.
- Audio cues (footsteps, heartbeat, breath) are wired to `ThreatCue` and the HUD, but no sound files exist yet. The visual cues work without them.
