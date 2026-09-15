extends EntityEffect
class_name EntityEffectUseAbility

@export var ability_id: int = 0


func _execute(entity: Entity) -> void:
	Log.info(str(entity))
	var input_component: InputComponent = entity.get_component(InputComponent)
		
	input_component.press_action(ability_id)
	input_component.release_action(ability_id)
