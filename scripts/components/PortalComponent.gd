extends Component
class_name PortalComponent

@export var autostart: bool = true
@export var timer_length: float = 3.0
var _timer: float = 0.0
var entities_to_spawn: Array[Entity] = []
var activated: bool = false



var portal_warping_effect: EntityEffect = load("uid://dmf1c7kgwsiil")
var portal_spawn_effect: EntityEffect = load("uid://bt3floikjhixg")
var entity_spawn_effect: EntityEffect = load("uid://v1fecg743jpx")

func _on_registered() -> void:
	_timer = RandomUtil.randomize_float(RunRng.get_stream(&"portal"), timer_length, 1)
	

func _on_entity_spawned() -> void:
	portal_spawn_effect.execute(entity)
	if autostart:
		activated = true

func _process(delta: float) -> void:
	if not activated:
		return
	_elapse_timer(delta)
	portal_warping_effect.execute(entity)

func _elapse_timer(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		activate_portal()

func add_entity(entity: Entity) -> void:
	entities_to_spawn.append(entity)

func activate_portal() -> void:
	for e in entities_to_spawn:
		EntityManager.spawn_entity(e, entity.global_position, entity.z)
	entity_spawn_effect.execute(entity)
	entity.queue_free()
