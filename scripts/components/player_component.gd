extends Component
class_name PlayerComponent

func _ready() -> void:
	var body: CharacterBody2D = owner
	PlayerManager.player = body

