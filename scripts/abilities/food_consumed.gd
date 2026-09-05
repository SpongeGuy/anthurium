extends Ability
class_name AbilityFoodConsumed

@export var ichor: IchorComponent
@export var interactable: InteractableComponent
@export var stage_manager: ItemStageManager
@export var effect: EntityEffect

var _cache_ichor: IchorComponent
var _last_interacted: Entity

## Called when the ability's input is first pressed.[br]
## [param modifier] reflects whether the modifier input was held at the time of the press.
func on_pressed(modifier: bool) -> void:
	_execute()

## Called every frame while the ability's input is held.[br]
## [param hold_duration] is the total time in seconds the input has been held.[br]
## [param modifier] reflects the current state of the modifier input.
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass

## Called when the ability's input is released.[br]
## [param hold_duration] is the total time in seconds the input was held.[br]
## [param modifier] reflects whether the modifier input was held at the time of release.
func on_released(hold_duration: float, modifier: bool) -> void:
	pass
	
	
## The internal execution logic. Override this in subclasses to define what the ability does.
## Only called by [method execute] after cooldown and disabled checks pass.
func _execute() -> void:
	Log.info(str(entity))
	if effect:
		effect.execute(entity)
	
	var subject: Entity = interactable.recently_interacted
	if subject != _last_interacted:
		_cache_ichor = subject.get_component(IchorComponent)
		_last_interacted = subject
	if subject == null:
		_cache_ichor = null
	if _cache_ichor:
		var value: float = ichor.take_ichor(ichor.max_ichor / stage_manager.stages)
		_cache_ichor.add_ichor(value)
	
	stage_manager.increment_stage()
