extends EntityEffect
class_name EntityEffectSpawnMultipleEntities

var poof_sound: VoiceProfile = preload("uid://dgiuplfa2wr8m")
@export var entity_names: Array[StringName]

func _execute(entity: Entity) -> void:
	for name in entity_names:
		EntityManager.spawn_safely(name, entity.global_position)
	AudioManager.play_voice(poof_sound, entity)
