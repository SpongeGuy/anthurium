extends Node
# GameInterface autoload

const MAIN_POOL: StringName = &"main"

var wave_runners: Dictionary = {} # StringName pool_id -> WaveRunner

var main_sequences: Array[WaveSequence] = []
var plant_sequences: Array[WaveSequence] = []

var current_level: int = 0

func _process(delta: float) -> void:
	for runner: WaveRunner in wave_runners.values():
		runner.process(delta)

func start_level(value: int) -> void:
	current_level = value
	_teardown_current_level()

	var level_rng: RandomNumberGenerator = RunRng.get_stream("level_%d" % current_level)
	WorldGrid.init_grid(level_rng.randi_range(8, 32), level_rng.randi_range(8, 32))
	DungeonGenerator.generate(level_rng)

	_activate_wave_runner(MAIN_POOL, main_sequences[current_level], true)
	_activate_wave_runner(&"plants", plant_sequences[current_level], false)

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
