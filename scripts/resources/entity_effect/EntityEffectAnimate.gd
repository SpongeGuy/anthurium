extends EntityEffect
class_name EntityEffectAnimate

@export var animation: SpriteAnimation

func _execute(entity: Entity) -> void:
	var animator: SpriteAnimator = entity.get_component(SpriteAnimator)
	animator.load_and_reset_animation(animation.name)
	await animator.animation_finished
