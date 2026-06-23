extends EntityEffect
class_name EntityEffectUseAbility

@export var ability_id: int = 0
var input_component: InputComponent

func _execute(entity: Entity) -> void:
	if not input_component:
		input_component = entity.get_component(InputComponent)
		
	input_component.press_action(ability_id)
	input_component.release_action(ability_id)
