extends Ability
class_name AbilitySimpleMelee

var simple_melee_scene: PackedScene = load("uid://vdp42k0mrf4n")

@export var radius: float = 8.0
@export var damage: float = 1.0
@export var offset: float = 10.0
@export var activation_effect: EntityEffect

var hurtbox: Hurtbox
var facing: FacingComponent

func initialize() -> void:
	hurtbox = Hurtbox.new(damage)
	hurtbox.create_circular_collision_shape(radius, offset)
	
	entity.add_child(hurtbox)
	register_new_system(hurtbox)
	
	facing = entity.get_component(FacingComponent)

func _physics_process(delta: float) -> void:
	hurtbox.set_rotation(facing.get_direction_angle())
	
## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	hurtbox.activate(0.0, 0.2)

func on_pressed(modifier: bool) -> void:
	execute()
	if activation_effect:
		activation_effect.execute(entity)
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass



