extends Component
class_name SimpleSpawner

@export var entity_name: StringName
@export var autostart: bool = true
@export var timer_length: float = 3.0

var activated: bool = false
var _timer: float = 0

var poof_sound: VoiceProfile = load("uid://dgiuplfa2wr8m")
var warp_sound: VoiceProfile = load("uid://ciolmmgn3qpw7")
var portal_particles: ParticleProfile = load("uid://caei1gsudwqth")

var entity_to_spawn: Entity

var _entity_initialized: bool = false

func _init(entity_type: StringName) -> void:
	entity_name = entity_type

func _on_registered() -> void:
	if autostart:
		activate()
	_timer = RandomUtil.randomize_float(RunRng.get_stream(&"entity"), timer_length, 1)
	entity_to_spawn = EntityManager._instantiate_entity(entity_name)
	entity_to_spawn.entity_initialized.connect(_on_entity_initialized, CONNECT_ONE_SHOT)

func activate() -> void:
	activated = true
	AudioManager.play_voice(warp_sound, entity)

func _process(delta: float) -> void:
	if not activated:
		return
	ParticleManager.burst(portal_particles, entity.global_position)
	_timer -= delta
	if _timer <= 0.0:
		spawn_entity()
		
func spawn_entity() -> void:
	entity_to_spawn.global_position = entity.global_position
	EntityManager._add(entity_to_spawn)
	AudioManager.play_voice(poof_sound, entity_to_spawn)

func _on_entity_initialized() -> void:
	_entity_initialized = true
	
func get_entity() -> Entity:
	if not _entity_initialized:
		await entity_to_spawn.entity_initialized
	
	return entity_to_spawn
