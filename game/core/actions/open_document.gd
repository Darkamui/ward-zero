class_name OpenDocument
extends Action

@export var document_id: StringName


func execute() -> void:
	GameState.add_document(document_id)
	EventBus.document_requested.emit(document_id)
