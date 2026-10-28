class_name UICharacterSelector extends Control

var selectors: Array[CharacterSelector]

var selector_scene: PackedScene = load("uid://vdlisehj0wve")

var hbox: HBoxContainer

var speed: float = 15

var idle_timers: Array[float] = [0, 0, 0, 0]
var idle_time: float = 10.0

const ACTIVE_POS: Vector2 = Vector2(0, 14)
const HIDDEN_POS: Vector2 = Vector2(0, -33)

var target_selector_positions: Array[Vector2] = [HIDDEN_POS, HIDDEN_POS, HIDDEN_POS, HIDDEN_POS]

func _ready() -> void:
	hbox = find_child("CONTAINER")
	for pos in target_selector_positions:
		pos = HIDDEN_POS
	
	
	selectors.resize(DeviceManager.MAX_PLAYERS)
	for slot in DeviceManager.MAX_PLAYERS:
		create_selector_element(slot)

func _process(delta: float) -> void:
	for i in range(selectors.size()):
		if selectors[i] == null:
			continue
		selectors[i].offset_transform_position = selectors[i].offset_transform_position.lerp(target_selector_positions[i], 1.0 - exp(delta * -speed))
	
	for i in range(idle_timers.size()):
		if idle_timers[i] > 0:
			idle_timers[i] -= delta
		
		if idle_timers[i] <= 0:
			target_selector_positions[i] = HIDDEN_POS

func create_selector_element(slot: int) -> void:
	var c: Control = Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(c)
	
	var sel: CharacterSelector = selector_scene.instantiate()
	c.add_child(sel)
	sel.set_anchors_and_offsets_preset(PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE)
	sel.offset_transform_enabled = true
	sel.offset_transform_position = HIDDEN_POS
	selectors[slot] = (sel)

func reset_idle_time(index: int) -> void:
	idle_timers[index] = idle_time


func hide_selector(index: int) -> void:
	target_selector_positions[index] = HIDDEN_POS
	selectors[index].disappear()

func show_selector(index: int) -> void:
	reset_idle_time(index)
	target_selector_positions[index] = ACTIVE_POS
	selectors[index].appear()
