extends Component
class_name ArteryComponent

var next: Array[Entity] = []
var prev: Array[Entity] = []
var accessories: Array[Entity] = []

@export var growth_component: GrowthComponent
@export var max_accessories: int = 0
@export var max_branches: int = 1
@export var transmission_timer: float = 0.1

func heartbeat(strength: float) -> void:
	await get_tree().create_timer(transmission_timer).timeout
	
	for part in next:
		if not is_instance_valid(part):
			continue
		var receptor: HeartbeatReceptor = part.get_component(HeartbeatReceptor)
		var artery: ArteryComponent = part.get_component(ArteryComponent)
		receptor.heartbeat(strength)
		artery.heartbeat(strength)
	for part in accessories:
		if not is_instance_valid(part):
			continue
		var receptor: HeartbeatReceptor = part.get_component(HeartbeatReceptor)
		receptor.heartbeat(strength)
		
	if growth_component and next.size() < max_branches:
		var new_root: Entity = growth_component.try_grow_root(entity)
		if new_root:
			next.append(new_root)
		
	if growth_component and accessories.size() < max_accessories:
		var new_accessory: Entity = growth_component.try_grow_accessory(entity)
		if new_accessory:
			accessories.append(new_accessory)
