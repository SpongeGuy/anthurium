extends Component
class_name HeartbeatReceptor

@export var heartbeat_effect: EntityEffect
@export var bloom_potential: BloomPotentialComponent
@export var artery: ArteryComponent

func heartbeat(strength: float) -> void:
	if heartbeat_effect:
		heartbeat_effect.execute(entity)
		
	
