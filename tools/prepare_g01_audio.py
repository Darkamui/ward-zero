"""Prepare selected CC0 recordings from art-src/audio; requires numpy and soundfile.

Archive URLs/hashes are recorded in production/art-review/g01_audio/sources.json.
No source files are overwritten. Outputs are mono 48 kHz PCM for short foley and
a looped Ogg Vorbis room tone. See the review README for source directories.
"""
from pathlib import Path
import json
import math
import html
import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'art-src/audio'
OUT = ROOT / 'game/audio/g01'
REVIEW = ROOT / 'production/art-review/g01_audio'
OUT.mkdir(parents=True, exist_ok=True)
REVIEW.mkdir(parents=True, exist_ok=True)
manifest = []


def prepare(name, source, peak_db=-6, loop=False):
    original, sr = sf.read(source, always_2d=True)
    x = original.mean(axis=1)
    x -= x.mean()
    if sr != 48000:
        x = np.interp(np.arange(round(len(x)*48000/sr))*sr/48000, np.arange(len(x)), x)
    sr = 48000
    if loop:
        x = x[:min(len(x), 24*sr)]
        fade = min(sr, len(x)//4)
        ramp = np.linspace(0, 1, fade, endpoint=False)
        join = x[-fade:]*(1-ramp) + x[:fade]*ramp
        x = np.concatenate([join, x[fade:-fade]])
        x *= 10**(-25/20) / max(np.sqrt(np.mean(x*x)), 1e-8)
        x *= min(1, .7/max(abs(x)))
    else:
        # Trim recording silence but keep a short attack/release margin.
        active = np.flatnonzero(abs(x) > max(abs(x))*.015)
        if len(active):
            x = x[max(0,active[0]-240):min(len(x),active[-1]+961)]
        fade = min(144, len(x)//8)
        x[:fade] *= np.linspace(0, 1, fade)
        x[-fade:] *= np.linspace(1, 0, fade)
        x *= 10**(peak_db/20) / max(max(abs(x)), 1e-8)
    target = OUT / (name + ('.ogg' if loop else '.wav'))
    sf.write(target, x, sr, subtype='VORBIS' if loop else 'PCM_16')
    manifest.append({'id':name, 'source':str(source.relative_to(SRC)).replace('\\','/'),
        'file':str(target.relative_to(ROOT)).replace('\\','/'), 'seconds':round(len(x)/sr,3),
        'peak_dbfs':round(20*math.log10(max(abs(x))),2), 'loop':loop})


prepare('ui_click', SRC/'kenney-interface/Audio/click_001.ogg', -12)
prepare('satchel', SRC/'kenney-rpg/Audio/handleSmallLeather.ogg', -9)
prepare('folder', SRC/'kenney-rpg/Audio/bookOpen.ogg', -9)
prepare('paper', SRC/'owlish/Paper/pageturn1.wav', -9)
prepare('door_close', SRC/'kenney-rpg/Audio/doorClose_1.ogg', -6)
for i in range(1,5):
    prepare(f'step_{i}', SRC/f'owlish/Footsteps/hard-footstep{i}.wav', -9)
chain = sorted(p for p in (SRC/'rubberduck').rglob('*') if p.suffix in ['.ogg','.wav'] and 'chain' in p.name.lower())[0]
prepare('chain_release', chain, -6)
prepare('dayroom_loop', SRC/'room-tone/TheShopCollection_convenience_store_drinks_fridge_drone.wav', loop=True)
(REVIEW/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(REVIEW/'sources.json').write_bytes((SRC/'downloads.json').read_bytes())
gains = {'ui_click':-8, 'satchel':-8, 'folder':-8, 'paper':-8, 'door_close':-8,
         'chain_release':-6, 'dayroom_loop':-9, **{f'step_{i}':-10 for i in range(1,5)}}
rows = []
for item in manifest:
    name = item['id']; gain = gains[name]
    rows.append(f'<article><h2>{html.escape(name.replace("_", " "))}</h2>'
        f'<audio controls preload="none" data-gain="{10**(gain/20):.6f}" '
        f'src="../../../{item["file"]}" {"loop" if item["loop"] else ""}></audio>'
        f'<p>{item["seconds"]} s · playback gain {gain} dB</p></article>')
page = '''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Ward Zero — Dayroom audio review</title>
<style>body{max-width:900px;margin:48px auto;padding:0 24px;background:#181917;color:#eee9dd;font:18px/1.5 system-ui}h1,h2{font-weight:500}h2{font-size:21px;margin:0 0 12px}p{color:#bab6ad}article{padding:22px;border:1px solid #565448;margin:16px 0;border-radius:6px}audio{width:100%}a{color:#d9bb7b}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:16px}.grid article{margin:0}</style>
<h1>Dayroom audio review</h1><p>First mix for listening. Characters and voice recordings remain separate work.</p>
<article><h2>Recorded in-game sequence</h2><audio controls preload="metadata" src="gameplay-mix.wav"></audio>
<p>Room tone → footsteps → satchel → folder and paper → cassette click → radio tuning → chain release → silence.</p>
<p>The recording uses default bus levels. Individual clips below use their in-game gain before bus volume. Playback starts only when you press Play.</p></article>
<h2>Individual sounds</h2><div class="grid">'''+''.join(rows)+'''</div>
<p><a href="README.md">Sources, reproduction and remaining work</a></p>
<script>for(const a of document.querySelectorAll('audio')){a.volume=Number(a.dataset.gain||1);a.addEventListener('play',()=>{for(const b of document.querySelectorAll('audio'))if(a!==b)b.pause()})}</script></html>'''
(REVIEW/'listen.html').write_text(page,encoding='utf-8')
print(json.dumps(manifest,indent=2))
