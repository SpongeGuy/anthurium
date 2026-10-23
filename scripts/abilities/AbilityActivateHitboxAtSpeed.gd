class_name AbilityActivateHitboxAtSpeed extends Ability

var hurtbox: Hurtbox

func initialize() -> void:
	hurtbox = Hurtbox.new()
	hurtbox.create_circular_collision_shape(8, 0)
	hurtbox.position = entity.visual.position
	hurtbox.set_behavior_type(Hurtbox.BehaviorType.DEFAULT)
	
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
	print(entity.velocity.length())
	if entity.velocity.length() > 50:
		hurtbox.set_behavior_type(Hurtbox.BehaviorType.CONSTANT)
	else:
		hurtbox.set_behavior_type(Hurtbox.BehaviorType.DEFAULT)

