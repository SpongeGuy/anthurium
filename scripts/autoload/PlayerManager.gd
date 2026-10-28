extends Node

class PlayerSlot:
	var entity: Entity
	var input: InputComponent
	var facing: FacingComponent

var slots: Dictionary[int, PlayerSlot] = {}

enum SlotState{ EMPTY, IDLE, SELECTING, PLAYING }

var slot_states: Dictionary[int, SlotState] = {}
signal slot_state_changed(slot: int, state: SlotState)

## for use in GameInterface
signal player_initialized(slot: int, entity: Entity)
signal player_destroyed(slot: int, entity: Entity)

signal player_set(slot: int, entity: Entity)
signal player_died(slot: int, entity: Entity)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DeviceManager.slot_connected.connect(_on_slot_connected)
	DeviceManager.slot_disconnected.connect(_on_slot_disconnected)
	for slot in DeviceManager.player_devices:
		_set_state(slot, SlotState.IDLE)

func _set_state(slot: int, state: SlotState) -> void:
	slot_states[slot] = state
	slot_state_changed.emit(slot, state)	


func control_selector(_delta: float) -> void:
	for slot in PlayerManager.slot_states:
		var p: String = "p%d_" % slot
		var state: SlotState = slot_states[slot]
		
		if Input.is_action_just_pressed(p + "start"):
			match state:
				SlotState.IDLE:
					if AppController.game_state == AppController.GameStatus.PLAYING:
						_set_state(slot, SlotState.SELECTING)
						UiController.c_selector.show_selector(slot)
				SlotState.PLAYING:
					if AppController.world_ready:
						AppController.toggle_pause()
				SlotState.SELECTING:
					confirm_selection(slot)
		elif state == SlotState.SELECTING:
			if Input.is_action_just_pressed(p + "right"):
				UiController.c_selector.selectors[slot].cycle_right()
				UiController.c_selector.reset_idle_time(slot)
			elif Input.is_action_just_pressed(p + "left"):
				UiController.c_selector.selectors[slot].cycle_left()
				UiController.c_selector.reset_idle_time(slot)


func confirm_selection(slot: int) -> void:
	var id: StringName = UiController.c_selector.selectors[slot].get_selected_playable_name()
	UiController.c_selector.hide_selector(slot)
	_set_state(slot, SlotState.PLAYING)
	
	if AppController.app_state != AppController.AppStatus.GAME:
		await AppController.switch_app_state(AppController.AppStatus.GAME)
	elif not AppController.world_ready:
		await AppController.game_started
	await GameInterface.spawn_player(slot, id)

func cancel_selection(slot: int) -> void:
	UiController.c_selector.hide_selector(slot)
	_set_state(slot, SlotState.IDLE)

func _on_slot_connected(slot: int) -> void:
	_set_state(slot, SlotState.IDLE)

func _on_slot_disconnected(slot: int) -> void:
	if slot_states.get(slot) == SlotState.SELECTING:
		cancel_selection(slot)

func is_any_player_active() -> bool:
	return slot_states.values().any(func(s): return s == SlotState.PLAYING or s == SlotState.SELECTING)

func is_entity_player(entity: Entity) -> bool:
	for index in slots:
		if slots[index].entity == entity:
			return true
	return false

func initialize_player(index: int, entity: Entity) -> void:
	set_player(index, entity)
	player_initialized.emit()

func set_player(index: int, entity: Entity) -> void:
	if slots.has(index):
		var old: PlayerSlot = slots[index]
		old.input.player_controlled = false
		old.entity.died.disconnect(_on_player_death)
	
	var slot: PlayerSlot = PlayerSlot.new()
	slot.entity = entity
	slot.input = entity.get_component(InputComponent)
	slot.facing = entity.get_component(FacingComponent)
	slot.input.player_controlled = true
	slots[index] = slot
	var cb: Callable = _on_player_death.bind(index, entity)
	if not entity.died.is_connected(cb):
		entity.died.connect(cb)
	player_set.emit(index, entity)
	
## Called by [AppController] when `Controller.PLAYER` is the `active_controller`
func control_players(_delta: float) -> void:
	for index in slots:
		var s: PlayerSlot = slots[index]
		var p: String = "p%d_" % index
		
		for id in s.input.actions.size():
			var action: String = p + s.input.actions[id]
			if Input.is_action_just_pressed(action):
				s.input.press_action(id)
		
		if Input.is_action_just_pressed(p + "action_interact"):
			s.input.press_interact()
		if Input.is_action_just_released(p + "action_interact"):
			s.input.release_interact()
	
		s.input.move_input_direction = Input.get_vector(p+"left", p+"right", p+"up", p+"down")
		if s.facing:
			s.facing.set_direction_vector(s.input.move_input_direction)
			
	

func _on_player_death(index: int, entity: Entity) -> void:
	Log.debug("Player %d (%s) died." % [index, entity])
	player_died.emit(index, entity)
	_set_state(index, SlotState.IDLE)
