class_name SlotList
extends VBoxContainer
## Save slots for the save screen (save + load) and the title screen (load only).

signal slot_chosen(slot: int)

var allow_save := false


func refresh() -> void:
	for c in get_children():
		c.queue_free()
	var used := {}
	for info in SaveSystem.list_slots():
		used[info["slot"]] = info
	for slot in SaveSystem.SLOT_COUNT:
		if slot == SaveSystem.AUTOSAVE_SLOT and allow_save:
			continue
		var text := tr("ui.save.empty")
		if used.has(slot):
			var info: Dictionary = used[slot]
			var room: RoomData = ContentDB.get_room(StringName(info["room"]))
			var room_name := tr(room.name_key) if room else String(info["room"])
			var t := int(info["play_time"])
			text = (
				"%s   %02d:%02d   %s"
				% [room_name, t / 3600, (t / 60) % 60, String(info["saved_at"]).replace("T", " ")]
			)
		var label := (
			tr("ui.save.autosave")
			if slot == SaveSystem.AUTOSAVE_SLOT
			else tr("ui.save.slot").format({"n": slot})
		)
		var b := Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.text = "%s — %s" % [label, text]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 24)
		b.disabled = not allow_save and not used.has(slot)
		b.pressed.connect(func() -> void: slot_chosen.emit(slot))
		add_child(b)
