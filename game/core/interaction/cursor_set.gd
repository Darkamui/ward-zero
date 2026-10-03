class_name CursorSet
extends RefCounted
## Procedural placeholder cursors (GDD §3.2: eye, hand, arrow, lock). Replaced by
## painted cursors in M5; only this file changes.

const SIZE := 32

static var _cache: Dictionary = {}


static func apply(kind: Interactable.Cursor) -> void:
	if kind == Interactable.Cursor.NONE:
		Input.set_custom_mouse_cursor(null)
		return
	if not _cache.has(kind):
		_cache[kind] = ImageTexture.create_from_image(_draw(kind))
	Input.set_custom_mouse_cursor(_cache[kind], Input.CURSOR_ARROW, Vector2(SIZE, SIZE) * 0.5)


static func _draw(kind: Interactable.Cursor) -> Image:
	var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var c := Vector2(SIZE, SIZE) * 0.5
	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5) - c
			var on := false
			match kind:
				Interactable.Cursor.EXAMINE:
					var e := (p.x * p.x) / 196.0 + (p.y * p.y) / 64.0
					on = (e <= 1.0 and e >= 0.62) or p.length() <= 4.0
				Interactable.Cursor.HAND:
					on = (
						(absf(p.x) <= 7.0 and p.y >= -2.0 and p.y <= 10.0)
						or (p.y < -2.0 and p.y >= -12.0 and int(p.x + 8.0) % 4 < 2 and absf(p.x) <= 7.0)
					)
				Interactable.Cursor.EXIT:
					on = (
						(absf(p.y) <= 2.5 and p.x >= -11.0 and p.x <= 4.0)
						or (p.x > 2.0 and p.x <= 12.0 and absf(p.y) <= 12.0 - p.x)
					)
				Interactable.Cursor.LOCKED:
					var body := absf(p.x) <= 9.0 and p.y >= -1.0 and p.y <= 12.0
					var r := Vector2(p.x, p.y + 1.0).length()
					var shackle := p.y < -1.0 and r <= 8.0 and r >= 5.0
					on = body or shackle
			if on:
				img.set_pixel(x, y, Color(0.95, 0.93, 0.88))
	# Dark outline for readability on light backgrounds.
	var out := img.duplicate() as Image
	for y in SIZE:
		for x in SIZE:
			if img.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < SIZE and q.y < SIZE and img.get_pixelv(q).a > 0.0:
					out.set_pixel(x, y, Color(0.05, 0.05, 0.05, 0.9))
					break
	return out
