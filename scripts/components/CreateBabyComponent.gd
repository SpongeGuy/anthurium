extends Component
class_name CreateBabyComponent

@export var ichor: IchorComponent
@export var baby_to_spawn: StringName
@export var take_from_max_ichor_portion_ratio: float = 0.25

var babies_made: int = 0


func spawn_new_baby() -> void:
	var bb: Entity = EntityManager.spawn_safely(baby_to_spawn, entity.global_position, false)
	await bb.entity_initialized
	var bb_ichor: IchorComponent = bb.get_component(IchorComponent)
	bb_ichor.ichor = ichor.take_ichor(ichor.max_ichor * take_from_max_ichor_portion_ratio)
	babies_made += 1


