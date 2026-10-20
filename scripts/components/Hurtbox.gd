extends Area2D
class_name Hurtbox

# projectile: a singular travelling instance of damage
# melee: usually close-range damage
# force: things like explosions, magic, or environmental damage
# contact: contact damage with an entity or damaging tile
# self: self-inflicted damage
enum DamageType{GENERIC, PROJECTILE, MELEE, FORCE, CONTACT, SELF}

enum BehaviorType{ DEFAULT, BLINKING, CONSTANT }

var entity: Entity
@export var damage: float
@export var can_hurt_self: bool = false
@export var collision_shape: CollisionShape2D
@export var behavior_type: BehaviorType = BehaviorType.DEFAULT
@export var damage_type: DamageType
@export var register_to_entity_z: bool = false

var persistence: float = -1
signal persistence_elapsed

@export var blink_timer: float = 1

## Height offset of this hurtbox's damage volume from the owning entity's
## current [member Entity.z] (its base). 0 means the volume starts at the
## entity's own base. For a standalone projectile flying at a fixed
## altitude, set this (or drive it from the projectile's own z-drive)
## instead of relying on the entity default.
@export var z_offset: float = 0.0
## Vertical extent of this hurtbox's damage volume, from
## [code]entity.z + z_offset[/code] up to [code]+ height[/code]. A tall
## height clears more of the space above it; e.g. a low melee swing vs. a
## soaring fireball.
@export var height: float = 2.0



var tween: Tween

signal activated

func set_behavior_type(type: BehaviorType) -> void:
	behavior_type = type
	match behavior_type:
		BehaviorType.DEFAULT:
			collision_shape.disabled = true
		BehaviorType.BLINKING:
			pass
		BehaviorType.CONSTANT:
			collision_shape.disabled = false
	

func _process(delta: float) -> void:
	tick_persistence(delta)
	

func tick_persistence(delta: float) -> void:
	if persistence < 0.0:
		return
	persistence -= delta
	if persistence <= 0.0:
		persistence_elapsed.emit()
	

func _ready() -> void:
	name = "Hurtbox"
	
	collision_layer |= 7
	collision_mask |= 6
	entity = Entity.find_entity(self)
	if collision_shape:
		set_behavior_type(behavior_type)
	
	
	if register_to_entity_z:
		entity.register_z_node(self)
	
## creates and adds a collision shape to the hurtbox.
## useful when programmatically creating new hurtboxes, like in [Ability].
func create_circular_collision_shape(r: float, offset: float = 0.0) -> void:
	if collision_shape:
		collision_shape.queue_free()
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = r
	collision.position.x = offset
	add_child(collision)
	collision_shape = collision
	set_behavior_type(behavior_type)
	

func _init(hurtbox_damage: float = 1.0) -> void:
	damage = hurtbox_damage
		
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
