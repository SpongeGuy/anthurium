extends Component
class_name ArteryComponent

var next: Array[Entity] = []
var prev: Array[Entity] = []
var accessories: Array[Entity] = []

@export var growth_component: GrowthComponent
@export var max_accessories: int = 0
@export var max_branches: int = 1

func heartbeat(strength: float) -> void:
	for part in next:
		var receptor: HeartbeatReceptor = part.get_component(HeartbeatReceptor)
		receptor.heartbeat(strength)
	for part in accessories:
		var receptor: HeartbeatReceptor = part.get_component(HeartbeatReceptor)
		receptor.heartbeat(strength)
		
	if growth_component and next.size() < max_branches:
		var new_root: Entity = growth_component.try_grow_root(entity)
		#next.append(new_root)
		
	if growth_component and accessories.size() < max_accessories:
		var new_accessory: Entity = growth_component.try_grow_accessory(entity)
		#accessories.append(new_accessory)
