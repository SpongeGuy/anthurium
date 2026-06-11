extends Node

# -----------------------------------------------------------------------------------
# autoload singleton for reliable audio playback
# single pool of AudioStreamPlayer nodes — no 2D nodes, no viewport listener issues
# positional sounds manually compute volume from distance to camera
# -----------------------------------------------------------------------------------

var _pool:   Array[AudioStreamPlayer] = []
var _active: Array[AudioStreamPlayer] = []
var _camera: Camera2D = null

const INITIAL_POOL_SIZE: int = 20
const MAX_POOL_SIZE:     int = 100

enum AudioBus { MASTER, SFX, MUSIC, UI }
const BUS_NAMES := {
	AudioBus.MASTER: "Master",
	AudioBus.SFX:    "SFX",
	AudioBus.MUSIC:  "Music",
	AudioBus.UI:     "UI"
}

var _wav_pending: Dictionary = {}   # id -> data dict
var _wav_next_id: int = 0
var _bfxr: BfxrSFX

func _ready() -> void:
	for i in INITIAL_POOL_SIZE:
		_pool.append(_create_player())
	EventBus.camera_ready.connect(_on_camera_ready)
	
	_bfxr = BfxrSFX.new()
	add_child(_bfxr)


func _on_camera_ready(camera: Camera2D) -> void:
	_camera = camera

# -----------------------------------------------------------------------------------
# public api
# -----------------------------------------------------------------------------------

## play a global non-positional sound (UI, music, screen-wide effects)
func play_sound(
	sound:       AudioStream,
	volume_db:   float    = 0.0,
	pitch_scale: float    = 1.0,
	bus:         AudioBus = AudioBus.UI
) -> AudioStreamPlayer:
	if sound == null:
		push_error("AudioManager: null sound"); return null
	var p := _get_player()
	p.stream      = sound
	p.volume_db   = volume_db
	p.pitch_scale = pitch_scale
	p.bus         = BUS_NAMES[bus]
	p.play()
	return p


## play a positional sound at a world position — volume computed from camera distance
func play_2d(
	sound:        AudioStream,
	position:     Vector2,
	volume_db:    float    = 0.0,
	pitch_scale:  float    = 1.0,
	bus:          AudioBus = AudioBus.SFX,
	max_distance: float    = 600.0,
	attenuation:  float    = 2.0
) -> AudioStreamPlayer:
	if sound == null:
		push_error("AudioManager: null sound"); return null
	var spatial_db := _distance_to_db(position, max_distance, attenuation)
	if spatial_db == -INF:
		return null  # out of range, skip
	var p := _get_player()
	p.stream      = sound
	p.volume_db   = volume_db + spatial_db
	p.pitch_scale = pitch_scale
	p.bus         = BUS_NAMES[bus]
	p.play()
	return p



	
## Play a BfxrVoiceProfile as a spatial or global sound.
func play_voice(
	profile:          VoiceProfile,
	entity:           Entity            = null,
	global_sound:     bool              = false,
	check_if_visible: bool              = true,
	volume_db:        float             = 0.0,
	pitch_scale:      float             = 1.0,
	bus:              AudioBus          = AudioBus.SFX,
	max_distance:     float             = 400.0,
	attenuation:      float             = 2.0
) -> void:
 
	# ── Validate ──────────────────────────────────────────────────────────────
	if profile == null:
		push_error("AudioManager.play_voice: profile is null"); return
	if not global_sound and entity == null:
		push_error("AudioManager.play_voice: entity required when global_sound is false"); return
 
	# ── Visibility gate (before any generation work) ──────────────────────────
	# Checked only for non-global sounds when check_if_visible is true.
	if not global_sound and check_if_visible:
		var vis: VisibilityComponent = entity.get_component(VisibilityComponent)
		if vis != null and not vis._visible:
			return
 
	# ── Capture position now, on the main thread ──────────────────────────────
	# The entity may move or be freed by the time async generation completes.
	# Storing a Vector2 value here is safe regardless.
	var position := Vector2.ZERO
	if not global_sound:
		position = entity.global_position
 
	# ── Build the mutated param dictionary ────────────────────────────────────
	# build_params() applies variance offsets and returns a plain Dictionary.
	# This is fast (pure GDScript arithmetic) and happens on the main thread.
	var params: Dictionary = profile.build_params()
	
 
	# ── Generate asynchronously, play on callback ─────────────────────────────
	# GenerateWavAsync() snapshots params into a C# struct (main thread),
	# runs synthesis on a Task (background thread, Random.Shared),
	# then fires the callback via CallDeferred (main thread) so play is safe.
	# ── Generate asynchronously, play on callback ─────────────────────────────
	var id := _wav_next_id
	_wav_next_id += 1
	_wav_pending[id] = {
		"global_sound": global_sound,
		"position":     position,
		"volume_db":    volume_db,
		"pitch_scale":  pitch_scale,
		"bus":          bus,
		"max_distance": max_distance,
		"attenuation":  attenuation,
	}
	_bfxr.GenerateWavAsync(self, "_on_wav_ready", id, params)

func _on_wav_ready(id: int, wav: AudioStreamWAV) -> void:
	var data: Dictionary = _wav_pending.get(id, {})
	_wav_pending.erase(id)
	if wav == null or data.is_empty():
		return
	if data.global_sound:
		play_sound(wav, data.volume_db, data.pitch_scale, data.bus)
	else:
		play_2d(wav, data.position, data.volume_db, data.pitch_scale,
				data.bus, data.max_distance, data.attenuation)

func stop_all_sounds() -> void:
	for p in _active: p.stop()


func stop_sounds_on_bus(bus: AudioBus) -> void:
	var bus_name = BUS_NAMES[bus]
	for p in _active:
		if p.bus == bus_name: p.stop()


func set_bus_volume(bus: AudioBus, volume_db: float) -> void:
	var idx := AudioServer.get_bus_index(BUS_NAMES[bus])
	if idx >= 0: AudioServer.set_bus_volume_db(idx, volume_db)


func get_bus_volume(bus: AudioBus) -> float:
	var idx := AudioServer.get_bus_index(BUS_NAMES[bus])
	return AudioServer.get_bus_volume_db(idx) if idx >= 0 else 0.0


func set_bus_mute(bus: AudioBus, muted: bool) -> void:
	var idx := AudioServer.get_bus_index(BUS_NAMES[bus])
	if idx >= 0: AudioServer.set_bus_mute(idx, muted)


func is_bus_muted(bus: AudioBus) -> bool:
	var idx := AudioServer.get_bus_index(BUS_NAMES[bus])
	return AudioServer.is_bus_mute(idx) if idx >= 0 else false


func get_active_sound_count() -> int:
	return _active.size()


func get_pool_size() -> int:
	return _pool.size() + _active.size()

# -----------------------------------------------------------------------------------
# internal
# -----------------------------------------------------------------------------------

## inverse power falloff — attenuation = 1.0 is linear, 2.0 is squared, higher = tighter
## returns -INF when out of range so the caller can skip the play entirely
func _distance_to_db(position: Vector2, max_distance: float, attenuation: float) -> float:
	if _camera == null:
		return 0.0  # no camera yet, play at full volume
	var distance := position.distance_to(_camera.global_position)
	if distance >= max_distance:
		return -INF
	var gain := pow(1.0 - distance / max_distance, attenuation)
	return linear_to_db(gain)


func _create_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.finished.connect(_on_finished.bind(p))
	return p


func _get_player() -> AudioStreamPlayer:
	if not _pool.is_empty():
		var p = _pool.pop_back()
		_active.append(p)
		return p
	if _active.size() + _pool.size() < MAX_POOL_SIZE:
		var p = _create_player()
		_active.append(p)
		return p
	push_warning("AudioManager: pool exhausted, reusing oldest")
	var p := _active[0]
	p.stop()
	return p


func _on_finished(player: AudioStreamPlayer) -> void:
	_active.erase(player)
	_pool.append(player)


















# -----------------------------------------------------------------------------------
# deprecated
# -----------------------------------------------------------------------------------


## play a random entity sound with visibility check and optional pitch variance
func play_entity_sound(
	sounds:       Array[AudioStream],
	entity:       Entity,
	pitch_min:    float    = 1.0,
	pitch_max:    float    = 1.0,
	volume_db:    float    = 0.0,
	max_distance: float    = 400.0,
	attenuation:  float    = 2.0,
	bus:          AudioBus = AudioBus.SFX
) -> AudioStreamPlayer:
	if sounds.is_empty():
		push_error("AudioManager: empty sounds array"); return null
	var vis: VisibilityComponent = entity.get_component(VisibilityComponent)
	if vis and not vis._visible:
		return null
	return play_2d(
		sounds.pick_random(), entity.global_position,
		volume_db, randf_range(pitch_min, pitch_max),
		bus, max_distance, attenuation
	)
