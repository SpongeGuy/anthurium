extends Component
class_name SpriteManipulator

# ----------------------------------
# provides methods to manipulate the frames of a sprite easily
# -----------------------------------

@export var sprite: Sprite2D

func _on_registered() -> void:
	pass # replace with function body


func set_frame(frame: int) -> void:
	sprite.frame = frame
