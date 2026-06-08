extends Area2D
class_name Hurtbox

var entity: Entity
@export var damage: float
@export var constant_hurtbox: bool = false
@export var can_hurt_self: bool = false
@export var collision_shape: CollisionShape2D
@export var layer: Array[Layer] = [Layer.NORMAL]
@export var type: DamageType
enum Layer{NORMAL, FLYING, GROUND}
# projectile: a singular travelling instance of damage
# melee: usually close-range damage
# force: things like explosions, magic, or environmental damage
# contact: contact damage with an entity or damaging tile
# self: self-inflicted damage
enum DamageType{GENERIC, PROJECTILE, MELEE, FORCE, CONTACT, SELF}
const COLLIDER_BITS = [6, 12, 14]

var tween: Tween

signal activated

func _enter_tree() -> void:
	if constant_hurtbox:
		set_active(true)
	else:
		set_active(false)

func _ready() -> void:
	name = "Hurtbox"
	if layer.is_empty():
		push_error("Collider type for hitbox cannot be empty!")
	
	collision_mask = 0
	collision_layer = 0
	for type in layer:
		collision_layer |= 1 << COLLIDER_BITS[type] + 1
		collision_mask |= 1 << COLLIDER_BITS[type]
	entity = Entity.find_entity(self)
	

		
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
	tween.tween_callback(_enable_shape).set_delay(start)
	tween.tween_callback(func(): collision_shape.disabled = true).set_delay(end - start)
	return tween.finished

func _enable_shape() -> void:
	collision_shape.disabled = false
