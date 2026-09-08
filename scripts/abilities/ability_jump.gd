extends Ability
class_name AbilityJump

@export var display_icon: Texture2D = preload("uid://bs0ft6kynohxb")
@export var power: float = 60.0

func initialize() -> void:
	display_name = "Leap"
	icon = display_icon
	

func on_pressed(modifier: bool) -> void:
	execute()
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass

## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	if entity._is_on_ground:
		entity.jump(power)
