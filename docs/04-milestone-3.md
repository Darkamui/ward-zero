# Ward Zero: Milestone 3, Act 2 (The Wards)

**Scope (§13.1):** East and West wings, the Boiler Room, P06–P13. Also the Dining Hall, Kitchen and Main Corridor (G07–G09), the Satchel, and memory variants for W02–W04.
**Exit:** content complete and playtested. Built in greybox first, like M1, so a full Act 2 critical-path test can run before any final art.

Like the earlier plans, this fills gaps in the GDD with proposed designs. Each one is marked **(proposed)** and is easy to change.

---

## 1. Room Graph (proposed)

```
G02 Lobby --(Choleric)--> G09 Main Corridor --+-- E01 East Corridor --+-- E02 Nurse Station (P06)
                              |               |                      +-- E03 Hydrotherapy (P07)
                              |               |                      +-- E04 Linen Room (P08, Linen key)
                              |               |                      +-- E05 Women's Ward (lockbox)
                              |               +-(Melancholic)- W01 West Corridor --+-- W02 Dormitory (P09, mem)
                              |                                                    +-- W03 Classroom (P10, mem)
                              |                                                    +-- W04 Playroom (P11, mem)
                              |                                                    +-- W05 Isolation Cells (P12)
                              |                                                    +-- W06 Staff Lounge ★
                              +-- G07 Dining Hall -- G08 Kitchen (pantry hiding)
                              +-(Phlegmatic)- stairs -- B01 Boiler Room (P13)
```

- The M1 "end of slice" corridor door in G02 becomes the real G09 door, using the Choleric key.
- The Kitchen's basement shortcut opens from the Boiler Room side after P13 (a one-way unlock). It matters for Act 4.

## 2. Critical Path (target about 90 min)

G09 → E01 → **P06** (Linen Room key, Sedatives) → E04 **P08** (lockbox code, Satchel) → E05 lockbox (valve wheel) → E03 **P07** (Melancholic key) → W01 → W06 (save, lullaby tape) → W02 **P09** with a memory shift (F04, Ribbon) → W03 **P10** with a memory shift using the Ribbon (F05, Cylinder) → W04 **P11** (Fuse) → W05 **P12** (Phlegmatic key, F06) → G09 stairs → B01 **P13** (elevator power, F07) → end of Act 2.

**Stalker:** an enter trigger on G09 turns on the room-graph AI (GDD §5.2). Patrol: G07, G09, E01, E05, E04, E01, G09, W01, W05, W01, G09. AI state is saved in `GameState.stalker` and restored on load.

## 3. Puzzle Designs (proposed)

| ID | Mechanic | Seeded | Easy / Hard | Fail noise | Reward |
|---|---|---|---|---|---|
| P06 Medication cart | Put the right pill in each patient's drawer. Charts give each patient's pill **shape**; the shift log gives its **colour** (always written as words, rule R5). | Patient → pill (unique colour/shape pairs) plus decoy pills | Easy: 3 patients, chart gives both. Hard: 5 patients. | 1 | Linen Room key, Sedatives |
| P07 Hydrotherapy | Water jugs: pour tub to tub, drain, and use the main valve to reset (rule R7). Reach the marked levels. Needs the valve wheel. | One config from a verified-solvable list | Easy: 2 tubs and a tap. Hard: bigger config. | 0 | Melancholic key |
| P08 Linen Room (stealth) | Find the stained sheet: the ledger maps bed + day to a tag, and a note gives the bed and day. Each wrong pull = noise. AI active. | Target tag, bed, day | Easy: note gives the tag. | 1 | Lockbox code (doc), Satchel (8 slots) |
| P08L E05 lockbox | 3-wheel code from P08 | (from P08) | | 1 | Valve wheel |
| P09 Dormitory | Hang 6 drawings in story order. Order = the dates on the backs. One drawing is missing in the present: in 1976, hide it behind the radiator (persistent object), then take it in the present. | Dates | Easy: dates on the front | 1 | F04, Ribbon (Anchor 2) |
| P10 Classroom | Present board shows code digits 1 and 3. The 1976 board (Ribbon anchor) shows digits 2 and 4 being written. Padlock code. | 4-digit code | Easy: 3 digits in the present | 1 | F05, Cylinder (Anchor 3) |
| P11 Music box | Needs the crank and cylinder. Set 6 pins to the lullaby. Tape subtitles and a sheet on the lid give the note names (visual alternative to the audio). | Melody | Easy: 4 notes. Hard: 8. | 1 | Fuse |
| P12 Isolation cells | Knocks from 5 cell doors in a sequence. Open the peepholes in order. Visual alternative: dust shaken from the door. | Sequence | Easy: 3 knocks. Hard: 6. | 1 per wrong door | Phlegmatic key, F06 |
| P13 Boiler | Fit the fuse, then set 3 valves so all 3 gauges are in the green band. Each valve moves two gauges. A gauge in the red is loud. | Base pressures from a seeded solution | Easy: each valve moves one gauge | **2** (by design) | Elevator power, F07 tape |

All puzzles meet the Puzzle DoD (Overview §6.2): a logic class with a test that it stays solvable after random input, a deterministic seed, clue documents checked against solutions over 20 seeds, and EN/FR strings.

## 4. Tasks

| ID | Task |
|---|---|
| M3-01 | Logic + tests for P06–P13 and P08L |
| M3-02 | Items, documents, tapes, strings (EN + fr_CA draft) |
| M3-03 | Close-up UIs |
| M3-04 | Greybox builders for G07–G09, E01–E05, W01–W06 and B01, plus renders (memory: W02–W04) |
| M3-05 | Persistent objects for P09 (MemoryShiftSystem API from M1) |
| M3-06 | Act 2 AI activation, patrol, and saving/restoring AI state |
| M3-07 | Satchel (8 slots) |
| M3-08 | Act 2 critical-path test on all 9 difficulty combinations |
| M3-09 | Act 2 content pack (PackLoader) and loading screen |
