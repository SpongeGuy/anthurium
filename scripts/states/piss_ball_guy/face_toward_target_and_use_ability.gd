extends BehaviorState
class_name FaceTargetUseAbilityState

@export var memory: Memory
@export var facing: FacingComponent
@export var abilities: AbilityManager
@export var input: InputComponent
@export var ability_to_use: int = 0
@export var default_state: BehaviorState
@export var locomotion: LocomotionHandler

var _timer: float = 0.0

func enter() -> void:
	randomize()
	for i in range(abilities.abilities.size()):
		if i != ability_to_use:
			abilities.abilities[i].disabled = true
	
	
func update(delta: float) -> void:
	pass
	
func physics_update(delta: float) -> void:
	if memory.has(Memory.Key.TARGET):
		var target: Entity = memory.get_value(Memory.Key.TARGET) as Entity
		input.move_input_direction = (Vector2.ZERO)
		facing.change_direction(target.global_position - state_machine.entity.global_position)
		input.press_action(ability_to_use)
		locomotion.handle_locomotion(delta)
	else:
		state_machine.switch(default_state)
	
	
	
func exit() -> void:
	input.release_action(ability_to_use)
	for i in range(abilities.abilities.size()):
		if i != ability_to_use:
			abilities.abilities[i].disabled = false
