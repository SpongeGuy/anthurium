class_name WaveRunner
extends RefCounted

signal wave_started(runtime: WaveRuntime)
signal sequence_complete

var sequence: WaveSequence
var wave_value: int = 0
var current_runtime: WaveRuntime

var _rng_stream_key: String

func _init(seq: WaveSequence, rng_stream_key: String, starting_escalation: int) -> void:
	sequence = seq
	_rng_stream_key = rng_stream_key
	wave_value = starting_escalation

func start() -> void:
	_start_wave(wave_value)

func process(delta: float) -> void:
	if current_runtime:
		current_runtime.process(delta)

func _start_wave(value: int) -> void:
	var def: WaveDefinition = sequence.get_wave(value)
	if def == null:
		sequence_complete.emit()
		return
	current_runtime = WaveRuntime.new(def, "%s_w%d" % [_rng_stream_key, value])
	current_runtime.wave_complete.connect(_on_wave_complete, CONNECT_ONE_SHOT)
	wave_started.emit(current_runtime)
	current_runtime.start()

func _on_wave_complete() -> void:
	wave_value += 1
	GameInterface.escalation = wave_value
	if sequence.is_exhausted(wave_value):
		sequence_complete.emit()
	else:
		_start_wave(wave_value)
