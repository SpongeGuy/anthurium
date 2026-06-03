extends Node
class_name Ability

## Base class for all abilities a creature can possess.
##
## Abilities are transferable between creatures via [AbilityManager].
## Override [method initialize] to link or create required components on the owning [Entity].
## Override [method on_pressed], [method on_held], and [method on_released] to define input-driven behavior.
## Override [method _execute] for cooldown-gated logic triggered by [method execute].[br][br]
## Any nodes created at runtime during [method initialize] should be appended to [member created_nodes]
## so they are properly cleaned up when the ability is transferred or removed.

## The [Entity] this ability is currently attached to.
var entity: Entity
## The [AbilityManager] managing this ability.
var manager: AbilityManager
## The display name shown in the UI.
var display_name: String = "AbilityName"

## Nodes created at runtime during [method initialize] that belong to this ability.
## Populate this in [method initialize] so [method clean_up] can free them when the ability is removed.
var created_nodes: Array[Node] = []

## Frees all runtime-created nodes and clears entity and manager references.
## Called automatically when the ability is removed or transferred.
func clean_up() -> void:
	var count: int = 0
	
	for node in created_nodes:
		count += 1
		node.queue_free()
	created_nodes.clear()
	print("cleaned up ", count, " nodes from ", entity)
	
	entity = null
	manager = null
	
## Called once when this ability is assigned to an entity.
## Link exported component references here, and create any runtime nodes the ability needs.
## Append runtime-created nodes to [member created_nodes].
func initialize() -> void:
	pass
	
func _ready() -> void:
	finished.connect(_start_cooldown)

## Time in seconds before this ability can be used again after [method execute] is called.
@export var cooldown: float = 0
## Minimum hold duration in seconds before [method execute] is called automatically.
## Useful for charge-style abilities.
@export var cast_time: float = 0
## When [code]true[/code], [method execute] will not fire.
@export var disabled: bool = false
## The icon displayed in the ability HUD slot.
@export var icon: Texture2D
## Emitted when the ability has fully resolved — for example, after an animation completes.
## [AbilityManager] and [BehaviorState] use this to know when the ability is done.
signal finished

var _cd: float = 0

## Called when the ability's input is first pressed.[br]
## [param modifier] reflects whether the modifier input was held at the time of the press.
func on_pressed(modifier: bool) -> void:
	pass

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

func _process(delta: float) -> void:
	if _cd > 0.0:
		_cd = max(_cd - delta, 0.0)

## Attempts to execute the ability. Does nothing if [member disabled] is [code]true[/code]
## or the ability is on cooldown. Starts the cooldown timer on success.
func execute() -> void:
	if disabled:
		return
	if _cd > 0.0:
		return
	_execute()

func _start_cooldown() -> void:
	_cd = cooldown

## The internal execution logic. Override this in subclasses to define what the ability does.
## Only called by [method execute] after cooldown and disabled checks pass.
func _execute() -> void:
	pass
