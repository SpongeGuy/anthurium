class_name AbilityChargeAndSmash extends Ability

func initialize() -> void:
	if not facing:
		facing = entity.get_component(FacingComponent)
	if not physics:
		physics = entity.get_component(PhysicsComponent)
	


# create a unique direction that lerps to where the entity is facing through a multiplier
# apply constant force to the entity towards the unique direction
# do damage to tiles near the entity
var force_direction: Vector2
var dir_change_factor: float = 1

var facing: FacingComponent
var physics: PhysicsComponent

var _timer: float = 0.0
var charge_timer_duration: float = 3.0

var charge_force: float = 10000

func _execute() -> void:
	_timer = charge_timer_duration
	
	

func _physics_process(delta: float) -> void:
	if _timer <= 0.0:
		finished.emit()
		return
	_timer -= delta
	print("sharting")
	force_direction = lerp(force_direction, facing.get_direction(), dir_change_factor * delta)
	force_direction = force_direction.normalized()

	physics.apply_force(force_direction, charge_force)
	
	

func on_pressed(modifier: bool) -> void:
	if _timer > 0.0:
		return
	execute()
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass



