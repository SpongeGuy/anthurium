extends BehaviorState
class_name StateCastAbilityIfEnoughIchor
## states should only include logic which alters data.
## all other functions should be outsourced to other components, such as visual effects or sounds.

@export var input: int = 0
@export var input_component: InputComponent
@export var ability_manager: AbilityManager
@export var animator: SpriteAnimator
@export var animation_names: Array[String] = ["closed", "open"]
@export var ichor_component: IchorComponent
@export var try_cooldown: float = 3.0

@export var open_effect: EntityEffect
@export var close_effect: EntityEffect

var _timer: float
var _is_open: bool = true
var _animation_cooldown: float
## called once when the state machine does its initial switch to this state
func enter() -> void:
	_timer = try_cooldown
	ability_manager.ability_cast_successfully.connect(_on_cast_successfully)
	ability_manager.disable(input)
	
## called every frame while this state is active
func update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		
		ability_manager.enable(input)
		if not input_component.player_controlled:
			input_component.press_action(input)
			input_component.release_action(input)
		if _is_open:
			_is_open = false
			if close_effect:
				close_effect.execute(state_machine.entity)
	else:
		ability_manager.disable(input)
	
## called every physics frame while this state is active
func physics_update(delta: float) -> void:
	pass
	
## called once when this state is switched from
func exit() -> void:
	pass

func _on_cast_successfully(slot: int) -> void:
	if slot == input:
		_timer = try_cooldown
		_is_open = true
		if open_effect:
			open_effect.execute(state_machine.entity)
