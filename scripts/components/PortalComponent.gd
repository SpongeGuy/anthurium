extends Component
class_name PortalComponent

@export var autostart: bool = true
@export var timer_length: float = 3.0
var _timer: float = 0.0
var entities_to_spawn: Array[Entity] = []
var activated: bool = false

var portal_particles: ParticleProfile = preload("uid://caei1gsudwqth")
var portal_sound: VoiceProfile = preload("uid://ciolmmgn3qpw7")

func _on_registered() -> void:
	_timer = RandomUtil.randomize_float(RunRng.get_stream(&"portal"), timer_length, 1)
	

func _on_entity_spawned() -> void:
	AudioManager.play_voice(portal_sound, entity.global_position)
	if autostart:
		activated = true

func _process(delta: float) -> void:
	if not activated:
		return
	_elapse_timer(delta)
	ParticleManager.burst(portal_particles, entity.global_position)

func _elapse_timer(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		activate_portal()

func add_entity(entity: Entity) -> void:
	entities_to_spawn.append(entity)

func activate_portal() -> void:
	for e in entities_to_spawn:
		EntityManager.spawn_entity(e, entity.global_position, entity.z)
	entity.queue_free()
