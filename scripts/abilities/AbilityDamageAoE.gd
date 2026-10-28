extends Ability
class_name AbilityDamageAoE


@export var radius: float = 10
@export var damage: float = 25


var hurtbox: Hurtbox

var n: String = "Burst"
var d: Texture2D = load("uid://d4ixqeh4puotd")

func initialize() -> void:
	display_icon = d
	display_name = n
	hurtbox = Hurtbox.new(damage)
	hurtbox.create_circular_collision_shape(radius)
	entity.add_child(hurtbox)
	
	register_new_system(hurtbox)
	
	
		

func on_pressed(modifier: bool) -> void:
	execute()
	
	
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass

## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	hurtbox.activate(0.0, 0.05)
