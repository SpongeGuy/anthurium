extends Ability
class_name LaserShoot

func initialize() -> void:
	pass

func on_pressed(modifier: bool) -> void:
	pass
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass

## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	pass
