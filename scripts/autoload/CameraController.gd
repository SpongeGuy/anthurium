extends Component

var lerp_weight: float = 5.0
var debug_sound: VoiceProfile
var camera: Camera2D

var target: Node2D
var behavior: Behavior = Behavior.TRACKING
var target_position: Vector2

enum Behavior{ TRACKING, FROZEN }


signal found_target




	
func _process(delta: float) -> void:
	if not camera:
		return
	relative_mouse_coords = get_viewport().get_mouse_position()
	relative_mouse_coords = (relative_mouse_coords /3 + camera.position - Vector2(320, 180))
	if target:
		target_position = target.global_position
	
	
	
	debug_handlers()

func _physics_process(delta: float) -> void:
	match behavior:
		Behavior.TRACKING:
			if target_position:
				go_to(target_position, delta)
	
	if not camera:
		return
	
	trauma = move_toward(trauma, 0.0, trauma_decay * delta)
	var intensity: float = trauma * trauma
	
	camera.offset = Vector2(
		randf_range(-1, 1) * max_shake_offset * intensity, 
		randf_range(-1, 1) * max_shake_offset * intensity
	)
	
		




func register_camera(c: Camera2D) -> void:
	Log.info("Camera %s registered." % c)
	camera = c


func change_camera_target(new_target: Node2D) -> void:
	target = new_target
	target_position = target.global_position
	EventBus.camera_target_changed.emit(target)

func go_to(pos: Vector2, delta: float) -> void:
	if not camera:
		return
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
