# WARD ZERO / AILE ZÉRO: Game Design Document

**Version:** 1.0 (handoff draft)
**Genre:** Psychological survival-horror escape room
**Platform:** Desktop web browser (mouse + keyboard)
**Languages:** English and French (Québec), from day one
**Target length:** 3–5 hours (Normal difficulty, first playthrough)
**Team / pipeline:** Solo dev. Art is AI-assisted plus asset-store kitbash.
**Status:** Private hobby project

---

## 1. High Concept

You wake inside the derelict **Institut Sainte-Odile**, an asylum in rural Québec that closed in 1981. A cassette in a dictaphone plays a child's voice: *"Mathieu… viens me chercher."* It is your sister Claire, who died 22 years ago.

The game is set in fixed-camera, pre-rendered rooms in the style of classic Resident Evil. You solve layered escape-room puzzles while a silent figure in a white uniform walks the halls. You cannot fight it. You can only hide, run, and keep going.

The deeper you go, the less the asylum makes sense. Documents carry the wrong dates, and some rooms slip back to 1976. The real question isn't how to escape. It's what you are escaping from.

### Design Pillars
1. **Every room is a puzzle box.** Each room has at least one self-contained puzzle, and most also feed puzzles in other rooms.
2. **Dread, not death.** The tension comes from what you might lose: progress, items, composure. Combat is never the source.
3. **Fair puzzles, unreliable world.** The world lies to the player. Puzzle-critical information never does. This rule cannot be broken.
4. **Two timelines, one building.** The present-day ruin and the 1976 memory version of a room affect each other.
5. **The truth is assembled, not told.** The ending depends on how much of the story the player has pieced together.

---

## 2. Story

### 2.1 Premise
- **Protagonist:** Mathieu Lavoie, 31. Players see him as a man who came looking for his missing sister. That framing is false.
- **Truth:** In 1976, nine-year-old Mathieu accidentally started the house fire that killed his sister Claire, who was six. He was committed to Sainte-Odile and pushed the event out of memory. In 1998, the "present" of the game, he is an inpatient in the modern psychiatric unit built on the old grounds. Every night he goes through a dissociative episode in which he relives Sainte-Odile and tries to escape it.
- **The Man in White (L'Homme en blanc):** The stalker. On the surface he is an orderly. Underneath, he is Mathieu's guilt. He is never explained outright, and he is unmasked only in the hidden ending.
- **Dr. Hélène Bouchard:** Mathieu's 1998 psychiatrist. Some of the tapes the player finds are recordings of her therapy sessions. Her voice is the only kind presence in the game.

### 2.2 Narrative Delivery
- **Documents:** notes, files, newspaper clippings, logs. They are readable and saved to the Files menu.
- **Tapes:** played on the dictaphone. Every tape has subtitles.
- **Memory shifts:** short visits to 1976 versions of rooms.
- **Anachronisms:** hints at the twist planted in plain sight, such as a 1998 pharmacy label or a modern fire-exit sign glimpsed while composure is low.

### 2.3 Truth Fragments
There are 12 key story items. Fragments marked **Opt** are optional and reward exploration. The finale puzzle (P21) uses all collected fragments.

| ID | Fragment | Found in | Req/Opt |
|---|---|---|---|
| F01 | Mathieu's admission file (1976) | Records Office (P03) | Req |
| F02 | Newspaper clipping: house fire, child dead | Administrator's Office | Req |
| F03 | Nurse's log: "the boy talks to his sister" | Nurse Station | Opt |
| F04 | Claire's crayon drawing | Children's Dormitory (P09) | Req |
| F05 | Class essay: "Ma famille" by M.L. | Classroom (P10) | Opt |
| F06 | Wall scratchings: tally marks and "MY FAULT" | Isolation Cells | Opt |
| F07 | Tape: Dr. Bouchard, session 1 (dated 1998) | Boiler Room | Req |
| F08 | Director's journal | Director's Quarters (P17) | Req |
| F09 | Pharmacy label for M. Lavoie, dated 1998 | Pharmacy | Opt |
| F10 | Lecture slide: "Case study: Patient L." | Observation Theatre (P16) | Req |
| F11 | Morgue registry with no Claire listed | Morgue (P19) | Opt |
| F12 | Tape: Mathieu's own adult voice, recorded "last night" | Treatment Room | Req |

### 2.4 Endings
| Ending | Condition | Outcome |
|---|---|---|
| **Relapse** | Fewer than 9 fragments placed correctly in P21 | Mathieu goes through the exit door and wakes up in the Dayroom again. Credits roll and New Game+ unlocks. |
| **Discharge** | 9 or more placed correctly | The asylum melts away. Mathieu wakes in a sunlit 1998 hospital room with Dr. Bouchard. |
| **Claire** (hidden) | 12 out of 12 correct, **and** in Ward Zero the player stops running and lets the Man in White reach him | The figure is unmasked. Mathieu forgives himself and Claire says goodbye. This is the true ending. |

---

## 3. Core Gameplay

### 3.1 Core Loop
**Explore** a room → **inspect** the hotspots → **collect** items and clues → **solve** puzzles in close-up → **unlock** new paths → **manage** the stalker threat → **save** at a safe room → repeat. Over all of that sits the meta loop: **gather truth fragments** for the finale.

### 3.2 Controls (Desktop)
| Input | Action |
|---|---|
| Left click (floor) | Walk to point |
| Double-click (floor) | Run. Faster, but **makes noise**. |
| Left click (hotspot) | Walk to it, then interact (examine / take / use / open) |
| Right click | Cancel or go back |
| I | Inventory |
| F | Files (documents and tapes) |
| M | Map |
| Esc | Pause / options |
| Space (while hiding) | Hold breath (see 5.3) |

The cursor changes over hotspots: eye for examine, hand for take or use, arrow for an exit, lock for something locked.
Click-to-move avoids the control-flip problem when the fixed camera cuts. A path keeps going across a cut.

### 3.3 Fixed-Camera Rooms
- Each room has 1 to 4 pre-rendered camera angles.
- Trigger volumes switch the camera as the player moves.
- The 3D player character is drawn over the background and correctly hidden behind foreground objects (see 9.3).
- Close-up puzzle views are separate 2D screens built on their own close-up renders.

### 3.4 Inventory
- **Main slots:** 6 to start, 8 after picking up the **Orderly's Satchel** (optional, in the Linen Room).
- **Key pouch:** unlimited and uses no slots. Holds keys, memory anchors, truth fragments and the dictaphone.
- **Effects Bins:** linked storage chests in every safe room, like the RE item box.
- **Examine:** items can be turned in 3D. Some reveal hidden details this way, for example a code engraved on the underside.
- **Combine:** drag one item onto another.

### 3.5 Map
- The map fills in as rooms are entered and the floor-plan maps are found.
- **Room colors:** red means something unresolved remains (an item, a puzzle, a locked door). Blue means fully cleared. This is the main way to cut down on aimless wandering.
- The map shows icons for locked doors and their key types.

---

## 4. Memory Shifts (Signature Mechanic)

### 4.1 Rules
- The player collects **Memory Anchors**, objects tied to 1976: the Photograph, Claire's Ribbon, the Music Box Cylinder, and the Drawing.
- **Resonant spots** are marked by a subtle flicker and a low audio hum. Using the right anchor there turns the room into its **1976 version**.
- The memory version shares the room's layout, but its state is different: doors that are now bricked up are open, objects are intact, and so on.
- **Crossing the timelines:**
  - Objects flagged as *persistent* carry **forward** into the present. Hide a fuse in a wall cavity in 1976, and you can collect it from the crumbling wall in 1998.
  - Nothing carries backward from the present into the memory, except the player's knowledge.
- **Leaving:** use the anchor again, or walk out through any door. Leaving always returns the player to the present.
- **The stalker cannot follow into a memory.** Scripted NPCs from 1976 can appear there, but they cannot hurt the player.
- **Budget:** 8 rooms have memory variants (listed in section 6).

### 4.2 Design Intent
Memory shifts are a puzzle tool, a breather from the stalker, and the main way the story reaches the player, all at once. Each one should reveal something about 1976.

---

## 5. Threat Systems

### 5.1 The Man in White: AI
**Simulated on the room graph.** When the stalker is off-screen, he exists only as a position on the graph of rooms and doors. He is spawned in 3D only when he is in the player's room or entering it. This keeps him cheap to run and keeps fixed-camera framing under control.

| State | Behavior |
|---|---|
| Dormant | Not in the simulation. Used in scripted-only zones. |
| Patrol | Follows a waypoint loop of rooms for the current act. |
| Investigate | Heads to the room where a noise came from. |
| Search | Checks hiding spots in that room for a few seconds, then gives up. |
| Chase | Has seen the player. Follows at walking or running speed and goes through doors after a short delay. |
| Lose | Line of sight broken long enough. Goes back to Search, then Patrol. |

**Noise events** (each has a radius measured in room-graph hops):
- Running: 1 hop
- Dropping or throwing an item: 1 hop
- **A failed loud puzzle attempt**, such as rattling a padlock or a wrong safe combination: 1 to 2 hops
- Slamming a door: 2 hops
- Some puzzle mechanisms (boiler, gears): 2 hops, by design

**Room access flags** (set in room data):
- `open`: the stalker can patrol through
- `scripted`: entered only during scripted events. **This is the default for rooms with a complex puzzle**, to avoid unfair punishment during long puzzles.
- `never`: safe rooms and memory rooms

**Telegraphing:** every visit is announced. Footsteps are positioned on the side of the door he's coming from, there's a heartbeat, and the edges of the screen desaturate. The player always gets a warning of at least 3 seconds.

**Close-up puzzle views do not pause the game**, except on Observer difficulty. Footstep cues keep playing over close-ups.

### 5.2 Presence by Act
| Act | Presence |
|---|---|
| Act 1 | Scripted only. One reveal chase from the Lobby to the Dayroom. |
| Act 2 | Active in the East and West wings and the Dining Hall. |
| Act 3 | Active on the Upper Floor, faster patrols. |
| Act 4 | Relentless in the Basement. Finale chase. |

### 5.3 Hiding
- **Hiding spots:** lockers, under beds, curtained alcoves, the kitchen pantry. Each room in an active zone has 1 or 2.
- Hiding works **unless he sees you go in** (a line-of-sight check when you enter the spot).
- **Hold breath:** if he searches your spot, you get a short hold. The tolerance window is set by threat difficulty. Letting go too early gets you found.

### 5.4 Composure (Hidden Meter)
There is no HUD. Composure shows up only through what the player sees and hears.

| Composure | Effects |
|---|---|
| Steady | Normal |
| Shaken | Vignette, heartbeat, phantom footsteps, and occasional fake item glints that vanish when clicked |
| Breaking | Stronger distortion, anachronism flashes, and the stalker's hearing radius +1 hop |

- **Lowered by:** seeing the stalker, being in unlit rooms, being caught (on Observer), and certain documents.
- **Restored by:** time spent in safe rooms, the Sedatives consumable, and finishing a memory shift.
- **Hard rule:** composure never changes puzzle-critical information. Hallucinations only affect atmosphere, fake glints, and stalker cues.
- Composure can be cut. If scope is tight, it can be reduced to Steady/Shaken audio and visual effects only.

---

## 6. World: Institut Sainte-Odile

### 6.1 Room List
Cams = camera angles. Mem = has a 1976 variant. Access = stalker access flag. **★** = safe room (tape recorder and Effects Bin).

| ID | Room | Cams | Mem | Access | Notes |
|---|---|---|---|---|---|
| **Ground Floor** |||||
| G01 ★ | Dayroom | 2 | ✔ | never | Start room |
| G02 | Main Lobby | 3 | | open | Central hub, first stalker reveal |
| G03 | Reception | 1 | | scripted | P02 |
| G04 | Records Office | 2 | | scripted | P03 |
| G05 | Administrator's Office | 2 | | scripted | P04 |
| G06 | Chapel | 2 | ✔ | scripted | P05, memory-shift tutorial |
| G07 | Dining Hall | 3 | | open | Links the two wings; stalker arena |
| G08 | Kitchen | 2 | | open | Pantry hiding spot; shortcut to the basement |
| G09 | Main Corridor | 3 | | open | |
| **East Wing** (Choleric key) |||||
| E01 | East Corridor | 3 | | open | |
| E02 | Nurse Station | 2 | | scripted | P06 |
| E03 | Hydrotherapy | 2 | | scripted | P07 |
| E04 | Linen Room | 2 | | open | P08 stealth puzzle; Satchel |
| E05 | Women's Ward | 2 | | open | Hiding spots, documents |
| **West Wing** (Melancholic key) |||||
| W01 | West Corridor | 3 | | open | |
| W02 | Children's Dormitory | 2 | ✔ | scripted | P09 |
| W03 | Classroom | 2 | ✔ | scripted | P10 |
| W04 | Playroom | 2 | ✔ | scripted | P11 |
| W05 | Isolation Cells | 3 | | open | P12 |
| W06 ★ | Staff Lounge | 1 | | never | |
| **Upper Floor** (reached by elevator after P13) |||||
| U01 | Upper Hall | 3 | | open | |
| U02 | Library | 2 | | scripted | P14 |
| U03 ★ | Reading Room | 1 | | never | |
| U04 | Pharmacy | 1 | | scripted | P15 |
| U05 | Observation Theatre | 2 | | scripted | P16 |
| U06 | Director's Quarters | 3 | ✔ | scripted | P17, P18 |
| **Basement** |||||
| B01 | Boiler Room | 2 | | scripted | P13 (Phlegmatic key opens the stairs) |
| B02 | Basement Corridor | 3 | | open | Sanguine key opens the treatment wing |
| B03 | Morgue | 2 | ✔ | scripted | P19 |
| B04 | Treatment Room | 2 | ✔ | scripted | P20 |
| B05 ★ | Archive Antechamber | 1 | | never | |
| B06 | Archive Vault | 1 | | never | P21 finale puzzle |
| B07 | Ward Zero | 3 | | open | P22. Not on any floor plan. |

**Totals:** 33 rooms, about 70 present-day backgrounds, about 16 memory backgrounds, and about 30 puzzle close-ups. That comes to **roughly 115 pre-rendered images**.

### 6.2 Progression Gating: the Temperament Keys
Four keys are stamped with the medical temperaments of old humoral theory. They stay in the key pouch after use, because all four are needed again for P20.

| Key | Obtained | Opens |
|---|---|---|
| Choleric (yellow, fire) | P04 Administrator's safe | East Wing |
| Melancholic (black, earth) | P07 Hydrotherapy | West Wing |
| Phlegmatic (white, water) | P12 Isolation Cells | Basement stairs → Boiler Room |
| Sanguine (red, air) | P17 Director's safe | Basement treatment wing |

---

## 7. Puzzle Catalog

**Every puzzle has three difficulty variants** (see 8.2). Numeric codes are **generated from the playthrough seed**, so walkthroughs can't hand out answers and NG+ stays fresh. Documents show the generated values through text templates.

| ID | Room | Puzzle | Type | Clue source | Reward |
|---|---|---|---|---|---|
| **Act 1: Arrival (~45 min)** ||||||
| P01 | G01 Dayroom | Tune the radio dial to the frequency from the "Quiet Hours" schedule. Static gives way to a message, and the door chain releases. | Observation (tutorial) | Wall notice | Exit to Lobby |
| P02 | G03 Reception | Switchboard: patch the cables using the staff extension directory to ring the Administrator. The phone rings and the electric gate unlocks. | Logic / matching | Directory, desk memo | Admin wing access |
| P03 | G04 Records | Card catalog: find your own file by cross-referencing the birthdate on your wristband. One drawer is misfiled. | Deduction | Wristband (item) | F01, Photograph (Anchor 1) |
| P04 | G05 Admin Office | Wall safe. The code comes from the lobby plaque's founding date, put through the memo's cipher rule. | Code / cipher | Plaque (G02), memo | Choleric key, F02 |
| P05 | G06 Chapel | **Memory tutorial.** In 1976 the hymn board is complete. Set the matching numbers on the present-day board to open the choir loft. | Cross-state | Memory version of the room | Music box crank |
| **Act 2: The Wards (~90 min)** ||||||
| P06 | E02 Nurse Station | Medication cart: match patients' charts to pills by **color and shape**. | Logic grid | Charts, shift log | Linen Room key, Sedatives |
| P07 | E03 Hydrotherapy | Three tubs and valves of different flow rates. Fill each to the exact marked level (water-jug logic). Emptying the last tub reveals a drain cache. | Logic / spatial | Gauge markings | Melancholic key |
| P08 | E04 Linen Room | Stealth puzzle: find the stained sheet with a ward code among the tagged laundry while he patrols. Each wrong pull makes noise. | Stealth hybrid | Laundry ledger | Code for E05 lockbox, Satchel |
| P09 | W02 Dormitory | Hang the children's drawings in story order. In 1976 one drawing is still on the wall and shows the missing step. | Sequencing / cross-state | Drawings, memory version | F04, Ribbon (Anchor 2) |
| P10 | W03 Classroom | The present-day chalkboard is half erased. In 1976 the lesson is being written. Combine the two to get the padlock code. | Cross-state | Both boards | F05, Music box cylinder (Anchor 3) |
| P11 | W04 Playroom | Music box: fit the crank (P05), set the cylinder pins to the melody hummed on a tape, then play it. The toy chest opens. | Audio / pattern | Tape | Fuse |
| P12 | W05 Isolation Cells | Knocks come from the cell doors in a sequence. Open the peepholes in the order of the knocks. **A visual alternative** is available (vibration dust). | Audio / spatial | Sound direction | Phlegmatic key, F06 |
| P13 | B01 Boiler Room | Restore power: fit the fuse, then balance three pressure valves using the gauge colors without going into the red. Loud: 2-hop noise. | Systems | Maintenance manual | Elevator power, F07 |
| **Act 3: Upper Floor (~60 min)** ||||||
| P14 | U02 Library | Reshelve the books by catalog number from the Director's reading list. A hidden door opens to the Director's Quarters. | Ordering | Reading list | Access to U06 |
| P15 | U04 Pharmacy | Balance scale: measure an exact weight using the available weights, as specified on the prescription. | Arithmetic | Prescription | Theatre projector key, F09 |
| P16 | U05 Theatre | Projector: put the slides in lecture order. Two slides overlap to show a combination. | Ordering / overlay | Lecture notes | Director's safe code, F10 |
| P17 | U06 Director's Quarters | The Director's safe, using the code from P16. The memory version of the room shows a 1976 session with young Mathieu. | Code + story | P16 | Sanguine key, F08 |
| P18 | U06 Director's Quarters | Set the grandfather clock to the time on the fire report (F02). A dumbwaiter shortcut to the Morgue opens. | Cross-reference | F02 | Shortcut |
| **Act 4: Below (~45 min)** ||||||
| P19 | B03 Morgue | Find the drawer that matches the death registry. In 1976 it is empty, because Claire was never brought here. | Deduction / cross-state | Registry | F11, Drawing (Anchor 4), part of the vault code |
| P20 | B04 Treatment Room | The humors panel: place all four temperament keys by element and season, following the wall mural. | Symbol matching | Mural | Archive Vault access, F12 |
| P21 | B06 Archive Vault | **Rebuild your own file.** Drag the collected fragments onto a timeline running from 1976 to 1998. The number placed correctly decides the ending. | Deduction (finale) | All fragments | Ending flag |
| P22 | B07 Ward Zero | Final sequence: chained memory shifts back through rooms already solved, while being pursued, to reach the exit. Then the final choice: run or stay. | Chase / choice | — | Ending |

**Puzzle authoring rules**
- Every clue must exist somewhere the player can **reach before** the puzzle that needs it, and be saved to Files or able to be re-examined.
- A failed attempt costs noise, not progress. No puzzle can be locked into an unsolvable state.
- Never encode information in color alone. Pair color with shape, symbol or text.
- Audio puzzles always have a visual alternative available.

---

## 8. Difficulty

Threat difficulty and puzzle difficulty are **chosen separately at New Game**, as in Silent Hill.

### 8.1 Threat Difficulty (also controls saving)
| Setting | Caught by stalker | Saving | Stalker tuning | Close-up pauses |
|---|---|---|---|---|
| **Observer** | Not lethal. The screen whites out and you wake in the nearest safe room. One non-key item drops where you were caught and can be picked up again. Composure drops. | Autosave on every room entry, plus unlimited manual saves at tape recorders | Slow, short hearing range, short searches, long breath-hold window | Yes |
| **Patient** | Lethal. Game over and reload. | Unlimited manual saves at tape recorders; autosave at the start of each act | Baseline | No |
| **Committed** | Lethal | Each save uses up a **Blank Cassette** (about 12 in the whole game) | Faster, +1 hearing hop, longer searches, tight breath-hold window | No |

### 8.2 Puzzle Difficulty
| Setting | Changes |
|---|---|
| **Easy** | Direct clues. Codes are partly visible. Fewer steps (for example, 2 tubs instead of 3 in P07). Map highlights rooms with an active puzzle. |
| **Normal** | As written in section 7 |
| **Hard** | Clues written as riddles, an extra cipher layer on codes, and more parts per puzzle (for example, 4 cables in P02) |

Each puzzle's resource file holds its three parameter sets.

### 8.3 New Game+
Unlocks after any ending. Codes get a new seed, all Files are kept, and the Claire ending hint becomes visible in the Files menu.

---

## 9. Technical Design

### 9.1 Engine Recommendation: **Godot 4.x (latest stable, 4.3 or newer)**
| Option | Verdict |
|---|---|
| **Godot 4 (web export)** | **Chosen.** Built-in navmesh, animation, localization, audio buses, scene tooling, and an editor for laying out hotspots and triggers. From 4.3, a single-threaded web export removes the need for the SharedArrayBuffer / COOP/COEP headers, so it works on any static host. |
| Three.js | Lighter download and native to the web, but you would build your own editor, navigation, animation state machine, save system and localization. That's too much custom work for a solo hobby project. |
| Phaser / PixiJS (2D) | Would need a 2D sprite character with fake depth. The occlusion and scaling against pre-rendered 3D backgrounds would be worse. |

**Render settings:** Compatibility renderer (WebGL 2), single-threaded web export, and web sample audio playback to cut audio latency.

### 9.2 Architecture
| System | Responsibility |
|---|---|
| **GameState** (autoload) | Global flags, inventory, key pouch, fragments, room states, seed, difficulty, composure, stalker simulation state |
| **SaveSystem** | Writes GameState as JSON to `user://`, which is IndexedDB in the browser. Also offers **export/import of saves as a text string**, because browsers can clear IndexedDB. |
| **RoomManager** | Loads and unloads room scenes, places the player at the door spawn, handles present/memory variants |
| **CameraDirector** | Camera trigger volumes, cuts, matching the background to the active camera |
| **PlayerController** | Click-to-move on the navmesh, interacting with hotspots, walk/run noise |
| **Interactable** (component) | Hotspot type, cursor icon, conditions, actions. Data-driven. |
| **PuzzleBase** (scene interface) | `setup(seed, difficulty)`, state serialize/deserialize, signals for solved / failed attempt / noise emitted. Each puzzle is a self-contained close-up scene. |
| **StalkerDirector** | Room-graph simulation, noise propagation, state machine, spawning into the 3D room when entering the player's room |
| **ComposureSystem** | Meter value; drives post-processing, audio and hallucination events |
| **MemoryShiftSystem** | Anchor use at resonant spots, swapping to the room variant, applying persistent cross-timeline object flags |
| **UI** | Inventory, 3D item examine, Files, Map, tape recorder save screen, options, subtitles |
| **Localization** | Godot TranslationServer with CSV (or PO) files. All strings go by key. **Document templates take placeholders for seed-generated codes.** |

**Data-driven content (Godot resources):**
- **RoomData:** id, cameras, exits (door → room id, key needed), access flag, memory variant scene, hiding spots, map rectangle
- **PuzzleData:** id, room, parameters per difficulty, seed fields, noise level on failure, rewards, prerequisite flags
- **ItemData:** id, name key, description key, 3D examine model, can combine with → result, slot or key pouch
- **DocumentData:** id, title key, body template key, fragment id (if any), placeholder bindings
- **TapeData:** id, audio per language, subtitle track key, fragment id

### 9.3 Pre-Rendered Background Pipeline
1. **Blender:** kitbash the room from asset-store packs, light it, and place 1 to 4 cameras.
2. **Render per camera:** a beauty pass at 1920×1080. Optionally a depth pass.
3. **AI-assisted paintover:** add grime, aging, and detail. **Use low strength and mask the edges of foreground objects**, because heavy paintover shifts silhouettes and breaks the occlusion alignment.
4. **Export a proxy scene** as glTF: the cameras, simplified collision and occluder meshes, the floor for the navmesh, and hotspot volumes.
5. **In Godot:** match the Camera3D to the exported camera. Show the background as a fullscreen backdrop.
   - **Occlusion approach:** proxy meshes use a shader that samples the background in screen space and writes depth. The character is then correctly hidden behind foreground furniture. The same proxies receive the character's shadow and provide the navmesh and collision.
   - Optional alternative: a depth-image shader on a fullscreen quad.
6. **Character lighting:** each camera has a simple light rig that matches the render. Light probes are optional.
7. **Memory variants:** same geometry and cameras, with re-textured and re-lit renders. The proxies are reused.
8. **Unified look** (this is what makes AI and asset-store material sit together): a single LUT, film grain, slight chromatic aberration and a vignette applied to *all* backgrounds and the live character. The reference is a late-90s CRT/VHS look without parody.

### 9.4 Web Budgets
| Item | Budget |
|---|---|
| First download (engine + Act 1) | 40 MB or less |
| Later content | Split into **resource packs per act** (about 15 to 25 MB each), downloaded and loaded at runtime with a loading screen between acts |
| Background images | WebP, about 200 to 400 KB each |
| Character | 15,000 to 25,000 triangles, 1 or 2 materials, retargeted asset-store or mocap animations |
| Frame rate | 60 fps on integrated laptop graphics (Chrome, Firefox, Edge) |
| Audio | OGG Vorbis. Ambient loops streamed, sound effects preloaded per act. |

### 9.5 Browser Requirements
Recent versions of Chrome, Edge and Firefox on desktop with WebGL 2. Safari is best-effort. Phones and tablets are blocked with a message.

---

## 10. Audio

Audio carries half of the horror, so it should be treated as a pillar.

- **Room ambience:** a layered loop per room plus random one-off sounds (pipes, distant doors). Memory rooms get warmer, muffled ambience with faint period sounds.
- **The stalker:** footsteps panned to the side of the door he's approaching from. He makes no vocal sounds, ever. Silence is part of who he is.
- **Composure:** the heartbeat layer, a tinnitus effect while Breaking, and phantom sounds.
- **Music:** minimal. Safe rooms get a unique, calm theme (as with RE save rooms). Music cues appear only for chases and memory shifts.
- **Tapes:** Dr. Bouchard, young Claire, adult Mathieu. Recorded in EN and FR, using AI text-to-speech plus processing (tape hiss, wobble). The processing hides the artificial quality of TTS. Subtitles are always on by default.
- **Audio puzzles** (P11, P12) always have a visual alternative.

---

## 11. UI and Presentation

- **Diegetic style:** the inventory looks like the contents of an orderly's satchel, Files is a manila patient folder, the Map is a laminated evacuation plan that gets annotated, and the save screen is the dictaphone interface.
- **HUD:** none during exploration. Composure is shown only through effects.
- **Transitions:** a black cut with a door sound, as in RE. The door animation can be skipped in options.
- **Typography:** a typewriter-style face for documents, a clean sans-serif for menus. Both must cover all French characters (é, è, ê, à, ç, œ…).
- **Language switching:** available at any time in options. Documents re-render from their keys.

---

## 12. Accessibility
- Subtitles (on by default), with a text size setting and a background-box option
- Puzzle information never relies on color alone (color plus shape plus symbol)
- Visual alternatives for every audio puzzle; sound-direction indicators as an option
- Photosensitivity toggle that reduces flicker and flashes
- Intensity sliders for camera shake, grain and chromatic aberration
- Observer difficulty works as the "story mode"
- Key rebinding for keyboard shortcuts

---

## 13. Production Plan

### 13.1 Milestones
| Milestone | Scope | Exit criteria |
|---|---|---|
| **M0: Tech spike** | 1 room, 2 cameras, through the full background pipeline. Occlusion, click-to-move across a camera cut, one hotspot, web export running on a static host. | Runs at 60 fps in Chrome and Firefox. Occlusion looks right. Pipeline steps written down. |
| **M1: Vertical slice** | Act 1 complete: rooms G01–G06, puzzles P01–P05, inventory, Files, save/load, EN/FR, scripted stalker chase, one memory shift | Someone outside the project can play Act 1 start to finish in either language |
| **M2: Systems complete** | Stalker AI, hiding, composure, difficulty matrix, map coloring, seeded codes, resource-pack loading | All systems tuned on a test level |
| **M3: Act 2** | East and West wings, basement boiler room, P06–P13 | Content complete and playtested |
| **M4: Acts 3–4 + endings** | Upper floor, basement, P14–P22, all three endings, New Game+ | Can be finished on every difficulty combination |
| **M5: Polish** | Audio pass, LUT and grain pass, accessibility, translation proofreading, performance | Release candidate |

### 13.2 Cut List (in order, if scope gets tight)
1. Composure reduced to effects only (no gameplay link to stalker hearing)
2. Combine the Dining Hall and the Kitchen
3. Reduce memory variants from 8 to 5 (keep the Chapel, Dormitory, Classroom, Director's Quarters and Morgue)
4. Drop the Linen Room stealth puzzle (P08) and give the Satchel as an item instead
5. Drop New Game+
6. **Cut-down release:** Acts 1 and 2 as a standalone release (about 2 hours) with the Relapse ending only

### 13.3 Risks
| Risk | Mitigation |
|---|---|
| **Scope.** About 115 pre-rendered images and 22 puzzles is a large solo project. | Retire the pipeline risk in M0 and measure how long one room takes in M1. Then decide on cuts using that real number. |
| Inconsistent art across AI and asset-store sources | Lock the style guide and LUT in M0; every background goes through the same post-processing |
| AI paintover breaks occlusion alignment | Low-strength paintover, masked foreground edges, an occlusion check on every background |
| Browser download size | Resource packs per act, WebP backgrounds, streamed audio |
| Browser storage being cleared | Save export/import as text, plus a warning in options |
| Puzzle fairness | Follow the authoring rules in section 7; playtest every puzzle with someone outside the project on Normal and Hard |
| The stalker feeling cheap | Room access flags, the 3-second warning, and no stalker during heavy puzzles |

---

## 14. Open Questions
- Final title: *Ward Zero / Aile Zéro*, or *Sainte-Odile*?
- Where to get the character model: asset store or a custom build. How much does the Man in White need a unique silhouette? (Strongly recommended.)
- Exact count of Blank Cassettes on Committed, to be set by playtesting.
- Should Act 1 start with a short exterior arrival scene before the Dayroom wake-up, for tone? It would only matter for the Relapse loop's framing.
