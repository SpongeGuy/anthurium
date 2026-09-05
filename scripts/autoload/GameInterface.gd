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

var game_instance_active: bool = false



func start_new_game_instance_with_player() -> void:
	start_new_game_instance()
	_initialize_player(Vector2i(16, 16))
	
	#_make_test_land()
	#

func start_new_game_instance() -> void:
	EventBus.starting_new_game.emit()
	game_instance_active = true
	WorldGrid.init_grid(64, 64)
	DungeonGenerator.generate(1143)
	#EntityManager.spawn_safely(&"anthurium_heart", Vector2(300, 300), false)
	EntityManager.spawn_safely(&"smiley_guy", Vector2(400, 300), false)
	EntityManager.spawn_safely(&"meat_shank", Vector2i(200, 150), false)
	EntityManager.spawn_safely(&"meat_shank", Vector2i(200, 190), false)
	#EntityManager.spawn_safely(&"portal", Vector2(300, 400), false)
	#_initialize_debug_spawns()

# --------------------------------------
# internal initialization procedure
# --------------------------------------
	
	
func _initialize_player(tile_pos: Vector2i) -> void:
	var player_spawn: Vector2 = WorldGrid.tile_to_world(tile_pos)
	var entity: Entity = EntityManager.spawn_as_player(&"focks", player_spawn)
	CameraController.change_camera_target(entity)
	CameraController.go_instantly_to(entity.global_position)
	
	await get_tree().process_frame
	
	
func _make_test_land() -> void:
	var cell: CellData = CellData.new()
	cell.terrain = CellType.TerrainType.GROUND
	WorldGrid.set_rectangle(Vector2i(0, 0), Vector2i(64, 64), cell)
	
func _initialize_anthurium(tile_pos: Vector2i) -> void:
	EntityManager.spawn_on_tile(&"test_tree", tile_pos)
	
func _initialize_debug_spawns() -> void:
	EntityManager.spawn_safely(&"bimpy", Vector2i(100, 150), false)
	
	

	for i in range(15):
		var pos: Vector2 = Vector2(randf_range(0, 1000), randf_range(0, 1000))
		EntityManager.spawn_safely(&"arcbimpy", pos, false)
		
	for i in range(15):
		var pos: Vector2 = Vector2(randf_range(100, 1000), randf_range(100, 550))
		EntityManager.spawn_safely(&"bimpy", pos, false)
	
	
	EntityManager.spawn_safely(&"bimpy", Vector2i(100, 150), false)
	EntityManager.spawn_safely(&"dcube_beta", Vector2i(200, 150), false)
	EntityManager.spawn_safely(&"dcube_beta", Vector2i(700, 500), false)
	EntityManager.spawn_safely(&"ecube_beta", Vector2i(500, 150), false)
	EntityManager.spawn_safely(&"ecube_gamma", Vector2i(550, 150), false)
	EntityManager.spawn_safely(&"ecube_gamma", Vector2i(500, 200), false)
	EntityManager.spawn_safely(&"ecube_gamma", Vector2i(450, 200), false)
	EntityManager.spawn_safely(&"arcbimpy", Vector2i(100, 125), false)
	
