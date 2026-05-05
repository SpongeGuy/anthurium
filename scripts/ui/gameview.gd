extends Control
class_name UIGameView

@export var bg_color: ColorRect

@export var central_message: Label

func clear_all() -> void:
	central_message.text = ""
