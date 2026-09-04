extends Component

var lerp_weight: float = 5.0
var debug_sound: VoiceProfile
var camera: Camera2D

var target: Node2D
var behavior: Behavior
var target_position: Vector2

enum Behavior{ TRACKING_PLAYER, TRACKING_RANDOM, FROZEN, CONTROLLED }


signal found_target


var tracking_random_patience: float = 5.0
var _tracking_random_timer: float = 0.0
var _delay_timer: float = 0.0
var delay_tween: Tween

var _visibility_timer: float = 0.0
var visibility_check_interval: float = 0.5

	
func _process(delta: float) -> void:
	if not camera:
		return
	relative_mouse_coords = get_viewport().get_mouse_position()
	relative_mouse_coords = (relative_mouse_coords /3 + camera.position - Vector2(320, 180))
	if target:
		target_position = target.global_position
	
	debug_handlers()

func _physics_process(delta: float) -> void:
	if not camera:
		return
	_handle_camera_behavior(delta)
	_handle_screen_shake(delta)
	_fix_if_standing_on_invisible(delta)
	
	
func _fix_if_standing_on_invisible(delta: float) -> void:
	if not target:
		WorldGrid.reveal_from_camera()
		return
	_visibility_timer += delta
	if _visibility_timer >= visibility_check_interval:
		_visibility_timer = 0
		var tile_pos: Vector2i = WorldGrid.world_to_tile(target.global_position)
		var occupying_cell: CellData = WorldGrid.get_cell(tile_pos)
		if not occupying_cell:
			return
		if occupying_cell.invisible:
			WorldGrid.reveal_from(tile_pos)
				
func directly_control(delta: float) -> void:
	var magnitude: float = 150.0
	var move_input_direction = Input.get_vector("west", "east", "north", "south")
	target_position += move_input_direction * magnitude * delta

func set_behavior_mode(b: Behavior, delay: float = 0.0) -> void:
	behavior = b
	if delay_tween:
		delay_tween.kill()
		_delay_timer = 0
	match b:
		Behavior.TRACKING_RANDOM:
			delay_tween = create_tween()
			delay_tween.tween_property(self, "_delay_timer", delay, delay)
			delay_tween.tween_callback((func(b: Behavior): behavior = b).bind(b))
		Behavior.CONTROLLED:
			target = null
			
	
func reset() -> void:
	target = null
	target_position = Vector2.ZERO
	behavior = 2
	_delay_timer = 0


func register_camera(c: Camera2D) -> void:
	Log.info("Camera %s registered." % c)
	camera = c
	camera.make_current()

func change_camera_target(new_target: Node2D) -> void:
	target = new_target
	target_position = target.global_position
	WorldGrid.hide_map()
	WorldGrid.reveal_from(WorldGrid.world_to_tile(new_target.global_position))
	EventBus.camera_target_changed.emit(target)

func go_to(pos: Vector2, delta: float) -> void:
	camera.position = lerp(camera.position, pos, delta * lerp_weight)

func go_instantly_to(pos: Vector2) -> void:
	if not camera:
		return
	camera.position = pos

# ---------------------------------------
# mouse position
# ---------------------------------------

var relative_mouse_coords: Vector2

func get_world_mouse_position() -> Vector2:
	if not camera:
		return Vector2.ZERO
	return camera.get_global_mouse_position()

func get_screen_mouse_position() -> Vector2:
	if not camera:
		return Vector2.ZERO
	return camera.get_viewport().get_mouse_position()




# -------------------------------------------
# screen shake
# ------------------------------------------
var trauma: float = 0
var trauma_decay: float = 1
var max_shake_offset: float = 18.0
var trauma_falloff_range: float = 400.0

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0, 1)
	
func add_trauma_distance(position: Vector2, amount: float) -> void:
	if not camera:
		return
	var dist: float = camera.global_position.distance_to(position)
	var falloff: float = 1.0 - clamp(dist / trauma_falloff_range, 0.0, 1.0)
	add_trauma(amount * falloff)



# ---------------------------------
# debug
# -----------------------------------
func debug_handlers() -> void:
	var tile_coords: Vector2i = WorldGrid.world_to_tile(relative_mouse_coords)
	if Input.is_action_just_pressed("debug_1"):
		WorldGrid.set_cell_type(tile_coords, &"wall_stone")
		#BFXR.PlayRandom()
		#WorldGrid.set_circle(tile_coords, 2, cell)

	if Input.is_action_just_pressed("debug_2"):
		WorldGrid.set_cell_type(tile_coords, &"ground_soil")
		#WorldGrid.set_circle(tile_coords, 2, cell)


# --------------------------------
# private eyes
# ------------------------------

func _handle_camera_behavior(delta: float) -> void:
	match behavior:
		Behavior.TRACKING_PLAYER:
			if target_position:
				go_to(target_position, delta)
		Behavior.TRACKING_RANDOM:
			_tracking_random_timer -= delta
			if _tracking_random_timer <= 0.0:
				var random_entity: Entity = EntityManager.active_entities.pick_random()
				change_camera_target(random_entity)
				_tracking_random_timer = tracking_random_patience + randf_range(-2, 2)
			if target_position:
				go_to(target_position, delta)
				
func _handle_screen_shake(delta: float) -> void:
	trauma = move_toward(trauma, 0.0, trauma_decay * delta)
	var intensity: float = trauma * trauma
	
	camera.offset = Vector2(
		randf_range(-1, 1) * max_shake_offset * intensity, 
		randf_range(-1, 1) * max_shake_offset * intensity
	)
