extends Component
class_name SoundPlayer

@export var possible_sounds: Array[AudioStream]
@export var visibility: VisibilityComponent

@export var pitch_min: float = 1.0
@export var pitch_max: float = 1.0
@export var volume_db: float = 0.0

@export var time_delay: float = 0.0

func play_sound() -> void:
	if not entity:
		return
	if visibility and visibility._visible == false:
		return
	var sound: AudioStream = possible_sounds.pick_random()
	AudioManager.play_sound_with_random_pitch(sound, entity.global_position, pitch_min, pitch_max, volume_db)

func play_sound_with_negative_volume_modifier(modifier: float) -> void:
	if not entity:
		return
	if visibility and visibility._visible == false:
		return
	var db: float = -14
	var sound: AudioStream = possible_sounds.pick_random()
	AudioManager.play_sound_with_random_pitch(sound, entity.global_position, pitch_min, pitch_max, volume_db + (db * modifier))

func play_sequence_of_sounds(random: bool = false) -> void:
	if not entity:
		return
	if visibility and visibility._visible == false:
		return
	var sounds_to_play: Array[AudioStream]
	for sound in possible_sounds:
		sounds_to_play.append(sound)
	if random:
			sounds_to_play.shuffle()
	for sound in sounds_to_play:
		AudioManager.play_sound_with_random_pitch(sound, entity.global_position, pitch_min, pitch_max, volume_db)
		await get_tree().create_timer(time_delay).timeout
