class_name AbilityShootWaterBomb extends Ability

var facing: FacingComponent
@export var magnitude: float = 60
@export var power: float = 30

func initialize() -> void:
	facing = entity.get_component(FacingComponent)
	
## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	var rng: RandomNumberGenerator = RunRng.get_stream("entity")
	var direction: Vector2 = facing.get_direction()
	var wb: Entity = EntityManager.create_entity("water_bomb")
	var spawn_effect: EntityEffectJump = EntityEffectJump.new()
	spawn_effect.power = power + rng.randf_range(-5, 5)
	wb.spawn_effect = spawn_effect
	wb.add_friend(entity)
	var wb_phys: PhysicsComponent = wb.get_component(PhysicsComponent)
	var final_magnitude: float = magnitude + rng.randf_range(-5, 5)
	wb_phys.apply_impulse(direction, magnitude)
	EntityManager.spawn_entity(wb, entity.global_position, 0, false, false)
	finished.emit()

func on_pressed(modifier: bool) -> void:
	execute()
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass



