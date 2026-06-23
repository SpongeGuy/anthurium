extends Node
class_name GameMaster

# -----------------------------------------------------------
# orchestrates the game
# utilizes all system nodes
# -----------------------------------------------------------

@export var debug_ui: DebugUIHelper
@export var game_viewport: SubViewport
var weather_scene: PackedScene = load("res://scenes/systems/weather.tscn")
var tile_set: TileSet = load("res://assets/tilesets/main.tres")
var visual_tile_set: TileSet = load("res://assets/tilesets/visual.tres")
var title_screen_scene: PackedScene = load("res://scenes/title_screen/title.tscn")
@export var dungeon_generator: DungeonGenerator


var opal_score: int = 0
var aura_score: int = 0
var anthurium_cores: Array[Entity]
var world: Node2D
static var time: float = 0

func _ready() -> void:
	call_deferred("initialize_game")
	GameState.game_state_changed.connect(_on_game_state_changed)
	time = 0

func _on_game_state_changed(status: GameState.Status) -> void:
	match status:
		GameState.Status.PAUSED:
			get_tree().paused = true
		GameState.Status.PLAYING:
			get_tree().paused = false
			
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("start"):
		GameState.toggle_pause()
		
	if Input.is_key_pressed(KEY_E):
		get_tree().reload_current_scene()
		
	time += delta

func initialize_game() -> void:
	EventBus.starting_new_game.emit()
	GameState.change_game_state(GameState.Status.LOADING)
	
	_initialize_tree()
	_create_new_dungeon()
	_initialize_player(Vector2i(16, 16))
	_initialize_debug_spawns()
	#_make_test_land()
	
	#_initialize_anthurium(Vector2i(16, 16))
	
	GameState.change_game_state(GameState.Status.PLAYING)

func initialize_main_menu() -> void:
	var title: Node3D = title_screen_scene.instantiate()
	game_viewport.add_child(title)
	title.camera.make_current()
	GameState.change_game_state(GameState.Status.MENU)





























# --------------------------------------
# internal initialization procedure
# --------------------------------------

func _create_new_dungeon() -> void:
	await WorldGrid.init_grid(64, 64)
	print("grid initialized")
	
	dungeon_generator.generate(1143)
	
func _initialize_player(tile_pos: Vector2i) -> void:
	var player_spawn: Vector2 = WorldGrid.tile_to_world(tile_pos)
	var entity: Entity = EntityManager.spawn_as_player(&"focks", player_spawn)
	CameraController.change_camera_target(entity)
	CameraController.go_instantly_to(entity.global_position)
	WeatherController.change_fog_target(entity)
	
	WorldGrid.hide_map()
	WorldGrid.reveal_from_camera()
	
func _make_test_land() -> void:
	var cell: CellData = CellData.new()
	cell.terrain = CellType.TerrainType.GROUND
	WorldGrid.set_rectangle(Vector2i(0, 0), Vector2i(64, 64), cell)
	
func _initialize_anthurium(tile_pos: Vector2i) -> void:
	EntityManager.spawn_on_tile(&"test_tree", tile_pos)
	
func _initialize_debug_spawns() -> void:
	EntityManager.spawn_safely(&"bimpy", Vector2i(100, 150))
	EntityManager.spawn_safely(&"meat_shank", Vector2i(200, 150))

	#for i in range(600):
		#var pos: Vector2 = Vector2(randf_range(0, 1000), randf_range(0, 1000))
		#EntityManager.spawn_safely(&"arcbimpy", pos)
		
	#for i in range(15):
		#var pos: Vector2 = Vector2(randf_range(100, 1000), randf_range(100, 550))
		#EntityManager.spawn_safely(&"bimpy", pos)
	#
	#EntityManager.spawn_on_tile(&"smiley_guy", Vector2i(15, 15))
	#EntityManager.spawn_on_tile(&"portal", Vector2i(17, 16))
	#
	#EntityManager.spawn_safely(&"bimpy", Vector2i(100, 150))
	#EntityManager.spawn_safely(&"dcube_beta", Vector2i(200, 150))
	#EntityManager.spawn_on_tile(&"dcube_alpha", Vector2i(15, 4))
	#EntityManager.spawn_safely(&"dcube_beta", Vector2i(700, 500))
	#EntityManager.spawn_safely(&"ecube_beta", Vector2i(500, 150))
	#EntityManager.spawn_safely(&"ecube_gamma", Vector2i(550, 150))
	#EntityManager.spawn_safely(&"ecube_gamma", Vector2i(500, 200))
	#EntityManager.spawn_safely(&"ecube_gamma", Vector2i(450, 200))
	#EntityManager.spawn_safely(&"arcbimpy", Vector2i(100, 125))
	
func _initialize_tree() -> void:
	var container: Node2D = Node2D.new()
	container.name = "Game Container"
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var camera: Camera2D = Camera2D.new()
	
	world = Node2D.new()
	var weather: WeatherComponent = weather_scene.instantiate() as WeatherComponent
	
	
	var world_renderer: WorldRenderer = WorldRenderer.new()
	world_renderer.tile_set = tile_set
	world_renderer.z_index = -10
	
	var visibility_renderer: VisibilityRenderer = VisibilityRenderer.new()
	visibility_renderer.tile_set = visual_tile_set
	visibility_renderer.z_index = -9
	
	var ysort: Node2D = Node2D.new()
	ysort.y_sort_enabled = true
	ysort.name = "YSort"
	
	
	var background: Polygon2D = Polygon2D.new()
	var background_shape: PackedVector2Array = PackedVector2Array([
		Vector2(-100000, -100000),
		Vector2(-100000, 100000),
		Vector2(100000, 100000),
		Vector2(100000, -100000)
	])
	background.polygon = background_shape
	background.color = Color(0, 0, 0, 1)
	background.z_index = -50
	
	world.add_child(world_renderer)
	world.add_child(visibility_renderer)
	world.add_child(weather)
	world.add_child(ysort)
	world.add_child(background)
	
	container.add_child(camera)
	container.add_child(world)
	
	game_viewport.add_child(container)
	camera.make_current()
	

	
	EventBus.camera_ready.emit(camera)
	
	EventBus.weather_ready.emit(weather)
	EventBus.ysort_ready.emit(ysort)
