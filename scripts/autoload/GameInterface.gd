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

## Whether a game instance is currently active (set by
## [method start_new_game_instance]).
var game_instance_active: bool = false

var main_creatures_pool: SpawnManager.SpawnPool
var plants_pool: SpawnManager.SpawnPool

var level: int = 0

var time: float = 0.0

const ENDLESS_WAVES: WaveSet = preload("uid://cem2qd3vmjd3o")
const NORMAL_WAVES: WaveSet = preload('uid://dvioo24e0vs44')
const PLANT_WAVES: WaveSet = preload("uid://c3yueget5go6v")

func _ready() -> void:
	SpawnManager.wave_complete.connect(_on_wave_complete)
	SpawnManager.all_waves_complete.connect(_on_all_waves_complete)
	
func _process(delta: float) -> void:
	time += delta

func reset(new_seed: int) -> void:
	game_instance_active = false
	level = 0
	RunRng.start_run(new_seed)

func start_new_run(new_seed: int) -> void:
	time = 0.0
	reset(new_seed)
	start_next_level()

func start_daily_run() -> void:
	start_new_run(daily_seed())

func daily_seed() -> int:
	var d: Dictionary = Time.get_date_dict_from_system(true) # UTC: same day for everyone
	return d.year * 10000 + d.month * 100 + d.day # e.g. 20260921

func start_next_level() -> void:
	SpawnManager.clear_pools()
	level += 1
	RunRng.start_level(level)
	start_new_game_instance()
	_initialize_player(WorldGrid.get_random_ground_tile(RunRng.get_stream(&"player_spawn")))

	var main_waves: Array[SpawnWave] = _waves_for_level(level)
	if main_waves.is_empty():
		# empty pool -> instant all_waves_complete -> start_next_level -> infinite recursion
		push_error("Main pool has no waves for level %d" % level)
		return
	main_creatures_pool = SpawnManager.create_new_pool(main_waves, level, RunRng.derive_seed(&"pool_main"))
	plants_pool = SpawnManager.create_new_pool(PLANT_WAVES.waves, level, RunRng.derive_seed(&"pool_plants"))
	SpawnManager.start_next_wave(main_creatures_pool)
	SpawnManager.start_next_wave(plants_pool)

func _waves_for_level(lvl: int) -> Array[SpawnWave]:
	var waves: Array[SpawnWave] = []
	waves.assign(ENDLESS_WAVES.waves)
	return waves

func _on_wave_complete(pool: SpawnManager.SpawnPool, _wave_index: int) -> void:
	await get_tree().create_timer(2.0).timeout
	if pool in SpawnManager.active_pools:
		SpawnManager.start_next_wave(pool)
		
func _on_all_waves_complete(pool: SpawnManager.SpawnPool) -> void:
	if not pool == main_creatures_pool:
		return
	start_next_level()

func _initialize_player(tile_pos: Vector2i) -> void: # dropped the no-op await
	var player_spawn: Vector2 = WorldGrid.tile_to_world(tile_pos)
	var entity: Entity = EntityManager.spawn_as_player(&"focks", player_spawn)
	CameraController.set_camera_target(entity)
	CameraController.go_instantly_to(entity.global_position)




## Resets and generates a new world: emits
## [signal EventBus.starting_new_game], marks the instance active,
## initializes [WorldGrid] and runs [DungeonGenerator], and spawns the
## initial set of non-player entities.
func start_new_game_instance() -> void:
	EventBus.starting_new_game.emit()
	game_instance_active = true
	WorldGrid.init_grid(16, 16)
	_make_test_land()
	DungeonGenerator._enforce_border()
	#DungeonGenerator.generate(RunRng.get_stream(&"terrain_generation"))
	
	
	
func start_new_demo_instance() -> void:
	start_new_game_instance()
	_spawn_losers()
	



	
	

	

# --------------------------------------
# internal initialization procedure
# --------------------------------------
	
func _spawn_losers() -> void:
	#EntityManager.spawn_safely(&"blom_bulb", Vector2(300, 300), false)
	#EntityManager.spawn_safely(&"meat_shank", Vector2(250, 300), false)
	#EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	#EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	#EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	#EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	#EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	#EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	#EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	#EntityManager.spawn_safely(&"blimble", Vector2(250, 300), false)
	EntityManager.spawn_safely(&"maw", Vector2(50, 50))
	EntityManager.spawn_safely(&"splitmaw", Vector2(50, 50))
	EntityManager.spawn_safely(&"blargle", Vector2(50, 50))
	EntityManager.spawn_safely(&"gnawlfy", Vector2(50, 50))
	EntityManager.spawn_safely(&"klicklack", Vector2(50, 50))
	EntityManager.spawn_safely(&"porcule", Vector2(50, 50))
	EntityManager.spawn_safely(&"hardhat", Vector2(50, 50))
	EntityManager.spawn_safely(&"skippa", Vector2(50, 50))

	
	
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
