extends Node2D


func _process(delta: float) -> void:
	var time: float = AppController.time
	global_position = Vector2(sin(time), -sin(time))
