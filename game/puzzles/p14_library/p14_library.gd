extends OrderingUi
## P14 close-up: the book cart and the gap on shelf D. Spines show titles only; the
## reading list gives the call numbers.


func piece_text(p: int) -> String:
	return tr("book.title.%d" % p)


func submit_key() -> String:
	return "puzzle.p14.push"
