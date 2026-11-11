extends Component
class_name ArteryComponent

var next: Array[ArteryLink] = []
var prev: Array[ArteryLink] = []
var accessories: Array[ArteryLink] = []

@export var growth_component: GrowthComponent
@export var max_accessories: int = 0
@export var max_branches: int = 1
@export var transmission_timer: float = 0.1

@export var ichor: IchorComponent



func heartbeat(strength: float) -> void:
	await get_tree().create_timer(transmission_timer).timeout
	
	for i in range(next.size() - 1, -1, -1):
		if not is_instance_valid(next[i].entity):
			next.remove_at(i)
			continue
		_diffuse_ichor(next[i])
		next[i].receptor.heartbeat(strength)
		next[i].artery.heartbeat(strength)
	
	for i in range(accessories.size() - 1, -1, -1):
		if not is_instance_valid(accessories[i].entity):
			accessories.remove_at(i)
			continue
		_diffuse_ichor(accessories[i])
		accessories[i].receptor.heartbeat(strength) # here
		
	if growth_component and next.size() < max_branches:
		var new_root: Entity = growth_component.try_grow_root(entity, prev)
		if new_root:
			next.append(ArteryLink.new(new_root))
		
	if growth_component and accessories.size() < max_accessories:
		var new_accessory: Entity = growth_component.try_grow_accessory(entity, prev)
		if new_accessory:
			accessories.append(ArteryLink.new(new_accessory))

func _diffuse_ichor(link: ArteryLink) -> void:
	if not link.ichor:
		return
	if not ichor:
		return
	var diff: float = ichor.ichor - link.ichor.ichor
	if diff > 0:
		var actual: float = ichor.take_ichor(diff * ichor.diffusion_rate)
		link.ichor.add_ichor(actual)
	elif diff < 0.0:
		var actual: float = link.ichor.take_ichor(-diff * link.ichor.diffusion_rate)
		ichor.add_ichor(actual)

class ArteryLink:
	var entity: Entity
	var receptor: HeartbeatReceptor
	var artery: ArteryComponent
	var ichor: IchorComponent
	
	func _init(e: Entity) -> void:
		entity = e
		if e.is_initialized:
			_resolve()
		else:
			e.entity_initialized.connect(_resolve, CONNECT_ONE_SHOT)
			
	func _resolve() -> void:
		receptor = entity.get_component(HeartbeatReceptor)
		artery = entity.get_component(ArteryComponent)
		ichor = entity.get_component(IchorComponent)
