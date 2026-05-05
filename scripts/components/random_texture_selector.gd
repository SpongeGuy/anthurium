extends Component
class_name RandomTextureSelector

@export var sprite: Sprite2D
@export var choices: Array[Texture2D]

func _ready() -> void:
	sprite.texture = choices.pick_random()

func _on_registered() -> void:
	pass # replace with function body


