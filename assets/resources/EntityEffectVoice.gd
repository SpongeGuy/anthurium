extends EntityEffect
class_name EntityEffectVoice

@export var voice: VoiceProfile

func _execute(entity: Entity) -> void:
	AudioManager.play_voice(voice, entity)
