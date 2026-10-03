"""Build editable vector puzzle components, localized documents and example seed data.
No third-party assets or fonts embedded. Python standard library only.
"""
from pathlib import Path
import json, random, html, math, re
ROOT=Path(__file__).resolve().parent.parent
P=ROOT/'puzzles';D=ROOT/'documents';P.mkdir(exist_ok=True);D.mkdir(exist_ok=True)
def svg(name,w,h,body,folder=P):
 (folder/(name+'.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>')
def text(x,y,s,size=24,fill='#292D2B',anchor='start'):
 return f'<text x="{x}" y="{y}" font-family="monospace" font-size="{size}" fill="{fill}" text-anchor="{anchor}">{html.escape(str(s))}</text>'
def rect(x,y,w,h,fill,stroke='none',r=0):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{stroke}" stroke-width="2"/>'
def circle(x,y,r,fill,stroke='none',sw=2):return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
def line(x,y,x2,y2,c,sw=2):return f'<path d="M{x} {y}L{x2} {y2}" stroke="{c}" stroke-width="{sw}" fill="none"/>'

# Individual controls; all gameplay labels remain external text nodes.
svg('radio-knob',128,128,circle(64,64,59,'#423C31','#A48A54',3)+circle(64,64,49,'#242A29','#706955',2)+line(64,20,64,40,'#E8E0CB',5))
svg('radio-needle',12,150,rect(4,0,4,150,'#9F493E'))
ticks=''.join(line(16+i*10,20,16+i*10,48 if i%5==0 else 35,'#403F35',1) for i in range(61))
svg('radio-scale-blank',632,76,ticks)
svg('switch-socket',80,80,circle(40,40,33,'#A48A54','#342C22',3)+circle(40,40,23,'#2B2A25','#D0B875',2)+circle(40,40,15,'#111713'))
for name,col,symbol in [('amber','#BF9B4F','circle'),('blue','#66828A','square'),('red','#945E53','triangle'),('ivory','#C8C2AA','diamond')]:
 mark={'circle':circle(40,30,6,'#17211C'),'square':rect(34,24,12,12,'#17211C'),'triangle':'<path d="M40 23 48 37H32Z" fill="#17211C"/>','diamond':'<path d="M40 22 48 30 40 38 32 30Z" fill="#17211C"/>'}[symbol]
 svg('patch-plug-'+name,80,120,rect(29,70,22,45,'#A48A54',r=3)+rect(22,15,36,66,col,'#242A29',8)+mark)
 svg('patch-cable-sample-'+name,400,200,'<path d="M20 20C20 180 380 180 380 20" fill="none" stroke="#18211D" stroke-width="15"/>'+f'<path d="M20 20C20 180 380 180 380 20" fill="none" stroke="{col}" stroke-width="10"/>')
for state,col in [('off','#383B2F'),('on','#B0A571')]:svg('indicator-'+state,40,40,circle(20,20,17,'#7E765C')+circle(20,20,12,col))
svg('safe-dial',240,240,circle(120,120,111,'#7E765C','#B2A27D',4)+circle(120,120,86,'#252D29','#D0C8B4',2)+''.join(line(120+math.sin(i*math.pi/20)*92,120-math.cos(i*math.pi/20)*92,120+math.sin(i*math.pi/20)*(105 if i%5==0 else 99),120-math.cos(i*math.pi/20)*(105 if i%5==0 else 99),'#D0C8B4',2) for i in range(40))+line(120,46,120,74,'#E8E0CB',4))
svg('safe-handle',80,250,rect(25,5,30,240,'#424E47','#A2A68E',10)+rect(35,28,10,194,'#707E70',r=5))
svg('safe-door',760,760,rect(5,5,750,750,'#4B564E','#939E89',14)+rect(28,28,704,704,'#313D36','#17221B',8)+rect(58,74,210,42,'#B9B29B',r=2))
svg('safe-interior',760,760,rect(5,5,750,750,'#49544D','#939E89',14)+rect(50,50,660,660,'#15211A')+rect(70,430,620,16,'#617064')+rect(70,680,620,18,'#617064'))
svg('catalog-drawer-closed',360,170,rect(3,3,354,164,'#5E4736','#312C23',4)+rect(75,25,210,50,'#A58C55',r=3)+rect(84,31,192,37,'#D9D0B8')+rect(116,105,128,18,'#927F55','#BBA678',4))
svg('catalog-drawer-open',360,260,rect(3,3,354,254,'#3E342A','#1B211B',4)+rect(25,22,310,143,'#23271F')+''.join(rect(39,40+i*14,282,55,'#C9BE9E','#827759',2) for i in range(7))+rect(10,184,340,69,'#5E4736','#897452',3)+rect(120,207,120,16,'#A99162',r=3))
svg('catalog-card-blank',600,380,rect(2,2,596,376,'#E1D7BA','#A89C7F',4)+line(35,80,565,80,'#A89C7F',1)+''.join(line(35,y,565,y,'#BEB398',1) for y in range(135,345,50)))
for i in range(10):svg('hymn-digit-'+str(i),120,180,rect(3,3,114,174,'#DAD3BD','#817D67',3)+text(60,130,i,112,'#262F28','middle'))
svg('hymn-tile-blank',120,180,rect(3,3,114,174,'#DAD3BD','#817D67',3))
svg('hymn-tile-missing',120,180,rect(3,3,114,174,'#222B25','#776D50',3)+line(20,25,100,155,'#403F32',1))
svg('choleric-fire-symbol',128,128,'<path d="M67 9C80 46 112 53 108 86C102 122 27 126 22 86C20 59 45 44 45 25C61 35 58 51 56 62C77 48 78 32 67 9Z" fill="#C6A64D" stroke="#282E27" stroke-width="4"/>')
svg('founding-plaque-blank',900,340,rect(5,5,890,330,'#7D765B','#BAB08B',12)+rect(32,32,836,276,'none','#3A3C30',8)+''.join(circle(x,y,6,'#343B30') for x in [25,875] for y in [25,315]))
svg('wristband-blank',900,160,rect(5,40,890,80,'#DDD7C6','#7C8273',15)+rect(260,15,380,130,'#EEE9DA','#9FA491',12)+circle(45,80,20,'#ABB3A4','#657062')+''.join(circle(x,80,5,'#8A917F') for x in range(700,861,32)))
svg('photo-reverse-blank',900,620,rect(5,5,890,610,'#D1C8AE','#9E9478',8)+line(40,560,860,560,'#ADA289',1))

r=random.Random(1976)
freq=round(r.randrange(881,1078,2)/10,1);year=r.randint(1901,1935);offset=r.randint(1,3)
digits=str(year)[2:]+str(year)[:2];safe=''.join(str((int(c)+offset)%10) for c in digits)
ext=r.sample(range(201,241),4);hymns=r.sample(range(101,399),3)
bindings={'frequency':f'{freq:.1f}','birthdate':'1967-03-12','founding_year':str(year),'offset':str(offset),'ext_admin':str(ext[0]),'ext_nurse':str(ext[1]),'ext_chapel':str(ext[2]),'ext_records':str(ext[3]),'hymn_1':str(hymns[0]),'hymn_2':str(hymns[1]),'hymn_3':str(hymns[2]),'file_id':'ML-1967-0312','fire_time':'21:40'}
docs=[]
def doc(id,room,en_title,fr_title,en,fr,fragment=None):
 docs.append({'id':id,'room':room,'fragment':fragment,'en':{'title':en_title,'body':en},'fr':{'title':fr_title,'body':fr}})
doc('quiet_hours','G01','Quiet Hours','Heures de silence','DAYROOM\nQuiet hours begin after evening rounds.\nFor the evening announcement, tune the receiver to {frequency} MHz.\nLeave the radio switched on.','SALLE DE SÉJOUR\nLe silence est demandé après la tournée du soir.\nPour le message du soir, réglez le récepteur sur {frequency} MHz.\nLaissez la radio allumée.')
doc('wristband','G01','Patient wristband','Bracelet du patient','LAVOIE, Mathieu\nDate of birth: {birthdate}\nDo not remove.','LAVOIE, Mathieu\nDate de naissance : {birthdate}\nNe pas retirer.')
doc('directory','G03','Internal directory','Annuaire interne','Administrator — {ext_admin}\nNurse station — {ext_nurse}\nChapel — {ext_chapel}\nRecords — {ext_records}','Administration — {ext_admin}\nPoste infirmier — {ext_nurse}\nChapelle — {ext_chapel}\nArchives — {ext_records}')
doc('switchboard_memo','G03','Reception instructions','Consignes de réception','Connect each department lead to its listed extension.\nThe administrator will release the internal gate once the board is correctly patched.\nPress CALL after completing the connections.','Branchez le cordon de chaque service au poste indiqué dans l’annuaire.\nL’administration déverrouillera la grille intérieure lorsque les branchements seront corrects.\nAppuyez sur APPELER une fois les branchements terminés.')
doc('catalog_instructions','G04','Catalog procedure','Classement des dossiers','Patient cards are filed by birth year, then month.\nDuring the move, the LAVOIE card was put with admissions for 1976. Retrieve it there, then match the full birthdate to the wristband.','Les fiches des patients sont classées par année, puis par mois de naissance.\nLors du déménagement, la fiche LAVOIE a été rangée avec les admissions de 1976. Cherchez-la à cet endroit, puis comparez la date de naissance complète avec le bracelet.')
doc('admission_file','G04','Admission record — M. Lavoie','Fiche d’admission — M. Lavoie','INSTITUT SAINTE-ODILE\nRecord: {file_id}\nPatient: Mathieu Lavoie\nBorn: {birthdate}\nAdmitted: 18 October 1976\nAge at admission: 9\nReason: observation following a serious domestic incident.\nPersonal effects: one family photograph.\nThe child repeatedly asks to see Claire.','INSTITUT SAINTE-ODILE\nDossier : {file_id}\nPatient : Mathieu Lavoie\nNaissance : {birthdate}\nAdmission : 18 octobre 1976\nÂge à l’admission : 9 ans\nMotif : observation à la suite d’un grave incident familial.\nEffets personnels : une photographie de famille.\nL’enfant demande à voir Claire à plusieurs reprises.','F01')
doc('founding_plaque','G02','Founding plaque','Plaque de fondation','INSTITUT SAINTE-ODILE\nFounded {founding_year}\nCare. Order. Rest.','INSTITUT SAINTE-ODILE\nFondé en {founding_year}\nSoins. Ordre. Repos.')
doc('safe_memo','G05','Private memorandum','Note personnelle','The founding year is on the lobby plaque.\nMove its last two digits in front of the first two.\nAdvance EACH digit by {offset}, wrapping after 9 to 0.\nThe four resulting digits open the safe.\nEnter them left to right.','L’année de fondation figure sur la plaque du hall.\nPlacez ses deux derniers chiffres devant les deux premiers.\nAvancez CHAQUE chiffre de {offset}, en revenant à 0 après 9.\nLes quatre chiffres obtenus ouvrent le coffre.\nSaisissez-les de gauche à droite.')
doc('fire_clipping','G05','Child dies in house fire','Une enfant meurt dans un incendie','REGIONAL NEWS — 17 OCTOBER 1976\nA fire broke out at the Lavoie family home yesterday evening. Emergency services were alerted at {fire_time}.\nClaire Lavoie, six, died in the blaze. Her older brother Mathieu was rescued.\nThe cause of the fire remains under investigation.','NOUVELLES RÉGIONALES — 17 OCTOBRE 1976\nUn incendie s’est déclaré hier soir au domicile de la famille Lavoie. Les services d’urgence ont été alertés à {fire_time}.\nClaire Lavoie, six ans, a perdu la vie. Son frère aîné Mathieu a été secouru.\nLa cause de l’incendie fait toujours l’objet d’une enquête.','F02')
doc('hymn_notice','G06','Choir notice','Avis à la chorale','The loft latch follows the hymn board.\nRestore the three hymn numbers in their original order, top to bottom.\nThe old photograph belongs here.','Le loquet de la tribune est relié au tableau des cantiques.\nRétablissez les trois numéros dans leur ordre d’origine, de haut en bas.\nL’ancienne photographie a sa place ici.')
doc('effects_bin_notice','G01','Personal effects','Effets personnels','Place unneeded objects in the effects bin.\nKeys and personal records remain with you.','Déposez les objets inutilisés dans le coffre des effets personnels.\nGardez vos clés et vos documents personnels avec vous.')
doc('recorder_notice','G01','Tape recorder','Magnétophone','Record your progress before leaving.\nOn Committed difficulty, each recording uses one blank cassette.','Enregistrez votre progression avant de partir.\nAu niveau Interné, chaque enregistrement consomme une cassette vierge.')
(ROOT/'data'/'act1-documents.json').write_text(json.dumps(docs,ensure_ascii=False,indent=2))
(ROOT/'data'/'example-seed-1976.json').write_text(json.dumps({'seed':1976,'difficulty':'normal prototype','bindings':bindings,'solutions':{'P01':freq,'P02':dict(zip(['admin','nurse','chapel','records'],ext)),'P03':{'drawer':'1976 admissions','card_birthdate':bindings['birthdate']},'P04':safe,'P05':hymns},'notes':['Authoring example, not the production game RNG.','Safe implementation uses a dial to select and confirm each of four digits, not a real-world three-number safe sequence.','P03 direct misfile note currently represents an easy clue; refine Normal/Hard during puzzle implementation.','Keep fixed story dates stable; never reseed when language changes.']},indent=2))

# Standalone readable sample documents. These have fixed example-seed text.
for item in docs:
 for lang in ['en','fr']:
  title=item[lang]['title'];body=item[lang]['body'].format(**bindings)
  lines=[]
  import textwrap
  for para in body.split('\n'):lines.extend(textwrap.wrap(para,46) or [''])
  content=rect(5,5,890,1190,'#E3DAC2','#A2977D',5)+text(70,80,'INSTITUT SAINTE-ODILE',23,'#646654')+line(70,105,830,105,'#A69D80')
  for i,t in enumerate(textwrap.wrap(title,35)):content+=text(70,160+i*36,t,28)
  for i,t in enumerate(lines):content+=text(70,265+i*39,t,25)
  content+=text(70,1140,item['id'].upper(),16,'#777761')
  svg(item['id']+'-'+lang,900,1200,content,D)

# Isolated institutional signs, EN and FR, with editable live vector text.
names=[('G01','DAYROOM','SALLE DE SÉJOUR'),('G02','MAIN LOBBY','HALL PRINCIPAL'),('G03','RECEPTION','RÉCEPTION'),('G04','RECORDS','ARCHIVES'),('G05','ADMINISTRATOR','ADMINISTRATION'),('G06','CHAPEL','CHAPELLE'),('east','EAST WING','AILE EST'),('staff','STAFF ONLY','PERSONNEL SEULEMENT')]
S=ROOT/'signs';S.mkdir(exist_ok=True)
for id,en,fr in names:
 for lang,label in [('en',en),('fr',fr)]:svg(id+'-'+lang,900,200,rect(4,4,892,192,'#CAC9AF','#5D6D5A',8)+circle(24,100,5,'#6F7762')+circle(876,100,5,'#6F7762')+text(450,117,label,36,'#344B3A','middle'),S)

print(f'Built {len(list(P.glob("*.svg")))} puzzle components, {len(docs)*2} document examples and {len(names)*2} signs.')
