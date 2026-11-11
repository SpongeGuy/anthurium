class_name TweenUtil

static func tween_to(tween: Tween, object: Object, property_val: NodePath, final_val: Variant, duration: float) -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = object.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(object, property_val, final_val, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
