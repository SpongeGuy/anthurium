extends Component
class_name CameraController

@export var lerp_weight: float = 1.0
var camera: Camera2D

static var target: Node2D
static var behavior: Behavior = Behavior.TRACKING

enum Behavior{ TRACKING, FROZEN }

var coords: Vector2

func _ready() -> void:
	EventBus.camera_ready.connect(_on_camera_ready)



	
	

func _physics_process(delta: float) -> void:
	if not target:
		return
	match behavior:
		Behavior.TRACKING:
			go_to(target.global_position, delta)
			
	coords = get_viewport().get_mouse_position()
	coords += camera.position - Vector2(320, 180)
	
	
		
	if Input.is_key_pressed(KEY_E):
		get_tree().reload_current_scene()
	
	handlers()
	
		


func handlers() -> void:
	var cell: CellData = CellData.new()
	var tile_coords: Vector2i = WorldGrid.world_to_tile(coords)
	if Input.is_action_just_pressed("debug_1"):
		cell.terrain = CellData.TerrainType.WALL
		WorldGrid.set_cell(tile_coords, cell)
		#WorldGrid.set_circle(tile_coords, 2, cell)
		await get_tree().create_timer(1).timeout
		
	if Input.is_action_just_pressed("debug_2"):
		cell.terrain = CellData.TerrainType.GROUND
		WorldGrid.set_cell(tile_coords, cell)
		#WorldGrid.set_circle(tile_coords, 2, cell)
		await get_tree().create_timer(1).timeout

func _on_camera_ready(c: Camera2D) -> void:
	camera = c


static func change_camera_target(new_target: Node2D) -> void:
	target = new_target
	EventBus.camera_target_changed.emit(target)

func go_to(pos: Vector2, delta: float) -> void:
	camera.position = lerp(camera.position, pos, delta * lerp_weight)

func go_instantly_to(pos: Vector2) -> void:
	camera.position = pos
