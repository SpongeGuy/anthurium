extends Ability
class_name AbilitySpawnEntity

@export var entity_name: StringName
@export var spawn_effect: EntityEffect

func initialize() -> void:
	display_name = "Spawn %s" % [entity_name]
	uses = 1

func on_pressed(modifier: bool) -> void:
	pass
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	execute()

## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	if spawn_effect:
		spawn_effect.execute(entity)
	var new_e: Entity = EntityManager.simple_spawn(entity_name, entity.position, false, false)
	new_e.add_friend(entity)
	new_e.owned
	await new_e.entity_initialized
	
	if ichor_component:
		var their_ichor: IchorComponent = new_e.get_component(IchorComponent)
		if their_ichor:
			their_ichor.reset_stats(ichor_cost, ichor_cost)
	finished.emit()
