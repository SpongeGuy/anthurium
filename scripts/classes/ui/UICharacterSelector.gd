class_name UICharacterSelector extends Control
## Pure view: one slide-down selector per player slot. It owns the cycling and the idle timeout
## but knows nothing about game state. UiController feeds it input from PlayerManager and
## reads the chosen character back out.

## The selector for [param slot] sat open too long. UiController answers with PlayerManager.cancel_selection.
signal selector_timed_out(slot: int)

const ACTIVE_POS: Vector2 = Vector2(0, 14)
const HIDDEN_POS: Vector2 = Vector2(0, -33)

@export var speed: float = 15.0
@export var idle_time: float = 10.0

var selectors: Array[CharacterSelector] = []
var selector_scene: PackedScene = load("uid://vdlisehj0wve")

var _hbox: HBoxContainer
var _targets: Array[Vector2] = []
var _idle_timers: Array[float] = []


func _ready() -> void:
	_hbox = find_child("CONTAINER")
	for slot in DeviceManager.MAX_PLAYERS:
		_targets.append(HIDDEN_POS)
		_idle_timers.append(0.0)
		selectors.append(null)
		_create_selector_element(slot)

func _process(delta: float) -> void:
	var weight: float = 1.0 - exp(-speed * delta)
	for i in selectors.size():
		var sel: CharacterSelector = selectors[i]
		if sel:
			sel.offset_transform_position = sel.offset_transform_position.lerp(_targets[i], weight)
		if _idle_timers[i] > 0.0:
			_idle_timers[i] -= delta
			if _idle_timers[i] <= 0.0:
				_idle_timers[i] = 0.0
				selector_timed_out.emit(i)

func _create_selector_element(slot: int) -> void:
	var c: Control = Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hbox.add_child(c)

	var sel: CharacterSelector = selector_scene.instantiate()
	c.add_child(sel)
	sel.set_anchors_and_offsets_preset(PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE)
	sel.offset_transform_enabled = true
	sel.offset_transform_position = HIDDEN_POS
	selectors[slot] = sel

func show_selector(slot: int) -> void:
	reset_idle_time(slot)
	_targets[slot] = ACTIVE_POS
	selectors[slot].appear()

func hide_selector(slot: int) -> void:
	_idle_timers[slot] = 0.0
	_targets[slot] = HIDDEN_POS
	selectors[slot].disappear()

func reset_idle_time(slot: int) -> void:
	_idle_timers[slot] = idle_time

## [param direction] > 0 cycles right, otherwise left.
func cycle(slot: int, direction: int) -> void:
	if direction > 0:
		selectors[slot].cycle_right()
	else:
		selectors[slot].cycle_left()
	reset_idle_time(slot)

func get_selected_id(slot: int) -> StringName:
	return selectors[slot].get_selected_playable_name()
