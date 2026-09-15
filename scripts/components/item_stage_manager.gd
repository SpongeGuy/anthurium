extends Component
class_name ItemStageManager

@export var animator: SpriteAnimator
@export var stage: int = 0
@export var stages: int = 5
@export var health_component: HealthComponent

@export var animations: Array[SpriteAnimation]


func _on_registered() -> void:
	pass # replace with function body


func increment_stage() -> void:
	stage += 1
	if stage >= stages:
		health_component.die()
	animator.play_and_reset_animation(animations[stage])
	
func set_stage(value: int) -> void:
	stage = value
	if stage >= stages:
		health_component.die()
	animator.play_and_reset_animation(animations[stage])
	
func set_correct_stage(current_value: float, max_value: float) -> void:
	var ratio: float = current_value / max_value
	var correct_stage: int = floor(stages * ratio)
	set_stage(correct_stage)
	
