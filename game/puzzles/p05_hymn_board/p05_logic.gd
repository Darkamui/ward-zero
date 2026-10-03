class_name P05Logic
extends PuzzleLogic
## P05 Chapel hymn board (memory tutorial): set the present-day board to the numbers seen
## on the complete 1976 board. Digit cards come from a tray and can always go back.
## values: hymns (3 unique numbers, 100-699). params.rows: how many numbers (Easy 2).

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
