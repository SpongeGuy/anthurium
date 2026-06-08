# SoundManager.gd — add as Autoload
extends Node

const SAMPLE_RATE := 22050
const POOL_SIZE   := 8  # simultaneous sounds

var _players: Array[AudioStreamPlayer] = []
var _pool_idx := 0

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

# --- Public API -----------------------------------------------------------

func play(params: Dictionary) -> void:
	var wav := _generate(params)
	var player := _players[_pool_idx % POOL_SIZE]
	_pool_idx += 1
	player.stream = wav
	player.play()

# Convenience presets — randomise within ranges for variation
func play_shoot() -> void:
	play({
		"wave":       0,                          # square
		"freq":       randf_range(400.0, 600.0),
		"freq_slide": randf_range(-300.0, -600.0),
		"duty":       randf_range(0.3, 0.6),
		"attack":     0.0,
		"sustain":    0.05,
		"decay":      randf_range(0.1, 0.2),
	})

func play_explosion() -> void:
	play({
		"wave":    3,                             # noise
		"freq":    randf_range(80.0, 180.0),
		"attack":  0.0,
		"sustain": randf_range(0.05, 0.1),
		"punch":   randf_range(0.3, 0.6),
		"decay":   randf_range(0.3, 0.6),
	})

func play_pickup() -> void:
	play({
		"wave":       2,                          # sine
		"freq":       randf_range(500.0, 700.0),
		"freq_slide": randf_range(200.0, 400.0),
		"attack":     0.0,
		"sustain":    0.05,
		"decay":      0.15,
	})
	
func play_random() -> void:
	play({
		"wave": randi_range(0, 4),
		"freq": randf_range(80.0, 1200.0),
		"freq_slide": randf_range(-600.0, 600.0),
		"duty": randf_range(0.2, 0.8),
		"attack": randf_range(0.0, 0.1),
		"sustain": randf_range(0.03, 0.25),
		"punch": randf_range(0.0, 0.8),
		"decay": randf_range(0.1, 0.7),
		"volume": randf_range(0.5, 0.95),
	})
		

# --- Synthesis engine -----------------------------------------------------

static func _generate(p: Dictionary) -> AudioStreamWAV:
	var wave_type: int   = p.get("wave",       0)
	var freq: float      = p.get("freq",       440.0)
	var freq_slide: float = p.get("freq_slide", 0.0)   # Hz/sec
	var duty: float      = p.get("duty",       0.5)

	var attack: float    = p.get("attack",     0.0)
	var sustain: float   = p.get("sustain",    0.1)
	var punch: float     = p.get("punch",      0.0)   # volume boost mid-sustain
	var decay: float     = p.get("decay",      0.3)
	var volume: float    = p.get("volume",     0.7)

	var total_time := attack + sustain + decay
	var num_samples := int(SAMPLE_RATE * total_time) + 1

	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)

	var phase := 0.0
	var noise_sample := 0.0
	var noise_phase  := 0

	for i in num_samples:
		var t := float(i) / SAMPLE_RATE

		# Envelope
		var env := 0.0
		if t < attack:
			env = t / attack if attack > 0.0 else 1.0
		elif t < attack + sustain:
			env = 1.0 + punch * ((t - attack) / sustain)
		else:
			env = 1.0 - (t - attack - sustain) / decay
		env = clamp(env, 0.0, 2.0)

		# Frequency with slide
		var cur_freq := maxf(1.0, freq + freq_slide * t)
		phase = fmod(phase + cur_freq / SAMPLE_RATE, 1.0)

		# Oscillator
		var s := 0.0
		match wave_type:
			0:  # Square
				s = 1.0 if phase < duty else -1.0
			1:  # Sawtooth
				s = phase * 2.0 - 1.0
			2:  # Sine
				s = sin(phase * TAU)
			3:  # Noise — hold each sample for a bit (lo-fi)
				noise_phase += 1
				if noise_phase >= int(SAMPLE_RATE / cur_freq):
					noise_phase = 0
					noise_sample = randf_range(-1.0, 1.0)
				s = noise_sample
			4:  # Triangle
				s = 1.0 - abs(phase - 0.5) * 4.0

		var val := int(clamp(s * env * volume * 32767.0, -32768.0, 32767.0))
		bytes[i * 2]     = val & 0xFF
		bytes[i * 2 + 1] = (val >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format   = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo   = false
	wav.data     = bytes
	return wav
