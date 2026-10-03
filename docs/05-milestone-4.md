# Ward Zero: Milestone 4, Acts 3–4, Endings, New Game+

**Scope (§13.1):** Upper Floor, Basement, P14–P22, all three endings, New Game+.
**Exit:** the game can be finished on every difficulty combination (greybox).
Designs marked **(proposed)** fill gaps in the GDD.

## 1. Room Graph (proposed)

```
G09 --elevator (power)--> U01 Upper Hall --+-- U02 Library (P14) --secret--> U06 Director's Quarters (P17, P18, mem)
                                           +-- U03 Reading Room ★                      |
                                           +-- U04 Pharmacy (P15)                       | dumbwaiter (P18)
                                           +-- U05 Observation Theatre (P16)            v
B01 Boiler --> B02 Basement Corridor --+-- B03 Morgue (P19, mem) <---------------------+
                                       +-(Sanguine)- B04 Treatment Room (P20, mem)
                                       +-- B05 Archive Antechamber ★ -- B06 Archive Vault (P21)
                                       +-(after P21)- B07 Ward Zero (P22)
```

The elevator in G09 (Act 2's end) goes up to U01. Act 4 starts when P18's dumbwaiter drops the player into the Morgue. B02 is also reachable from B01.

## 2. Puzzles (proposed)

| ID | Mechanic | Seeded | Easy / Hard | Reward |
|---|---|---|---|---|
| P14 Library | Shelve 5 books from the Director's reading list in catalog-number order | Catalog numbers | Easy: 3 books. Hard: 7 books. | Secret door to U06 |
| P15 Pharmacy | Balance scale: the substance on the left, weights on either pan, to the prescribed weight | Target weight | Easy: weights on one pan only. Hard: weights 1/3/9/27 on both pans. | Projector key, F09 |
| P16 Theatre | Put 6 slides in lecture order (lecture notes). Slides 2 and 5 overlap to show the safe code. | Slide order, safe code | Easy: notes number the slides | Safe-code document, F10 |
| P17 Director's safe | 4-digit lock with the code from P16. The 1976 version of the room shows a session with young Mathieu. | (shared with P16) | | Sanguine key, F08 |
| P18 Grandfather clock | Set the clock to the fire time on F02 (seeded since Act 1) | Fire time | | Dumbwaiter to the Morgue |
| P19 Morgue | Open the drawer the death registry gives for "the girl from the fire". In 1976 that drawer is empty. | Drawer number | | F11 (optional), Drawing (Anchor 4), vault code part |
| P20 Humors panel | Place the 4 temperament keys by season, following the mural (Choleric = summer/fire, Melancholic = autumn/earth, Phlegmatic = winter/water, Sanguine = spring/air) | Slot order | Easy: elements written on the slots | Vault access, F12 tape |
| P21 Archive Vault | Place collected fragments on a 1975→1998 timeline. The number placed correctly decides the ending. | — | — | Ending flag |
| P22 Ward Zero | Finale chase toward the exit. Choice: run (ending by P21 count), or stay and let him reach you (Claire ending if 12/12). | — | — | Ending |

**Fragment timeline (P21, proposed dates):** F04 drawing (1975), F02 fire (1976), F11 morgue registry (1976), F01 admission (1976), F05 essay (1976), F03 nurse log (1977), F06 scratchings (1978), F08 Director's journal (1979), F10 case-study slide (1984), F07 session 1 (1998), F09 pharmacy label (1998), F12 "last night" tape (1998).

## 3. Endings (GDD §2.4)

| Ending | Condition | Outcome |
|---|---|---|
| Relapse | P21 < 9 correct | Wakes in the Dayroom; credits; NG+ unlocks |
| Discharge | ≥ 9 correct | Sunlit 1998 hospital room with Dr. Bouchard |
| Claire | 12/12 **and** stays in Ward Zero | The figure is unmasked; Claire says goodbye |

Endings seen and NG+ unlocks are stored in `user://profile.cfg`, separate from saves.

## 4. New Game+ (GDD §8.3)

New seed and the same difficulty choice. Every document and tape stays in Files. A Files entry hints at the Claire ending.

## 5. Tasks

| ID | Task |
|---|---|
| M4-01 | Logic + tests for P14–P22 |
| M4-02 | Items, documents, tapes, strings |
| M4-03 | Close-up UIs |
| M4-04 | Greybox rooms U01–U06, B02–B07 + renders (memory: U06, B03, B04) |
| M4-05 | Act 3/4 AI routes (upper floor faster; basement relentless) |
| M4-06 | Finale (P22), endings, profile, NG+ |
| M4-07 | Full-game critical-path test on all 9 combinations, for each ending |
