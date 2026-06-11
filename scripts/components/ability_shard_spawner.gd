extends Component
class_name AbilityShardSpawner

@export var chance: Array[float] = [1.0, 1.0, 1.0, 1.0]
@export var ability_manager: AbilityManager
@export var sound: VoiceProfile = preload("res://scripts/resources/voices/drop_item.tres")


func _on_registered() -> void:
	pass # replace with function body


func try_create() -> void:
	for i in range(chance.size()):
		if not ability_manager.abilities.get(i):
			continue
		if randf() < chance[i]:
			AudioManager.play_voice(sound, entity)
			ability_manager.drop_ability_shard(i, entity.global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5)))
