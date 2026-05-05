extends BehaviorState
class_name PlopState

@export var orb_scene: PackedScene
@export var animator: SpriteAnimator
@export var exit_state: BehaviorState

@export var time_to_plop: float = 3.0
var plop_timer: float = 0.0

func enter() -> void:
	if animator:
		animator.load_and_reset_animation("plop")
	
func update(delta: float) -> void:
	plop_timer += delta
	if plop_timer >= time_to_plop:
		EntityManager.spawn_safely(&"plopp_orb", owner.global_position)
		plop_timer = 0.0
		state_machine.switch(exit_state)
	

	
func exit() -> void:
	pass
