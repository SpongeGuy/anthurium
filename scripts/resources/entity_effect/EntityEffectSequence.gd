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
	
	var pending: int = 0
	var callbacks: Array[Callable] = []
	
	# connect completion tracking before starting anything so a child that resolves
	#  synchronously (no internal await) can't finish before we're listening
	for effect in effects:
		if not is_instance_valid(effect):
			continue
		pending += 1
		var cb: Callable
		cb = func(finished_entity: Entity) -> void:
			if finished_entity != entity:
				return
			pending -= 1
			effect.finished.disconnect(cb)
		callbacks.append(cb)
		effect.finished.connect(cb)
		
	for effect in effects:
		if is_instance_valid(effect):
			effect.execute(entity)
	
	
	while pending > 0:
		if not is_instance_valid(entity):
			break
		await entity.get_tree().process_frame
