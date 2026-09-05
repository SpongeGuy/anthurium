extends Area2D
class_name Hurtbox

var entity: Entity
@export var damage: float
@export var constant_hurtbox: bool = false
@export var can_hurt_self: bool = false
@export var collision_shape: CollisionShape2D
@export var type: DamageType

var z: float = 0.0
var layer: Entity.VerticalLayer = Entity.VerticalLayer.GROUND

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
	
	collision_layer |= 7
	collision_mask |= 6
	entity = Entity.find_entity(self)
	if entity:
		z = entity.z
		layer = entity.layer
		entity.z_updated.connect(_on_entity_z_updated)
		
func _on_entity_z_updated(new_z: float, new_layer: Entity.VerticalLayer) -> void:
	z = new_z
	layer = new_layer


		
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
