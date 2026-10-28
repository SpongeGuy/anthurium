class_name AbilityActivateHitboxAtSpeed extends Ability

var hurtbox: Hurtbox

var d: Texture2D = load("uid://f4uvgttmu56k")
var n: String = "Velocity Smash"

func initialize() -> void:
	display_name = n
	display_icon = d
	
	
	hurtbox = Hurtbox.new()
	hurtbox.create_circular_collision_shape(10, 0)
	hurtbox.position = entity.visual.position
	hurtbox.set_behavior_type(Hurtbox.BehaviorType.DEFAULT)
	
	entity.add_child(hurtbox)
	
	created_nodes.append(hurtbox)
	
## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	pass

func on_pressed(modifier: bool) -> void:
	pass
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass

func _physics_process(delta: float) -> void:
	if entity.velocity.length() > 100:
		hurtbox.set_behavior_type(Hurtbox.BehaviorType.CONSTANT)
	else:
		hurtbox.set_behavior_type(Hurtbox.BehaviorType.DEFAULT)

