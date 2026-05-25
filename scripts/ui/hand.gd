extends Node2D

@export var current: InteractableUI
@export var animator: SpriteAnimator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not current:
		return
	global_position = current.get_screen_position() + (current.size - Vector2(8, 4))

				
func _input(event: InputEvent) -> void:
	if not GameState.state == GameState.Status.PAUSED:
		return
		
	for dir in DIR_ACTIONS:
		if Input.is_action_just_pressed(DIR_ACTIONS[dir]):
			var next = current.get_neighbor(dir)
			if next:
				current = next
	
const DIR_ACTIONS = {
	Vector2i.LEFT: "ui_left",
	Vector2i.RIGHT: "ui_right",
	Vector2i.UP: "ui_up",
	Vector2i.DOWN: "ui_down"
}
