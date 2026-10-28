class_name GateComponent extends Component

var _check_timer: float = 0.0
@export var check_timer: float = 0.05
@export var check_radius: float = 32
@export var spawn_effect: EntityEffect

func _on_registered() -> void:
	pass # replace with function body

func _on_entity_initialized() -> void:
	pass

func _on_entity_spawned() -> void:
	if spawn_effect:
		spawn_effect.execute(entity)

func _physics_process(delta: float) -> void:
	_check_timer -= delta
	if _check_timer <= 0.0:
		_check_timer = check_timer
		var nearby: Array[Entity] = SpatialUtil.get_entities_in_rectangle(entity.get_world_2d().direct_space_state, entity.global_position, Vector2(32, 32), 0, SpatialUtil.PhysicsLayers.CREATURES)
		for e in nearby:
			if not PlayerManager.is_entity_player(e):
				return
			if e.key:
				activate_gate(e)
		
func activate_gate(e: Entity) -> void:
	e.key.queue_free()
	EventBus.gate_activated.emit(entity.global_position)
