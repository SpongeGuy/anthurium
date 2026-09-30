class_name KeyComponent extends Component

var _check_timer: float = 0.0
@export var check_timer: float = 0.05
@export var check_radius: float = 10
@export var distance_behind: float = 4
@export var transfer_cooldown: float = 1.0

var _hop_timer: float = 0.0
var _transfer_cooldown: float = 0.0

var following: Entity
@export var input: InputComponent
@export var physics: PhysicsComponent

@export var take_effect: EntityEffect

func _on_registered() -> void:
	pass # replace with function body

func _on_entity_initialized() -> void:
	if not input:
		input = entity.get_component(InputComponent)
	if not physics:
		physics = entity.get_component(PhysicsComponent)

func _on_entity_spawned() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	_check_for_nearby_and_transfer(delta)
	_follow_owner(delta)
	_transfer_cooldown -= delta

func _follow_owner(delta: float) -> void:
	if not following:
		return
	var f_facing: FacingComponent = following.get_component(FacingComponent)
	var target_position: Vector2
	if f_facing:
		target_position = following.global_position - (f_facing.get_direction() * distance_behind)
	else:
		target_position = following.global_position
	
	input.set_move_input_direction(Vector2.from_angle(SpatialUtil.get_angle_between_positions(entity.global_position, target_position)))
	var distance: float = entity.global_position.distance_to(target_position)
	physics.apply_force(input.move_input_direction, distance * 40)
	#entity.global_position = lerp(entity.global_position, following.global_position, delta * 20)
	_hop_timer -= delta * distance
	if _hop_timer <= 0.0:
		entity.jump(40, false)
		_hop_timer = 1.0

func _check_for_nearby_and_transfer(delta: float) -> void:
	_check_timer -= delta
	if _check_timer <= 0.0:
		_check_timer = check_timer
		var possible_targets: Array[Entity] = SpatialUtil.get_entities_in_radius(entity.get_world_2d().direct_space_state, entity.global_position, check_radius, SpatialUtil.PhysicsLayers.CREATURES)
		if possible_targets.is_empty():
			return
		var nearest: Entity = SpatialUtil.get_nearest_entity_in_array(entity.global_position, possible_targets, [following])
		if not nearest:
			return
		if _transfer_cooldown > 0.0:
			return
		transfer_ownership(nearest)

func transfer_ownership(to: Entity) -> void:
	if not is_instance_valid(following):
		following = null
	else:
		following.key = null
	following = to
	following.key = entity
	take_effect.execute(entity)
	_transfer_cooldown = transfer_cooldown
