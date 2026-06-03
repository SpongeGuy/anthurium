extends Ability
class_name AbilityDungeonCubeRush

@export var locomotion: LocomotionHandler
#@export var obstruction: ObstructionDetector
@export var hurtbox: Hurtbox
@export var physics: PhysicsComponent
@export var facing: FacingComponent

var active: bool = false

var icon_texture: Texture2D = preload("res://assets/textures/ability_icons/dcube_rush_icon.png")

var launch_sound: AudioStream = preload("res://assets/sounds/effects/dcube/launch(1).wav")
var land_sound: AudioStream = preload("res://assets/sounds/effects/thud2.wav")

func initialize() -> void:
	icon = icon_texture
	display_name = "Indomitable Rush"
	
	if not locomotion:
		locomotion = entity.get_component(LocomotionHandler)
	#if not obstruction:
		#obstruction = entity.get_component(ObstructionDetector)
	if not hurtbox:
		hurtbox = Hurtbox.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(18, 18)
		var collider = CollisionShape2D.new()
		collider.shape = shape
		hurtbox.add_child(collider)
		hurtbox.collision_shape = collider
		hurtbox.damage = 50
		
		created_nodes.append(hurtbox)
		entity.add_child(hurtbox)
		hurtbox.set_active(false)
	if not physics:
		physics = entity.get_component(PhysicsComponent)
	if not facing:
		facing = entity.get_component(FacingComponent)
		
func on_pressed(modifier: bool) -> void:
	execute()
	
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	if not active:
		return
	
	if physics.physics_velocity.length() < 800:
		physics.apply_force(facing.get_direction(), 2500)
	locomotion.handle_locomotion(delta)
	
func _on_wall_collision(source: Node) -> void:
	finished.emit()
	hurtbox.set_active(false)
	active = false
	physics.wall_collision.disconnect(_on_wall_collision)
	AudioManager.play_entity_sound([land_sound], entity)

## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	active = true
	hurtbox.set_active(true)
	physics.wall_collision.connect(_on_wall_collision)
	AudioManager.play_entity_sound([launch_sound], entity)

