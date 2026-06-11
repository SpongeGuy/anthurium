extends Component
class_name EntitySpawner

@export var entities_to_spawn: Array[StringName] = []
@export var spawn_chance: Array[float] = []

var poof_voice: VoiceProfile = preload("res://assets/resources/voices/poof.tres")

var _spawned: bool = false

func spawn_at(position: Vector2) -> void:
	_spawned = false
	for i in range(entities_to_spawn.size()):
		if randf() < spawn_chance[i]:
			EntityManager.spawn_safely(entities_to_spawn[i], position + Vector2(randf_range(-8, 8), randf_range(-8, 8)))
			_spawned = true
			
	if _spawned:
		AudioManager.play_voice(poof_voice, entity)


func spawn_at_entity() -> void:
	var position: Vector2 = entity.global_position
	spawn_at(position)
