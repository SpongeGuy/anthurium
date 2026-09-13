extends Lobe
class_name FightReactNearbyLobe

var target: Entity
@export var memory: Memory
@export var targeting: bool = true
@export var proximity: ProximityDetector
@export var attack_state: BehaviorState

var priority_strength: float = 1.0

func _ready() -> void:
	proximity.detected.connect(_on_entity_detected)
	proximity.lost.connect(_on_entity_lost)
	
	
func _process(delta: float) -> void:
	_process_every_ten_frames(delta)
	
func _on_entity_detected(source: Entity, t: Entity) -> void:
	if targeting:
		target = t
		changed.emit()
	
func _on_entity_lost(source: Entity, t: Entity) -> void:
	if targeting:
		target = null
		changed.emit()

func _process_every_ten_frames(delta: float) -> void:
	if Engine.get_process_frames() % 10 != 0:
		return
	
	_try_forget_invalid_target()
	
	
func _try_forget_invalid_target() -> void:
	if not target:
		return
		
	if not is_instance_valid(target):
		target = null
		changed.emit()
		
	
	
func evaluate() -> Array:
	# in this case, priority will either be 0 or 1 which will reflect if there is a target at all.
	# return [priority, attack_state]
	var priority: float
	if target:
		priority = 1
	else:
		priority = 0
		
	return [priority, attack_state]

func commit(memory: Memory) -> void:
	memory.set_value(Memory.Key.TARGET, target)
