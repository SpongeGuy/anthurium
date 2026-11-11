extends EntityEffect
class_name EntityEffectVoice

@export var voice: VoiceProfile

func _execute(entity: Entity) -> void:
	if entity:
		AudioManager.play_voice(voice, entity)
	else:
		AudioManager.play_voice(voice, null, true, false)
