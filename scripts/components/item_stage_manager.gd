extends Component
class_name ItemStageManager

@export var animator: SpriteAnimator
@export var stage: int = 0
@export var stages: int = 5


func _on_registered() -> void:
	pass # replace with function body


func increment_stage() -> void:
	stage += 1
	var string: String = "stage_" + str(stage)
	animator.load_and_reset_animation(string)
	if stage >= stages:
		entity.queue_free()
