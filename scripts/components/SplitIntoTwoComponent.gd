extends Component
class_name SplitIntoTwoComponent

@export var health: HealthComponent
@export var ichor: IchorComponent
@export var split_effect: EntityEffect
@export var leave_original: bool = true

var _already_split: bool = false

func _on_registered() -> void:
	health.taken_damage.connect(_on_hit_received)
	if not health:
		health = entity.get_component(HealthComponent)
	
	if not ichor:
		ichor = entity.get_component(IchorComponent)
	
func _on_hit_received(damage: float, source: Entity) -> void:
	if _already_split:
		return
	_already_split = true
	
	if health.health < 1:
		return
		
	var half_health: float = health.health / 1.5
	var half_max_health: float = health.max_health / 2
	var half_ichor: float = ichor.ichor / 2
	var half_max_ichor: float = ichor.max_ichor / 2
	var spawn_pos: Vector2 = entity.global_position
	var basename: StringName = entity.basename
	
	
	
	if split_effect:
		split_effect.execute(entity)
		
	#health.taken_damage.disconnect(_on_hit_received)
	if not leave_original:
		entity.queue_free()
		
		_spawn_clone(basename, spawn_pos, half_health, health.max_health, half_ichor, half_max_ichor)
	_spawn_clone(basename, spawn_pos, half_health, health.max_health, half_ichor, half_max_ichor)
	if leave_original:
		_already_split = false

	
func _spawn_clone(basename: StringName, pos: Vector2, hp: float, max_hp: float, ich: float, max_ich: float) -> void:
	var clone: Entity = EntityManager.simple_spawn(basename, pos)
	if not clone.is_initialized:
		await clone.entity_initialized
		
	var h: HealthComponent = clone.get_component(HealthComponent)
	var i: IchorComponent = clone.get_component(IchorComponent)
	if h:
		h.health = hp
		h.max_health = max_hp
		h.set_invincibility_timer(1.0)
	if i:
		i.ichor = ich
		i.max_ichor = max_ich
