extends Component
class_name ArteryComponent

var next: Array[ArteryLink] = []
var prev: Array[ArteryLink] = []
var accessories: Array[ArteryLink] = []

@export var growth_component: GrowthComponent
@export var max_accessories: int = 0
@export var max_branches: int = 1
@export var transmission_timer: float = 0.1

func heartbeat(strength: float) -> void:
	await get_tree().create_timer(transmission_timer).timeout
	
	for i in range(next.size()):
		if not is_instance_valid(next[i].entity):
			next.remove_at(i)
			continue
		next[i].receptor.heartbeat(strength)
		next[i].artery.heartbeat(strength)
	
	for i in range(accessories.size()):
		if not is_instance_valid(accessories[i]):
			accessories.remove_at(i)
			continue
		accessories[i].receptor.heartbeat(strength)
		accessories[i].artery.heartbeat(strength)
		
	if growth_component and next.size() < max_branches:
		var new_root: Entity = growth_component.try_grow_root(entity)
		if new_root:
			next.append(ArteryLink.new(new_root))
		
	if growth_component and accessories.size() < max_accessories:
		var new_accessory: Entity = growth_component.try_grow_accessory(entity)
		if new_accessory:
			accessories.append(ArteryLink.new(new_accessory))


class ArteryLink:
	var entity: Entity
	var receptor: HeartbeatReceptor
	var artery: ArteryComponent
	
	func _init(e: Entity) -> void:
		entity = e
		if e.is_initialized:
			_resolve()
		else:
			e.entity_initialized.connect(_resolve, CONNECT_ONE_SHOT)
			
	func _resolve() -> void:
		receptor = entity.get_component(HeartbeatReceptor)
		artery = entity.get_component(ArteryComponent)
