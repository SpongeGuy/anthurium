## Autoload: GameInterface
##
## Orchestrates a single run of the game itself (as opposed to
## [AppController], which orchestrates the surrounding app shell): resets and
## generates the world, seeds initial entities, spawns and hands off the
## player, and tracks run-scoped score state.
extends Node

# -----------------------------------------------------------
# orchestrates the game
# utilizes all system nodes
# -----------------------------------------------------------

## Gameplay tileset, currently unused directly in this script's reachable
## code but loaded for use elsewhere.
var tile_set: TileSet = load("uid://ofx275c8vgy4")
## Visual/decorative tileset, currently unused directly in this script's
## reachable code but loaded for use elsewhere.
var visual_tile_set: TileSet = load("uid://b43hq6wx88hsl")


## Current run's Opal score.
var opal_score: int = 0
## Current run's Aura score.
var aura_score: int = 0
## Every anthurium core entity currently tracked this run.
var anthurium_cores: Array[Entity]
## Reference to the active world node, currently unused beyond its
## declaration.
var world: Node2D

## Whether a game instance is currently active (set by
## [method start_new_game_instance]).
var game_instance_active: bool = false



## Starts a fresh game instance (see [method start_new_game_instance]) and
## additionally spawns and hands control to a player entity at tile
## [code](16, 16)[/code].
func start_new_game_instance_with_player() -> void:
	start_new_game_instance()
	_initialize_player(Vector2i(5, 5))
	
	#_make_test_land()
	#_spawn_losers()

## Resets and generates a new world: emits
## [signal EventBus.starting_new_game], marks the instance active,
## initializes [WorldGrid] and runs [DungeonGenerator], and spawns the
## initial set of non-player entities.
func start_new_game_instance() -> void:
	EventBus.starting_new_game.emit()
	game_instance_active = true
	WorldGrid.init_grid(16, 16)
	DungeonGenerator.generate()
	
	_make_test_land()
	Waver.configure(_build_board_config())
	Waver.wave_complete.connect(_on_wave_complete)
	Waver.start_next_wave()
	
func start_new_demo_instance() -> void:
	start_new_game_instance()
	
	#_spawn_losers()
	

func _on_wave_complete(wave_index: int) -> void:
	Waver.start_next_wave()
	
func _build_board_config() -> WaveBoardConfig:
	var cfg: WaveBoardConfig = WaveBoardConfig.new()
	cfg.max_waves = randi_range(3, 6)
	return cfg
	

# --------------------------------------
# internal initialization procedure
# --------------------------------------
	
func _spawn_losers() -> void:
	EntityManager.spawn_safely(&"blom_bulb", Vector2(300, 300), false)
	EntityManager.spawn_safely(&"meat_shank", Vector2(250, 300), false)
	EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	
## Spawns a [code]&"focks"[/code] entity as the player at [param tile_pos]
## and snaps the camera to it.
func _initialize_player(tile_pos: Vector2i) -> void:
	var player_spawn: Vector2 = WorldGrid.tile_to_world(tile_pos)
	var entity: Entity = EntityManager.spawn_as_player(&"focks", player_spawn)
	CameraController.set_camera_target(entity)
	CameraController.go_instantly_to(entity.global_position)
	
	await get_tree().process_frame
	
	
## Test helper for flooding a rectangular region with ground terrain.
## References an outdated [WorldGrid] API ([code]set_rectangle[/code]) and is
## not currently wired up to run.
func _make_test_land() -> void:
	for x in range(WorldGrid.width):
		for y in range(WorldGrid.height):
			WorldGrid.set_cell_type(Vector2i(x, y), "ground_soil")
	
## Spawns a [code]&"test_tree"[/code] entity on [param tile_pos]. Reserved
## for anthurium-specific world setup.
func _initialize_anthurium(tile_pos: Vector2i) -> void:
	EntityManager.spawn_on_tile(&"test_tree", tile_pos)
	
	

	

func _initialize_debug_spawns() -> void:
	EntityManager.spawn_safely(&"bimpy", Vector2i(100, 150), false)
	
	EntityManager.spawn_safely(&"anthurium_heart", Vector2(300, 300), false)
	EntityManager.spawn_safely(&"smiley_guy", Vector2(400, 300), false)
	EntityManager.spawn_safely(&"meat_shank", Vector2i(200, 150), false)
	EntityManager.spawn_safely(&"meat_shank", Vector2i(200, 190), false)
	EntityManager.spawn_safely(&"bimpy", Vector2i(100, 150), false)
	EntityManager.spawn_safely(&"portal", Vector2(300, 400), false)

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
