extends Ability
class_name AbilityIncrementStage

@export var stage_manager: ItemStageManager

func initialize() -> void:
	if not stage_manager:
		stage_manager = entity.get_component(ItemStageManager)

func on_pressed(modifier: bool) -> void:
	if stage_manager:
		stage_manager.increment_stage()
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass

## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	pass

