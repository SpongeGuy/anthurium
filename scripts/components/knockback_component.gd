extends Component
class_name KnockbackComponent

@export var friction: float = 400.0
@export var health: HealthComponent

var _knockback_velocity: Vector2 = Vector2.ZERO

func _on_registered() -> void:
	pass # replace with function body

func _ready() -> void:
	if health:
		health.taken_damage.connect(_on_taken_damage)
		
func _physics_process(delta: float) -> void:
	if _knockback_velocity.is_zero_approx():
		return
	var new_speed: float = max(_knockback_velocity.length() - friction * delta, 0.0)
	_knockback_velocity = Vector2.ZERO if new_speed == 0.0 else _knockback_velocity.normalized()
	
func consume_velocity() -> Vector2:
	var v: Vector2 = _knockback_velocity
	_knockback_velocity = Vector2.ZERO
	return v
	
func apply_knockback(direction: Vector2, force: float) -> void:
	_knockback_velocity += direction.normalized() * force
	
func _on_taken_damage(amount: float, source: Entity) -> void:
	var direction: Vector2 = (entity.global_position - source.global_position).normalized()
	apply_knockback(direction, amount * 50)
