extends Ability
class_name AbilitySpawnEntity

@export var entity_name: StringName

func initialize() -> void:
	display_name = "Spawn %s" % [entity_name]
	uses = 1

func on_pressed(modifier: bool) -> void:
	execute()
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass

## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	EntityManager.spawn(entity_name, entity.position, true, entity.z)
