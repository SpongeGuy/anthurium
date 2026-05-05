extends Node

# -----------------------------------------------------------------------------------
# autoload singleton for reliable 2D audio playback
# handles multiple simultaneous sounds without glitches using object pooling
# lovely
# -----------------------------------------------------------------------------------

## pool of available AudioStreamPlayer2D nodes
var _audio_pool: Array[AudioStreamPlayer2D] = []
## currently active players
var _active_players: Array[AudioStreamPlayer2D] = []
## initial pool size
const INITIAL_POOL_SIZE: int = 20
## maximum pool size (prevents memory issues)
const MAX_POOL_SIZE: int = 100

## audio bus names for different categories
enum AudioBus {
	MASTER,
	SFX,
	MUSIC,
	UI
}

## bus name mapping
const BUS_NAMES = {
	AudioBus.MASTER: "Master",
	AudioBus.SFX: "SFX",
	AudioBus.MUSIC: "Music",
	AudioBus.UI: "UI"
}


func _ready() -> void:
	_initialize_pool()
	print("AudioManager initialized with pool size: ", INITIAL_POOL_SIZE)

# -----------------------------------------------------------------------------------
# public api
# -----------------------------------------------------------------------------------

## play a sound at a specific position in the world
func play_sound_at_position(
	sound: AudioStream,
	position: Vector2,
	volume_db: float = 0.0,
	pitch_scale: float = 1.0,
	bus: AudioBus = AudioBus.SFX,
	max_distance: float = 2000.0,
	attenuation: float = 1.0
) -> AudioStreamPlayer2D:
	if sound == null:
		push_error("AudioManager: Attempted to play null sound")
		return null
	
	var player = _get_available_player()
	
	player.stream = sound
	player.global_position = position
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.bus = BUS_NAMES[bus]
	player.max_distance = max_distance
	player.attenuation = attenuation
	
	player.play()
	
	return player


## play a non-positional sound
func play_sound(
	sound: AudioStream,
	volume_db: float = 0.0,
	pitch_scale: float = 1.0,
	bus: AudioBus = AudioBus.UI
) -> AudioStreamPlayer2D:
	if sound == null:
		push_error("AudioManager: Attempted to play null sound")
		return null
	
	var player = _get_available_player()
	
	player.stream = sound
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.bus = BUS_NAMES[bus]
	player.max_distance = 0.0  # 0 means no attenuation (plays everywhere)
	
	# Play the sound
	player.play()
	
	return player


## play a sound with random pitch variation
func play_sound_with_random_pitch(
	sound: AudioStream,
	position: Vector2,
	min_pitch: float = 0.9,
	max_pitch: float = 1.1,
	volume_db: float = 0.0,
	bus: AudioBus = AudioBus.SFX
) -> AudioStreamPlayer2D:
	var random_pitch = randf_range(min_pitch, max_pitch)
	return play_sound_at_position(sound, position, volume_db, random_pitch, bus)


func stop_all_sounds() -> void:
	for player in _active_players:
		player.stop()


func stop_sounds_on_bus(bus: AudioBus) -> void:
	var bus_name = BUS_NAMES[bus]
	for player in _active_players:
		if player.bus == bus_name:
			player.stop()


func get_active_sound_count() -> int:
	return _active_players.size()


func get_pool_size() -> int:
	return _audio_pool.size() + _active_players.size()


func set_bus_volume(bus: AudioBus, volume_db: float) -> void:
	var bus_index = AudioServer.get_bus_index(BUS_NAMES[bus])
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, volume_db)


func get_bus_volume(bus: AudioBus) -> float:
	var bus_index = AudioServer.get_bus_index(BUS_NAMES[bus])
	if bus_index >= 0:
		return AudioServer.get_bus_volume_db(bus_index)
	return 0.0


func set_bus_mute(bus: AudioBus, muted: bool) -> void:
	var bus_index = AudioServer.get_bus_index(BUS_NAMES[bus])
	if bus_index >= 0:
		AudioServer.set_bus_mute(bus_index, muted)


func is_bus_muted(bus: AudioBus) -> bool:
	var bus_index = AudioServer.get_bus_index(BUS_NAMES[bus])
	if bus_index >= 0:
		return AudioServer.is_bus_mute(bus_index)
	return false
	
# -----------------------------------------------------------------------------------
# internal
# -----------------------------------------------------------------------------------
	
func _initialize_pool() -> void:
	for i in range(INITIAL_POOL_SIZE):
		_create_audio_player()


func _create_audio_player() -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.name = "PooledAudioPlayer2D_%d" % _audio_pool.size()
	add_child(player)
	player.finished.connect(_on_player_finished.bind(player))
	_audio_pool.append(player)
	return player


func _get_available_player() -> AudioStreamPlayer2D:
	if _audio_pool.size() > 0:
		var player = _audio_pool.pop_back()
		_active_players.append(player)
		return player
	
	if get_child_count() < MAX_POOL_SIZE:
		var player = _create_audio_player()
		_active_players.append(player)
		return player
	
	# pool exhausted! find the oldest active player and reuse it
	print("AudioManager: Pool exhausted, reusing oldest player")
	var oldest_player = _active_players[0]
	oldest_player.stop()
	return oldest_player


## return a player to the pool when finished
func _on_player_finished(player: AudioStreamPlayer2D) -> void:
	if player in _active_players:
		_active_players.erase(player)
		_audio_pool.append(player)
