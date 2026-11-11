extends Control
class_name UIScreen

@export var bg_color: ColorRect

@export var central_message: Label

	
func set_message(message: String) -> void:
	central_message.text = message

func change_color(color: Color) -> void:
	bg_color.color = color

func set_bg_visible(v: bool) -> void:
	bg_color.visible = v
	
func set_message_visible(v: bool) -> void:
	central_message.visible = v
