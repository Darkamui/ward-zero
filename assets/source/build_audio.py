"""Original synthesized placeholder effects; no sampled third-party recordings.
48 kHz mono PCM WAV; normalize peaks conservatively; layer/pan in the engine.
"""
from pathlib import Path
import numpy as np, wave, json
ROOT=Path(__file__).resolve().parent.parent;OUT=ROOT/'audio';OUT.mkdir(exist_ok=True)
SR=48000;rng=np.random.default_rng(1976);manifest=[]
def noise(n):return rng.normal(0,1,n)
def tone(t,f):return np.sin(2*np.pi*f*t)
def save(name,x,loop=False,description=''):
 x=np.nan_to_num(x);n=len(x)
 if not loop:
  fade=min(480,n//10);x[:fade]*=np.linspace(0,1,fade);x[-fade:]*=np.linspace(1,0,fade)
 x=x/max(1e-8,np.max(np.abs(x)))*.42
 with wave.open(str(OUT/(name+'.wav')),'wb') as w:w.setparams((1,2,SR,0,'NONE','not compressed'));w.writeframes((x*32767).astype('<i2').tobytes())
 manifest.append({'id':name,'seconds':round(n/SR,3),'sample_rate':SR,'channels':1,'loop':loop,'description':description,'status':'synthesized prototype effect; requires listening and in-game mix review'})
def t(s):return np.arange(int(SR*s))/SR
for i in range(3):
 a=t(.14);x=(noise(len(a))*.35+tone(a,1400+i*170)*.2)*np.exp(-a*65)
 save('ui_click_'+str(i+1),x,description='Small dry mechanical interface click')
a=t(.22);save('radio_detent',(tone(a,1800)*.25+noise(len(a))*.15)*np.exp(-a*60),description='Tuning knob detent')
a=t(.45);save('patch_plug_insert',(tone(a,130)*.6+noise(len(a))*.2)*np.exp(-a*35)+tone(a,620)*np.exp(-((a-.07)/.01)**2)*.08,description='Short plug seating knock')
a=t(.65);save('safe_latch',(tone(a,92)*.5+tone(a,690)*.15+noise(len(a))*.2)*np.exp(-a*16),description='Safe latch release')
a=t(.8);save('chain_release',sum(tone(a,f)*np.exp(-a*(5+i)) for i,f in enumerate([780,1137,1601,2293]))*.15+noise(len(a))*.06*np.exp(-a*9),description='Synthetic chain rattle')
a=t(.9);save('paper_turn',noise(len(a))*(np.exp(-((a-.22)/.14)**2)+.6*np.exp(-((a-.58)/.1)**2))*.12,description='Paper-like noise sweep')
a=t(.5);save('cassette_transport',(tone(a,190)*.4+noise(len(a))*.3)*np.exp(-a*25)+tone(a,950)*np.exp(-((a-.15)/.008)**2)*.08,description='Cassette transport click')
for i in range(4):
 a=t(.48);thump=tone(a,72+i*5)*np.exp(-a*17);scuff=noise(len(a))*.08*np.exp(-((a-.085)/.05)**2)
 save('footstep_'+str(i+1),thump*.45+scuff,description='Synthetic shoe impact variation; replace with foley for final realism')
a=t(1.2);save('door_close',tone(a,63)*np.exp(-a*6)*.5+noise(len(a))*.1*np.exp(-a*24),description='Low door-closing impact')
a=t(1.8);save('telephone_ring',(tone(a,440)+tone(a,480))*.18*(.5+.5*tone(a,18))*np.minimum(1,a*20)*np.minimum(1,(1.8-a)*20),description='Stylized telephone ring pulse, not period-authentic bell foley')
a=t(3);save('memory_shift',sum(tone(a,f)*(np.sin(np.pi*a/3)**2) for f in [110,165,221])*.12+noise(len(a))*.015*np.sin(np.pi*a/3),description='Gentle harmonic memory transition, no sudden transient')
a=t(1.1);save('heartbeat',tone(a,58)*(np.exp(-((a-.15)/.055)**2)+.6*np.exp(-((a-.38)/.045)**2)),description='Two-beat pulse, timing controlled by engine')
# Exact integer-cycle oscillators loop at 8 seconds. Noise loops crossfaded.
a=t(8);save('electrical_hum_loop',(tone(a,60)*.4+tone(a,120)*.12+tone(a,180)*.05)*(1+.04*tone(a,.5)),True,'Low electrical room hum; adjust volume conservatively')
x=noise(SR*9)*.10;fade=SR;tail=x[-fade:].copy();x=x[:SR*8].copy();ramp=np.linspace(0,1,fade,endpoint=False);x[:fade]=tail*(1-ramp)+x[:fade]*ramp
save('radio_static_loop',x,True,'Broadband synthetic radio static; use at low level and attenuate near target frequency')
(ROOT/'data'/'audio.json').write_text(json.dumps(manifest,indent=2));print(f'Created {len(manifest)} original prototype sound effects.')
