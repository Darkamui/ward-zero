"""Act 2 strings (EN + fr_CA draft). Run once; existing keys are left alone."""
from loc_helper import add

add("items", [
    ("item.linen_key.name", "Linen Room Key", "Clé de la lingerie"),
    ("item.linen_key.desc", "A small key on a cardboard tag: LINGERIE.", "Une petite clé avec une étiquette de carton : LINGERIE."),
    ("item.valve_wheel.name", "Valve Wheel", "Volant de vanne"),
    ("item.valve_wheel.desc", "A cast-iron wheel with a square socket. It would fit a valve stem.", "Un volant en fonte avec une douille carrée. Il irait sur une tige de vanne."),
    ("item.melancholic_key.name", "Melancholic Key", "Clé mélancolique"),
    ("item.melancholic_key.desc", "A black iron key stamped with a stone and the word MELANCHOLIC.", "Une clé de fer noir frappée d’une pierre et du mot MÉLANCOLIQUE."),
    ("item.phlegmatic_key.name", "Phlegmatic Key", "Clé flegmatique"),
    ("item.phlegmatic_key.desc", "A white enamel key stamped with a wave and the word PHLEGMATIC.", "Une clé émaillée blanche frappée d’une vague et du mot FLEGMATIQUE."),
    ("item.satchel.name", "Orderly’s Satchel", "Sacoche d’infirmier"),
    ("item.satchel.desc", "A canvas satchel. More room to carry things.", "Une sacoche en toile. Plus de place pour transporter des choses."),
    ("item.ribbon.name", "Claire’s Ribbon", "Ruban de Claire"),
    ("item.ribbon.desc", "A faded red hair ribbon. It still smells faintly of smoke.", "Un ruban à cheveux rouge délavé. Il sent encore un peu la fumée."),
    ("item.cylinder.name", "Music Box Cylinder", "Cylindre de boîte à musique"),
    ("item.cylinder.desc", "A brass cylinder studded with movable pins.", "Un cylindre de laiton hérissé de picots mobiles."),
    ("item.fuse.name", "Fuse", "Fusible"),
    ("item.fuse.desc", "A heavy ceramic fuse, rated 60 amps.", "Un gros fusible en céramique de 60 ampères."),
    ("item.f03_nurse_log.name", "Nurse’s Log", "Journal de l’infirmière"),
    ("item.f03_nurse_log.desc", "A page from the night nurse’s log.", "Une page du journal de l’infirmière de nuit."),
    ("item.f04_drawing.name", "Claire’s Drawing", "Dessin de Claire"),
    ("item.f04_drawing.desc", "A crayon drawing of a house and two children.", "Un dessin aux crayons de cire : une maison et deux enfants."),
    ("item.f05_essay.name", "Class Essay", "Rédaction"),
    ("item.f05_essay.desc", "“Ma famille”, by M.L.", "« Ma famille », par M.L."),
    ("item.f06_scratchings.name", "Wall Scratchings", "Gravures au mur"),
    ("item.f06_scratchings.desc", "I copied what was scratched into the cell wall.", "J’ai recopié ce qui était gravé dans le mur de la cellule."),
    ("item.f07_tape.name", "Tape: Session 1", "Cassette : séance 1"),
    ("item.f07_tape.desc", "A cassette labelled “Dr. H. Bouchard – L., session 1 – 1998”.", "Une cassette étiquetée « Dre H. Bouchard – L., séance 1 – 1998 »."),
])

colors = [("white", "white", "blanc"), ("yellow", "yellow", "jaune"), ("pink", "pink", "rose"), ("blue", "blue", "bleu"), ("green", "green", "vert")]
shapes = [("round", "round", "rond"), ("oval", "oval", "ovale"), ("square", "square", "carré"), ("triangle", "triangular", "triangulaire"), ("capsule", "capsule-shaped", "en forme de gélule")]
notes = [("c", "C", "do"), ("d", "D", "ré"), ("e", "E", "mi"), ("g", "G", "sol"), ("a", "A", "la")]
days = [("monday", "Monday", "lundi"), ("tuesday", "Tuesday", "mardi"), ("wednesday", "Wednesday", "mercredi"), ("thursday", "Thursday", "jeudi"), ("friday", "Friday", "vendredi"), ("saturday", "Saturday", "samedi"), ("sunday", "Sunday", "dimanche")]

add("puzzles", [(f"pill.color.{k}", e, f) for k, e, f in colors] + [(f"pill.shape.{k}", e, f) for k, e, f in shapes] + [(f"note.{k}", e, f) for k, e, f in notes] + [
    ("puzzle.p06.name", "Medication Cart", "Chariot à médicaments"),
    ("puzzle.p06.hint", "Click a patient’s drawer, then a pill. Then close the cart.", "Cliquez sur le tiroir d’un patient, puis sur un comprimé. Puis fermez le chariot."),
    ("puzzle.p06.submit", "Close the cart", "Fermer le chariot"),
    ("puzzle.p06.wrong", "Somewhere a buzzer sounds. That isn’t right.", "Quelque part, un avertisseur sonne. Ce n’est pas ça."),
    ("puzzle.p07.name", "Hydrotherapy Tubs", "Bains d’hydrothérapie"),
    ("puzzle.p07.hint", "Pour, drain, or open the main valve to start over. Match every marked level.", "Versez, videz, ou ouvrez la vanne principale pour recommencer. Atteignez chaque niveau marqué."),
    ("puzzle.p07.pour", "Pour {a} → {b}", "Verser {a} → {b}"),
    ("puzzle.p07.drain", "Drain {a}", "Vider {a}"),
    ("puzzle.p07.fill", "Fill {a}", "Remplir {a}"),
    ("puzzle.p07.reset", "Main valve (start over)", "Vanne principale (recommencer)"),
    ("puzzle.p07.tub", "Tub {a}: {n} of {cap} (mark {mark})", "Bain {a} : {n} sur {cap} (marque {mark})"),
    ("puzzle.p08.name", "Laundry Shelves", "Étagères de linge"),
    ("puzzle.p08.hint", "Pull a sheet to read its tag. Every wrong pull makes noise.", "Tirez un drap pour lire son étiquette. Chaque mauvais drap fait du bruit."),
    ("puzzle.p08.wrong", "The pile slumps loudly to the floor.", "La pile s’effondre bruyamment sur le plancher."),
    ("puzzle.p08l.name", "Lockbox", "Coffret"),
    ("puzzle.p08l.hint", "Three wheels.", "Trois molettes."),
    ("puzzle.p08l.wrong", "The lid stays shut.", "Le couvercle reste fermé."),
    ("puzzle.p09.name", "Children’s Drawings", "Dessins d’enfants"),
    ("puzzle.p09.hint", "Click a frame, then a drawing. Turn a drawing over to read its back.", "Cliquez sur un cadre, puis sur un dessin. Retournez un dessin pour lire le verso."),
    ("puzzle.p09.submit", "Step back", "Reculer"),
    ("puzzle.p09.wrong", "No. That isn’t how it happened.", "Non. Ça ne s’est pas passé comme ça."),
    ("puzzle.p09.back", "Back: dated the {date}", "Verso : daté du {date}"),
    ("puzzle.p09.missing", "One frame has no drawing to go in it.", "Il manque un dessin pour un des cadres."),
    ("puzzle.p10.name", "Desk Padlock", "Cadenas du pupitre"),
    ("puzzle.p10.hint", "Four wheels.", "Quatre molettes."),
    ("puzzle.p10.wrong", "The padlock doesn’t give.", "Le cadenas ne cède pas."),
    ("puzzle.p11.name", "Music Box", "Boîte à musique"),
    ("puzzle.p11.hint", "Set one pin per step, then wind the crank.", "Placez un picot par temps, puis tournez la manivelle."),
    ("puzzle.p11.play", "Wind", "Remonter"),
    ("puzzle.p11.wrong", "The tune is wrong. It sounds like someone else’s song.", "L’air est faux. On dirait la chanson de quelqu’un d’autre."),
    ("puzzle.p12.name", "Cell Doors", "Portes des cellules"),
    ("puzzle.p12.hint", "Watch the doors. Open the peepholes in the order of the knocks.", "Observez les portes. Ouvrez les judas dans l’ordre des coups."),
    ("puzzle.p12.listen", "Listen again", "Écouter de nouveau"),
    ("puzzle.p12.wrong", "Silence. Then the knocking starts over.", "Silence. Puis les coups recommencent."),
    ("puzzle.p13.name", "Boiler Valves", "Vannes de la chaudière"),
    ("puzzle.p13.hint", "Keep every needle in the green band. Above 18 the whistle screams.", "Gardez chaque aiguille dans la bande verte. Au-dessus de 18, le sifflet hurle."),
    ("puzzle.p13.gauge", "Gauge {n}: {v} ({band})", "Manomètre {n} : {v} ({band})"),
    ("puzzle.p13.band_green", "green band", "bande verte"),
    ("puzzle.p13.band_red", "RED", "ROUGE"),
    ("puzzle.p13.band_low", "low", "bas"),
    ("puzzle.p13.band_high", "high", "haut"),
    ("puzzle.p13.wrong", "The safety whistle screams through the pipes.", "Le sifflet de sécurité hurle dans la tuyauterie."),
])
add("ui", [(f"ui.day.{k}", e, f) for k, e, f in days] + [("ui.bed", "Bed", "Lit")])


def lines(en_fmt, fr_fmt, n):
    return "\n".join(en_fmt.format(i=i) for i in range(n)), "\n".join(fr_fmt.format(i=i) for i in range(n))


docs = []
for key, count in (("body", 4), ("body_easy", 3), ("body_hard", 5)):
    if key == "body_easy":
        en, frt = lines("{{p{i}}}: one {{c{i}}} {{s{i}}} tablet at 20:00", "{{p{i}}} : un comprimé {{c{i}}} et {{s{i}}} à 20 h", count)
    else:
        en, frt = lines("{{p{i}}}: one {{s{i}}} tablet at 20:00", "{{p{i}}} : un comprimé {{s{i}}} à 20 h", count)
    docs.append((f"doc.med_charts.{key}", "EAST WING — EVENING ROUND\n\n" + en, "AILE EST — TOURNÉE DU SOIR\n\n" + frt))
    en, frt = lines("{{p{i}}} — the {{c{i}}} one", "{{p{i}}} — le {{c{i}}}", count)
    docs.append((f"doc.shift_log.{key}", "Night shift. Colours given out, as usual:\n" + en, "Quart de nuit. Couleurs distribuées, comme d’habitude :\n" + frt))
rows = "\n".join("{r%d}" % k for k in range(6))
docs += [
    ("doc.med_charts.title", "Medication Charts", "Fiches de médication"),
    ("doc.shift_log.title", "Shift Log", "Registre de quart"),
    ("doc.f03_nurse_log.title", "Nurse’s Log", "Journal de l’infirmière"),
    ("doc.f03_nurse_log.body", "March 3, 1977. The Lavoie boy again. Awake at 2:00, sitting up, talking to the empty bed beside him. When I asked who he was talking to he said, “Claire. She’s cold.” There is no Claire on this ward.", "3 mars 1977. Encore le petit Lavoie. Réveillé à 2 h, assis, il parlait au lit vide à côté de lui. Quand je lui ai demandé à qui il parlait, il a répondu : « Claire. Elle a froid. » Il n’y a pas de Claire dans cette aile."),
    ("doc.laundry_ledger.title", "Laundry Ledger", "Registre de buanderie"),
    ("doc.laundry_ledger.body", "LAUNDRY LEDGER — LINEN ROOM\n\n" + rows, "REGISTRE DE BUANDERIE — LINGERIE\n\n" + rows),
    ("doc.laundry_note.title", "Note", "Note"),
    ("doc.laundry_note.body", "The sheet from bed {bed}, {day} night, came back stained. Find it in the ledger and pull it before Sister sees.\n— M.", "Le drap du lit {bed}, la nuit de {day}, est revenu taché. Trouvez-le dans le registre et retirez-le avant que la Sœur le voie.\n— M."),
    ("doc.laundry_note.body_easy", "The sheet tagged {tag} came back stained. Pull it before Sister sees.\n— M.", "Le drap étiqueté {tag} est revenu taché. Retirez-le avant que la Sœur le voie.\n— M."),
    ("doc.sheet_label.title", "Laundry Tag", "Étiquette de buanderie"),
    ("doc.sheet_label.body", "Pinned to the stained sheet:\nWARD E — LOCKBOX {a}{b}{c}", "Épinglée au drap taché :\nAILE E — COFFRET {a}{b}{c}"),
    ("doc.f04_drawing.title", "Claire’s Drawing", "Dessin de Claire"),
    ("doc.f04_drawing.body", "A crayon drawing: a farmhouse, two children holding hands. The girl has a red ribbon. Above the house, in an adult’s neat print, someone has written: “Before.”", "Un dessin aux crayons de cire : une ferme, deux enfants qui se tiennent la main. La fille porte un ruban rouge. Au-dessus de la maison, d’une écriture soignée d’adulte, quelqu’un a écrit : « Avant. »"),
    ("doc.board_1998.title", "Chalkboard (now)", "Tableau (maintenant)"),
    ("doc.board_1998.body", "Half-erased chalk on the board:\n{d0}  _  {d2}  _", "De la craie à moitié effacée au tableau :\n{d0}  _  {d2}  _"),
    ("doc.board_1998.body_easy", "Half-erased chalk on the board:\n{d0}  {d1}  {d2}  _", "De la craie à moitié effacée au tableau :\n{d0}  {d1}  {d2}  _"),
    ("doc.board_1976.title", "Chalkboard (1976)", "Tableau (1976)"),
    ("doc.board_1976.body", "The teacher is still writing the lesson:\n_  {d1}  _  {d3}", "L’institutrice écrit encore la leçon :\n_  {d1}  _  {d3}"),
    ("doc.f05_essay.title", "“Ma famille”", "« Ma famille »"),
    ("doc.f05_essay.body", "Ma famille, by Mathieu L., age 9.\nThere is Papa and Maman and Claire. Claire is six. She is afraid of the dark so I leave the candle on. The teacher asked why I wrote “was” and crossed it out. I don’t know.", "Ma famille, par Mathieu L., 9 ans.\nIl y a Papa et Maman et Claire. Claire a six ans. Elle a peur du noir alors je laisse la chandelle allumée. Madame m’a demandé pourquoi j’ai écrit « avait » et que je l’ai rayé. Je sais pas."),
    ("doc.lid_sheet.title", "Music Box Lid", "Couvercle de la boîte à musique"),
    ("doc.lid_sheet.body", "Inside the lid, in pencil, a child’s note of the tune:\n{n0} {n1} {n2} {n3} {n4} {n5}", "À l’intérieur du couvercle, au crayon, la mélodie notée par un enfant :\n{n0} {n1} {n2} {n3} {n4} {n5}"),
    ("doc.lid_sheet.body_easy", "Inside the lid, in pencil, a child’s note of the tune:\n{n0} {n1} {n2} {n3}", "À l’intérieur du couvercle, au crayon, la mélodie notée par un enfant :\n{n0} {n1} {n2} {n3}"),
    ("doc.lid_sheet.body_hard", "Inside the lid, in pencil, a child’s note of the tune:\n{n0} {n1} {n2} {n3} {n4} {n5} {n6} {n7}", "À l’intérieur du couvercle, au crayon, la mélodie notée par un enfant :\n{n0} {n1} {n2} {n3} {n4} {n5} {n6} {n7}"),
    ("doc.f06_scratchings.title", "Wall Scratchings", "Gravures au mur"),
    ("doc.f06_scratchings.body", "Tally marks, hundreds of them, in rows of five. Under them, pressed hard enough to break a nail:\nMY FAULT", "Des traits de décompte, des centaines, en rangées de cinq. En dessous, gravé assez fort pour casser un ongle :\nMA FAUTE"),
    ("doc.boiler_manual.title", "Boiler Manual", "Manuel de la chaudière"),
    ("doc.boiler_manual.body", "RESTARTING: fit a 60 A fuse. Each valve feeds two gauges. Keep every needle in the green band (10–14). Above 18 the safety whistle sounds.", "REDÉMARRAGE : installer un fusible de 60 A. Chaque vanne alimente deux manomètres. Gardez chaque aiguille dans la bande verte (10 à 14). Au-dessus de 18, le sifflet de sécurité se déclenche."),
    ("doc.boiler_manual.body_easy", "RESTARTING: fit a 60 A fuse. Each valve feeds one gauge. Keep every needle in the green band (10–14). Above 18 the safety whistle sounds.", "REDÉMARRAGE : installer un fusible de 60 A. Chaque vanne alimente un seul manomètre. Gardez chaque aiguille dans la bande verte (10 à 14). Au-dessus de 18, le sifflet de sécurité se déclenche."),
    ("doc.dining_menu.title", "Menu", "Menu"),
    ("doc.dining_menu.body", "FRIDAY\nPea soup — fish — bread pudding\nNo second helpings.", "VENDREDI\nSoupe aux pois — poisson — pouding au pain\nPas de deuxième portion."),
]
add("documents", docs)

add("tapes", [
    ("tape.02_bouchard.title", "Tape: Session 1 (1998)", "Cassette : séance 1 (1998)"),
    ("tape.02_bouchard.line1", "Dr. Bouchard: Session one. It’s the fourteenth of March, 1998.", "Dre Bouchard : Séance un. Nous sommes le 14 mars 1998."),
    ("tape.02_bouchard.line2", "Dr. Bouchard: Mathieu, do you know where you are?", "Dre Bouchard : Mathieu, savez-vous où vous êtes ?"),
    ("tape.02_bouchard.line3", "Mathieu: At Sainte-Odile. I came to find my sister.", "Mathieu : À Sainte-Odile. Je suis venu chercher ma sœur."),
    ("tape.02_bouchard.line4", "Dr. Bouchard: (a pause) We’ll talk about Claire when you’re ready.", "Dre Bouchard : (une pause) On parlera de Claire quand vous serez prêt."),
    ("tape.03_lullaby.title", "Tape: Lullaby", "Cassette : berceuse"),
    ("tape.03_lullaby.line1", "(A girl hums a slow tune, over and over.)", "(Une fillette fredonne un air lent, encore et encore.)"),
    ("tape.03_lullaby.line2", "(The tape hisses. The humming stops mid-note.)", "(La bande grésille. Le fredonnement s’arrête au milieu d’une note.)"),
])
print("strings_act2: done")
