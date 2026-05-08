extends Node
class_name GameMaster

# -----------------------------------------------------------
# orchestrates the game
# utilizes all system nodes
# -----------------------------------------------------------

@export var game_canvas: CanvasLayer
var weather_scene: PackedScene = load("res://scenes/systems/weather.tscn")
var tile_set: TileSet = load("res://assets/tilesets/prototype.tres")
var visual_tile_set: TileSet = load("res://assets/tilesets/visual.tres")

@export var dungeon_generator: DungeonGenerator

var world: Node2D

func _ready() -> void:
	call_deferred("initialize_game")
	

func initialize_game() -> void:
	EventBus.starting_new_game.emit()
	GameState.change_game_state(GameState.Status.LOADING)
	
	initialize_tree()
	WorldGrid.init_grid(64, 64)
	print("grid initialized")
	
	var wall: CellData = CellData.new()
	wall.terrain = CellData.TerrainType.WALL
	var ground: CellData = CellData.new()
	ground.terrain = CellData.TerrainType.GROUND
	
	dungeon_generator.generate()
	
	
	
	
	var player_spawn: Vector2 = Vector2(300, 50)
	var anthurium_spawn: Vector2 = Vector2(512, 512)
	#WorldGrid.set_rectangle(Vector2i(0,0), Vector2i(80, 46), ground)
	#WorldGrid.set_cell(Vector2i(11, 11), ground)
	
	#
	for i in range(15):
		var pos: Vector2 = Vector2(randf_range(100, 550), randf_range(100, 550))
		EntityManager.spawn_safely(&"arcbimpy", pos)
		
	for i in range(5):
		var pos: Vector2 = Vector2(randf_range(100, 1000), randf_range(100, 550))
		EntityManager.spawn_safely(&"bimpy", pos)
	
	
	await get_tree().create_timer(1).timeout
	
	EntityManager.spawn_as_player(&"ecube_beta", player_spawn)
	var gx: int = 5
	var gy: int = 5
	for x in range(gx):
		for y in range(gy):
			EntityManager.spawn_on_tile(&"anthurium_grass", Vector2i(x, y))
			
	EntityManager.spawn_on_tile(&"anthurium_grass", Vector2(5, 5))
	EntityManager.spawn_on_tile(&"anthurium_growth_node", Vector2i(15, 3))
	EntityManager.spawn_safely(&"bimpy", Vector2i(100, 150))
	EntityManager.spawn_safely(&"dcube_beta", Vector2i(200, 150))
	EntityManager.spawn_on_tile(&"dcube_alpha", Vector2i(15, 4))
	EntityManager.spawn_safely(&"dcube_beta", Vector2i(700, 500))
	EntityManager.spawn_safely(&"ecube_beta", Vector2i(500, 150))
	EntityManager.spawn_safely(&"ecube_gamma", Vector2i(550, 150))
	EntityManager.spawn_safely(&"ecube_gamma", Vector2i(500, 200))
	EntityManager.spawn_safely(&"arcbimpy", Vector2i(100, 125))
	WorldGrid.hide_map()
	WorldGrid.reveal_from_player()
	GameState.change_game_state(GameState.Status.PLAYING)




func initialize_tree() -> void:
	var sub_viewport_container: SubViewportContainer = SubViewportContainer.new()
	sub_viewport_container.size = Vector2(640, 360)
	
	
	var sub_viewport: SubViewport = SubViewport.new()
	sub_viewport.size = Vector2(640, 360)
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.handle_input_locally = false
	sub_viewport.snap_2d_transforms_to_pixel = true
	sub_viewport.snap_2d_vertices_to_pixel = true
	
	HUDParticleController._instance.viewport_container = sub_viewport_container
	HUDParticleController._instance.game_viewport = sub_viewport
	
	sub_viewport_container.add_child(sub_viewport)
	game_canvas.add_child(sub_viewport_container)
	
	
	var container: Node2D = Node2D.new()
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
	
	sub_viewport.add_child(container)
	print("the trees")
	
	EventBus.camera_ready.emit(camera)
	EventBus.weather_ready.emit(weather)
	EventBus.ysort_ready.emit(ysort)


