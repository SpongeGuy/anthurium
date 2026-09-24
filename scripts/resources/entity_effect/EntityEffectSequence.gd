extends EntityEffect
class_name EntityEffectSequence

@export var parallel: bool = false
@export var effects: Array[EntityEffect]

func _execute(entity: Entity) -> void:
	if parallel:
		await _run_parallel(entity)
	else:
		await _run_sequential(entity)

func _run_sequential(entity: Entity) -> void:
	for effect in effects:
		if not is_instance_valid(effect):
			continue
		await effect.execute(entity)

func _run_parallel(entity: Entity) -> void:
	var state: Dictionary = {"pending": 0}
	var connections: Array[Dictionary] = [] # [{effect, cb}, ...]

	for effect in effects:
		if not is_instance_valid(effect):
			continue
		state.pending += 1
		var cb: Callable = func(finished_entity: Entity) -> void:
			if finished_entity != entity:
				return
			state.pending -= 1
		connections.append({"effect": effect, "cb": cb})
		effect.finished.connect(cb)

	for conn in connections:
		conn.effect.execute(entity)

	while state.pending > 0:
		if not is_instance_valid(entity):
			break
		await entity.get_tree().process_frame

	for conn in connections:
		if is_instance_valid(conn.effect) and conn.effect.finished.is_connected(conn.cb):
			conn.effect.finished.disconnect(conn.cb)
