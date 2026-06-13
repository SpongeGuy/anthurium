extends Component
class_name AbilityShardSpawner

## Spawns [AbilityShard] entities when an entity dies, based on per-slot drop chances.
##
## Iterates all occupied slots in the linked [AbilityManager] and rolls against
## [member chance] for each. Successful rolls call [method AbilityManager.drop_to_shard],
## which extracts the ability from the manager and creates a shard in the world.

## Per-slot drop probability (0.0–1.0), indexed to match [AbilityManager.abilities].
@export var chance: Array[float] = [1.0, 1.0, 1.0, 1.0]
@export var ability_manager: AbilityManager
@export var sound: VoiceProfile = preload("res://assets/resources/voices/drop_item.tres")

func _on_registered() -> void:
	pass

## Rolls each occupied slot and spawns a shard for every successful roll.
## Applies a small random scatter so shards don't stack exactly on top of one another.
func try_create() -> void:
	for i in range(chance.size()):
		if not ability_manager.has_ability(i):
			continue
		if randf() < chance[i]:
			var scatter: Vector2 = Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))
			AudioManager.play_voice(sound, entity)
			ability_manager.drop_to_shard(i, entity.global_position + scatter)
