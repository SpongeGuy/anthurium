extends Node
var _resolved_this_frame: Dictionary[int, bool] = {}

func try_claim(a: Entity, b: Entity) -> bool:
	var key: int = hash([min(a.get_instance_id(), b.get_instance_id()), max(a.get_instance_id(), b.get_instance_id())])
	if _resolved_this_frame.has(key):
		return false
	_resolved_this_frame[key] = true
	return true

func _physics_process(_delta: float) -> void:
	_resolved_this_frame.clear()
