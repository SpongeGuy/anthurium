class_name EntityEffectJump extends EntityEffect

@export var power: float = 60.0

func _execute(entity: Entity) -> void:
	if entity.is_on_ground():
		entity.jump(power)

