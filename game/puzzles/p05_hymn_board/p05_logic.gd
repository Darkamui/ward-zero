class_name P05Logic
extends PuzzleLogic
## P05 Chapel hymn board (memory tutorial): set the present-day board to the numbers seen
## on the complete 1976 board. Digit cards come from a tray and can always go back.
## values: hymns (3 unique numbers, 100-699). params.rows: how many numbers (Easy 2).

const TITLE_COUNT := 12

var board: Array = []  # rows x 3 digits; -1 = empty slot


func rows() -> int:
	return int(params.get("rows", 3))


func hymns() -> Array:
	var h: Array = values.get(&"hymns", [100, 200, 300])
	return h.slice(0, rows())


func _setup() -> void:
	board = []
	for r in rows():
		board.append([-1, -1, -1])


func place(row: int, col: int, digit: int) -> void:
	if row < 0 or row >= board.size() or col < 0 or col > 2:
		return
	board[row][col] = clampi(digit, 0, 9)


func clear(row: int, col: int) -> void:
	if row >= 0 and row < board.size() and col >= 0 and col <= 2:
		board[row][col] = -1


func is_full() -> bool:
	for row in board:
		if row.has(-1):
			return false
	return true


func row_value(row: int) -> int:
	var d: Array = board[row]
	if d.has(-1):
		return -1
	return d[0] * 100 + d[1] * 10 + d[2]


## Checks a full board. True if it matches the 1976 board.
func submit() -> bool:
	if not is_full():
		return false
	for r in board.size():
		if row_value(r) != int(hymns()[r]):
			return false
	solved = true
	return true


func serialize() -> Dictionary:
	return {"board": board.duplicate(true)}


func deserialize(d: Dictionary) -> void:
	var b: Array = d.get("board", [])
	if b.size() == rows():
		board = []
		for row in b:
			var r := []
			for x in row:
				r.append(int(x))
			board.append(r)


func solution() -> Variant:
	return hymns()


## Hard (GDD §8.2): the 1976 board shows hymn titles; the hymnal index maps every title to
## a number. title_key_<k>: title of hymn k. number_<i>: index entry for title i.
static func computed_value(v: Dictionary, field: StringName) -> Variant:
	var f := String(field)
	var titles: Array = v.get(&"hymn_titles", [0, 1, 2])
	var hymn_numbers: Array = v.get(&"hymns", [100, 200, 300])
	if f.begins_with("title_key_"):
		return "hymn.title.%d" % int(titles[int(f.trim_prefix("title_key_"))])
	if f.begins_with("number_"):
		var i := int(f.trim_prefix("number_"))
		var k := titles.find(i)
		if k != -1:
			return int(hymn_numbers[k])
		var n := 100 + (i * 53 + int(hymn_numbers[0])) % 600
		while hymn_numbers.has(n):
			n = 100 + (n - 99) % 600
		return n
	return null
