extends Control
class_name UIStage

@export var starting_element: InteractableUI

var last_selected_element: InteractableUI

func _ready() -> void:
	register_children(self)
			

func register_children(node: Control) -> void:
	for child in node.get_children():
		if child is InteractableUI:
			child.stage = self
		elif child is Control:
			register_children(child)
