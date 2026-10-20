class_name DespawnComponent extends Component

@export var timer: float = 60
@export var spawn_effect: EntityEffect
var _timer: float = 0.0

func _on_entity_spawned() -> void:
	if spawn_effect:
		spawn_effect.execute(entity)
	_timer = timer
	
func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		entity.die_and_despawn()
