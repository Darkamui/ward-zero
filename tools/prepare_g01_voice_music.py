"""Prepare the recorded voice candidates and CC0 safe-room loop; no generation calls.

Requires numpy/scipy/soundfile. Raw voices and generation provenance are retained
in production/art-review/g01_voice_music. Download music from music-source.json
to art-src/audio/music/safe_space_loop.flac before running.
"""
from pathlib import Path
import hashlib
import json
import math
import html

import numpy as np
import soundfile as sf
from scipy.signal import butter, sosfilt, resample_poly

ROOT = Path(__file__).resolve().parents[1]
REVIEW = ROOT / "production/art-review/g01_voice_music"
OUT = ROOT / "game/audio/g01"
RATE = 48000
manifest = []


def read_voice(name):
    path = REVIEW / "raw" / f"{name}.wav"
    x, sr = sf.read(path, always_2d=True)
    x = x.mean(axis=1)
    x = resample_poly(x, RATE // math.gcd(sr, RATE), sr // math.gcd(sr, RATE))
    active = np.flatnonzero(np.abs(x) > np.max(np.abs(x)) * .008)
    x = x[max(0, active[0] - 2400):min(len(x), active[-1] + 6000)]
    x -= x.mean()
    x *= 10 ** (-7 / 20) / max(np.max(np.abs(x)), 1e-8)
    return x


def process_voice(x, radio=False):
    # Mild band-pass, saturation and low-level hiss. No pitch shift or sped-up speech.
    x = sosfilt(butter(2, [280 if radio else 160, 3800 if radio else 6000],
                             btype="bandpass", fs=RATE, output="sos"), x)
    x = np.tanh(x * 1.2) / 1.2
    rng = np.random.default_rng(401 if radio else 101)
    hiss = sosfilt(butter(1, [1400, 6500], btype="bandpass", fs=RATE, output="sos"),
                   rng.normal(0, 1, len(x)))
    hiss *= 10 ** (-49 / 20) / np.sqrt(np.mean(hiss * hiss))
    x += hiss
    x[:960] *= np.linspace(0, 1, 960)
    x[-4800:] *= np.linspace(1, 0, 4800)
    x *= min(1, 10 ** (-6 / 20) / np.max(np.abs(x)))
    return x


def write(name, x, extra=None):
    target = OUT / f"{name}.ogg"
    # Small blocks avoid libsndfile's Windows stack overflow on long stereo buffers.
    with sf.SoundFile(target, mode="w", samplerate=RATE,
                      channels=1 if x.ndim == 1 else x.shape[1], subtype="VORBIS") as file:
        for offset in range(0, len(x), RATE):
            file.write(x[offset:offset + RATE])
    decoded, _ = sf.read(target)
    entry = {"id": name, "file": target.relative_to(ROOT).as_posix(),
             "seconds": round(len(decoded) / RATE, 3),
             "peak_dbfs": round(20 * np.log10(np.max(np.abs(decoded))), 2),
             "sha256": hashlib.sha256(target.read_bytes()).hexdigest()}
    entry.update(extra or {})
    manifest.append(entry)


def tape_resource(tape_id, title_key, tracks, listed=True):
    lines = ['[gd_resource type="Resource" script_class="TapeData" format=3]', '',
             '[ext_resource type="Script" path="res://game/schemas/tape_data.gd" id="1"]',
             '[ext_resource type="Script" path="res://game/schemas/sub_line.gd" id="2"]']
    for locale, (name, _) in tracks.items():
        lines.append(f'[ext_resource type="AudioStream" path="res://game/audio/g01/{name}.ogg" id="{locale}"]')
    for locale, (_, subs) in tracks.items():
        for i, (start, end, key) in enumerate(subs):
            lines.extend(['', f'[sub_resource type="Resource" id="{locale}_{i}"]',
                          'script = ExtResource("2")', f'start = {start:.3f}',
                          f'end = {end:.3f}', f'key = "{key}"'])
    refs = lambda loc: ', '.join(f'SubResource("{loc}_{i}")' for i in range(len(tracks[loc][1])))
    lines.extend(['', '[resource]', 'script = ExtResource("1")', f'id = &"{tape_id}"',
                  f'title_key = "{title_key}"',
                  'audio = Dictionary[String, AudioStream]({"en": ExtResource("en"), "fr_CA": ExtResource("fr_CA")})',
                  f'subtitles = Array[ExtResource("2")]([{refs("en")}])',
                  'per_locale_subtitles = Dictionary[String, Array]({"fr_CA": [' + refs('fr_CA') + ']})'])
    if not listed:
        lines.append('listed_in_files = false')
    (ROOT / "game/data/tapes" / f"{tape_id}.tres").write_text('\n'.join(lines) + '\n', encoding="utf-8")


name = read_voice("claire_name")
claire = {}
radio = {}
for locale in ["en", "fr_CA"]:
    line2 = read_voice(f"claire_{locale}")
    second_start = max(3.5, .5 + len(name) / RATE + .8)
    end = second_start + len(line2) / RATE
    x = np.zeros(round((max(7, end) + .3) * RATE))
    x[24000:24000 + len(name)] = name
    offset = round(second_start * RATE)
    x[offset:offset + len(line2)] = line2
    subs = [[.5, min(second_start - .3, 3), "tape.01_claire.line1"],
            [second_start, max(7, end), "tape.01_claire.line2"]]
    clip = f"claire_{locale}"
    write(clip, process_voice(x), {"subtitles": subs})
    claire[locale] = (clip, subs)

    speech = read_voice(f"radio_{locale}")
    start = .65  # Existing SFX-bus chain reward plays at t=0; leave its transient clear.
    end = start + len(speech) / RATE
    x = np.concatenate([np.zeros(round(start * RATE)), speech, np.zeros(14400)])
    subs = [[0, .6, "tape.vo_p01_radio.line2"], [start, end, "tape.vo_p01_radio.line1"]]
    clip = f"radio_{locale}"
    write(clip, process_voice(x, radio=True), {"subtitles": subs})
    radio[locale] = (clip, subs)

tape_resource("tape_01_claire", "tape.01_claire.title", claire)
tape_resource("vo_p01_radio", "tape.vo_p01_radio.title", radio, listed=False)

music_path = ROOT / "art-src/audio/music/safe_space_loop.flac"
music_source = json.loads((REVIEW / "music-source.json").read_text(encoding="utf-8-sig"))
assert hashlib.sha256(music_path.read_bytes()).hexdigest() == music_source["sha256"]
x, sr = sf.read(music_path, always_2d=True)
assert sr == RATE
# Retain the composer's entire supplied loop and stereo image, only lower gain.
x *= min(10 ** (-23 / 20) / np.sqrt(np.mean(x * x)),
         10 ** (-6 / 20) / np.max(np.abs(x)))
write("safe_room", x, {"loop": True, "source_sha256": hashlib.sha256(music_path.read_bytes()).hexdigest()})
(REVIEW / "manifest.json").write_text(json.dumps(manifest, indent=2) + '\n', encoding="utf-8")

cards = []
for item in manifest:
    music = item['id'] == 'safe_room'
    cards.append(f'<article><h2>{html.escape(item["id"].replace("_", " "))}</h2>'
                 f'<audio controls preload="none" src="../../../{item["file"]}" '
                 f'data-gain="{10 ** (-10 / 20) if music else 1}" {"loop" if music else ""}></audio>'
                 f'<p>{item["seconds"]} s · {"in-game gain −10 dB; loops" if music else "processed voice candidate"}</p></article>')
page = '''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Ward Zero — voices and safe-room music</title>
<style>body{max-width:950px;margin:48px auto;padding:0 24px;background:#181917;color:#eee9dd;font:18px/1.5 system-ui}h1,h2{font-weight:500}h2{font-size:22px}p{color:#c6c0b7}article{padding:22px;border:1px solid #565448;margin:16px 0;border-radius:6px}audio{width:100%}a{color:#d9bb7b}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px}</style>
<h1>Dayroom voices &amp; safe-room music</h1>
<p>First listening candidates. Review Claire’s age, consistency, name pronunciation, Québec French, the calm radio delivery and music fit. Engineering checks do not establish performance quality.</p>
<article><h2>Recorded in-game mix</h2><audio controls preload="metadata" src="gameplay-mix.wav"></audio><p>English opening → radio solve → post-chase music → French Claire with music ducking → French radio → cleanup. <a href="capture-timeline.json">Timing log</a>.</p></article>
<div class="grid">''' + ''.join(cards) + '''</div><p>Music: <a href="https://opengameart.org/content/safe-space-0">Safe Space by TsorthanGrove (CC0)</a>. Voices: Gemini TTS via fal, original fictional roles. <a href="generation.json">Prompts, endpoint, request IDs and original output URLs</a>. <a href="README.md">Processing and validation notes</a>.</p>
<script>document.querySelectorAll('audio').forEach(a=>{a.volume=Number(a.dataset.gain||1);a.addEventListener('play',()=>document.querySelectorAll('audio').forEach(b=>{if(a!==b)b.pause()}))})</script></html>'''
(REVIEW / 'listen.html').write_text(page, encoding='utf-8')
print(json.dumps(manifest, indent=2))
