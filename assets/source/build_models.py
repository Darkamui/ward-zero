"""Original Ward Zero prop kit. Requires Python, numpy, scipy, Pillow.
Exports glTF 2.0 binary meshes with named independent parts and metre/Y-up units.
Run from anywhere; output is relative to this file's parent directory.
"""
from pathlib import Path
import json, struct, math
import numpy as np
from scipy.spatial import ConvexHull
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent.parent
MATS={
 'wood':('#594336',0,.75), 'wood_edge':('#312B25',0,.7),
 'steel':('#68726D',.6,.52), 'brass':('#A88949',.75,.4),
 'dark':('#242A29',.15,.56), 'ivory':('#D8CFB8',0,.85),
 'fabric':('#657064',0,.95), 'red':('#8F453A',.05,.7),
 'glass':('#536963',.2,.2), 'yellow':('#C6A64D',.1,.6)}

def box(size,bevel=.004):
 h=np.array(size)/2; r=min(bevel,float(min(h))*.45)
 pts=[]
 for ax in range(3):
  other=[a for a in range(3) if a!=ax]
  for sign in [-1,1]:
   for a in [-h[other[0]],-h[other[0]]+r,h[other[0]]-r,h[other[0]]]:
    for b in [-h[other[1]],-h[other[1]]+r,h[other[1]]-r,h[other[1]]]:
     p=np.zeros(3);p[ax]=sign*h[ax];p[other]=[a,b]
     q=np.clip(p,-h+r,h-r);n=p-q;p=q+n/np.linalg.norm(n)*r
     pts.append(p)
 pts=np.unique(np.round(pts,8),axis=0); hull=ConvexHull(pts)
 return pts,hull.simplices

def cyl(radius,length,segments=24,axis='y'):
 p=[]
 for h in [-length/2,length/2]:
  for i in range(segments):
   a=2*math.pi*i/segments;p.append([radius*math.cos(a),h,radius*math.sin(a)])
 p.extend([[0,-length/2,0],[0,length/2,0]])
 f=[]
 for i in range(segments):
  j=(i+1)%segments;f.extend([[i,j,j+segments],[i,j+segments,i+segments],[2*segments,j,i],[2*segments+1,i+segments,j+segments]])
 p=np.array(p)
 if axis=='z':p=p[:,[0,2,1]]
 if axis=='x':p=p[:,[1,0,2]]
 return p,np.array(f)

def torus(radius,tube,axis='z',n=40,m=10):
 p=[];f=[]
 for i in range(n):
  a=i*2*math.pi/n
  for j in range(m):
   b=j*2*math.pi/m;p.append([(radius+tube*math.cos(b))*math.cos(a),(radius+tube*math.cos(b))*math.sin(a),tube*math.sin(b)])
 for i in range(n):
  for j in range(m):
   a=i*m+j;b=((i+1)%n)*m+j;c=((i+1)%n)*m+(j+1)%m;d=i*m+(j+1)%m
   f.extend([[a,b,c],[a,c,d]])
 p=np.array(p)
 if axis=='y':p=p[:,[0,2,1]]
 return p,np.array(f)

class Model:
 def __init__(self,name):self.name=name;self.parts=[]
 def add(self,name,geom,pos,mat):
  p,f=geom;p=p+np.array(pos);self.parts.append((name,p,f,mat));return self
 def b(self,name,size,pos,mat='wood',bevel=.004):return self.add(name,box(size,bevel),pos,mat)
 def c(self,name,r,l,pos,mat='steel',axis='y'):return self.add(name,cyl(r,l,axis=axis),pos,mat)
 def t(self,name,r,t,pos,mat='brass',axis='z'):return self.add(name,torus(r,t,axis),pos,mat)

def normals_and_faces(p,f):
 # Hulls may have inconsistent winding; use centre test for convex shapes.
 # Torus has consistent topology but is concave: preserve its winding.
 f=f.copy();norm=np.cross(p[f[:,1]]-p[f[:,0]],p[f[:,2]]-p[f[:,0]])
 if len(p)<300:
  flip=np.einsum('ij,ij->i',norm,p[f].mean(axis=1)-p.mean(axis=0))<0
  f[flip]=f[flip][:,[0,2,1]]
 pp=p[f].reshape(-1,3);nn=np.cross(p[f[:,1]]-p[f[:,0]],p[f[:,2]]-p[f[:,0]])
 nn/=np.maximum(np.linalg.norm(nn,axis=1,keepdims=True),1e-10)
 return pp.astype('<f4'),np.repeat(nn,3,axis=0).astype('<f4')

def export(model):
 binary=bytearray();views=[];access=[];meshes=[];nodes=[]
 def acc(arr,typ):
  while len(binary)%4:binary.append(0)
  off=len(binary);binary.extend(arr.tobytes());views.append({'buffer':0,'byteOffset':off,'byteLength':arr.nbytes,'target':34962})
  a={'bufferView':len(views)-1,'componentType':5126,'count':len(arr),'type':typ,'min':arr.min(axis=0).tolist(),'max':arr.max(axis=0).tolist()};access.append(a);return len(access)-1
 for name,p,f,mat in model.parts:
  v,n=normals_and_faces(p,f);a=acc(v,'VEC3');b=acc(n,'VEC3')
  meshes.append({'name':name,'primitives':[{'attributes':{'POSITION':a,'NORMAL':b},'material':list(MATS).index(mat)}]})
  nodes.append({'name':name,'mesh':len(meshes)-1})
 materials=[]
 for name,(color,metal,rough) in MATS.items():
  rgb=[int(color[i:i+2],16)/255 for i in [1,3,5]]
  materials.append({'name':name,'pbrMetallicRoughness':{'baseColorFactor':rgb+[1],'metallicFactor':metal,'roughnessFactor':rough}})
 doc={'asset':{'version':'2.0','generator':'Ward Zero original procedural prop kit'},'scene':0,'scenes':[{'name':model.name,'nodes':list(range(len(nodes)))}],'nodes':nodes,'meshes':meshes,'materials':materials,'buffers':[{'byteLength':len(binary)}],'bufferViews':views,'accessors':access,'extras':{'units':'metres','up_axis':'Y','status':'untextured procedural prop; not matched to generated item artwork'}}
 if hasattr(model,'cameras'):
  doc['cameras']=[]
  for camera in model.cameras:
   eye=np.array(camera['position']);target=np.array(camera['target']);direction=target-eye;direction/=np.linalg.norm(direction)
   right=np.cross(direction,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,direction)
   matrix=np.eye(4);matrix[:3,0]=right;matrix[:3,1]=up;matrix[:3,2]=-direction;matrix[:3,3]=eye
   doc['cameras'].append({'name':camera['id'],'type':'perspective','perspective':{'yfov':math.radians(56),'aspectRatio':16/9,'znear':.05,'zfar':100}})
   doc['nodes'].append({'name':camera['id'],'camera':len(doc['cameras'])-1,'matrix':matrix.flatten(order='F').tolist()});doc['scenes'][0]['nodes'].append(len(doc['nodes'])-1)
 js=json.dumps(doc,separators=(',',':')).encode();js+=b' '*((-len(js))%4);binary+=b'\0'*((-len(binary))%4)
 data=struct.pack('<4sII',b'glTF',2,12+8+len(js)+8+len(binary))+struct.pack('<I4s',len(js),b'JSON')+js+struct.pack('<I4s',len(binary),b'BIN\0')+binary
 (ROOT/'models'/f'{model.name}.glb').write_bytes(data)
 return {'id':model.name,'parts':len(nodes),'triangles':sum(len(f) for _,_,f,_ in model.parts),'bounds_m':[np.concatenate([p for _,p,_,_ in model.parts]).min(axis=0).tolist(),np.concatenate([p for _,p,_,_ in model.parts]).max(axis=0).tolist()]}

def render(model,path,size=500):
 # Orthographic inspection image only; no promise of engine/PBR equivalence.
 az=.55;el=.38
 right=np.array([math.cos(az),0,-math.sin(az)]);up=np.array([-math.sin(az)*math.sin(el),math.cos(el),-math.cos(az)*math.sin(el)]);forward=np.cross(right,up)
 allp=np.concatenate([p for _,p,_,_ in model.parts]);xy=np.stack([allp@right,allp@up],axis=1);lo=xy.min(0);hi=xy.max(0);scale=(size-80)/max(hi-lo);mid=(hi+lo)/2
 pixels=np.zeros((size,size,3),dtype=np.uint8);pixels[:]=[24,31,29];zbuf=np.full((size,size),-np.inf);tris=[]
 light=np.array([-.5,.8,.6]);light/=np.linalg.norm(light)
 for name,p,f,mat in model.parts:
  pp,nn=normals_and_faces(p,f)
  for pts,n in zip(pp.reshape(-1,3,3),nn[::3]):
   if n@forward<=0:continue
   proj=np.stack([pts@right,pts@up],axis=1);proj=(proj-mid)*scale;proj[:,0]+=size/2;proj[:,1]=size/2-proj[:,1]
   rgb=np.array([int(MATS[mat][0][i:i+2],16) for i in [1,3,5]])
   color=tuple(np.clip(rgb*(.45+.55*max(0,n@light)),0,255).astype(int))
   tris.append((pts@forward,proj,color))
 for zz,q,c in tris:
  xmin=max(0,int(np.floor(q[:,0].min())));xmax=min(size-1,int(np.ceil(q[:,0].max())))
  ymin=max(0,int(np.floor(q[:,1].min())));ymax=min(size-1,int(np.ceil(q[:,1].max())))
  if xmax<xmin or ymax<ymin:continue
  xx,yy=np.meshgrid(np.arange(xmin,xmax+1)+.5,np.arange(ymin,ymax+1)+.5)
  a,b,cc=q;den=(b[1]-cc[1])*(a[0]-cc[0])+(cc[0]-b[0])*(a[1]-cc[1])
  if abs(den)<1e-9:continue
  w0=((b[1]-cc[1])*(xx-cc[0])+(cc[0]-b[0])*(yy-cc[1]))/den
  w1=((cc[1]-a[1])*(xx-cc[0])+(a[0]-cc[0])*(yy-cc[1]))/den;w2=1-w0-w1
  depth=w0*zz[0]+w1*zz[1]+w2*zz[2];sub=zbuf[ymin:ymax+1,xmin:xmax+1]
  mask=(w0>=-1e-7)&(w1>=-1e-7)&(w2>=-1e-7)&(depth>sub)
  sub[mask]=depth[mask];pixels[ymin:ymax+1,xmin:xmax+1][mask]=c
 img=Image.fromarray(pixels);d=ImageDraw.Draw(img)
 d.text((18,size-25),model.name.replace('_',' '),fill='#E8E0CB');img.save(path)

def build():
 out=[]
 m=Model('choleric_key');m.t('bow',.018,.004,(0,.10,0));m.c('shaft',.004,.078,(0,.047,0),'brass');m.b('bit_1',(.016,.008,.008),(.007,.009,0),'brass',.001);m.b('bit_2',(.012,.006,.008),(.005,.022,0),'brass',.001);m.b('yellow_tag',(.016,.019,.003),(0,.10,.006),'yellow',.002);out.append(m)
 m=Model('music_box_crank');m.c('shaft',.003,.032,(0,.016,0),'brass');m.b('arm',(.027,.005,.005),(.012,.034,0),'brass',.001);m.c('handle_spindle',.002,.018,(.025,.044,0),'brass');m.c('wooden_grip',.005,.014,(.025,.047,0),'wood');out.append(m)
 m=Model('blank_cassette');m.b('shell',(.1016,.0635,.0127),(0,.032,0),'dark',.003);m.b('label',(.089,.032,.001),(0,.042,.007),'ivory',.001)
 for x in [-.023,.023]:m.c('hub',.009,.002,(x,.032,.008),'ivory','z');m.c('spindle_hole',.004,.002,(x,.032,.0095),'dark','z')
 m.b('tape_window',(.018,.013,.002),(0,.032,.008),'glass',.001)
 for x in [-.044,.044]:
  for y in [.007,.056]:m.c('screw',.0014,.001,(x,y,.007),'steel','z')
 out.append(m)
 m=Model('dictaphone');m.b('body',(.082,.16,.03),(0,.08,0),'dark',.005);m.b('speaker_panel',(.065,.05,.002),(0,.128,.016),'steel',.002)
 for y in np.linspace(.108,.148,10):m.b('grille_slot',(.058,.001,.001),(0,y,.0175),'dark',.0002)
 m.b('cassette_window',(.06,.045,.002),(0,.07,.016),'glass',.002)
 for x in [-.015,.015]:m.c('reel',.009,.002,(x,.07,.018),'ivory','z');m.c('reel_centre',.004,.003,(x,.07,.019),'dark','z')
 for i in range(5):m.b('transport_'+str(i),(.012,.02,.004),(-.028+i*.014,.024,.018),'red' if i==0 else 'steel',.001)
 out.append(m)
 m=Model('table_radio');m.b('cabinet',(.46,.27,.17),(0,.145,0),'wood',.012);m.b('front_panel',(.426,.22,.006),(0,.145,.089),'steel',.003);m.b('speaker_inset',(.19,.192,.003),(-.107,.145,.094),'dark',.003)
 for x in np.linspace(-.19,-.025,17):m.b('speaker_slats',(.003,.18,.002),(x,.145,.097),'brass',.0005)
 m.b('frequency_display',(.18,.06,.004),(.103,.207,.095),'ivory',.002);m.b('tuning_needle',(.001,.05,.001),(.1,.207,.099),'red',.0001)
 for x in [.06,.155]:m.c('knob',.023,.017,(x,.092,.105),'dark','z');m.b('knob_mark',(.002,.012,.001),(x,.103,.115),'ivory',.0002)
 for x in [-.16,.16]:m.b('foot',(.04,.015,.12),(x,.0075,0),'dark')
 out.append(m)
 m=Model('wooden_chair');m.b('seat',(.43,.055,.43),(0,.455,0),'wood')
 for x in [-.175,.175]:
  for z in [-.17,.17]:m.b('leg',(.04,.43,.04),(x,.215,z),'wood_edge')
  m.b('back_post',(.04,.43,.04),(x,.68,-.175),'wood_edge')
 for y in [.64,.77,.85]:m.b('back_slat',(.39,.065,.025),(0,y,-.175),'wood')
 out.append(m)
 m=Model('side_table');m.b('top',(.65,.045,.50),(0,.60,0),'wood')
 for x in [-.27,.27]:
  for z in [-.195,.195]:m.b('leg',(.045,.58,.045),(x,.29,z),'wood_edge')
 m.b('shelf',(.57,.03,.42),(0,.18,0),'wood');out.append(m)
 m=Model('office_desk');m.b('desktop',(1.4,.055,.70),(0,.755,0),'wood');m.b('modesty_panel',(1.28,.40,.035),(0,.49,-.30),'wood_edge')
 for x in [-.46,.46]:
  m.b('pedestal',(.38,.69,.57),(x,.345,0),'wood_edge')
  for j in range(3):
   y=.17+j*.20;m.b('drawer',(.345,.175,.025),(x,y,.296),'wood');m.b('handle',(.11,.018,.025),(x,y,.32),'brass')
 out.append(m)
 m=Model('card_catalog');m.b('carcass',(1.14,1.32,.47),(0,.66,0),'wood_edge')
 for col in range(4):
  for row in range(6):
   x=-.42+col*.28;y=.16+row*.205;m.b(f'drawer_{row}_{col}',(.262,.183,.026),(x,y,.244),'wood');m.b(f'label_{row}_{col}',(.13,.045,.002),(x,y+.035,.26),'ivory',.001);m.b(f'pull_{row}_{col}',(.095,.014,.03),(x,y-.025,.276),'brass',.002)
 out.append(m)
 m=Model('wall_safe');m.b('back',(.60,.62,.025),(0,.31,-.22),'steel');m.b('top',(.60,.025,.44),(0,.6075,0),'steel');m.b('bottom',(.60,.025,.44),(0,.0125,0),'steel')
 for x in [-.2875,.2875]:m.b('side',(.025,.62,.44),(x,.31,0),'steel')
 m.b('door',(.55,.57,.04),(0,.31,.24),'dark');m.c('dial',.06,.035,(-.06,.38,.278),'brass','z');m.c('dial_centre',.043,.015,(-.06,.38,.302),'dark','z');m.b('dial_indicator',(.006,.02,.002),(-.06,.405,.311),'ivory',.001);m.b('handle',(.025,.19,.04),(.15,.32,.28),'steel');out.append(m)
 m=Model('switchboard');m.b('housing',(.72,.52,.12),(0,.28,0),'wood');m.b('panel',(.67,.43,.008),(0,.28,.066),'dark');m.b('header',(.60,.045,.002),(0,.468,.072),'ivory',.001)
 for row in range(3):
  for col in range(6):
   x=-.26+col*.104;y=.18+row*.095;m.t(f'socket_{row}_{col}',.014,.003,(x,y,.076),'brass');m.c('socket_hole',.009,.001,(x,y,.073),'dark','z')
 out.append(m)
 m=Model('chapel_pew');m.b('seat',(1.85,.055,.40),(0,.46,0),'wood');m.b('back',(1.85,.40,.035),(0,.69,-.18),'wood')
 for x in [-.85,.85]:m.b('end',(.065,.77,.45),(x,.385,0),'wood_edge');m.b('arm',(.09,.04,.48),(x,.78,0),'wood')
 out.append(m)
 m=Model('hymn_board');m.b('board',(.62,.94,.055),(0,.47,0),'wood');m.b('face',(.54,.78,.01),(0,.43,.032),'dark')
 for y in [.08,.29,.50,.71]:m.b('rail',(.55,.018,.022),(0,y,.045),'wood_edge')
 m.b('header',(.50,.10,.005),(0,.845,.033),'ivory');m.b('cross_vertical',(.035,.17,.025),(0,1.015,0),'wood');m.b('cross_horizontal',(.12,.035,.025),(0,1.035,0),'wood');out.append(m)
 m=Model('effects_bin');m.b('base',(.85,.045,.47),(0,.03,0),'steel');m.b('front',(.85,.43,.025),(0,.26,.235),'steel');m.b('back',(.85,.43,.025),(0,.26,-.235),'steel')
 for x in [-.4125,.4125]:m.b('side',(.025,.43,.47),(x,.26,0),'steel')
 m.b('lid',(.87,.045,.49),(0,.495,0),'dark');m.b('latch',(.065,.1,.023),(0,.445,.261),'brass');m.b('label',(.28,.10,.002),(0,.29,.25),'ivory');out.append(m)
 m=Model('radiator')
 for i in range(12):m.b('fin',(.055,.58,.16),(-.36+i*.066,.37,0),'ivory',.018)
 for y in [.14,.62]:m.c('manifold',.025,.82,(0,y,0),'steel','x')
 for x in [-.30,.30]:m.b('foot',(.07,.09,.24),(x,.045,0),'steel')
 m.c('valve',.035,.03,(.45,.62,0),'brass','x');out.append(m)
 m=Model('institutional_door');m.b('door_leaf',(.90,2.05,.045),(0,1.025,0),'wood');m.b('upper_panel',(.62,.82,.012),(0,1.48,.028),'wood_edge');m.b('lower_panel',(.62,.72,.012),(0,.53,.028),'wood_edge');m.b('handle_plate',(.045,.17,.008),(.34,1.0,.03),'brass');m.c('handle_spindle',.012,.055,(.34,1.0,.057),'brass','z');m.b('lever',(.11,.018,.02),(.295,1.0,.085),'brass');out.append(m)
 m=Model('clipboard');m.b('board',(.235,.325,.005),(0,.165,0),'wood');m.b('paper',(.205,.28,.001),(0,.157,.004),'ivory',.001);m.b('clip',(.07,.036,.007),(0,.30,.01),'steel');out.append(m)
 m=Model('patient_wristband');m.b('strap',(.21,.018,.001),(0,.009,0),'ivory',.0004);m.b('nameplate',(.066,.024,.0015),(0,.009,.001),'ivory',.0005);m.c('snap',.004,.002,(-.094,.009,.002),'steel','z');out.append(m)
 for m in out:export(m);render(m,ROOT/'previews'/f'{m.name}.png')
 (ROOT/'data'/'models.json').write_text(json.dumps([export(m) for m in out],indent=2))
 sheet=Image.new('RGB',(1500,math.ceil(len(out)/3)*500),(24,31,29))
 for i,m in enumerate(out):sheet.paste(Image.open(ROOT/'previews'/f'{m.name}.png'),((i%3)*500,(i//3)*500))
 sheet.save(ROOT/'previews'/'model-contact-sheet.jpg',quality=90)
 print(f'Exported {len(out)} GLB props and inspection previews.')
 return out

if __name__=='__main__':build()
