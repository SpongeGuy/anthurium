@tool
extends Resource
class_name VoiceProfile

# ─────────────────────────────────────────────────────────────────────────────
#  INSPECTOR PREVIEW BUTTON  (Godot 4.3+)
# ─────────────────────────────────────────────────────────────────────────────

@export_tool_button("Preview Sound") var _preview_action = _preview_sound
@export_group("Randomize")
@export_tool_button("Randomize Params") var _randomize_action  = _randomize_params


# ─────────────────────────────────────────────────────────────────────────────
#  MASTER
# ─────────────────────────────────────────────────────────────────────────────
@export_group("Master")

## Overall output volume. Squared internally before use, so small values drop off sharply.
@export_range(0.0, 1.0, 0.001) var master_volume: float = 0.5
## Additive variance applied to master_volume each play. Clamped to [0, 1].
@export_range(0.0, 1.0, 0.001) var master_volume_variance: float = 0.0


# ─────────────────────────────────────────────────────────────────────────────
#  WAVE TYPE
# ─────────────────────────────────────────────────────────────────────────────
@export_group("Wave Type")

## The oscillator shape. Fixed per voice — no variance field.
## 0=Square  1=Saw  2=Sine  3=White Noise  4=Triangle
## 5=Rasp    6=Tan  7=Whistle  8=Breaker  9=Bitnoise  10=FM Synth  11=Voice
@export_enum(
	"Square:0", "Saw:1", "Sine:2", "White Noise:3", "Triangle:4",
	"Rasp:5", "Tan:6", "Whistle:7", "Breaker:8", "Bitnoise:9",
	"FM Synth:10", "Voice:11"
) var wave_type: int = 0


# ─────────────────────────────────────────────────────────────────────────────
#  ENVELOPE
# ─────────────────────────────────────────────────────────────────────────────
@export_group("Envelope")

## Time for the sound to fade in from silence. Squared internally (0 = instant attack).
@export_range(0.0, 1.0, 0.001) var attack_time: float = 0.0
@export_range(0.0, 1.0, 0.001) var attack_time_variance: float = 0.0

## Duration of the held peak volume. Must be > 0 (enforced with a 0.01 minimum).
@export_range(0.0, 1.0, 0.001) var sustain_time: float = 0.3
@export_range(0.0, 1.0, 0.001) var sustain_time_variance: float = 0.0

## Volume boost applied during the sustain stage. 0 = no punch.
@export_range(0.0, 1.0, 0.001) var sustain_punch: float = 0.0
@export_range(0.0, 1.0, 0.001) var sustain_punch_variance: float = 0.0

## Time for the sound to fade to silence. Squared internally.
@export_range(0.0, 1.0, 0.001) var decay_time: float = 0.4
@export_range(0.0, 1.0, 0.001) var decay_time_variance: float = 0.0

## Dynamic range compression. 0 = off. Higher values squash loud peaks.
@export_range(0.0, 1.0, 0.001) var compression_amount: float = 0.0
@export_range(0.0, 1.0, 0.001) var compression_amount_variance: float = 0.0


# ─────────────────────────────────────────────────────────────────────────────
#  FREQUENCY
# ─────────────────────────────────────────────────────────────────────────────
@export_group("Frequency")

## Starting pitch. Mapped non-linearly; 0.3 ≈ mid-range.
@export_range(0.0, 1.0, 0.001) var frequency_start: float = 0.3
@export_range(0.0, 1.0, 0.001) var frequency_start_variance: float = 0.0

## How fast the pitch slides up (+) or down (-) over the sound's lifetime.
@export_range(-1.0, 1.0, 0.001) var frequency_slide: float = 0.0
@export_range(0.0, 1.0, 0.001) var frequency_slide_variance: float = 0.0

## Acceleration applied to the slide itself (+/- changes slide rate over time).
@export_range(-1.0, 1.0, 0.001) var frequency_acceleration: float = 0.0
@export_range(0.0, 1.0, 0.001) var frequency_acceleration_variance: float = 0.0

## Floor pitch as a fraction of frequency_start. When the slide reaches this, the
## sound mutes if > 0. 0 = no floor.
@export_range(0.0, 1.0, 0.001) var min_frequency: float = 0.0
@export_range(0.0, 1.0, 0.001) var min_frequency_variance: float = 0.0


# ─────────────────────────────────────────────────────────────────────────────
#  VIBRATO
# ─────────────────────────────────────────────────────────────────────────────
@export_group("Vibrato")

## How much the pitch oscillates (tremolo depth).
@export_range(0.0, 1.0, 0.001) var vibrato_depth: float = 0.0
@export_range(0.0, 1.0, 0.001) var vibrato_depth_variance: float = 0.0

## How fast the pitch oscillates.
@export_range(0.0, 1.0, 0.001) var vibrato_speed: float = 0.0
@export_range(0.0, 1.0, 0.001) var vibrato_speed_variance: float = 0.0


# ─────────────────────────────────────────────────────────────────────────────
#  PITCH JUMPS
# ─────────────────────────────────────────────────────────────────────────────
@export_group("Pitch Jumps")

## How often the pitch-jump cycle repeats. 0 = only once.
@export_range(0.0, 1.0, 0.001) var pitch_jump_repeat_speed: float = 0.0
@export_range(0.0, 1.0, 0.001) var pitch_jump_repeat_speed_variance: float = 0.0

## Magnitude of the first pitch jump. Positive = up, negative = down.
@export_range(-1.0, 1.0, 0.001) var pitch_jump_amount: float = 0.0
@export_range(0.0, 1.0, 0.001) var pitch_jump_amount_variance: float = 0.0

## When in the cycle the first jump fires (0 = immediately, 1 = never).
@export_range(0.0, 1.0, 0.001) var pitch_jump_onset_percent: float = 0.0
@export_range(0.0, 1.0, 0.001) var pitch_jump_onset_percent_variance: float = 0.0

## Magnitude of the second pitch jump.
@export_range(-1.0, 1.0, 0.001) var pitch_jump_2_amount: float = 0.0
@export_range(0.0, 1.0, 0.001) var pitch_jump_2_amount_variance: float = 0.0

## When in the cycle the second jump fires.
@export_range(0.0, 1.0, 0.001) var pitch_jump_onset2_percent: float = 0.0
@export_range(0.0, 1.0, 0.001) var pitch_jump_onset2_percent_variance: float = 0.0


# ─────────────────────────────────────────────────────────────────────────────
#  OVERTONES
# ─────────────────────────────────────────────────────────────────────────────
@export_group("Overtones")

## Number of additional harmonic layers (mapped to 0–10 internally). 0 = off (fast path).
@export_range(0.0, 1.0, 0.001) var overtones: float = 0.0
@export_range(0.0, 1.0, 0.001) var overtones_variance: float = 0.0

## How quickly each successive overtone layer fades in amplitude.
@export_range(0.0, 1.0, 0.001) var overtone_falloff: float = 0.0
@export_range(0.0, 1.0, 0.001) var overtone_falloff_variance: float = 0.0


# ─────────────────────────────────────────────────────────────────────────────
#  SQUARE WAVE  (only active when wave_type = 0)
# ─────────────────────────────────────────────────────────────────────────────
@export_group("Square Wave")

## Pulse width / duty cycle. 0 = thin pulse, ~0.5 = full square.
@export_range(0.0, 1.0, 0.001) var square_duty: float = 0.0
@export_range(0.0, 1.0, 0.001) var square_duty_variance: float = 0.0

## Rate at which the duty cycle sweeps over time. Positive = widens, negative = narrows.
@export_range(-1.0, 1.0, 0.001) var duty_sweep: float = 0.0
@export_range(0.0, 1.0, 0.001) var duty_sweep_variance: float = 0.0


# ─────────────────────────────────────────────────────────────────────────────
#  REPEAT
# ─────────────────────────────────────────────────────────────────────────────
@export_group("Repeat")

## How often the synthesis resets (re-triggers the pitch envelope). 0 = no repeat.
@export_range(0.0, 1.0, 0.001) var repeat_speed: float = 0.0
@export_range(0.0, 1.0, 0.001) var repeat_speed_variance: float = 0.0


# ─────────────────────────────────────────────────────────────────────────────
#  FLANGER
# ─────────────────────────────────────────────────────────────────────────────
@export_group("Flanger")

## Delay offset of the flanged copy. Positive/negative controls direction.
@export_range(-1.0, 1.0, 0.001) var flanger_offset: float = 0.0
@export_range(0.0, 1.0, 0.001) var flanger_offset_variance: float = 0.0

## Rate at which the flanger offset changes over time.
@export_range(-1.0, 1.0, 0.001) var flanger_sweep: float = 0.0
@export_range(0.0, 1.0, 0.001) var flanger_sweep_variance: float = 0.0


# ─────────────────────────────────────────────────────────────────────────────
#  LP FILTER
# ─────────────────────────────────────────────────────────────────────────────
@export_group("LP Filter")

## Low-pass filter cutoff. 1.0 = fully open (no filtering). Lower values muffle the sound.
@export_range(0.0, 1.0, 0.001) var lp_filter_cutoff: float = 1.0
@export_range(0.0, 1.0, 0.001) var lp_filter_cutoff_variance: float = 0.0

## How the LP cutoff changes over time. Positive = opens up, negative = closes down.
@export_range(-1.0, 1.0, 0.001) var lp_filter_cutoff_sweep: float = 0.0
@export_range(0.0, 1.0, 0.001) var lp_filter_cutoff_sweep_variance: float = 0.0

## Resonance peak at the cutoff frequency. Higher = more pronounced peak / ringing.
@export_range(0.0, 1.0, 0.001) var lp_filter_resonance: float = 0.0
@export_range(0.0, 1.0, 0.001) var lp_filter_resonance_variance: float = 0.0


# ─────────────────────────────────────────────────────────────────────────────
#  HP FILTER
# ─────────────────────────────────────────────────────────────────────────────
@export_group("HP Filter")

## High-pass filter cutoff. 0.0 = off. Higher values cut more bass.
@export_range(0.0, 1.0, 0.001) var hp_filter_cutoff: float = 0.0
@export_range(0.0, 1.0, 0.001) var hp_filter_cutoff_variance: float = 0.0

## How the HP cutoff changes over time.
@export_range(-1.0, 1.0, 0.001) var hp_filter_cutoff_sweep: float = 0.0
@export_range(0.0, 1.0, 0.001) var hp_filter_cutoff_sweep_variance: float = 0.0


# ─────────────────────────────────────────────────────────────────────────────
#  BIT CRUSH
# ─────────────────────────────────────────────────────────────────────────────
@export_group("Bit Crush")

## Sample-rate reduction / lo-fi degradation. 0 = off, higher = more crushed.
@export_range(0.0, 1.0, 0.001) var bit_crush: float = 0.0
@export_range(0.0, 1.0, 0.001) var bit_crush_variance: float = 0.0

## How the bit-crush intensity changes over time.
@export_range(-1.0, 1.0, 0.001) var bit_crush_sweep: float = 0.0
@export_range(0.0, 1.0, 0.001) var bit_crush_sweep_variance: float = 0.0


# ─────────────────────────────────────────────────────────────────────────────
#  PUBLIC API
# ─────────────────────────────────────────────────────────────────────────────

## Build a param dictionary with variance applied, ready to pass to BfxrSFX.
## Called once per play invocation. Every call returns a freshly randomized dict.
func build_params() -> Dictionary:
	return {
		# ── Master ─────────────────────────────────────────────────────────
		"masterVolume":      _vary(master_volume,      master_volume_variance,      0.0,  1.0),
		"waveType":          wave_type,   # integer — no variance
		# ── Envelope ───────────────────────────────────────────────────────
		"attackTime":        _vary(attack_time,         attack_time_variance,        0.0,  1.0),
		"sustainTime":       _vary(sustain_time,        sustain_time_variance,       0.0,  1.0),
		"sustainPunch":      _vary(sustain_punch,       sustain_punch_variance,      0.0,  1.0),
		"decayTime":         _vary(decay_time,          decay_time_variance,         0.0,  1.0),
		"compressionAmount": _vary(compression_amount,  compression_amount_variance, 0.0,  1.0),
		# ── Frequency ──────────────────────────────────────────────────────
		"frequency_start":               _vary(frequency_start,          frequency_start_variance,          0.0,  1.0),
		"frequency_slide":               _vary(frequency_slide,          frequency_slide_variance,          -1.0, 1.0),
		"frequency_acceleration":        _vary(frequency_acceleration,   frequency_acceleration_variance,   -1.0, 1.0),
		"min_frequency_relative_to_starting_frequency":
										 _vary(min_frequency,            min_frequency_variance,            0.0,  1.0),
		# ── Vibrato ────────────────────────────────────────────────────────
		"vibratoDepth": _vary(vibrato_depth, vibrato_depth_variance, 0.0, 1.0),
		"vibratoSpeed": _vary(vibrato_speed, vibrato_speed_variance, 0.0, 1.0),
		# ── Pitch jumps ────────────────────────────────────────────────────
		"pitch_jump_repeat_speed":   _vary(pitch_jump_repeat_speed,   pitch_jump_repeat_speed_variance,   0.0,  1.0),
		"pitch_jump_amount":         _vary(pitch_jump_amount,         pitch_jump_amount_variance,         -1.0, 1.0),
		"pitch_jump_onset_percent":  _vary(pitch_jump_onset_percent,  pitch_jump_onset_percent_variance,  0.0,  1.0),
		"pitch_jump_2_amount":       _vary(pitch_jump_2_amount,       pitch_jump_2_amount_variance,       -1.0, 1.0),
		"pitch_jump_onset2_percent": _vary(pitch_jump_onset2_percent, pitch_jump_onset2_percent_variance, 0.0,  1.0),
		# ── Overtones ──────────────────────────────────────────────────────
		"overtones":      _vary(overtones,      overtones_variance,      0.0, 1.0),
		"overtoneFalloff": _vary(overtone_falloff, overtone_falloff_variance, 0.0, 1.0),
		# ── Square wave ────────────────────────────────────────────────────
		"squareDuty": _vary(square_duty, square_duty_variance, 0.0,  1.0),
		"dutySweep":  _vary(duty_sweep,  duty_sweep_variance,  -1.0, 1.0),
		# ── Repeat ─────────────────────────────────────────────────────────
		"repeatSpeed": _vary(repeat_speed, repeat_speed_variance, 0.0, 1.0),
		# ── Flanger ────────────────────────────────────────────────────────
		"flangerOffset": _vary(flanger_offset, flanger_offset_variance, -1.0, 1.0),
		"flangerSweep":  _vary(flanger_sweep,  flanger_sweep_variance,  -1.0, 1.0),
		# ── LP filter ──────────────────────────────────────────────────────
		"lpFilterCutoff":      _vary(lp_filter_cutoff,       lp_filter_cutoff_variance,       0.0, 1.0),
		"lpFilterCutoffSweep": _vary(lp_filter_cutoff_sweep, lp_filter_cutoff_sweep_variance, -1.0, 1.0),
		"lpFilterResonance":   _vary(lp_filter_resonance,    lp_filter_resonance_variance,    0.0, 1.0),
		# ── HP filter ──────────────────────────────────────────────────────
		"hpFilterCutoff":      _vary(hp_filter_cutoff,       hp_filter_cutoff_variance,       0.0, 1.0),
		"hpFilterCutoffSweep": _vary(hp_filter_cutoff_sweep, hp_filter_cutoff_sweep_variance, -1.0, 1.0),
		# ── Bit crush ──────────────────────────────────────────────────────
		"bitCrush":      _vary(bit_crush,       bit_crush_variance,       0.0,  1.0),
		"bitCrushSweep": _vary(bit_crush_sweep, bit_crush_sweep_variance, -1.0, 1.0),
	}


# ─────────────────────────────────────────────────────────────────────────────
#  INTERNAL HELPERS
# ─────────────────────────────────────────────────────────────────────────────

## Apply additive variance to a base value and clamp to [min_val, max_val].
## When variance is 0 the fast path returns base_val unchanged.
func _vary(base_val: float, variance: float, min_val: float, max_val: float) -> float:
	if variance == 0.0:
		return base_val
	return clampf(base_val + randf_range(-variance, variance), min_val, max_val)


## Preview handler — called when the 🔊 button is pressed in the Inspector.
## Creates a temporary BfxrSFX node, generates a variation synchronously,
## then plays it through a temporary AudioStreamPlayer parented to the editor tree.
## Both nodes auto-free themselves when playback ends.
func _preview_sound() -> void:
	if not Engine.is_editor_hint():
		return

	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		push_error("VoiceProfile: cannot access SceneTree for preview")
		return

	# Temporary synthesis node — we only need it for generate_wav(); it is freed
	# immediately after generation so its internal player pool never runs.
	var bfxr := BfxrSFX.new()
	tree.root.add_child(bfxr)
	var wav: AudioStreamWAV = bfxr.GenerateWav(build_params())
	bfxr.queue_free()

	if wav == null:
		push_error("VoiceProfile: generate_wav returned null during preview")
		return
	
	var player := AudioStreamPlayer.new()
	tree.root.add_child(player)
	player.stream = wav
	player.play()
	# Auto-free once the clip finishes so we don't litter the editor scene tree.
	player.finished.connect(player.queue_free)


func _randomize_params() -> void:
	# Parameters listed here have their raw randf() result raised to a power,
	# biasing the distribution toward 0 (i.e. "usually subtle, occasionally extreme").
	var powers := {
		"attackTime": 4, "sustainTime": 2, "sustainPunch": 2,
		"overtones": 3, "overtoneFalloff": 2, "vibratoDepth": 3,
		"dutySweep": 3, "flangerOffset": 3, "flangerSweep": 3,
		"lpFilterCutoff": 3, "lpFilterCutoffSweep": 3,
		"hpFilterCutoff": 5, "hpFilterCutoffSweep": 5,
		"bitCrush": 4, "bitCrushSweep": 5,
		"frequency_slide": 4, "frequency_acceleration": 7, "frequency_start": 4,
	}

	# Each entry: [min, max, default_value, resource_property_name]
	# The default is the "centre" of the distribution — we flip a coin to decide
	# whether to sample above or below it, then scale r into that half-range.
	var ranges := {
		"masterVolume":    [0.0,   1.0,  0.5,  "master_volume"],
		"attackTime":      [0.0,   1.0,  0.0,  "attack_time"],
		"sustainTime":     [0.0,   1.0,  0.3,  "sustain_time"],
		"sustainPunch":    [0.0,   1.0,  0.0,  "sustain_punch"],
		"decayTime":       [0.03,  1.0,  0.4,  "decay_time"],
		"compressionAmount":                [0.0,  1.0,  0.0,  "compression_amount"],
		"frequency_start": [0.0,   1.0,  0.3,  "frequency_start"],
		"frequency_slide": [-0.5,  0.5,  0.0,  "frequency_slide"],
		"frequency_acceleration":           [-1.0, 1.0,  0.0,  "frequency_acceleration"],
		"min_frequency_relative_to_starting_frequency": [0.0, 0.99, 0.0, "min_frequency"],
		"vibratoDepth":    [0.0,   1.0,  0.0,  "vibrato_depth"],
		"vibratoSpeed":    [0.0,   1.0,  0.0,  "vibrato_speed"],
		"pitch_jump_repeat_speed":          [0.0,  1.0,  0.0,  "pitch_jump_repeat_speed"],
		"pitch_jump_amount":                [-1.0, 1.0,  0.0,  "pitch_jump_amount"],
		"pitch_jump_onset_percent":         [0.0,  1.0,  0.0,  "pitch_jump_onset_percent"],
		"pitch_jump_2_amount":              [-1.0, 1.0,  0.0,  "pitch_jump_2_amount"],
		"pitch_jump_onset2_percent":        [0.0,  1.0,  0.0,  "pitch_jump_onset2_percent"],
		"overtones":       [0.0,   1.0,  0.0,  "overtones"],
		"overtoneFalloff": [0.0,   1.0,  0.0,  "overtone_falloff"],
		"squareDuty":      [0.0,   0.99, 0.0,  "square_duty"],
		"dutySweep":       [-1.0,  1.0,  0.0,  "duty_sweep"],
		"repeatSpeed":     [0.0,   1.0,  0.0,  "repeat_speed"],
		"flangerOffset":   [-1.0,  1.0,  0.0,  "flanger_offset"],
		"flangerSweep":    [-1.0,  1.0,  0.0,  "flanger_sweep"],
		"lpFilterCutoff":  [0.01,  1.0,  1.0,  "lp_filter_cutoff"],
		"lpFilterCutoffSweep":              [-1.0, 1.0,  0.0,  "lp_filter_cutoff_sweep"],
		"lpFilterResonance":                [0.0,  1.0,  0.0,  "lp_filter_resonance"],
		"hpFilterCutoff":  [0.0,   1.0,  0.0,  "hp_filter_cutoff"],
		"hpFilterCutoffSweep":              [-1.0, 1.0,  0.0,  "hp_filter_cutoff_sweep"],
		"bitCrush":        [0.0,   1.0,  0.0,  "bit_crush"],
		"bitCrushSweep":   [-1.0,  1.0,  0.0,  "bit_crush_sweep"],
	}

	for key: String in ranges:
		var entry: Array = ranges[key]
		var mn: float  = entry[0]
		var mx: float  = entry[1]
		var dv: float  = entry[2]
		var prop: String = entry[3]

		var r: float = randf()
		if powers.has(key):
			r = pow(r, powers[key])

		# Coin flip: sample above or below the default.
		# Edge cases: default == min → always above; default == max → always below.
		var above: bool = randf() < 0.5
		if mn == dv: above = true
		if mx == dv: above = false

		set(prop, dv + (mx - dv) * r if above else dv - (dv - mn) * r)

	# Post-pass overrides — match the C# behaviour exactly.
	wave_type          = randi() % 12       # 0–11 inclusive
	if randf() < 0.5:
		repeat_speed   = 0.0               # half the time, no repeat
	min_frequency      = 0.0               # always cleared
	compression_amount = 0.0               # always cleared

	notify_property_list_changed()  # refreshes Inspector sliders
	emit_changed()                  # marks resource dirty
	
	_preview_sound()
