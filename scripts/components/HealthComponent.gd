extends Component
class_name HealthComponent

@export var max_health: float = 5
@export var health: float = 5
@export var hitbox: Hitbox ## not mandatory

@export var death_effect: EntityEffect = preload("uid://bg2bks2clcl4r")
var show_points_on_death_effect: EntityEffect = preload("uid://troqen01nx1q")


signal taken_damage(amount: float, source: Entity)
signal health_changed(value: float, max_value: float)

@export_category("Invincibility")
@export var invincibility_length: float = 0.1
var _invincibility_timer: float = 0.0
@export var god_mode: bool = false

@export_category("Ichor Mechanics")
@export var ichor: IchorComponent
@export var ichor_starvation: bool = true
@export var starvation_timer: float = 1.0
@export var starve_damage: float = 0.5
var _starvation_timer: float = 0.0

var dying: bool = false

func _ready() -> void:
	if hitbox:
		hitbox.hit_received.connect(take_damage)

func _process(delta: float) -> void:
	_process_invincibility(delta)
	if ichor:
		_process_ichor_starving(delta)
	
func _process_invincibility(delta: float) -> void:
	if _invincibility_timer >= 0.0:
		_invincibility_timer -= delta

func _process_ichor_starving(delta: float) -> void:
	if god_mode:
		return
	if ichor.ichor <= 0:
		_starvation_timer += delta
	if _starvation_timer >= starvation_timer:
		health -= starve_damage
		_starvation_timer = 0.0
		
		if health <= 0 and not dying:
			die(null)
			
func set_invincibility_timer(time: float) -> void:
	_invincibility_timer = time

func take_damage(amount: float, source: Entity) -> void:
	if god_mode:
		return
	if _invincibility_timer > 0:
		return
	_invincibility_timer = invincibility_length
	health -= amount
	taken_damage.emit(amount, source)
	health_changed.emit(health, max_health)
		
	if health <= 0 and not dying:
		die(source)
		
func heal(amount: float, source: Entity) -> void:
	health_changed.emit(health, max_health)

func die(source: Entity) -> void:
	var loco: LocomotionHandler = entity.get_component(LocomotionHandler)
	if loco:
		loco.disabled = true
	dying = true
	if death_effect:
		death_effect.execute(entity)
	if source and PlayerManager.is_entity_player(source) and show_points_on_death_effect:
		show_points_on_death_effect.execute(entity)
	if source:
		entity.transfer_points(source)
	
	entity.die_and_despawn()
