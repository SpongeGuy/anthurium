extends Node2D

@export var control: Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position = control.get_screen_position()
	print("p:", position)
	print(control.global_position)
