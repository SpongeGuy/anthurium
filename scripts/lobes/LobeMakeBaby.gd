extends BrainLobe
class_name LobeMakeBaby

## lifespan must be above this threshold to make baby
@export var lifespan_floor_ratio: float = 0.25
## ichor must be above this threshold to make baby
@export var ichor_floor_ratio: float = 0.5

func get_priority(entity: Entity) -> float:
	var ichor: IchorComponent = entity.get_component(IchorComponent)
	var baby_maker: CreateBabyComponent = entity.get_component(CreateBabyComponent)
	
	var lifespan_bonus: float = 0.0
	var ichor_bonus: float = 0.0
	
	return 0.0

