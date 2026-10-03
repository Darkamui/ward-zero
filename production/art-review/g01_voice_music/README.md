# G01 voice and safe-room music candidates

Open [listen.html](listen.html) for the real engine mix and separate English/French recordings and music. These are first listening candidates, not approved performances. Review Claire's age and consistency across lines/languages, pronunciation of Mathieu, Québec French, the radio woman's tone, and music fit. No auditory approval is claimed from signal analysis or automated tests.

## Assets and behavior

- Claire uses one shared recording of the name followed by a separate localized call, assembled at the existing opening subtitle times. Directions in parentheses are captions, never part of the generation transcript. The original five WAVs are preserved in `raw/`.
- P01 has separate EN/fr_CA speech and timing tracks. The existing SFX-bus chain release and chain-state flag still happen immediately on solve; the chain caption now appears then. The radio voice follows after 0.65 seconds. The chain is not baked into Voice audio and is not played twice. Radio VO stays out of Files and has no cassette transport click.
- Voice processing applies a mild band-pass, restrained saturation, low-level hiss and fades. No pitch shift, sped-up speech or new narrative text. Runtime clips are mono 48 kHz Ogg. Original voice outputs and exact endpoint/request/output URL records: [generation.json](generation.json).
- Music is Tsorthan Grove's existing CC0 **Safe Space** loop, used intact in stereo with lower gain. It starts only in present-day G01 with `act1.chase_done`, including restored saves/reentry. The opening retains room tone alone. Camera cuts do not restart the music; leaving the room or changing to memory fades it out. Voice playback lowers music by 9 dB and restores it afterward. Music and Voice retain independent volume buses.
- Tape replacement stops old audio even if the new tape only has subtitles. Mid-tape language changes restart the same subtitle key in the new language and recompute the duration. French language fallback also uses the French timing track. Playback pauses with the game; freeing the player releases music ducking.

## Validation

**28 tests pass:** five voice/music integration tests, six existing G01 audio tests, four Act 1 critical-path tests, four schema tests and nine document tests. The voice/music tests cover story gating, room/timeline/camera behavior, reentry, ducking, pause, cleanup, locale switching, subtitle-only replacement, natural completion and Files exclusion. See `tests/integration/test_g01_voice_music.gd`. Formatting and lint pass for all seven affected GDScript files.

The real Godot capture is 33.90 seconds, stereo 44.1 kHz, peak **−6.66 dBFS**, zero clipped samples, silence in the final 250 ms. [capture-timeline.json](capture-timeline.json) lists the sequence; [mix-validation.json](mix-validation.json) records signal checks. The supplied music loop's decoded boundary step is below its 99th percentile adjacent-sample step; seamless musical phrasing still needs listening. Runtime additions total 1,538,542 bytes.

Existing RID/ObjectDB/resource warnings remain at engine shutdown. No in-test runtime errors are accepted. The capture uses temporary bus levels, restores them and does not save settings or gameplay. It exercises the post-chase flag, not an entire chase playthrough.

## Reproduce

Download the FLAC in [music-source.json](music-source.json) to `art-src/audio/music/safe_space_loop.flac`. Retained raw voices avoid repeat generation charges. The preparation script requires `numpy`, `scipy`, `soundfile` and writes the selected Ogg assets, tape resources, manifest and listening page. Long stereo encoding uses small blocks to avoid a Windows libsndfile stack overflow.

```powershell
python tools/prepare_g01_voice_music.py
godot --headless --editor --import --quit
godot --headless res://tests/run_tests.tscn -- --filter=test_g01_voice_music
godot --audio-driver Dummy res://tools/run_tool.tscn -- res://tools/smoke/g01_voice_music_capture.gd
```

If recapturing, update the signal measurements and timeline. Other tapes, chase/stalker cues and other rooms' music remain separate asset work. Character models/animation remain deferred for the user's Meshy/Mixamo workflow.
