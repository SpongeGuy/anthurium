extends EntityEffect
class_name AnimateEntityEffect

@export var animation: SpriteAnimation

func execute(entity: Entity) -> void:
	var animator: SpriteAnimator = entity.get_component(SpriteAnimator)
	animator.load_and_reset_animation(animation.name)
	await animator.animation_finished
