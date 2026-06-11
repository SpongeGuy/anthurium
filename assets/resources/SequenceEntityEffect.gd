extends EntityEffect
class_name SequenceEntityEffect

@export var effects: Array[EntityEffect]
@export var parallel: bool = false

signal sequence_finished

func execute(entity: Entity) -> void:
	if parallel:
		for effect in effects:
			effect.execute(entity)
	else:
		for i in range(effects):
			if not is_instance_valid(effects[i]): return
			await effects[i].execute(entity)
	sequence_finished.emit()
