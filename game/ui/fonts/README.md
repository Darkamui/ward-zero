# Fonts

| File | Use | Licence |
|---|---|---|
| `IBMPlexSans.ttf` (variable) | Menus, UI, subtitles | SIL OFL 1.1 (`OFL-IBMPlexSans.txt`) |
| `CourierPrime-Regular.ttf`, `-Bold.ttf` | Typewritten and printed documents | SIL OFL 1.1 (`OFL-CourierPrime.txt`) |
| `Caveat.ttf` (variable) | Handwritten notes | SIL OFL 1.1 (`OFL-Caveat.txt`) |

All cover French (é è ê ë à â ç î ï ô û ù ü ÿ œ Œ « » ’, U+00A0). Courier Prime and Caveat lack U+202F (narrow no-break space): use U+00A0 in strings. `tools/loc_lint.py` flags U+202F.
