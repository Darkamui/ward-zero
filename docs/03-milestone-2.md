# Ward Zero: Milestone 2, Systems Complete

**Goal (from §13.1):** stalker AI, hiding, composure, the difficulty matrix, map colouring, seeded codes on every difficulty, and resource-pack loading, all tuned on a test level.
**Exit:** every system works on a test level and Act 1 is playable on all 9 difficulty combinations.

Written before the M1 retro (no playtest data yet), so the tuning numbers below are starting values to replace with playtest results.

---

## 1. Scope

| In | Out (milestone) |
|---|---|
| Observer and Committed threat rules; Easy and Hard parameters and clue texts for P01–P05 | Act 2+ content (M3) |
| Room-graph stalker AI: patrol, investigate, search, chase, lose; noise in hops; access flags; 3D spawn with telegraph | Finale chase (M4) |
| Hiding spots and breath-hold | |
| Composure: three bands, causes, effects, Sedatives | Anachronism art (M5) |
| Map UI: visited rooms, red/blue status, locked-door icons | Floor-plan pickups (M3) |
| Resource-pack loader (download → `load_resource_pack`) with a loading screen | Real per-act packs (M3) |
| Test level T01–T05 (greybox) | |

## 2. Difficulty Matrix (GDD §8)

| | Observer | Patient | Committed |
|---|---|---|---|
| Caught | Whiteout → wake in nearest safe room; one random droppable slot item left where caught; composure −0.3 | Game over → Load | Game over → Load |
| Saving | Autosave on every room entry + recorders | Recorders; act-start autosave | Each save consumes `item_blank_cassette` |
| Stalker walk / run (m/s) | 1.2 / 2.2 | 1.5 / 2.8 | 1.7 / 3.1 |
| Hearing bonus (hops) | −1 | 0 | +1 |
| Search time in a room (s) | 6 | 10 | 14 |
| Breath: required hold / capacity (s) | 1.5 / 6.0 | 2.5 / 4.5 | 3.5 / 4.2 |
| Close-ups pause the world | Yes | No | No |

All values live in `StalkerTuning` resources (`game/data/tuning/<threat>.tres`), not in code.

Puzzle Easy/Hard (Normal as in M1):

| Puzzle | Easy | Hard |
|---|---|---|
| P01 | Station marked on the dial | Notice gives the station as a sum (`{a} + {b}`) |
| P02 | 2 cables (memo route of 3 roles) | 4 cables (route through Records) |
| P03 | Labels not swapped | As Normal (patient-number cross-reference deferred to M3 content) |
| P04 | First two digits shown on the safe | Memo adds "then read them backwards" |
| P05 | 2 numbers | Board shows hymn *titles*; the hymnal index maps titles to numbers |

## 3. Stalker AI (GDD §5.1, ADR-006)

**Graph.** Nodes are rooms, edges are exits (both directions). He never enters `never` rooms or memory rooms, and enters `scripted` rooms only from a script. Locked doors don't stop him.

**Simulation** (off-screen, 0.5 s ticks). Position is a room plus progress along an edge. Edge time = `EDGE_LENGTH / speed` (EDGE_LENGTH = 10 m).

| State | Behaviour | Leaves when |
|---|---|---|
| Patrol | Follows the act's `patrol_route` loop | Hears a noise → Investigate |
| Investigate | BFS path to the noise room | Arrives → Search |
| Search | Stays `search_time`; in the player's room he checks hiding spots | Time up → Patrol (nearest route room) |
| Chase | 3D only: pursues at run speed; follows through doors after 3 s | No line of sight for 8 s → Lose |
| Lose | → Search in the current room | |

**Noise.** `EventBus.noise_emitted(room, hops)`. Effective hops = hops + difficulty bonus + 1 if composure is Breaking. Heard if the BFS distance from the noise room to his room is at most that, and not across a `never` room.

**Entering the player's room.** When his next room is the player's: telegraph for at least 3 s (rule R9; `ThreatCue` panned toward the door he comes from), then spawn at that door's spawn marker (`spawn_from_<his room>`). In 3D: line of sight (raycast to the player's head within a 110° cone, 15 m) → Chase. Otherwise he searches (walks to each hiding spot, then leaves).

**Puzzles.** If the player is caught while a close-up is open, the close-up closes first.

## 4. Hiding (GDD §5.3)

`HidingSpot` (an Interactable of kind USE plus hiding behaviour): enter by clicking it, leave by right-click or clicking again. While hidden the player is invisible, without collision, and noise from running stops. **Seen entering:** if he has line of sight at the moment of entering, he knows (caught when he checks it).
**Breath-hold:** when he checks the spot, a meter appears. Hold Space for `required` seconds. Releasing early or exceeding `capacity` means found. The meter is the visual alternative (rule R6).

## 5. Composure (GDD §5.4)

Value 0–1 in GameState. Bands: Steady ≥ 0.66 > Shaken ≥ 0.33 > Breaking.

| Cause | Change |
|---|---|
| Stalker in line of sight | −0.08/s |
| Unlit room (`RoomData.unlit`) | −0.01/s |
| Caught (Observer) | −0.3 |
| Document `composure_delta` | as set |
| Safe room | +0.02/s |
| Sedatives | +0.4 |
| Memory shift completed | +0.15 |

Effects: post-shader `wz_composure` (vignette pulse, slight desaturation), heartbeat volume, phantom footsteps (Shaken+), fake item glints that vanish when clicked (Shaken+, never on `puzzle_critical` nodes, rule R2), +1 hearing hop (Breaking). Cut-list item 1 removes only the hearing link.

## 6. Map (GDD §3.5)

Rooms appear once visited, drawn from `RoomData.map_rect` per floor. **Red** = unresolved (an untaken pickup, an unsolved puzzle in the room, or a locked exit not yet opened), **blue** = cleared. Status is recomputed on leaving a room and stored in its room state. Colour is paired with a symbol (`!` / `✓`) (rule R5). Locked exits show a lock icon with the key's name.

## 7. Resource Packs (GDD §9.4)

`PackLoader.load_pack(url)`: HTTPRequest download to `user://packs/`, then `ProjectSettings.load_resource_pack`, with a progress screen. M2 builds the loader and a test pack exported from `packs/test/`. M3 splits Act 2.

## 8. Tasks

| ID | Task | Acceptance |
|---|---|---|
| M2-01 | Difficulty rules (catch, saving, tuning resources) | Unit tests per threat level. New Game enables all options. |
| M2-02 | Easy/Hard puzzle parameters and clue documents | Clue tests (20 seeds) pass on all 3 difficulties |
| M2-03 | Room-graph simulation + noise | Headless tests: patrol loop, investigate by hops, access flags respected |
| M2-04 | 3D spawn, telegraph, line of sight, chase, lose, door follow | Integration tests on the test level |
| M2-05 | Hiding + breath-hold | Tests: seen-entering caught; hold window pass/fail |
| M2-06 | Composure + Sedatives + effects | Band tests; R2 test (no effect touches puzzle-critical nodes) |
| M2-07 | Map UI | Status tests; screenshot review |
| M2-08 | Pack loader | Loads a test pack in the web build |
| M2-09 | Test level T01–T05 | Contract tests pass |
| M2-10 | Act 1 on 9 combinations | Critical-path test parameterised over all combinations |
