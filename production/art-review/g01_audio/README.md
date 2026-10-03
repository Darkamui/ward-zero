# Dayroom and shared audio: first mix

Open [listen.html](listen.html) for the recorded game sequence and individual sounds, or play [gameplay-mix.wav](gameplay-mix.wav). This is a first mix for listening, not a claim of final perceptual/audio quality approval.

## Integrated behavior

- G01 plays a subdued electrical room-tone loop from LEGIT Audio's CC0 recording. Camera cuts and repeat requests retain playback. Room/timeline changes fade to the new stream or silence; game exit and world reset stop playback.
- Dayroom footsteps cycle four OwlishMedia hard-floor recordings based on actual distance traveled. Running is louder; stopping, teleporting and standing against an obstacle do not produce timer-driven footsteps. Other rooms retain their current sound behavior pending surface choices.
- P01 owns a looping static player. Signal strength attenuates it from -22 to -50 dB; solving stops it, closing frees it and reopening a solved radio stays quiet. Detents are rate-limited to one per 80 ms while tuning.
- The existing P01 reward action list plays a CC0 chain sound once. Loading/reopening a solved state does not retrigger it.
- Shared buttons, satchel, Files and paper use quiet UI-bus effects. Listed tape playback has a cassette transport click; radio voice events do not get a cassette click. Door transitions use a short closing sound.
- Ambience, SFX, UI and existing Voice volume controls remain independent. UI audio works while paused. The one-shot pool is bounded to 12 players. Audible effects do not emit gameplay noise events or alter AI hearing rules.

## Sources and mix

See [credits](../../credits.md), [archive URLs and hashes](sources.json), and [selected files and levels](manifest.json). Free assets were sourced from Kenney (Interface Sounds and RPG Audio), OwlishMedia, LEGIT Audio and rubberduck, all CC0. Radio static, detent and cassette transport are the supplied synthesized prototypes, retained for listening review. No new audio generation was needed.

Prepared foley files have -6 to -12 dBFS peaks before runtime attenuation. Room tone is normalized to -25 dBFS RMS before its -9 dB runtime level and the Ambience bus. Individual controls in the listening page apply runtime clip gain; the recorded sequence includes the default bus volumes too.

The actual engine capture is 13.19 seconds of stereo audio, with a measured -11.75 dBFS peak, zero clipped samples, and silence after world cleanup. It exercises ambience, walking, inventory, files, documents, cassette transport, radio tuning and solve. Timing is recorded in [capture-timeline.json](capture-timeline.json); signal checks are in [mix-validation.json](mix-validation.json). The capture does not include voice recordings.

## Validation and reproduction

Six `test_g01_audio` integration tests verify room/timeline transitions, camera-cut continuity, loop flags, rapid ambience changes, cleanup, paused UI playback, bus routing, bounded one-shots, actual walking/stop/teleport behavior, and radio lifecycle/one-time chain reward. The six existing radio input tests and four Act 1 critical-path tests also pass: 16 relevant tests total. Formatting and lint pass for the affected GDScript files. The previously documented resource cleanup warnings remain at engine shutdown.

To reproduce prepared assets, download the archives in `sources.json` into ignored `art-src/audio/` and extract under the IDs `kenney-interface`, `kenney-rpg`, `owlish`, `room-tone`, and `rubberduck`. The preparation script uses `numpy` and `soundfile`.

```powershell
python tools/prepare_g01_audio.py
godot --headless --editor --import --quit
godot --headless res://tests/run_tests.tscn -- --filter=test_g01_audio
godot --headless res://tests/run_tests.tscn -- --filter=test_radio_ui
godot --audio-driver Dummy res://tools/run_tool.tscn -- res://tools/smoke/g01_audio_capture.gd
```

The capture temporarily adjusts bus levels in memory and restores them; it writes no saves/settings. If recapturing, update `mix-validation.json` from the resulting WAV. Characters are deferred for the user's Meshy/Mixamo workflow. Remaining audio work includes listening/mix adjustments, Claire/radio voice, safe-room music, stalker cues and other rooms' ambience/surfaces.
