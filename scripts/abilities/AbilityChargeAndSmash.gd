class_name AbilityChargeAndSmash extends Ability

@export var damage: float = 4.0

func initialize() -> void:
	if not facing:
		facing = entity.get_component(FacingComponent)
	if not physics:
		physics = entity.get_component(PhysicsComponent)
		
	hurtbox = Hurtbox.new(damage)
	hurtbox.create_circular_collision_shape(20, 0)
	hurtbox.knockback_multiplier = 5
	created_nodes.append(hurtbox)
	entity.add_child(hurtbox)
	
	charge_force = entity.mass * 1000
	


# create a unique direction that lerps to where the entity is facing through a multiplier
# apply constant force to the entity towards the unique direction
# do damage to tiles near the entity
var force_direction: Vector2
var dir_change_factor: float = 1.5

var facing: FacingComponent
var physics: PhysicsComponent

var _timer: float = 0.0
var charge_timer_duration: float = 3.0

var charge_force: float

var hurtbox: Hurtbox

var ability_active: bool = false

var collisions: int = 0

func _execute() -> void:
	_timer = charge_timer_duration
	physics.wall_collision.connect(_on_collision)
	physics.entity_collision.connect(_on_collision)
	force_direction = facing.get_direction()
	hurtbox.activate(0, charge_timer_duration)
	ability_active = true
	collisions = 0
	
	

func _physics_process(delta: float) -> void:
	if (_timer <= 0.0 or collisions > 5) and ability_active:
		finish_ability()
		return
	if not ability_active:
		return
	_timer -= delta
	force_direction = lerp(force_direction, facing.get_direction(), dir_change_factor * delta)
	force_direction = force_direction.normalized()

	physics.apply_force(force_direction, charge_force)
	
func finish_ability() -> void:
	finished.emit()
	if physics and physics.wall_collision.is_connected(_on_collision):
		physics.wall_collision.disconnect(_on_collision)
	ability_active = false
	return

func on_pressed(modifier: bool) -> void:
	if _timer > 0.0:
		return
	execute()
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass



func _on_collision(node: Node) -> void:
	WorldGrid.damage_circle(WorldGrid.world_to_tile(entity.global_position), 1, 25)
	collisions += 1
