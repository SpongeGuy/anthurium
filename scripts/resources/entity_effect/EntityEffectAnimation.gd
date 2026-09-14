extends EntityEffect
class_name EntityEffectAnimation


@export var animation: SpriteAnimation
@export var is_default_animation: bool = false
@export var speed_modifier: float = 1.0

## if true and the animation doesn't loop, this effect won't resolve until
## SpriteAnimator.animation_finished fires for this animation
@export var wait_for_finish: bool = true

func _execute(entity: Entity) -> void:
	var animator: SpriteAnimator = entity.get_component(SpriteAnimator)
	if not animator or not animation:
		Log.error("No animator or animation provided for %s" % [entity])
		return
	if is_default_animation:
		animator.set_default_animation(animation, speed_modifier)
	else:
		animator.play_and_reset_animation(animation, speed_modifier)
		if wait_for_finish and not animation.loop:
			await animator.animation_finished
