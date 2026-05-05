extends BehaviorState
class_name FaceTargetUseAbilityState

@export var memory: Memory
@export var facing: FacingComponent
@export var abilities: AbilityManager
@export var input: InputComponent
@export var time_to_use_ability: float = 1
@export var ability_to_use: int = 0
@export var sprite: Sprite2D

@export var default_state: BehaviorState

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
		input.move_input_direction = Vector2.ZERO
		facing.change_direction(target.global_position - state_machine.entity.global_position)
		_timer += delta
		if _timer >= time_to_use_ability:
			_timer = 0 - randf_range(0, 1)
			input.press_action(ability_to_use)
			input.release_action(ability_to_use)
	else:
		state_machine.switch(default_state)
	
	sprite.position = floor(sin(GameState.time * 15)) * (Vector2.RIGHT * 2)
	
func exit() -> void:
	for i in range(abilities.abilities.size()):
		if i != ability_to_use:
			abilities.abilities[i].disabled = false
	sprite.position = Vector2.ZERO
