extends Node2D
class_name Shadow

@export var shadow_size: float = 1
@export var sprite: Sprite2D

func set_shadow_size(value: float) -> void:
	scale = Vector2(value, value)

func set_shadow_alpha(value: float) -> void:
	sprite.modulate.a = value
