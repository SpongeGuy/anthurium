extends Control
class_name InteractableUI

@export var neighbor_left: InteractableUI
@export var neighbor_up: InteractableUI
@export var neighbor_right: InteractableUI
@export var neighbor_down: InteractableUI


func on_select() -> void:
	pass
	
func on_activate() -> void:
	pass


func get_neighbor(direction: Vector2i) -> InteractableUI:
	match direction:
		Vector2i.LEFT: return neighbor_left
		Vector2i.RIGHT: return neighbor_right
		Vector2i.UP: return neighbor_up
		Vector2i.DOWN: return neighbor_down
	return null
