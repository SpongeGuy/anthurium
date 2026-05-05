extends Control
class_name UIScreen

@export var bg_color: ColorRect

@export var central_message: Label

func clear_all() -> void:
	central_message.text = ""
