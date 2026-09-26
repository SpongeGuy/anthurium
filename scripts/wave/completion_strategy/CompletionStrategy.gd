class_name CompletionStrategy
extends RefCounted

signal completed

func start(_ctx: WaveRuntime) -> void: pass
func tick(_delta: float) -> void: pass
func on_entity_tracked(_entity: Entity) -> void: pass
func _complete() -> void: completed.emit()
