class_name WaveSequence
extends Resource

@export var scripted_waves: Array[WaveDefinition] = []
@export var generator: WaveGenerator # null = no procedural fallback!
@export var generated_wave_count: int = 0
@export var endless: bool = false

func get_wave(wave_value: int) -> WaveDefinition:
	if wave_value < scripted_waves.size():
		return scripted_waves[wave_value]
	if generator and (endless or wave_value < scripted_waves.size() + generated_wave_count):
		return generator.generate_wave(wave_value)
	return null

func is_exhausted(wave_value: int) -> bool:
	if endless:
		return false
	return get_wave(wave_value) == null
