extends DeathState
class_name AbilityDeathState

@export var input: InputComponent
@export var ability_to_use: int = 0
	
func _death_behavior() -> void:
	input.press_action(ability_to_use)
	input.release_action(ability_to_use)
	
## called every frame while this state is active
func update(delta: float) -> void:
	pass
	
## called every physics frame while this state is active
func physics_update(delta: float) -> void:
	pass
	
## called once when this state is switched from
func exit() -> void:
	pass
