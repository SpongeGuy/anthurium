@tool
extends EditorProperty

var _main_vbox = VBoxContainer.new()
var _bar_container = Control.new()
var _bar = ColorRect.new()           # background
var _range_rect = ColorRect.new()    # blue filled range
var _min_spin = EditorSpinSlider.new()
var _max_spin = EditorSpinSlider.new()

var _min_handle = Control.new()
var _max_handle = Control.new()

var _updating := false
var _dragging := false
var _drag_mode := ""  # "min", "max", "move"

func _init() -> void:
	add_child(_main_vbox)
	_main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Top bar area
	_bar_container.custom_minimum_size = Vector2(0, 24)
	_bar_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_main_vbox.add_child(_bar_container)
	
	_bar.color = Color(0.2, 0.2, 0.2)
	_bar.anchor_right = 1.0
	_bar.anchor_bottom = 1.0
	_bar_container.add_child(_bar)
	
	_range_rect.color = Color(0.3, 0.6, 1.0, 0.9)  # Godot blue-ish
	_bar_container.add_child(_range_rect)
	
	# Handles (small draggable areas)
	_min_handle.custom_minimum_size = Vector2(8, 24)
	_max_handle.custom_minimum_size = Vector2(8, 24)
	_bar_container.add_child(_min_handle)
	_bar_container.add_child(_max_handle)
	
	# Bottom spins
	var hbox = HBoxContainer.new()
	hbox.add_child(_min_spin)
	hbox.add_child(_max_spin)
	_main_vbox.add_child(hbox)
	
	_min_spin.value_changed.connect(_on_min_changed)
	_max_spin.value_changed.connect(_on_max_changed)
	
	_bar_container.gui_input.connect(_on_bar_gui_input)
	_min_handle.gui_input.connect(_on_handle_input.bind("min"))
	_max_handle.gui_input.connect(_on_handle_input.bind("max"))

func update_property() -> void:
	var value: Vector2 = get_edited_object()[get_edited_property()]
	_updating = true
	_min_spin.value = value.x
	_max_spin.value = value.y
	_update_visuals(value)
	_updating = false

func _update_visuals(value: Vector2) -> void:
	var total_range = max(0.0001, value.y - value.x)
	var global_min = min(value.x, value.y)  # support swapped min/max
	# For simplicity we assume x < y, but you can improve this
	
	var width = _bar_container.size.x
	_range_rect.position.x = (value.x / 1000.0) * width   # rough scaling - improve as needed
	_range_rect.size.x = (total_range / 1000.0) * width
	
	_min_handle.position.x = _range_rect.position.x - 4
	_max_handle.position.x = _range_rect.position.x + _range_rect.size.x - 4

# --- Input handling for dragging ---
func _on_bar_gui_input(event: InputEvent) -> void:
	# Implement click-to-move and handle dragging here
	pass  # I'll give you the full version if you want

func _on_handle_input(event: InputEvent, mode: String) -> void:
	# Dragging logic for min/max handles
	pass

func _on_min_changed(val: float) -> void:
	if _updating: return
	var v: Vector2 = get_edited_object()[get_edited_property()]
	v.x = val
	emit_changed(get_edited_property(), v)

func _on_max_changed(val: float) -> void:
	if _updating: return
	var v: Vector2 = get_edited_object()[get_edited_property()]
	v.y = val
	emit_changed(get_edited_property(), v)
