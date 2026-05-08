extends Ability
class_name AbilitySwipe

@export var animator: SpriteAnimator
@export var hurtbox: Hurtbox
@export var locomotion: LocomotionHandler
@export var sound_player: SoundPlayer



func on_pressed() -> void:
	animator.load_and_reset_animation("swipe")
	sound_player.play_sound()
	locomotion.disabled = true
	await hurtbox.activate(0.0, 0.2)
	locomotion.disabled = false
	
