extends BehaviorState
class_name StateGrowIntoNewEntity
## states should only include logic which alters data.
## all other functions should be outsourced to other components, such as visual effects or sounds.
@export var time_to_growth: float = 30.0
@export var entity_to_grow_into: StringName
@export var health_component: HealthComponent
@export var growth_effect: EntityEffect

var _timer: float

@export_group("Stages")
@export var item_stage: ItemStageManager
@export var stage_disqualification: int = 1
@export var disqualification_state: BehaviorState

## called once when the state machine does its initial switch to this state
func enter() -> void:
	_timer = time_to_growth
	
## called every frame while this state is active
func update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		grow()
		_timer = INF
	
	if item_stage and disqualification_state:
		if item_stage.stage >= stage_disqualification:
			state_machine.switch(disqualification_state)
	
## called every physics frame while this state is active
func physics_update(delta: float) -> void:
	pass
	
## called once when this state is switched from
func exit() -> void:
	pass

func grow() -> void:
	var e: Entity = EntityManager.spawn_safely(entity_to_grow_into, state_machine.entity.position)
	await e.entity_initialized
	if growth_effect:
		growth_effect.execute(e)
	health_component.die()
