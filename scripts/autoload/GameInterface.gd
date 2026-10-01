extends Node
# GameInterface autoload

## While [AppController] orchestrates the greater systems of the game (user interface [UIStage]s etc), GameInterface orchestrates the game world and its levels.
## As long as a [member level_sequence] is defined, [method start_new_run] is able to be called safely from [AppController].
## Takes in a [LevelSequence] to pull [LevelDefinition]s for each [member current_level], set in [method start_level].[br]

const MAIN_POOL: StringName = &"main"

var level_sequence: LevelSequence = load("uid://3e6jt2dwi4wd")
var wave_runners: Dictionary[StringName, WaveRunner] = {}

var current_level: int = 0
var time: float = 0.0
var run_active: bool = false
## Used in level generation to choose what kind of creatures are spawned. The higher the escalation, the more likely harder/weirder creatures will spawn.
var escalation: int = 0

var background_mode: bool = true
var process_paused: bool = true

func _ready() -> void:
	EventBus.gate_activated.connect(_on_gate_activated)

func _process(delta: float) -> void:
	if process_paused:
		return
	for runner: WaveRunner in wave_runners.values():
		runner.process(delta)
	
	if run_active:
		time += delta


## A "run" is essentially just a collection of levels which play one after another.
## This function starts the player at a [param level] with an [member escalation] value of 0.
## If [member level_sequence] is null, this will error within [method start_level].
func start_new_run(at_level: int, seed: int) -> void:
	run_active = true
	time = 0
	escalation = 0
	current_level = at_level
	RunRng.start_run(seed)
	start_level(current_level)

func start_daily_run() -> void:
	start_new_run(0, daily_seed())

func daily_seed() -> int:
	# use utc here so its global time
	var d: Dictionary = Time.get_date_dict_from_system(true)
	return d.year * 10000 + d.month * 100 + d.day










func finish_run() -> void:
	run_active = false

## Starts the next level at [param value]. if [member background_mode] is `true`, then this function will also spawn a player entity with a visual effect before doing any processes.
## [member process_paused] is turned on when this function first starts and turned off when the function ends so that the player animation can play.
func start_level(value: int) -> void:
	process_paused = true
	current_level = value
	_teardown_current_level()
	RunRng.start_level(current_level)
	
	var level_def: LevelDefinition = level_sequence.get_level(current_level, escalation)
	_reset_appstate_for_new_level(level_def)
	
	if level_sequence.is_exhausted(current_level, escalation):
		return
	
	for pool_id: StringName in level_def.pool_sequences:
		_activate_wave_runner(pool_id, level_def.pool_sequences[pool_id], pool_id == MAIN_POOL)
	
	_debug_stuff()
	
	if not background_mode:
		await spawn_player("focks")
		
	process_paused = false


## this used to change the camera mode, but i think that the camera mode should only be changed within [AppController]
func spawn_player(entity_name: StringName) -> void:
	UiController.hud.set_state(UIHUD.State.INACTIVE)
	var spawn_pos: Vector2i = WorldGrid.random_spawn_tile(RunRng.get_stream("dungeon"))
	WorldGrid.reveal_from(spawn_pos)
	CameraController.go_instantly_to(WorldGrid.tile_to_world(spawn_pos))
	var scriptsprite: ScriptableSprite = ScriptableSprite.new("focks", WorldGrid.tile_to_world(spawn_pos), SpatialUtil.get_random_offscreen_position(CameraController.camera), 2.5, 0)
	AppController.container_2d.add_child(scriptsprite)
	await scriptsprite.finished_animating
	UiController.hud.set_state(UIHUD.State.BAR)
	EntityManager.simple_spawn_tile("focks", spawn_pos, true)
	
## Spawns in a [ScriptableSprite] of the player and spins them toward the spawn point. Purely a visual effect.
func _sprite_effect_player(position: Vector2, duration: float) -> void:
	UiController.hud.set_state(UIHUD.State.INACTIVE)
	var scriptsprite: ScriptableSprite = ScriptableSprite.new(PlayerManager.player.basename, position, PlayerManager.player.global_position, duration, 1)
	PlayerManager.player.queue_free()
	AppController.container_2d.add_child(scriptsprite)
	await scriptsprite.finished_animating


func _reset_appstate_for_new_level(level_def: LevelDefinition) -> void:
	EntityManager.destroy_all_entities()
	CameraController.target = null
	var level_rng: RandomNumberGenerator = RunRng.get_stream("level_%d" % current_level)
	WorldGrid.init_grid(level_rng.randi_range(8, 32), level_rng.randi_range(8, 32))
	TerrainManager.generate(level_def.terrain_generator, level_rng, level_def.ground_type, level_def.wall_type, level_def.indestructible_type, level_def.soft_wall_type)
	WorldGrid.hide_map()
	UiController.hud.update_level_text()









func _activate_wave_runner(pool_id: StringName, sequence: WaveSequence, drives_level: bool) -> void:
	var runner: WaveRunner = WaveRunner.new(sequence, "level_%d_%s" % [current_level, pool_id], escalation)
	wave_runners[pool_id] = runner
	if drives_level:
		runner.sequence_complete.connect(_on_main_sequence_complete, CONNECT_ONE_SHOT)
	runner.start()


func _teardown_current_level() -> void:
	wave_runners.clear() # RefCounted, no explicit disconnects needed
	EntityManager.destroy_all_entities()

func _debug_stuff() -> void:
	EntityManager.simple_spawn_tile("key", WorldGrid.random_spawn_tile(RunRng.get_stream("dungeon")))
	EntityManager.simple_spawn_tile("gate", WorldGrid.random_spawn_tile(RunRng.get_stream("dungeon")))

func _on_main_sequence_complete() -> void:
	start_level(current_level + 1)



func _on_gate_activated(position: Vector2) -> void:
	await _sprite_effect_player(position, 1)
	start_level(current_level + 1)
