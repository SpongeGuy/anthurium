extends Node


var run_seed: int = 0
var level: int = 0
var _streams: Dictionary[StringName, RandomNumberGenerator] = {}

func start_run(new_seed: int) -> void:
	run_seed = new_seed
	level = 0
	_reseed_all()
	
func start_level(new_level: int) -> void:
	level = new_level
	_reseed_all()
	
## seed for anything that wants its own RNG
func derive_seed(stream_name: StringName) -> int:
	return hash([run_seed, level, stream_name])
	
func get_stream(stream_name: StringName) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = _streams.get(stream_name)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.seed = derive_seed(stream_name)
		_streams[stream_name] = rng
	return rng
	
func _reseed_all() -> void:
	# ressed in place so cached references stay valid.
	# setting .seed resets the state
	for stream_name in _streams:
		_streams[stream_name].seed = derive_seed(stream_name)
		
	# safety net: stragglers using the global RNG become at least run-dependent
	seed(derive_seed(&"global_fallback"))
