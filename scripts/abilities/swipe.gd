extends Ability
class_name AbilitySwipe

@export var locomotion: LocomotionHandler

@export var animator: SpriteAnimator
@export var hurtbox: Hurtbox
@export var rotator: Rotator


var icon_texture: Texture = preload("res://assets/textures/ability_icons/claw_icon.png")

var swipe_texture: Texture = preload("res://assets/textures/misc/swice.png")

var swipe_sound: VoiceProfile = preload("res://assets/resources/voices/swipe.tres")

func initialize() -> void:
	display_name = "Swipe"
	icon = icon_texture
	# link locomotion
	if not locomotion:
		locomotion = entity.get_component(LocomotionHandler)
		
	if not rotator:
		rotator = Rotator.new()
		created_nodes.append(rotator)
		rotator.name = "SwipeAbilityComponents"
		var facing: FacingComponent = entity.get_component(FacingComponent)
		rotator.facing = facing
		rotator.position = Vector2(0, -4)
		
		created_nodes.append(rotator)
		
		
		entity.add_child(rotator)
		
	
	# create animator
	if not animator:
		animator = SpriteAnimator.new()
		var sprite: Sprite2D = Sprite2D.new()
		sprite.hframes = 4
		sprite.flip_h = true
		sprite.frame = 3
		sprite.position = Vector2(13, 0)
		sprite.texture = swipe_texture
		animator.sprite = sprite
		
		rotator.add_child(sprite)
		
		var animation: SpriteAnimation = SpriteAnimation.new()
		animation.name = &"swipe"
		animation.frames = 4
		animation.speed = 25
		animation.loop = false
		animator.animations.append(animation)
		
		created_nodes.append(animator)
		
		entity.add_component(rotator, animator)
		
	
	# create hurtbox
	if not hurtbox:
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(16, 16)
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		collision_shape.shape = shape
		collision_shape.position = Vector2(13, 0)
		hurtbox = Hurtbox.new()
		hurtbox.damage = 0.7
		hurtbox.collision_shape = collision_shape
		hurtbox.add_child(collision_shape)
		
		created_nodes.append(hurtbox)
		
		rotator.add_child(hurtbox)
		

	

func on_pressed(modifier: bool) -> void:
	animator.load_and_reset_animation("swipe")
	AudioManager.play_voice(swipe_sound, entity)
	locomotion.disabled = true
	await hurtbox.activate(0.0, 0.2)
	locomotion.disabled = false
	
