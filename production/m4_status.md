# M4 Status: Acts 3–4, Endings, New Game+ (greybox)

**Exit criterion met in greybox:** the game can be finished on all 9 difficulty combinations. `test_act34_critical_path` plays Acts 3–4 and the finale on each one, rotating through the three endings.

## Done

| Task | Notes |
|---|---|
| M4-01 Logic + tests | P14–P21 (P17 shares P16's code through `values_from`). P22 is the finale, not a close-up. All of them pass the Puzzle DoD tests. |
| M4-02 Content | 3 items, 5 fragments (F08–F12), 14 documents, 2 tapes, about 120 EN/fr_CA strings. Clues are checked against solutions on every difficulty. |
| M4-03 Close-ups | Placeholder UIs for P14–P21. There is a shared `OrderingUi` for the shelf and the slide carousel. Screenshot tool: `tools/smoke/m4_puzzle_screens.gd`. |
| M4-04 Rooms | U01–U06 and B02–B07 come from one builder (`build_act34.gd`), with clay renders. Memory variants: U06, B03, B04. The G09 elevator and the B01→B02 door are wired in. |
| M4-05 AI | Act 3 and Act 4 routes and zone modifiers. See the plan, §4. |
| M4-06 Finale | `Finale` autoload, `Ending` rules, `EndingScreen`, `Profile` (`user://profile.cfg`), and New Game+ from the title (keeps Files, adds the Claire hint, new seed). |
| M4-07 Full-game test | 9 combinations, each ending, plus tests for the NG+ profile, saving the AI zone, and the patrol routes. |

## Proposed choices to review

- Being caught in Ward Zero without 12/12 plays Relapse, not a game over.
- The GDD's "chained memory shifts" in P22 are not built in the greybox.
- Most Act 3–4 rooms are `scripted` in the GDD, so the stalker mostly haunts the hubs (U01, B02).
- F04 is dated 1975 on the P21 timeline, while the GDD says the timeline starts in 1976.

## Still needs people

Final art for every new room and close-up, VO/TTS for tapes 04–05, Québec French review of the new strings, ending cinematics, and playtests of the Act 3–4 pacing.
