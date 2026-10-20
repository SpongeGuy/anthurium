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

## Time in seconds before this ability can be used again after [method execute] is called.
@export var cooldown: float = 0
## Minimum hold duration in seconds before [method execute] is called automatically.
## Useful for charge-style abilities.
@export var cast_time: float = 0
## When [code]true[/code], [method execute] will not fire.
@export var disabled: bool = false
## The icon displayed in the ability HUD slot.
@export var icon: Texture2D
## Emitted when the ability has fully resolved; for example, after an animation completes.
## [AbilityManager] and [BehaviorState] use this to know when the ability is done.
signal finished

## -1 means infinite uses
@export var uses: int = -1
@export var use_up_effect: EntityEffect = preload("uid://beo48ab5ks11a")

@export var ichor_cost: float = 0
@export var ichor_component: IchorComponent

var slot: int = -1

var _cd: float = 0

## The [Entity] this ability is currently attached to.
var entity: Entity
## The [AbilityManager] managing this ability.
var manager: AbilityManager
## The display name shown in the UI.
var display_name: String = "AbilityName"

func set_metadata(ability_name: String, ability_icon: Texture2D) -> void:
	display_name = ability_name
	icon = ability_icon
	

## Nodes created at runtime during [method initialize] that belong to this ability.
## Populate this in [method initialize] so [method clean_up] can free them when the ability is removed.
var created_nodes: Array[Node] = []

## Call this when adding nodes to the tree that this ability in particular uses and calls when executing.
## Nodes added this way are correctly cleaned up when the ability is destroyed.
## This version accepts a packedscene and initializes it as a child of the entity.
func create_new_system(scene: PackedScene) -> Node:
	var new: Node = scene.instantiate()
	created_nodes.append(new)
	entity.add_child(new)
	return new

## Call this when adding nodes to the tree that this ability in particular uses and calls when executing.
## Nodes added this way are correctly cleaned up when the ability is destroyed.
## This version assumes that systems have been created and initialized in initialize()
func register_new_system(node: Node) -> void:
	created_nodes.append(node)

## Frees all runtime-created nodes and clears entity and manager references.
## Called automatically when the ability is removed or transferred.
func clean_up() -> void:
	var count: int = 0
	slot = -1
	for node in created_nodes:
		count += 1
		if node is Node2D:
			entity.unregister_z_node(node)
		node.queue_free()
	created_nodes.clear()
	Log.info("Cleaned up %d nodes from %s" % [count, entity])
	
	
	entity = null
	manager = null
	
## Called once when this ability is assigned to an entity.
## Link exported component references here, and create any runtime nodes the ability needs.
## Append runtime-created nodes to [member created_nodes].
## also make sure to register nodes that need to be transformed based on z using entity.register_z_node()
## remember to define icon and display_name 
func initialize() -> void:
	pass
	
func _ready() -> void:
	finished.connect(_start_cooldown)



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
	var ichor_spend_successful: bool = true
	if disabled:
		return
	if _cd > 0.0:
		return
	if ichor_component:
		ichor_spend_successful = ichor_component.try_spend(ichor_cost)
	if not ichor_spend_successful:
		return
	_execute()
	
	

func _start_cooldown() -> void:
	_cd = cooldown

## The internal execution logic. Override this in subclasses to define what the ability does.
## Only called by [method execute] after cooldown and disabled checks pass.
func _execute() -> void:
	pass
