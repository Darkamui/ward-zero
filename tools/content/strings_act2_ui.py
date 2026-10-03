from loc_helper import add
drawings = [
    ("A farmhouse in the sun, two children in the yard.", "Une ferme au soleil, deux enfants dans la cour."),
    ("The children hold hands under a big tree.", "Les enfants se tiennent la main sous un grand arbre."),
    ("Night. A candle on the windowsill.", "La nuit. Une chandelle sur le rebord de la fenêtre."),
    ("Orange scribbles over the house.", "Des gribouillis orange sur la maison."),
    ("The boy alone in the yard, very small.", "Le garçon seul dans la cour, tout petit."),
    ("A white building with many windows.", "Un bâtiment blanc avec beaucoup de fenêtres."),
]
add("puzzles", [(f"puzzle.p09.drawing_{i}", e, f) for i, (e, f) in enumerate(drawings)] + [
    ("puzzle.p09.turn", "Turn the drawings over", "Retourner les dessins"),
    ("puzzle.p12.cell", "Cell {n}", "Cellule {n}"),
    ("puzzle.p12.dust", "· dust falls ·", "· la poussière tombe ·"),
])
print("strings_act2_ui: done")
