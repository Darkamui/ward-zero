from pathlib import Path
import json,shutil,html,struct,hashlib,wave,xml.etree.ElementTree as ET
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parent.parent;SRC=ROOT.parent/'generated_images'
files={
'art/ui/folder.png':'0698d7d6-c95c-40ac-b8f4-1a8cc4d9bea8',
'art/ui/satchel.png':'d4be0c1c-fb73-47a8-80c0-f7d657e1e004',
'art/ui/paper.png':'85c8e789-704e-4998-9490-f8e23bc9448b',
'art/items/dictaphone.png':'7c2f224b-781b-49c1-bf07-d44b3d89a7a0',
'art/items/photograph-anchor.png':'c473ef13-1601-4954-8140-a3d44245a53f',
'art/items/blank-cassette.png':'b5c1e659-1142-455f-a67f-5b75157fbd9a',
'art/puzzle-bases/radio-housing.png':'01bdbbc8-53f1-4eb1-aa4d-f7d1e9ac7a08',
'art/puzzle-bases/switchboard-panel.png':'de85c73b-86e2-46ce-ba59-3ca87b0e52e1',
'art/puzzle-bases/hymn-board.png':'1cd00d9c-f195-47a0-8d46-370bb968ee23',
'references/characters/mathieu-reference.png':'7039c834-5aee-4887-86a0-8bfa18b4dde5',
'references/characters/stalker-reference.png':'db06d67a-2ee9-4288-80f1-ed002be61a18',
'references/rooms/G01-dayroom-concept.png':'fc7a8697-56e7-4e2c-89c5-651be1290efa',
'references/rooms/G02-lobby-concept.png':'4105b209-3eaa-4cc9-85be-7775d3fead04',
'references/rooms/G03-reception-concept.png':'59186b96-373a-467e-b9a0-c8e7e8d87f72',
'references/rooms/G04-records-concept.png':'9045536c-88fd-4c21-a9cd-bbeb7ae0ba9a',
'references/rooms/G05-administrator-concept.png':'4664133c-f796-470e-b792-3a4744179855',
'references/rooms/G06-chapel-present-concept.png':'378af725-dfcb-434d-a63b-d6726d56b228',
'references/rooms/G06-chapel-memory-concept.png':'84bd1cad-31dc-47e7-a468-229ab3d9200d'}
for target,id in files.items():
 dest=ROOT/target;dest.parent.mkdir(parents=True,exist_ok=True)
 if (SRC/('exec-'+id+'.png')).exists():shutil.copyfile(SRC/('exec-'+id+'.png'),dest)

# Engine overlay anchors are starting measurements, not calibrated hotspots.
anchors={'coordinate_space':'native source image pixels','status':'initial layout guides; verify against final imported texture','radio':{'image_size':[1536,1024],'scale_rect':[805,370,585,90],'tuning_knob_center':[1117,639],'volume_knob_center':[1276,639],'knob_diameter':110},'switchboard':{'image_size':[1536,1024],'header_rect':[165,125,1195,70],'usable_panel_rect':[190,265,1155,485],'recommended_socket_grid':[6,3]},'hymn':{'image_size':[1024,1536],'header_rect':[145,345,730,115],'number_rows':[[190,535,640,215],[190,850,640,215],[190,1160,640,215]],'tiles_per_row':3},'ui':json.loads((ROOT.parent/'ward-zero-ui-starter/data/ui-tokens.json').read_text()) if (ROOT.parent/'ward-zero-ui-starter/data/ui-tokens.json').exists() else {}}
(ROOT/'data'/'layout-anchors.json').write_text(json.dumps(anchors,indent=2))
voices={'status':'Historical starter-pack draft; not used by the game. Current dialogue and timing are in game/localization/tapes.csv and game/data/tapes/.','lines':[{'id':'claire_opening','speaker':'Claire, age six','en':'Mathieu… come and find me.','fr':'Mathieu… viens me chercher.','direction':'Quiet and intimate, a child speaking normally through a worn cassette, not a demonic whisper.','subtitle_default':True},{'id':'radio_unlocked','speaker':'Institutional announcement','en':'Evening rounds are complete. The dayroom door is released.','fr':'La tournée du soir est terminée. La porte de la salle de séjour est déverrouillée.','direction':'Neutral period institutional delivery.','subtitle_default':True},{'id':'mathieu_photo','speaker':'Mathieu','en':'I remember this house.','fr':'Je me souviens de cette maison.','direction':'Optional short restrained reaction, no exposition.','subtitle_default':True}]}
(ROOT/'data'/'act1-voice-lines.json').write_text(json.dumps(voices,ensure_ascii=False,indent=2))

maps=ROOT/'maps';maps.mkdir(exist_ok=True)
rooms=[('G01',70,360,240,180,'Dayroom','Salle de séjour'),('G02',360,320,260,260,'Lobby','Hall'),('G03',670,360,220,180,'Reception','Réception'),('G04',940,360,240,180,'Records','Archives'),('G05',940,80,240,180,'Administrator','Administration'),('G06',370,60,240,180,'Chapel','Chapelle')]
for lang in ['en','fr']:
 parts=['<rect x="5" y="5" width="1270" height="750" rx="8" fill="#DFD9C1" stroke="#7E8974" stroke-width="4"/>']
 title='INSTITUT SAINTE-ODILE · ACT 1' if lang=='en' else 'INSTITUT SAINTE-ODILE · ACTE 1'
 parts.append(f'<text x="65" y="45" font-family="sans-serif" font-size="24" fill="#344B3A">{title}</text>')
 for x,y,x2,y2 in [(310,450,360,450),(620,450,670,450),(890,450,940,450),(1060,260,1060,360),(490,240,490,320)]:parts.append(f'<path d="M{x} {y}L{x2} {y2}" stroke="#344B3A" stroke-width="12"/>')
 for id,x,y,w,h,en,fr in rooms:
  label=en if lang=='en' else fr
  parts.append(f'<g id="{id}"><rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#CBCAB0" stroke="#344B3A" stroke-width="4"/><text x="{x+w/2}" y="{y+65}" text-anchor="middle" font-family="monospace" font-size="26" fill="#344B3A">{id}</text><text x="{x+w/2}" y="{y+110}" text-anchor="middle" font-family="sans-serif" font-size="23" fill="#344B3A">{label}</text></g>')
 note='SCHEMATIC · NOT TO SCALE · Room states and lock icons are runtime overlays.' if lang=='en' else 'SCHÉMA · NON À L’ÉCHELLE · Ajouter les états et les serrures dans le jeu.'
 parts.append(f'<text x="65" y="680" font-family="sans-serif" font-size="22" fill="#344B3A">{note}</text>')
 (maps/('act1-map-'+lang+'.svg')).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="760" viewBox="0 0 1280 760">'+''.join(parts)+'</svg>')

# Offline, zero-network visual index. Original images are referenced, not modified.
chunks=['<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Ward Zero · Asset workshop</title><style>body{margin:0;background:#111916;color:#e8e0cb;font:16px/1.6 system-ui}main{max-width:1450px;margin:auto;padding:36px}h1{font:48px Georgia;margin:0}h2{margin:54px 0 18px;font:30px Georgia;color:#d8ba7b}p{max-width:850px;color:#bfc4b4}a{color:#dfc187}nav{display:flex;gap:20px;flex-wrap:wrap;margin:25px 0}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px}.card{background:#202a24;border:1px solid #394638;padding:14px;border-radius:6px;overflow:hidden}.card img{width:100%;height:220px;object-fit:contain;background:#172019}.card a{display:block;overflow-wrap:anywhere}small{color:#a6b29f}audio{width:100%}code{color:#d6ba85}</style><main><small>INSTITUT SAINTE-ODILE / ACT 1</small><h1>Ward Zero asset workshop</h1><p>Editable components, actual 3D prototypes and separately labeled art references. Extract the entire folder before opening this index. Click an image to open its source. Room concepts are not matched to the GLB cameras.</p><nav><a href="README.md">Read integration notes</a><a href="#art">Artwork</a><a href="#models">3D props</a><a href="#rooms">Room blockouts</a><a href="#puzzles">Puzzles</a><a href="#audio">Audio</a></nav>']
def images(title,id,paths):
 chunks.append(f'<h2 id="{id}">{title}</h2><div class="grid">')
 for f in paths:
  rel=f.relative_to(ROOT).as_posix();name=html.escape(f.stem.replace('-',' ').replace('_',' '))
  chunks.append(f'<div class="card"><a href="{rel}"><img loading="lazy" src="{rel}" alt="{name}">{name}</a></div>')
 chunks.append('</div>')
images('Generated UI and item artwork','art',sorted((ROOT/'art').rglob('*.png')))
images('Environment concepts · reference only','concepts',sorted((ROOT/'references/rooms').glob('*.png')))
images('Character modeling references · not rigs','characters',sorted((ROOT/'references/characters').glob('*.png')))
chunks.append('<h2 id="models">18 actual GLB props · untextured prototypes</h2><div class="grid">')
for f in sorted((ROOT/'models').glob('*.glb')):chunks.append(f'<div class="card"><img loading="lazy" src="previews/{f.stem}.png" alt="{f.stem}"><a href="models/{f.name}">{f.stem.replace("_"," ")} · GLB</a></div>')
chunks.append('</div><h2 id="rooms">Furnished room blockouts · actual geometry</h2><div class="grid">')
for f in sorted((ROOT/'rooms').glob('*.glb')):
 preview=f.stem.replace('_memory','')+'_cutaway.png'
 chunks.append(f'<div class="card"><img loading="lazy" src="previews/{preview}" alt="Room cutaway"><a href="rooms/{f.name}">{f.stem} · GLB</a><small>Cutaway inspection view; memory variant preview shows shared geometry.</small></div>')
chunks.append('</div>')
for folder,title in [('puzzles','Editable puzzle components'),('documents','EN/FR sample documents · example seed'),('signs','Institutional signs'),('maps','Schematic maps'),('icons','UI icon variants'),('controls','UI control states')]:images(title,folder,sorted((ROOT/folder).glob('*.svg')))
chunks.append('<h2 id="audio">Original synthesized effects · prototype mix</h2><div class="grid">')
for f in sorted((ROOT/'audio').glob('*.wav')):chunks.append(f'<div class="card"><a href="audio/{f.name}">{f.stem.replace("_"," ")}</a><audio controls preload="none" src="audio/{f.name}"></audio></div>')
chunks.append('</div></main></html>');(ROOT/'ASSET-INDEX.html').write_text(''.join(chunks))

checks={'svg_files':0,'json_files':0,'glb_files':0,'png_files':0,'wav_files':0,'glb_triangles':0,'notes':['Structural validation and software inspection previews; not tested in Blender or Godot.','Two sample documents rendered and visually reviewed.','Generated artwork visually reviewed; RGBA asset alpha verified.','Audio peaks checked, not subjectively auditioned.']}
for f in ROOT.rglob('*.svg'):ET.parse(f);checks['svg_files']+=1
for f in ROOT.rglob('*.json'):json.loads(f.read_text());checks['json_files']+=1
for f in ROOT.rglob('*.png'):
 im=Image.open(f);im.verify();checks['png_files']+=1
for f in (ROOT/'art').rglob('*.png'):
 im=Image.open(f);assert im.mode=='RGBA' and im.getchannel('A').getextrema()[0]==0,f
for f in ROOT.rglob('*.glb'):
 raw=f.read_bytes();magic,ver,total=struct.unpack_from('<4sII',raw);assert magic==b'glTF' and ver==2 and total==len(raw)
 n,kind=struct.unpack_from('<I4s',raw,12);assert kind==b'JSON';g=json.loads(raw[20:20+n]);blen,bkind=struct.unpack_from('<I4s',raw,20+n);assert bkind==b'BIN\0';binary=raw[28+n:];assert len(binary)==blen
 for a in g['accessors']:
  bv=g['bufferViews'][a['bufferView']];off=bv.get('byteOffset',0);length=a['count']*3*4;assert off+length<=len(binary)
  arr=np.frombuffer(binary[off:off+length],dtype='<f4').reshape(-1,3);assert np.isfinite(arr).all()
 for mesh in g['meshes']:
  for pr in mesh['primitives']:
   count=g['accessors'][pr['attributes']['POSITION']]['count'];assert count%3==0;checks['glb_triangles']+=count//3
 for node in g['nodes']:
  if 'camera' in node:
   m=np.array(node['matrix']).reshape(4,4,order='F');assert abs(np.linalg.det(m[:3,:3])-1)<1e-5
 checks['glb_files']+=1
for f in ROOT.rglob('*.wav'):
 with wave.open(str(f)) as w:assert w.getnchannels()==1 and w.getframerate()==48000;data=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2');assert np.max(np.abs(data.astype(int)))<32767
 checks['wav_files']+=1
seed=json.loads((ROOT/'data/example-seed-1976.json').read_text());b=seed['bindings'];y=b['founding_year'];assert ''.join(str((int(c)+int(b['offset']))%10) for c in y[2:]+y[:2])==seed['solutions']['P04']
for d in json.loads((ROOT/'data/act1-documents.json').read_text()):
 for lang in ['en','fr']:d[lang]['body'].format(**b)
(ROOT/'data'/'validation.json').write_text(json.dumps(checks,indent=2))
manifest=[]
for f in sorted(ROOT.rglob('*')):
 if f.is_file() and '__pycache__' not in f.parts and f.suffix not in ['.import', '.uid', '.pyc'] and f.name!='asset-manifest.json':manifest.append({'path':f.relative_to(ROOT).as_posix(),'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()})
(ROOT/'data'/'asset-manifest.json').write_text(json.dumps(manifest,indent=2));print(json.dumps(checks));print('Manifest:',len(manifest),'files')
