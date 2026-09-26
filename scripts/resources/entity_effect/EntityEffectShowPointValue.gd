extends EntityEffect
class_name EntityEffectShowPointValue

var theme: Theme = preload("uid://mujvlgvkfhuh")

func _execute(entity: Entity) -> void:
	if entity.points > 0:
		ParticleManager.spawn_number(entity.points, entity.global_position, theme)
	finished.emit()

