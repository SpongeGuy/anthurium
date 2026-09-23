extends Ability
class_name AbilitySimpleMelee

var simple_melee_scene: PackedScene = load("uid://vdp42k0mrf4n")

@export var damage: float = 1.0

var rotator: Node2D
var hurtbox: Hurtbox
var facing: FacingComponent

func initialize() -> void:
	rotator = create_new_system(simple_melee_scene)
	hurtbox = rotator.find_child("Hurtbox")
	if not hurtbox:
		Log.error("fuck", true)
		
	hurtbox.damage = damage
	
	facing = entity.get_component(FacingComponent)

func _physics_process(delta: float) -> void:
	rotator.rotation = facing.get_direction_angle()
	
## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	hurtbox.activate(0.0, 0.2)

func on_pressed(modifier: bool) -> void:
	execute()
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass



