extends EntityEffect
class_name EntityEffectUseAbility

@export var ability_id: int = 0


func _execute(entity: Entity) -> void:
	Log.info(str(entity))
	var input_component: InputComponent = entity.get_component(InputComponent)
		
	Log.info("input_component's entity: %s" % input_component.entity)
	input_component.press_action(ability_id)
	input_component.release_action(ability_id)
