extends Component
class_name KnockbackComponent



@export var minimum_force: float = 0.0

@export var knockback_scale: float = 1.0

@export var physics: PhysicsComponent

func _on_registered() -> void:
	if not physics:
		physics = entity.get_component(PhysicsComponent)

func apply_knockback(source_position: Vector2, force: float) -> void:
	var scaled_force: float = force * knockback_scale
	if scaled_force < minimum_force:
		return
	var direction: Vector2 = (entity.global_position - source_position).normalized()
	physics.apply_impulse(direction, scaled_force)
