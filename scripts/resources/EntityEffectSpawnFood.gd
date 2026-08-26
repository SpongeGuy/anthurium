extends EntityEffect
class_name EntityEffectSpawnFood

@export var entity_name: StringName

func _execute(entity: Entity) -> void:
	var ichor_component: IchorComponent = entity.get_component(IchorComponent)
	if not ichor_component:
		push_error("EntityEffectSpawnFood: entity does not have ichor component!")
		return
		
	var max: float = ichor_component.max_ichor
	var current: float = ichor_component.ichor
	var food: Entity = EntityManager.spawn(entity_name, entity.global_position)
	
	food.ready.connect(_apply_ichor_values.bind(food, max, current), CONNECT_ONE_SHOT)
	
func _apply_ichor_values(food: Entity, max: float, current: float) -> void:
	var ichor_component: IchorComponent = food.get_component(IchorComponent)
	ichor_component.max_ichor = max
	ichor_component.ichor = current
