extends Node2D
class_name HUDParticle

var _tween: Tween
var _color: Color = Color.WHITE
var _radius: float = 4.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, _radius, _color)


func fly_to(target_screen_pos: Vector2, duration: float, ease_type: Tween.EaseType = Tween.EASE_IN) -> void:
	_tween = create_tween()
	_tween.set_ease(ease_type)
	_tween.set_trans(Tween.TRANS_BACK)
	_tween.tween_property(self, "position", target_screen_pos, duration)
	_tween.tween_callback(queue_free)
