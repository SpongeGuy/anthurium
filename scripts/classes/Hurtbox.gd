extends Area2D
class_name Hurtbox

@export var damage: float
@export var constant_hurtbox: bool = false
@export var collision_shape: CollisionShape2D
@export var collider_type: Array[ColliderType] = [ColliderType.NORMAL]
enum ColliderType{NORMAL, FLYING, GROUND}
const COLLIDER_BITS = [6, 12, 14]

var tween: Tween

signal activated

func _ready() -> void:
	if collider_type.is_empty():
		push_error("Collider type for hitbox cannot be empty!")
	
	collision_mask = 0
	collision_layer = 0
	for type in collider_type:
		collision_layer |= 1 << COLLIDER_BITS[type] + 1
		collision_mask |= 1 << COLLIDER_BITS[type]
	
	
	if not constant_hurtbox:
		collision_shape.disabled = true
	else:
		collision_shape.disabled = false
		
func set_active(value: bool) -> void:
	collision_shape.disabled = !value

func activate_in_time_range(value: float, min: float, max: float) -> void:
	if value > min and value < max:
		collision_shape.disabled = false
	else:
		collision_shape.disabled = true

func activate(start: float, end: float) -> Signal:
	if tween: 
		tween.kill()
	collision_shape.disabled = true
	activated.emit()
	tween = create_tween()
	tween.tween_callback(func(): collision_shape.disabled = false).set_delay(start)
	tween.tween_callback(func(): collision_shape.disabled = true).set_delay(end - start)
	return tween.finished
