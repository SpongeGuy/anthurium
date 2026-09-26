extends Node
class_name Component

var entity: Entity
@export var display_name: StringName

signal registered

func _on_registered() -> void:
	pass

func _on_entity_initialized() -> void:
	pass

func _on_entity_spawned() -> void:
	pass
