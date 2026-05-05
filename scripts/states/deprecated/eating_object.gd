extends BehaviorState
class_name EatingObjectState

@export var target_seeker: TargetSeeker
@export var timer_length: float = 2.0
var eat_time: float = 0.0
@export var eat_radius: float = 25.0
@export var exit_state: BehaviorState
@export var eating_power: int = 1

var eat_target: Node2D

signal interrupted()

func enter() -> void:
	eat_target = target_seeker.current_target
		
	interrupted.connect(_on_interrupted)
	eat_time = 0.0
		
func update(delta: float) -> void:
	if not is_instance_valid(eat_target):
		interrupted.emit()
		return
	
	if eat_target.global_position.distance_to(owner.global_position) > eat_radius:
		interrupted.emit()
		
	eat_time += delta
	
	if eat_time >= timer_length:
		var edible: EdibleComponent = eat_target.get_node_or_null("EdibleComponent")
		if edible:
			edible.eat(eating_power)
		
func exit() -> void:
	interrupted.disconnect(_on_interrupted)

func _on_interrupted() -> void:
	state_machine.switch(exit_state)
