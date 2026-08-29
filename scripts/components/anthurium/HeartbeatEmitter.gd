extends Component
class_name HeartbeatEmitter

@export var base_strength: float = 1.0
@export var min_strength_add: float = 0.1
@export var max_strength_add: float = 0.5
@export var artery: ArteryComponent

func heartbeat() -> void:
	var strength: float = base_strength + randf_range(min_strength_add, max_strength_add)
	artery.heartbeat(strength)
