extends Node2D
class_name Rotator

var intended_rotation: float = 0.0
@export var weight: float = 15.0

@export var facing: FacingComponent

func _physics_process(delta: float) -> void:
	intended_rotation = facing.get_direction_angle()

	rotation = lerp_angle(rotation, intended_rotation, delta * weight)
