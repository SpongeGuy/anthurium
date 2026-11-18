extends Ability

@export var power: float = 60.0

func initialize() -> void:
	pass
	

func on_pressed(_modifier: bool) -> void:
	execute()
	
func on_held(_hold_duration: float, _delta: float, _modifier: bool) -> void:
	pass
	
func on_released(_hold_duration: float, _modifier: bool) -> void:
	pass

## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	if entity._is_on_ground:
		entity.jump(power)
