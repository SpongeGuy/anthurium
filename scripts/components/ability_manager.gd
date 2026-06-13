extends Component
class_name AbilityManager

# -----------------------------------------------
# interfaces with an inputcomponent to activate abilities
# -----------------------------------------------

@export var abilities: Array[Ability] = [null, null, null, null]
var _disabled: Array[bool] = [false, false, false, false]
@export var ichor_component: IchorComponent
@export var input: InputComponent

signal ability_registered(slot: int, ability: Ability)
signal ability_unregistered(slot: int)




func _ready() -> void:
	input.input_just_pressed.connect(_on_input_just_pressed)
	input.input_just_released.connect(_on_input_just_released)
	
func _on_registered() -> void:
	# initialize any abilities already present as children in the scene tree
	for child in get_children():
		if child is Ability:
			_register_ability_to_first_slot(child)
			
			



	
func is_full() -> bool:
	return abilities.all(func(a): return a != null)
	
func get_first_empty_slot() -> int:
	for i in abilities.size():
		if abilities[i] == null:
			return i
	return -1
	
func has_ability(slot: int) -> bool:
	return abilities.get(slot) != null
	
func get_ability(slot: int) -> Ability:
	return abilities.get(slot)
	



# -------------------------------------
# slot manipulation
# --------------------------------------

## Places [param ability] into [param slot] (default: first available slot).
##
## Reparents the ability under this manager and initializes it for the owning
## entity. Returns true on success, false if the target slot is occupied or
## the manager is full.
func add_ability(ability: Ability, slot: int = -1) -> bool:
	var target: int = slot if slot >= 0 else get_first_empty_slot()
	if target < 0 or target >= abilities.size():
		return false
	if abilities[target] != null:
		return false
	if ability.get_parent():
		ability.reparent(self)
	else:
		add_child(ability)
	_initialize_ability(ability, target)
	return true
	

## Removes the ability from [param slot] and returns it without freeing it.
##
## Tears down all runtime state (created nodes, entity/manager references) so
## the ability can be safely transferred to another entity or stored in a shard.
## Returns null if the slot was already empty.
func extract_ability(slot: int) -> Ability:
	var ability: Ability = abilities.get(slot)
	if ability == null:
		return null
	abilities[slot] = null
	ability.clean_up()
	ability_unregistered.emit(slot)
	return ability

## Removes and permanently frees the ability in [param slot].
## Returns true if an ability was destroyed, false if the slot was empty.
func destroy_ability(slot: int) -> bool:
	var ability: Ability = extract_ability(slot)
	if ability == null:
		return false
	ability.queue_free()
	return true

## Swaps the contents of [param slot_a] and [param slot_b].
##
## Handles every case: both filled, one empty, or both empty. Emits change
## signals for each slot so listeners see both halves of the swap.
func swap_slots(slot_a: int, slot_b: int) -> void:
	if slot_a == slot_b:
		return
	var a: Ability = abilities.get(slot_a)
	var b: Ability = abilities.get(slot_b)
	if a == b:
		return
	abilities[slot_a] = b
	abilities[slot_b] = a
	_emit_slot_changed(slot_a, b)
	_emit_slot_changed(slot_b, a)
	

## Extracts the ability from [param slot] and spawns an [AbilityShard] at
## [param position], transferring the ability into the shard's [AbilityContainer].
##
## Returns the spawned shard entity, or null if the slot was empty.
## A scatter offset is applied when no explicit position is supplied.
func drop_to_shard(slot: int, position: Vector2) -> Entity:
	var ability: Ability = extract_ability(slot)
	if ability == null:
		return null
	var shard: Entity = EntityManager.spawn_safely(&"ability_shard", position)
	var container: AbilityContainer = shard.get_component(AbilityContainer)
	container.add_ability.call_deferred(ability)
	return shard
	

# -----------------------------------
# enable/disable
# -----------------------------------

func disable(id: int) -> void:
	_disabled[id] = true
	
func enable(id: int) -> void:
	_disabled[id] = false
	
	
# -------------------------------
# input handling
# --------------------------------

func _on_input_just_pressed(id: int) -> void:
	if not abilities.get(id):
		return
	if _disabled[id]:
		return
	abilities[id].on_pressed(input.modifier)

func _on_input_just_released(id: int, held_time: float) -> void:
	if not abilities.get(id):
		return
	abilities[id].on_released(held_time, input.modifier)

func _process(delta: float) -> void:
	for i in range(input.is_held.size()):
		if not input.is_held[i]:
			continue
		if i >= abilities.size() or abilities[i] == null:
			continue
		abilities[i].on_held(input.hold_time[i], delta, input.modifier)
			
func _initialize_ability(ability: Ability, slot: int) -> void:
	ability.entity = entity
	ability.manager = self
	ability.initialize()
	abilities[slot] = ability
	ability_registered.emit(slot, ability)
	
func _register_ability_to_first_slot(ability: Ability) -> void:
	var slot: int = get_first_empty_slot()
	if slot < 0:
		return
	_initialize_ability(ability, slot)
	
func _emit_slot_changed(slot: int, ability: Ability) -> void:
	if ability != null:
		ability_registered.emit(slot, ability)
	else:
		ability_unregistered.emit(slot)
		

		
