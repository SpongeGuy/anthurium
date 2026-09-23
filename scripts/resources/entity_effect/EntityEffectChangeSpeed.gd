extends EntityEffect
class_name EntityEffectChangeSpeed

var locomotion: LocomotionHandler
@export var speed: float

func _execute(entity: Entity) -> void:
	locomotion = entity.get_component(LocomotionHandler)
	locomotion.set_speed(speed)
	finished.emit(entity)
	

