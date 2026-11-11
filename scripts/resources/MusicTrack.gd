extends Resource
class_name MusicTrack

# -----------------------------------------------------------------------------------
# music track
# holds one AudioStream per MusicController.Layer so a whole layered track can be
# authored as a single resource and handed to MusicController.load_track()
# -----------------------------------------------------------------------------------

@export var track_name: String = ""

@export var drums: AudioStream
@export var bass: AudioStream
@export var chords: AudioStream
@export var melody: AudioStream
@export var pad: AudioStream
@export var lead: AudioStream
@export var vocals: AudioStream


func get_stream(layer: MusicController.Layer) -> AudioStream:
	match layer:
		MusicController.Layer.DRUMS:
			return drums
		MusicController.Layer.BASS:
			return bass
		MusicController.Layer.CHORDS:
			return chords
		MusicController.Layer.MELODY:
			return melody
		MusicController.Layer.PAD:
			return pad
		MusicController.Layer.LEAD:
			return lead
		MusicController.Layer.VOCALS:
			return vocals
	return null
