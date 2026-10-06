extends Node

enum Behavior{ TRACKING_PLAYER, TRACKING_RANDOM, FROZEN, CONTROLLED, CENTERED }
var camera: Camera2D
var target: Node2D
var behavior: Behavior
var target_position: Vector2

var lerp_weight: float = 5.0
var debug_sound: VoiceProfile
var tracking_random_patience: float = 5.0
var _tracking_random_timer: float = 0.0

var _visibility_timer: float = 0.0
var visibility_check_interval: float = 0.5

var _delay_timer: float = 0.0
var delay_tween: Tween


signal found_target


var trauma: float = 0 # range [0, 1]
var trauma_decay: float = 1
var max_shake_offset: float = 18.0
var trauma_falloff_range: float = 400.0

var relative_mouse_coords: Vector2


func _process(delta: float) -> void:
	if not camera:
		return
	relative_mouse_coords = (get_viewport().get_mouse_position()/3) + camera.position - Vector2(320, 180)
	debug_handlers()

func _physics_process(delta: float) -> void:
	if not camera:
		return
	_handle_camera_behavior(delta)
	_handle_screen_shake(delta)
	_periodically_reveal_target(delta)


# --------------------------------------------------------------------------------------------------
# placement
# --------------------------------------------------------------------------------------------------

func _place(pos: Vector2, instant: bool, delta: float = 0.0) -> void:
	target_position = pos
	if not camera:
		return
	if instant:
		camera.position = pos
	else:
		camera.position = camera.position.lerp(pos, delta * lerp_weight)

func go_instantly_to(pos: Vector2) -> void:
	_place(pos, true)

# --------------------------------------------------------------------------------------------------
# behavior
# --------------------------------------------------------------------------------------------------

func set_behavior_mode(b: Behavior, delay: float = 0.0, instant: bool = false) -> void:
	var was_tracking_player: bool = behavior == Behavior.TRACKING_PLAYER
	behavior = b
	
	if was_tracking_player and behavior != Behavior.TRACKING_PLAYER and PlayerManager.player_set.is_connected(_on_player_set):
		PlayerManager.player_set.disconnect(_on_player_set)
	
	if delay_tween:
		delay_tween.kill()
		_delay_timer = 0.0
	
	match behavior:
		Behavior.TRACKING_RANDOM:
			delay_tween = create_tween()
			delay_tween.tween_property(self, "_delay_timer", delay, delay)
			delay_tween.tween_callback((func(bb: Behavior): behavior = bb).bind(b))
		Behavior.CONTROLLED:
			target = null
		Behavior.CENTERED:
			_place(_get_center_fallback_position(), instant)
			reveal_from_camera()
		Behavior.TRACKING_PLAYER:
			if not PlayerManager.player_set.is_connected(_on_player_set):
				PlayerManager.player_set.connect(_on_player_set)
			if is_instance_valid(PlayerManager.player):
				_set_camera_target(PlayerManager.player, instant)

func _on_player_set(player: Entity) -> void:
	if behavior != Behavior.TRACKING_PLAYER:
		return
	_set_camera_target(player, true)
	
#func await_and_track_player(instant: bool) -> void:
	#var generation: int = _await_generation
	#if not is_instance_valid(PlayerManager.player):
		#await PlayerManager.player_set
	#if generation != _await_generation or behavior != Behavior.TRACKING_PLAYER:
		#return
	#set_camera_target(PlayerManager.player, instant)

func _set_camera_target(new_target: Entity, instant: bool = false) -> void:
	if not new_target:
		return
	target = new_target
	_place(new_target.global_position, instant)
	EventBus.camera_target_changed.emit(target)

## Used by [AppController] to control the camera manually. Currently just a debug feature.
func directly_control(delta: float) -> void:
	var magnitude: float = 150.0
	var move_input_direction = Input.get_vector("west", "east", "north", "south")
	target_position += move_input_direction * magnitude * delta

## Used by [AppController] when creating a fresh world to create a camera.
func register_camera(c: Camera2D) -> void:
	Log.info("Camera %s registered." % c)
	camera = c
	camera.make_current()

func reset() -> void:
	if delay_tween:
		delay_tween.kill()
	target = null
	target_position = Vector2.ZERO
	behavior = Behavior.FROZEN
	_delay_timer = 0
	_visibility_timer = 0
	_tracking_random_timer = 0.0

	
# --------------------------------------------------------------------------------------------------------------
# reveal / fog-of-war
# --------------------------------------------------------------------------------------------------
	


func _periodically_reveal_target(delta: float) -> void:
	if not target:
		return
	_visibility_timer += delta
	if _visibility_timer >= visibility_check_interval:
		_visibility_timer = 0
		_reveal_target()


func _reveal_target() -> void:
	if not target:
		reveal_from_camera()
		return
	var tile_pos: Vector2i = WorldGrid.world_to_tile(target.global_position)
	var occupying_cell: CellData = WorldGrid.get_cell(tile_pos)
	if not occupying_cell:
		return
	if occupying_cell.invisible:
		WorldGrid.reveal_from(tile_pos)

## Used when camera target changes and when [WorldGrid] sets new cells.
func reveal_from_camera() -> void:
	var tile: Vector2i = WorldGrid.world_to_tile(target_position)
	if not WorldGrid._in_bounds(tile):
		return
	var safe_tile: Vector2i = WorldGrid.get_safe_coords(tile, CellType.TerrainType.GROUND)
	WorldGrid.reveal_from(safe_tile)
			


# --------------------------------------------------------------------------------------------------------------
# screen shake
# --------------------------------------------------------------------------------------------------

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0, 1)
	
## Adds trauma from an event at [param position], falling off linearly with
## distance from the camera up to [member trauma_falloff_range]
func add_trauma_distance(position: Vector2, amount: float) -> void:
	if not camera:
		return
	var dist: float = camera.global_position.distance_to(position)
	var falloff: float = 1.0 - clamp(dist / trauma_falloff_range, 0.0, 1.0)
	add_trauma(amount * falloff)

# -----------------------------------------------------------------------------------------------------------
# mouse position
# -----------------------------------------------------------------------------------------------------------



## Returns the mouse position in world space, or [constant Vector2.ZERO] if
## no camera is registered.
func get_world_mouse_position() -> Vector2:
	if not camera:
		return Vector2.ZERO
	return camera.get_global_mouse_position()

## Returns the mouse position in viewport (screen) space, or
## [constant Vector2.ZERO] if no camera is registered.
func get_screen_mouse_position() -> Vector2:
	if not camera:
		return Vector2.ZERO
	return camera.get_viewport().get_mouse_position()





# ---------------------------------
# debug
# -----------------------------------

func debug_handlers() -> void:
	var tile_coords: Vector2i = WorldGrid.world_to_tile(relative_mouse_coords)
	if Input.is_action_just_pressed("debug_1"):
		WorldGrid.set_cell_type(tile_coords, &"wall_stone")
	if Input.is_action_just_pressed("debug_2"):
		WorldGrid.set_cell_type(tile_coords, &"ground_soil")

# --------------------------------
# private eyes
# ------------------------------

func _handle_camera_behavior(delta: float) -> void:
	match behavior:
		Behavior.TRACKING_PLAYER:
			if target and is_instance_valid(target):
				_place(target.global_position, false, delta)
		Behavior.TRACKING_RANDOM:
			_tracking_random_timer -= delta
			if _tracking_random_timer <= 0.0:
				_tracking_random_timer = tracking_random_patience + randf_range(-2, 2)
				if not EntityManager.active_entities.is_empty():
					_set_camera_target(EntityManager.active_entities.pick_random())
			var pos: Vector2 = target.global_position if (target and is_instance_valid(target)) else _get_center_fallback_position()
			_place(pos, false, delta)
		Behavior.CENTERED, Behavior.CONTROLLED:
			_place(target_position, false, delta)
		Behavior.FROZEN:
			pass
				
func _get_center_fallback_position() -> Vector2:
	return WorldGrid.tile_to_world(WorldGrid.get_safe_coords(WorldGrid.get_center(), CellType.TerrainType.GROUND))
	
				
func _handle_screen_shake(delta: float) -> void:
	trauma = move_toward(trauma, 0.0, trauma_decay * delta)
	var intensity: float = trauma * trauma
	
	camera.offset = Vector2(
		randf_range(-1, 1) * max_shake_offset * intensity, 
		randf_range(-1, 1) * max_shake_offset * intensity
	)
