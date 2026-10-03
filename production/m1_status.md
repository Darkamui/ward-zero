# M1 Status

Snapshot of where the vertical slice stands against `docs/02-milestone-1.md`. Everything here runs in **greybox**: rooms are code-built and clay-rendered, close-ups are placeholder UI, and there is no audio yet.

## Playable now

Title → New Game → G01 (opening tape) → P01 radio → Lobby → P02 switchboard → gate → P03 card catalog (F01, Photograph) → P04 safe (Choleric key, F02) → reveal chase in the Lobby → Dayroom → Chapel memory shift → P05 hymn board → crank → Lobby corridor door → end-of-slice screen. Both languages, switchable at any time. Save at the G01 recorder, load, export/import as text.

`tests/integration/test_act1_critical_path.gd` plays this route through the game systems on three seeds in CI.

## Task status

| Task | Status | Notes |
|---|---|---|
| M1-01 GameState | ✅ | |
| M1-02 SaveSystem + export/import | ✅ | Reload persistence checked in Chromium |
| M1-03 RoomManager | ✅ | Black cuts, spawn, room state, enter triggers |
| M1-04 Interactable / actions / use-item / keys | ✅ | Keys auto-use on their door |
| M1-05 PuzzleBase | ✅ | Logic separate from UI |
| M1-06 DocumentRenderer | ✅ | Seeded placeholders, live language switch |
| M1-07 Noise plumbing | ✅ | Puzzles, drops, running |
| M1-08 Debug tools | ✅ | F9 overlay + warp/give/solve/memory keys |
| M1-09 Content validator | ✅ | As tests: `test_rooms_contract`, `test_documents` |
| M1-10…16 UI | ✅ placeholder look | Inventory, examine, bin, Files, tapes/subtitles, save screen, menus |
| M1-17 Memory shift | ✅ | Chapel only, as planned |
| M1-18 Scripted chase | ✅ | Speed retuned to 1.6× walk (see plan doc) |
| M1-19 Characters | ⏳ placeholders | Capsules. Needs real models (Overview Q2). |
| M1-20/21 Greybox + greybox playthrough | ✅ built / ⏳ human playthrough | |
| M1-22…29 Final art | ⏳ | Needs the Blender + paintover pipeline on real hardware |
| M1-30…34 Puzzles | ✅ logic + placeholder UI | Final close-up art pending |
| M1-35 Paper prototypes | ⏳ | Human task |
| M1-36 Writing EN | ✅ first draft | All Act 1 text exists |
| M1-37 FR translation | ✅ first draft, ⏳ native review | Written to OQLF typography conventions; needs a Québec French reviewer |
| M1-38 Voices (TTS) | ⏳ | Provider not chosen (Overview Q10). Tapes run on subtitle timings meanwhile. |
| M1-39 Fonts | ✅ | IBM Plex Sans, Courier Prime, Caveat (OFL) |
| M1-40 Audio | ⏳ | No assets. Buses and players exist. |
| M1-50…54 Playtests + retro | ⏳ | Human tasks |

## Design changes made during implementation

- **P02 switchboard:** a route is a chain, so relay jacks take two cables. The plan's one-cable-per-jack rule made it unsolvable.
- **Chase speed:** 1.6× walking speed instead of 1.1× (1.1× never caught a walking player across the Lobby).
- **G01 memory variant** moved to M3 (only the Chapel variant is in M1 scope).
- **Static G02 barricade:** the greybox background always shows it. Final art needs a second background state, or an overlay prop, once it breaks.

## Needs you

1. Run one room through Blender → paintover (M0 still open: real-GPU fps, Firefox/Edge, LUT).
2. Pick a TTS provider and voices (Q10). Pick character models (Q2).
3. Québec French review of all strings.
4. Two outside playtests (EN and FR) once art and audio are in.
