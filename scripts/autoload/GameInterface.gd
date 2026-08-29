extends Node

# -----------------------------------------------------------
# orchestrates the game
# utilizes all system nodes
# -----------------------------------------------------------

var tile_set: TileSet = load("uid://ofx275c8vgy4")
var visual_tile_set: TileSet = load("uid://b43hq6wx88hsl")


var opal_score: int = 0
var aura_score: int = 0
var anthurium_cores: Array[Entity]
var world: Node2D



func start_new_game_instance() -> void:
	EventBus.starting_new_game.emit()
	WorldGrid.init_grid(64, 64)
	DungeonGenerator.generate(1143)
	_initialize_player(Vector2i(16, 16))
	EntityManager.spawn_safely(&"anthurium_heart", Vector2(100, 100))
	#_initialize_debug_spawns()
	#_make_test_land()
	#1143



# --------------------------------------
# internal initialization procedure
# --------------------------------------
	
	
func _initialize_player(tile_pos: Vector2i) -> void:
	var player_spawn: Vector2 = WorldGrid.tile_to_world(tile_pos)
	var entity: Entity = EntityManager.spawn_as_player(&"focks", player_spawn)
	CameraController.change_camera_target(entity)
	CameraController.go_instantly_to(entity.global_position)
	
	await get_tree().process_frame
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
	EntityManager.spawn_safely(&"meat_shank", Vector2i(200, 190))

	for i in range(15):
		var pos: Vector2 = Vector2(randf_range(0, 1000), randf_range(0, 1000))
		EntityManager.spawn_safely(&"arcbimpy", pos)
		
	for i in range(15):
		var pos: Vector2 = Vector2(randf_range(100, 1000), randf_range(100, 550))
		EntityManager.spawn_safely(&"bimpy", pos)
	
	EntityManager.spawn_on_tile(&"smiley_guy", Vector2i(15, 15))
	EntityManager.spawn_on_tile(&"portal", Vector2i(17, 16))
	
	EntityManager.spawn_safely(&"bimpy", Vector2i(100, 150))
	EntityManager.spawn_safely(&"dcube_beta", Vector2i(200, 150))
	EntityManager.spawn_on_tile(&"dcube_alpha", Vector2i(15, 4))
	EntityManager.spawn_safely(&"dcube_beta", Vector2i(700, 500))
	EntityManager.spawn_safely(&"ecube_beta", Vector2i(500, 150))
	EntityManager.spawn_safely(&"ecube_gamma", Vector2i(550, 150))
	EntityManager.spawn_safely(&"ecube_gamma", Vector2i(500, 200))
	EntityManager.spawn_safely(&"ecube_gamma", Vector2i(450, 200))
	EntityManager.spawn_safely(&"arcbimpy", Vector2i(100, 125))
	
