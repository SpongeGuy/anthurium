extends Node

# PlayerManager autoload
##
## The single owner of player state. Everything about "who is playing, what are they controlling,
## and what are they doing right now" lives here, and nowhere else.
##
## Layering: PlayerManager sits BELOW AppController/GameInterface/UiController. It never calls them.
## It reports upward through signals; those layers connect and react:
##   - AppController  : join_requested, all_players_dead
##   - UiController   : slot_state_changed, selector_navigated, selection_confirm_requested,
##                      menu_input, player_bound, player_unbound, participants_changed
##   - GameInterface  : calls bind_entity() / unbind_entity() (the ONLY way an entity becomes a player)
##
## Per-slot state machine:
##   EMPTY     no device on this slot
##   IDLE      device present, no character
##   SELECTING character selector is open (left/right cycle, start confirms, select cancels)
##   PLAYING   slot has (or is about to get) an entity; start opens the ability UI
##   MANAGING  ability UI is open for this slot; the entity is frozen, inputs go to the UI; start closes it

enum SlotState{ EMPTY, IDLE, SELECTING, PLAYING, MANAGING }

class PlayerSlot:
	var entity: Entity
	var input: InputComponent
	var facing: FacingComponent
	var death_cb: Callable



## Emitted for every state change, including to EMPTY when a device leaves.
signal slot_state_changed(slot: int, state: SlotState)
## An entity became controlled by [param slot] / stopped being controlled by it.
signal player_bound(slot: int, entity: Entity)
signal player_unbound(slot: int, entity: Entity)
signal player_died(slot: int, entity: Entity)
## Selector input. [param direction] is -1 (left) or 1 (right).
signal selector_navigated(slot: int, direction: int)
## Start was pressed while selecting. UI should answer with [method confirm_selection].
signal selection_confirm_requested(slot: int)
## A slot confirmed a character. AppController should make sure a game is running, then
## call GameInterface.spawn_player(slot, character_id).
signal join_requested(slot: int, character_id: StringName)
## Navigation input while a slot is in MANAGING. [param action] is one of
## up/down/left/right/action_primary/action_secondary.
signal menu_input(slot: int, action: StringName)
## Number of distinct slots that have taken part in the current run.
signal participants_changed(count: int)
## Every participant is dead (and nobody is selecting). [param results] rows:
## {"slot": int, "character": StringName, "points": float}
signal all_players_dead(results: Array[Dictionary])


const MENU_ACTIONS: Array[StringName] = [&"up", &"down", &"left", &"right", &"action_primary", &"action_secondary"]
 
var slot_states: Dictionary[int, SlotState] = {}
## Slots that currently control an entity.
var slots: Dictionary[int, PlayerSlot] = {}
## Per-run scoreboard, one row per slot, filled in as players die.
var run_results: Array[Dictionary] = []
 
var _run_slots: Dictionary[int, bool] = {}
var _all_dead_emitted: bool = false
 
 
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DeviceManager.slot_connected.connect(_on_slot_connected)
	DeviceManager.slot_disconnected.connect(_on_slot_disconnected)
	for slot in DeviceManager.player_devices:
		slot_states[slot] = SlotState.IDLE


# ----------------------------------------------------------------------
# input polling (called once per frame by AppController)
# ----------------------------------------------------------------------
 
func poll(_delta: float) -> void:
	for slot in slot_states.keys():
		if slot_states.has(slot): # a release mid-loop may have removed it
			_poll_slot(slot)
	_poll_keyboard_join()
 
func _poll_slot(slot: int) -> void:
	var p: String = "p%d_" % slot
	match slot_states[slot]:
		SlotState.IDLE:
			if Input.is_action_just_pressed(p + "start"):
				_set_state(slot, SlotState.SELECTING)
		SlotState.SELECTING:
			if Input.is_action_just_pressed(p + "start"):
				selection_confirm_requested.emit(slot)
			elif Input.is_action_just_pressed(p + "select"):
				cancel_selection(slot)
			elif Input.is_action_just_pressed(p + "right"):
				selector_navigated.emit(slot, 1)
			elif Input.is_action_just_pressed(p + "left"):
				selector_navigated.emit(slot, -1)
		SlotState.PLAYING:
			if Input.is_action_just_pressed(p + "start") and slots.has(slot):
				_freeze_entity(slot)
				_set_state(slot, SlotState.MANAGING)
			else:
				_drive_entity(slot, p)
		SlotState.MANAGING:
			if Input.is_action_just_pressed(p + "start"):
				_set_state(slot, SlotState.PLAYING)
			else:
				for action in MENU_ACTIONS:
					if Input.is_action_just_pressed(p + action):
						menu_input.emit(slot, action)
 
## The keyboard has no slot until it asks for one.
func _poll_keyboard_join() -> void:
	if DeviceManager.has_keyboard():
		return
	if not Input.is_action_just_pressed(DeviceManager.KEYBOARD_JOIN_ACTION):
		return
	var slot: int = DeviceManager.claim_keyboard() # fires slot_connected -> IDLE
	if slot >= 0:
		_set_state(slot, SlotState.SELECTING)
 
func _drive_entity(slot: int, p: String) -> void:
	var s: PlayerSlot = slots.get(slot)
	if s == null:
		return # joined, entity still spawning
	if not is_instance_valid(s.entity) or not is_instance_valid(s.input):
		unbind_entity(slot)
		_return_to_idle(slot)
		_check_all_dead()
		return
	for id in s.input.actions.size():
		var action: String = p + s.input.actions[id]
		if Input.is_action_just_pressed(action):
			s.input.press_action(id)
		elif Input.is_action_just_released(action):
			s.input.release_action(id)
	if Input.is_action_just_pressed(p + "action_interact"):
		s.input.press_interact()
	elif Input.is_action_just_released(p + "action_interact"):
		s.input.release_interact()
	var dir: Vector2 = Input.get_vector(p + "left", p + "right", p + "up", p + "down")
	s.input.set_move_input_direction(dir)
	if s.facing:
		s.facing.set_direction_vector(dir)
 
func _freeze_entity(slot: int) -> void:
	var s: PlayerSlot = slots.get(slot)
	if s == null or not is_instance_valid(s.input):
		return
	s.input.set_move_input_direction(Vector2.ZERO)
	for id in s.input.actions.size():
		s.input.release_action(id)
	s.input.release_interact()
	if s.facing:
		s.facing.set_direction_vector(Vector2.ZERO)


# ----------------------------------------------------------------------
# selection flow
# ----------------------------------------------------------------------
 
## Called by UiController with whatever the slot's selector is showing.
func confirm_selection(slot: int, character_id: StringName) -> void:
	if slot_states.get(slot) != SlotState.SELECTING or character_id == &"":
		return
	_run_slots[slot] = true
	participants_changed.emit(_run_slots.size())
	_set_state(slot, SlotState.PLAYING)
	join_requested.emit(slot, character_id)
 
func cancel_selection(slot: int) -> void:
	if slot_states.get(slot) != SlotState.SELECTING:
		return
	_return_to_idle(slot)
	_check_all_dead()


# ----------------------------------------------------------------------
# entity binding: the ONE place an entity becomes a player
# ----------------------------------------------------------------------
 
func bind_entity(slot: int, entity: Entity) -> void:
	if slots.has(slot):
		unbind_entity(slot)
	var input: InputComponent = entity.get_component(InputComponent)
	if input == null:
		Log.error("Entity '%s' has no InputComponent, can't bind to slot %d." % [entity.basename, slot])
		return
	var ps: PlayerSlot = PlayerSlot.new()
	ps.entity = entity
	ps.input = input
	ps.facing = entity.get_component(FacingComponent)
	ps.death_cb = _on_entity_died.bind(slot, entity)
	entity.died.connect(ps.death_cb)
	input.player_controlled = true
	slots[slot] = ps
	player_bound.emit(slot, entity)
 
## Releases control of [param slot]'s entity without killing it. Returns the entity (or null).
## GameInterface uses this to carry players between levels.
func unbind_entity(slot: int) -> Entity:
	if not slots.has(slot):
		return null
	var ps: PlayerSlot = slots[slot]
	slots.erase(slot)
	var entity: Entity = ps.entity
	if is_instance_valid(entity):
		if entity.died.is_connected(ps.death_cb):
			entity.died.disconnect(ps.death_cb)
		if is_instance_valid(ps.input):
			ps.input.set_move_input_direction(Vector2.ZERO)
			ps.input.player_controlled = false
	player_unbound.emit(slot, entity)
	return entity if is_instance_valid(entity) else null


# ----------------------------------------------------------------------
# run bookkeeping
# ----------------------------------------------------------------------
 
## Called by GameInterface.start_new_run. Slots that already confirmed a character
## (PLAYING with no entity yet) are the players who triggered this run, so they stay.
func reset_run_records() -> void:
	for slot in slots.keys():
		unbind_entity(slot)
	run_results.clear()
	_run_slots.clear()
	_all_dead_emitted = false
	for slot in slot_states:
		if slot_states[slot] == SlotState.PLAYING or slot_states[slot] == SlotState.MANAGING:
			_run_slots[slot] = true
	participants_changed.emit(_run_slots.size())
 
func get_participant_count() -> int:
	return _run_slots.size()
 
func get_player_entities() -> Array[Entity]:
	var out: Array[Entity] = []
	for slot in slots:
		if is_instance_valid(slots[slot].entity):
			out.append(slots[slot].entity)
	return out
 
func is_any_player_active() -> bool:
	return slot_states.values().any(func(s: SlotState) -> bool: return s == SlotState.PLAYING or s == SlotState.SELECTING or s == SlotState.MANAGING)
 
func is_entity_player(entity: Entity) -> bool:
	for index in slots:
		if slots[index].entity == entity:
			return true
	return false
 
func _record_result(slot: int, entity: Entity) -> void:
	if not is_instance_valid(entity):
		return
	for row in run_results:
		if row.slot == slot:
			row.points += entity.points
			row.character = entity.basename
			return
	run_results.append({"slot": slot, "character": entity.basename, "points": entity.points})
 
func _check_all_dead() -> void:
	if _all_dead_emitted or _run_slots.is_empty():
		return
	for slot in slot_states:
		if slot_states[slot] in [SlotState.SELECTING, SlotState.PLAYING, SlotState.MANAGING]:
			return # someone is alive or about to join
	_all_dead_emitted = true
	all_players_dead.emit(run_results)


# ----------------------------------------------------------------------
# internals
# ----------------------------------------------------------------------
 
func _set_state(slot: int, state: SlotState) -> void:
	if slot_states.get(slot, SlotState.EMPTY) == state:
		return
	slot_states[slot] = state
	slot_state_changed.emit(slot, state)
 
## IDLE for a keyboard slot means giving the slot back so it doesn't block controllers.
func _return_to_idle(slot: int) -> void:
	_set_state(slot, SlotState.IDLE)
	if DeviceManager.is_keyboard_slot(slot):
		DeviceManager.release_slot(slot)
 
func _on_slot_connected(slot: int, _device: int) -> void:
	_set_state(slot, SlotState.IDLE)
 
func _on_slot_disconnected(slot: int) -> void:
	# An unplugged pad mid-game means that player leaves: score them and remove their entity.
	if slots.has(slot):
		var e: Entity = slots[slot].entity
		_record_result(slot, e)
		unbind_entity(slot)
		if is_instance_valid(e):
			e.die_and_despawn()
	if slot_states.erase(slot):
		slot_state_changed.emit(slot, SlotState.EMPTY)
	_check_all_dead()
 
func _on_entity_died(slot: int, entity: Entity) -> void:
	Log.debug("Player %d (%s) died." % [slot, entity])
	_record_result(slot, entity)
	unbind_entity(slot)
	player_died.emit(slot, entity)
	_return_to_idle(slot)
	_check_all_dead()






	



