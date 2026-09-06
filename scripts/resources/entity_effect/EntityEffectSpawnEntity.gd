extends EntityEffect
class_name EntityEffectSpawnEntity

var poof_sound: VoiceProfile = preload("uid://dgiuplfa2wr8m")
@export var entity_name: StringName

func _execute(entity: Entity) -> void:
	var spawned: Entity = EntityManager.spawn(entity_name, entity.global_position)
	AudioManager.play_voice(poof_sound, entity)
	if not spawned:
		push_error("EntityEffectSpawnEntity: Could not spawn entity '%s', does not exist?" % spawned)
		return
	

		
