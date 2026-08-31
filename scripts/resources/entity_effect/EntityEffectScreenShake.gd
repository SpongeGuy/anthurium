extends EntityEffect
class_name EntityEffectScreenShake

@export_range(0, 1) var trauma: float

func _execute(entity: Entity) -> void:
	CameraController.add_trauma_distance(entity.global_position, trauma)
