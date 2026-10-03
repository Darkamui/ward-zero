"""Furnished editable room blockouts; no final lighting/texturing or navmesh.
Rooms use local coordinates. Portal linking is logical, not a continuous building.
"""
from pathlib import Path
import math,json
import numpy as np
from build_models import Model,MATS,build,export,render
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'rooms';OUT.mkdir(exist_ok=True)
MATS.update({'plaster':('#BCB9A1',0,.95),'sage':('#728171',0,.88),'floor':('#777568',0,.9),'trim':('#C6C2AA',0,.7),'memory_plaster':('#DDD6BC',0,.85),'memory_sage':('#92A489',0,.8)})
models={m.name:m for m in build()}
def place(room,prop,pos,yaw=0,scale=1,pitch=0):
 a=math.radians(yaw);rot=np.array([[math.cos(a),0,math.sin(a)],[0,1,0],[-math.sin(a),0,math.cos(a)]])
 b=math.radians(pitch);rot=rot@np.array([[1,0,0],[0,math.cos(b),-math.sin(b)],[0,math.sin(b),math.cos(b)]])
 for name,p,f,mat in models[prop].parts:room.parts.append((prop+'_'+str(len(room.parts))+'_'+name,p@rot.T*scale+np.array(pos),f,mat))
def shell(id,w,d,doors):
 room=Model(id);h=3.3;room.b('floor',(w,.12,d),(0,-.06,0),'floor',.003)
 # Local sides: south=+Z, north=-Z, west=-X, east=+X.
 for side in ['north','south','east','west']:
  length=w if side in ['north','south'] else d
  intervals=[(-length/2,length/2)]
  if side in doors:intervals=[(-length/2,-.56),(.56,length/2)]
  def slab(lo,hi,y,height,mat,name):
   if side in ['north','south']:
    room.b(side+'_'+name,(hi-lo,height,.19 if mat=='trim' else .16),((lo+hi)/2,y,-d/2 if side=='north' else d/2),mat,.003)
   else:room.b(side+'_'+name,(.19 if mat=='trim' else .16,height,hi-lo),(-w/2 if side=='west' else w/2,y,(lo+hi)/2),mat,.003)
  for lo,hi in intervals:
   slab(lo,hi,.6,1.2,'sage','lower');slab(lo,hi,2.25,2.1,'plaster','upper');slab(lo,hi,.065,.13,'trim','skirting');slab(lo,hi,1.2,.035,'trim','dado')
  if side in doors:
   slab(-.56,.56,2.80,1.,'plaster','lintel');slab(-.64,-.56,1.14,2.28,'trim','jamb');slab(.56,.64,1.14,2.28,'trim','jamb');slab(-.64,.64,2.29,.10,'trim','head')
 # Windows are surface placeholders. Replace wall sections with real openings in Blender.
 for x in [-w*.23,w*.23]:
  room.b('window_frame',(1.22,1.65,.055),(x,2.02,-d/2+.11),'trim');room.b('window_glazing',(1.10,1.53,.025),(x,2.02,-d/2+.15),'glass');room.b('window_mullion',(.035,1.53,.032),(x,2.02,-d/2+.17),'trim');room.b('window_crossbar',(1.1,.035,.032),(x,2.02,-d/2+.17),'trim')
 return room

specs=[('G01_dayroom',6,5,['east'],2),('G02_lobby',8,7,['west','east','north','south'],3),('G03_reception',4.5,4,['west','east'],1),('G04_records',5,4.5,['west','east'],2),('G05_administrator',5,5,['west'],2),('G06_chapel',6,9,['south'],2)]
room_data=[]
for id,w,d,doors,count in specs:
 r=shell(id,w,d,doors)
 if id.startswith('G01'):
  place(r,'office_desk',(1.85,0,-1.6));place(r,'dictaphone',(1.6,.805,-1.5),-10,pitch=-90);place(r,'side_table',(-1.9,0,-1.7));place(r,'table_radio',(-1.9,.625,-1.7));place(r,'wooden_chair',(-1,0,.1),25);place(r,'wooden_chair',(1,0,.3),-30);place(r,'side_table',(0,0,-.4),0,.8);place(r,'effects_bin',(1.9,0,1.45));place(r,'radiator',(0,0,-2.25))
 elif id.startswith('G02'):
  place(r,'chapel_pew',(-2.7,0,-2.5),90);place(r,'chapel_pew',(2.7,0,-2.5),-90);place(r,'side_table',(-2.7,0,2.3));place(r,'radiator',(-1.8,0,-3.2));place(r,'radiator',(1.8,0,-3.2));r.b('founding_plaque',(1.2,.5,.04),(0,1.7,3.38),'brass')
 elif id.startswith('G03'):
  place(r,'office_desk',(0,0,-.9));place(r,'switchboard',(0,.785,-.95),0,.8);place(r,'wooden_chair',(0,0,-1.6),180);place(r,'clipboard',(.45,.80,-.65),0,.7,pitch=-90)
 elif id.startswith('G04'):
  for x in [-1.5,0,1.5]:place(r,'card_catalog',(x,0,-1.85))
  place(r,'office_desk',(0,0,1.5),180);place(r,'wooden_chair',(.8,0,.6),-20)
 elif id.startswith('G05'):
  place(r,'office_desk',(0,0,-.7));place(r,'wooden_chair',(0,0,-1.5),180);place(r,'wall_safe',(2.12,.85,0),-90);place(r,'side_table',(-1.8,0,-1.7));place(r,'clipboard',(.4,.80,-.65),0,.8,pitch=-90);place(r,'radiator',(0,0,-2.25))
 else:
  for z in [-1.8,-.5,.8,2.1]:
   for x in [-1.5,1.5]:place(r,'chapel_pew',(x,0,z),180,.8)
  r.b('altar',(2.2,.95,.65),(0,.475,-3.55),'wood');r.b('altar_top',(2.35,.07,.78),(0,.985,-3.55),'ivory');place(r,'hymn_board',(2.90,1.20,-2.2),-90);r.b('cross_vertical',(.09,1.2,.05),(0,2.15,-4.37),'wood');r.b('cross_horizontal',(.65,.09,.05),(0,2.4,-4.37),'wood')
 r.cameras=[{'id':id+'_cam_'+str(i+1),'position':v,'target':[0,1,-.35]} for i,v in enumerate([[w/2-.4,2.7,d/2-.4],[-w/2+.4,2.6,-d/2+.4],[0,2.8,d/2-.4]][:count])]
 cutaway=Model(id+'_cutaway');cutaway.parts=[part for part in r.parts if not part[0].startswith(('south_','east_'))];render(cutaway,ROOT/'previews'/(id+'_cutaway.png'),900)
 info=export(r);(ROOT/'models'/(id+'.glb')).replace(OUT/(id+'.glb'))
 room_data.append({'id':id,'size_m':[w,3.3,d],'doors':doors,'cameras':r.cameras,'status':'furnished blockout; no collision/navmesh/hotspots','triangles':info['triangles']})
 if id.startswith('G06'):
  r.name='G06_chapel_memory';r.parts=[(n,p,f,{'plaster':'memory_plaster','sage':'memory_sage'}.get(m,m)) for n,p,f,m in r.parts];export(r);(ROOT/'models'/(r.name+'.glb')).replace(OUT/(r.name+'.glb'))
(ROOT/'data'/'room-layouts.json').write_text(json.dumps({'rooms':room_data,'links':[['G01_dayroom','east','G02_lobby','west'],['G02_lobby','east','G03_reception','west'],['G03_reception','east','G04_records','west'],['G04_records','east','G05_administrator','west'],['G02_lobby','north','G06_chapel','south']],'future_exit':['G02_lobby','south'],'chase_path':['G02_lobby','G01_dayroom'],'notes':['Graph proposal for this blockout; not final GDD architecture.','Chapel memory uses exactly the same geometry/cameras with changed wall materials.','Generated concept images are not matched to these cameras.']},indent=2))
print('Created six room GLBs plus Chapel memory variant, with 12+2 cameras.')
