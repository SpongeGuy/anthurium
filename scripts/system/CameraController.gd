extends Component
class_name CameraController

@export var lerp_weight: float = 1.0
@export var debug_sound: BfxrVoiceProfile
static var camera: Camera2D

static var target: Node2D
static var behavior: Behavior = Behavior.TRACKING
var target_position: Vector2

enum Behavior{ TRACKING, FROZEN }

static var trauma: float = 0
@export var trauma_decay: float = 1
@export var max_shake_offset: float = 18.0
static var trauma_falloff_range: float = 400.0



var coords: Vector2

func _ready() -> void:
	EventBus.camera_ready.connect(_on_camera_ready)


static func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0, 1)
	
static func add_trauma_distance(position: Vector2, amount: float) -> void:
	if not camera:
		return
	var dist: float = camera.global_position.distance_to(position)
	var falloff: float = 1.0 - clamp(dist / trauma_falloff_range, 0.0, 1.0)
	add_trauma(amount * falloff)
	
	

func _physics_process(delta: float) -> void:	
	match behavior:
		Behavior.TRACKING:
			if target:
				target_position = target.global_position
			if target_position:
				go_to(target_position, delta)
	
	if not camera:
		return
	
	coords = get_viewport().get_mouse_position()
	coords += camera.position - Vector2(320, 180)
	
	debug_handlers()
	
	trauma = move_toward(trauma, 0.0, trauma_decay * delta)
	var intensity: float = trauma * trauma
	
	camera.offset = Vector2(
		randf_range(-1, 1) * max_shake_offset * intensity, 
		randf_range(-1, 1) * max_shake_offset * intensity
	)
	
		


func debug_handlers() -> void:
	var cell: CellData = CellData.new()
	var tile_coords: Vector2i = WorldGrid.world_to_tile(coords)
	if Input.is_action_just_pressed("debug_1"):
		cell.terrain = CellData.TerrainType.WALL
		WorldGrid.set_cell(tile_coords, cell)
		#BFXR.PlayRandom()
		#WorldGrid.set_circle(tile_coords, 2, cell)

	if Input.is_action_just_pressed("debug_2"):
		cell.terrain = CellData.TerrainType.GROUND
		WorldGrid.set_cell(tile_coords, cell)
		#WorldGrid.set_circle(tile_coords, 2, cell)

func _on_camera_ready(c: Camera2D) -> void:
	camera = c


static func change_camera_target(new_target: Node2D) -> void:
	target = new_target
	EventBus.camera_target_changed.emit(target)

func go_to(pos: Vector2, delta: float) -> void:
	camera.position = lerp(camera.position, pos, delta * lerp_weight)

static func go_instantly_to(pos: Vector2) -> void:
	camera.position = pos
