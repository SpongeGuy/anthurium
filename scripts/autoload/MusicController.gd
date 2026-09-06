## Autoload: MusicController
##
## Handles layered music playback: each [enum Layer] (drums, bass, chords,
## etc) gets its own [AudioStreamPlayer] so a [MusicTrack]'s stems can play
## simultaneously and have their volumes mixed independently, while still
## being started, stopped, and looped together as one logical track.
extends Node
# audoload singleton!!!

# -----------------------------------------------------------------------------------
# music manager
# handles layered music tracks that all play simultaneously (drums, bass, melody, etc)
# each layer gets its own AudioStreamPlayer so volumes can be mixed independently
# -----------------------------------------------------------------------------------

## The individual instrument/stem layers a [MusicTrack] can provide streams for.
enum Layer { DRUMS, BASS, CHORDS, MELODY, PAD, LEAD, VOCALS }

## Emitted when the reference layer's stream finishes playing (before any
## looping restart triggered by [method play]'s [code]loop[/code] flag).
signal track_finished

## One [AudioStreamPlayer] per [enum Layer], created in [method _ready].
var _players: Dictionary[Layer, AudioStreamPlayer] = {}
## The layer player used to detect end-of-track and drive looping/resync;
## whichever layer was first found with a loaded stream in [method play].
var _reference_player: AudioStreamPlayer
## Whether the current track should automatically restart on finish.
var _looping: bool = false


## Creates one named [AudioStreamPlayer] child per [enum Layer] value.
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

## Loads every layer's stream from [param track] via [method load_layer].
## Logs an error and does nothing if [param track] is [code]null[/code].
func load_track(track: MusicTrack) -> void:
	if not track:
		Log.error("MusicManager: given a null MusicTrack.")
		return
	for layer in Layer.values():
		load_layer(layer, track.get_stream(layer))
	Log.info("MusicManager: loaded track '%s'." % track.track_name)

## Sets [param stream] on the player for [param layer]. Logs an error if
## [param layer] isn't a recognized layer.
func load_layer(layer: Layer, stream: AudioStream) -> void:
	if not _players.has(layer):
		Log.error("MusicManager: unknown layer %s" % layer)
		return
	_players[layer].stream = stream
	Log.debug("Loaded %s into layer %s" % [stream, Layer.keys()[layer]])

## Loads an [AudioStream] resource from [param path] and applies it to
## [param layer] via [method load_layer]. Logs an error if loading fails.
func load_layer_from_path(layer: Layer, path: String) -> void:
	var stream: AudioStream = load(path)
	if not stream:
		Log.error("MusicManager: failed to load stream at %s" % path)
		return
	load_layer(layer, stream)

# -----------------------------------------------------------------------------------
# playback
# -----------------------------------------------------------------------------------

## Starts playback on every layer that currently has a loaded stream,
## queuing them all in the same call so they start sample-synced, and wires
## up looping (if [param loop] is [code]true[/code]) via the first such
## layer found as the reference player.
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

## Stops every layer, clears their streams, and disables looping.
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

## Seeks every other playing layer to match [param reference_layer]'s
## current playback position (plus elapsed time since the last audio mix),
## correcting any drift between layers. Logs a warning and does nothing if
## the reference layer isn't currently playing.
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

## Connected to the reference layer's [signal AudioStreamPlayer.finished];
## emits [signal track_finished] and restarts playback if [member _looping]
## is set.
func _on_track_finished() -> void:
	track_finished.emit()
	if _looping:
		play(true)

# -----------------------------------------------------------------------------------
# mixing
# -----------------------------------------------------------------------------------

## Sets [param layer]'s volume in dB. Logs an error if [param layer] isn't
## recognized.
func set_layer_volume_db(layer: Layer, volume_db: float) -> void:
	if not _players.has(layer):
		Log.error("MusicManager: unknown layer %s" % layer)
		return
	_players[layer].volume_db = volume_db

## Sets [param layer]'s volume from a linear [param volume] value (converted
## to dB).
func set_layer_volume_linear(layer: Layer, volume: float) -> void:
	set_layer_volume_db(layer, linear_to_db(volume))

## Returns the [AudioStreamPlayer] backing [param layer], or [code]null[/code]
## if unrecognized.
func get_layer_player(layer: Layer) -> AudioStreamPlayer:
	return _players.get(layer)
