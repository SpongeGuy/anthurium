extends Ability
class_name AbilitySwipe

var locomotion: LocomotionHandler
var animator: SpriteAnimator
var hurtbox: Hurtbox
var facing: FacingComponent

var swipe_animation: SpriteAnimation

var rotator: Node2D

var n: String = "Swipe"
var d: Texture = load("uid://cgskihl2d35os") # clow_icon.png

var swipe_texture: Texture = preload("res://assets/textures/misc/swice.png")

var swipe_sound: VoiceProfile = preload("res://assets/resources/voices/swipe.tres")

func initialize() -> void:
	display_name = n
	display_icon = d
	locomotion = entity.get_component(LocomotionHandler)
		

	rotator = Node2D.new()
	rotator.position = entity.visual.position
	entity.add_child(rotator)
	entity.register_z_node(rotator)
	created_nodes.append(rotator)
	
	# create animator
	animator = SpriteAnimator.new()
	var sprite: Sprite2D = Sprite2D.new()
	sprite.hframes = 4
	sprite.flip_h = true
	sprite.frame = 3
	sprite.position = Vector2(13, 0)
	sprite.texture = swipe_texture
	animator.sprite = sprite
	
	rotator.add_child(sprite)
	
	swipe_animation = SpriteAnimation.new()
	swipe_animation.name = &"swipe"
	swipe_animation.frames = 4
	swipe_animation.speed = 25
	swipe_animation.loop = false
	
	
	
	
	entity.add_child(animator)
	created_nodes.append(animator)
	

	hurtbox = Hurtbox.new(0.7)
	hurtbox.create_circular_collision_shape(8, 12)
	hurtbox.height = 0.1
	rotator.add_child(hurtbox)
	
	
	
	facing = entity.get_component(FacingComponent)

func _physics_process(delta: float) -> void:
	if rotator:
		rotator.rotation = facing.get_direction_angle()

func on_pressed(modifier: bool) -> void:
	execute()
	
func _execute() -> void:
	animator.play_and_reset_animation(swipe_animation)
	AudioManager.play_voice(swipe_sound, entity)
	locomotion.disabled = true
	await hurtbox.activate(0.0, 0.2)
	locomotion.disabled = false
