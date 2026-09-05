extends Control
class_name InteractableUI

@export var neighbor_left: Control
@export var neighbor_up: Control
@export var neighbor_right: Control
@export var neighbor_down: Control

@export var type: UIHand.State = UIHand.State.DEFAULT

var stage: UIStage
@export var selection_location: Marker2D


func select(hand: UIHand) -> void:
	pass
	
func activate(hand: UIHand) -> void:
	pass

func deselect(hand: UIHand) -> void:
	pass

func get_neighbor(direction: Vector2i) -> Control:
	match direction:
		Vector2i.LEFT: return neighbor_left
		Vector2i.RIGHT: return neighbor_right
		Vector2i.UP: return neighbor_up
		Vector2i.DOWN: return neighbor_down
	return null
