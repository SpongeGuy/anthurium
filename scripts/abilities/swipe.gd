extends Ability
class_name AbilitySwipe

@export var locomotion: LocomotionHandler

@export var animator: SpriteAnimator
@export var hurtbox: Hurtbox
@export var sound_player: SoundPlayer
@export var rotator: Rotator


var icon_texture: Texture = preload("res://assets/textures/ability_icons/claw_icon.png")

var swipe_texture: Texture = preload("res://assets/textures/misc/swice.png")

var swipe_sound: AudioStream = preload("res://assets/sounds/effects/slice.wav")

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
		
		
		entity.add_child(rotator)
	
	# create sound player
	if not sound_player:
		sound_player = SoundPlayer.new()
		created_nodes.append(sound_player)
		var visibility: VisibilityComponent = entity.get_component(VisibilityComponent)
		if visibility:
			sound_player.visibility = visibility
		sound_player.pitch_min = 0.9
		sound_player.pitch_max = 1.1
		sound_player.possible_sounds.append(swipe_sound)
		
		entity.add_component(rotator, sound_player)
		
	
	# create animator
	if not animator:
		animator = SpriteAnimator.new()
		created_nodes.append(sound_player)
		var sprite: Sprite2D = Sprite2D.new()
		sprite.hframes = 4
		sprite.flip_h = true
		sprite.frame = 3
		sprite.position = Vector2(13, 0)
		animator.sprite = sprite
		var animation: SpriteAnimation = SpriteAnimation.new()
		animation.name = &"swipe"
		animation.frames = 4
		animation.speed = 25
		animation.loop = false
		animator.animations.append(animation)
		
		entity.add_component(rotator, animator)
		
	
	# create hurtbox
	if not hurtbox:
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(16, 16)
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		collision_shape.shape = shape
		collision_shape.position = Vector2(13, 0)
		hurtbox = Hurtbox.new()
		hurtbox.damage = 1
		hurtbox.collision_shape = collision_shape
		hurtbox.add_child(collision_shape)
		created_nodes.append(hurtbox)
		
		rotator.add_child(hurtbox)
		

	

func on_pressed(modifier: bool) -> void:
	animator.load_and_reset_animation("swipe")
	sound_player.play_sound()
	locomotion.disabled = true
	print(locomotion)
	await hurtbox.activate(0.0, 0.2)
	locomotion.disabled = false
	
