extends Node
# GameInterface autoload

const MAIN_POOL: StringName = &"main"

var wave_runners: Dictionary[StringName, WaveRunner] = {}
var levels: Array[LevelDefinition] = [
	load("uid://e4wghocsr5ug"),
	load("uid://e4wghocsr5ug"),
	load("uid://e4wghocsr5ug"),
	load("uid://e4wghocsr5ug"),
	load("uid://e4wghocsr5ug"),
	load("uid://e4wghocsr5ug"),
	load("uid://e4wghocsr5ug"),
	load("uid://e4wghocsr5ug"),
	load("uid://e4wghocsr5ug"),
	load("uid://e4wghocsr5ug"),
	load("uid://e4wghocsr5ug"),
	load("uid://e4wghocsr5ug"),
	load("uid://e4wghocsr5ug"),
	]

var current_level: int = 0
var time: float = 0.0
var run_active: bool = false

func _process(delta: float) -> void:
	for runner: WaveRunner in wave_runners.values():
		runner.process(delta)
	
	if run_active:
		time += delta

func start_new_run(at_level: int, seed: int) -> void:
	run_active = true
	time = 0
	current_level = at_level
	RunRng.start_run(seed)
	start_level(current_level)

func start_daily_run() -> void:
	start_new_run(0, daily_seed())

func daily_seed() -> int:
	var d: Dictionary = Time.get_date_dict_from_system(true) # UTC: same day for everyone
	return d.year * 10000 + d.month * 100 + d.day # e.g. 20260921


func finish_run() -> void:
	run_active = false

func start_level(value: int) -> void:
	current_level = value
	_teardown_current_level()
	RunRng.start_level(current_level)
	
	var level_rng: RandomNumberGenerator = RunRng.get_stream("level_%d" % current_level)
	WorldGrid.init_grid(level_rng.randi_range(8, 32), level_rng.randi_range(8, 32))
	DungeonGenerator.generate(level_rng)
	
	if current_level >= levels.size():
		Log.error("No LevelDefinition for level %d" % current_level)
		return
	
	var level_def: LevelDefinition = levels[current_level]
	for pool_id: StringName in level_def.pool_sequences:
		_activate_wave_runner(pool_id, level_def.pool_sequences[pool_id], pool_id == MAIN_POOL)

func _activate_wave_runner(pool_id: StringName, sequence: WaveSequence, drives_level: bool) -> void:
	var runner: WaveRunner = WaveRunner.new(sequence, "level_%d_%s" % [current_level, pool_id])
	wave_runners[pool_id] = runner
	if drives_level:
		runner.sequence_complete.connect(_on_main_sequence_complete, CONNECT_ONE_SHOT)
	runner.start()

func _teardown_current_level() -> void:
	wave_runners.clear() # RefCounted, no explicit disconnects needed
	EntityManager.destroy_all_entities()

func _on_main_sequence_complete() -> void:
	start_level(current_level + 1)
