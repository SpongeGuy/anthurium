extends Component
class_name HealthComponent

@export var max_health: float
@export var health: float
@export var hitbox: Hitbox ## not mandatory
@export var state_machine: StateMachine

signal taken_damage(amount: float, source: Entity)
signal died()
signal health_changed(value: float, max_value: float)

@export var invincibility_length: float = 0.05
var invincibility_timer: float = 0.0
@export var god_mode: bool = false

var dying: bool = false

func _ready() -> void:
	if hitbox:
		hitbox.hit_received.connect(take_damage)

func _process(delta: float) -> void:
	_process_invincibility(delta)
	
func _process_invincibility(delta: float) -> void:
	if invincibility_timer >= 0.0:
		invincibility_timer -= delta

func take_damage(amount: float, source: Entity) -> void:
	if god_mode:
		return
	if invincibility_timer > 0:
		return
	invincibility_timer = invincibility_length
	health -= amount
	taken_damage.emit(amount, source)
	health_changed.emit(health, max_health)
		
	if health <= 0 and not dying:
		die()
		return
		
func heal(amount: float, source: Entity) -> void:
	health_changed.emit(health, max_health)

func die() -> void:
	dying = true
	died.emit()
	state_machine.switch_to_death_state()
