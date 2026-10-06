## Autoload: MusicController
##
## Handles layered music playback: each [enum Layer] (drums, bass, chords,
## etc) gets its own [AudioStreamPlayer] so a [MusicTrack]'s stems can play
## simultaneously and have their volumes mixed independently, while still
extends Node
# audoload singleton!!!

# -----------------------------------------------------------------------------------
# music manager
# handles layered music tracks that all play simultaneously (drums, bass, melody, etc)
# each layer gets its own AudioStreamPlayer so volumes can be mixed independently
# -----------------------------------------------------------------------------------

enum Layer { DRUMS, BASS, CHORDS, MELODY, PAD, LEAD, VOCALS }

signal track_finished
var _players: Dictionary[Layer, AudioStreamPlayer] = {}
var _reference_player: AudioStreamPlayer
var _looping: bool = false

func _ready() -> void:
	for layer in Layer.values():
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "Layer_%s" % Layer.keys()[layer]
		add_child(player)
		_players[layer] = player
	Log.info("MusicManager initialized with %d layers." % _players.size())

# -----------------------------------------------------------------------------------
# loading
# -----------------------------------------------------------------------------------

func load_track(track: MusicTrack) -> void:
	if not track:
		Log.error("MusicManager: given a null MusicTrack.")
		return
	for layer in Layer.values():
		load_layer(layer, track.get_stream(layer))
	Log.info("MusicManager: loaded track '%s'." % track.track_name)

func load_layer(layer: Layer, stream: AudioStream) -> void:
	if not _players.has(layer):
		Log.error("MusicManager: unknown layer %s" % layer)
		return
	_players[layer].stream = stream
	Log.debug("Loaded %s into layer %s" % [stream, Layer.keys()[layer]])

func load_layer_from_path(layer: Layer, path: String) -> void:
	var stream: AudioStream = load(path)
	if not stream:
		Log.error("MusicManager: failed to load stream at %s" % path)
		return
	load_layer(layer, stream)

# -----------------------------------------------------------------------------------
# playback
# -----------------------------------------------------------------------------------

func play(loop: bool = false) -> void:
	# calling play() on every player back-to-back like this, with no awaits in between,
	# gets them all queued for the same audio mix cycle so they start sample-synced.
	# the real drift risk isn't the initial start though, it's layers that get stopped
	# and restarted independently later (e.g. to "mute" one) - use set_layer_volume_*
	# instead of stop() for that, and lean on resync_layers() if anything ever slips.
	_looping = loop
	var new_reference: AudioStreamPlayer
	for layer in _players:
		var player: AudioStreamPlayer = _players[layer]
		if player.stream:
			if not new_reference:
				new_reference = player
			player.play()
	if new_reference and new_reference != _reference_player:
		if _reference_player and _reference_player.finished.is_connected(_on_track_finished):
			_reference_player.finished.disconnect(_on_track_finished)
		_reference_player = new_reference
		_reference_player.finished.connect(_on_track_finished)
	Log.info("MusicManager: playing loaded layers%s." % (" (looping)" if loop else ""))

func stop() -> void:
	_looping = false
	if _reference_player and _reference_player.finished.is_connected(_on_track_finished):
		_reference_player.finished.disconnect(_on_track_finished)
	_reference_player = null
	for layer in _players:
		var player: AudioStreamPlayer = _players[layer]
		player.stop()
		player.stream = null
	Log.info("MusicManager: stopped and cleared all layers.")

func resync_layers(reference_layer: Layer = Layer.DRUMS) -> void:
	var reference: AudioStreamPlayer = _players.get(reference_layer)
	if not reference or not reference.playing:
		Log.warn("MusicManager: reference layer %s isn't playing, can't resync." % Layer.keys()[reference_layer])
		return
	var target_position: float = reference.get_playback_position() + AudioServer.get_time_since_last_mix()
	for layer in _players:
		var player: AudioStreamPlayer = _players[layer]
		if player != reference and player.stream and player.playing:
			player.seek(target_position)
	Log.info("MusicManager: resynced layers to %.3fs." % target_position)

func _on_track_finished() -> void:
	track_finished.emit()
	if _looping:
		play(true)

# -----------------------------------------------------------------------------------
# mixing
# -----------------------------------------------------------------------------------

func set_layer_volume_db(layer: Layer, volume_db: float) -> void:
	if not _players.has(layer):
		Log.error("MusicManager: unknown layer %s" % layer)
		return
	_players[layer].volume_db = volume_db

func set_layer_volume_linear(layer: Layer, volume: float) -> void:
	set_layer_volume_db(layer, linear_to_db(volume))

func get_layer_player(layer: Layer) -> AudioStreamPlayer:
	return _players.get(layer)
