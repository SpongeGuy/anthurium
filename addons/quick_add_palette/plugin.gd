@tool
extends EditorPlugin

const QuickAddWindow = preload("res://addons/quick_add_palette/quick_add_window.gd")

var _window: Window
var _toolbar_button: Button

func _enter_tree() -> void:
	_window = QuickAddWindow.new()
	_window.editor_interface = get_editor_interface()
	get_editor_interface().get_base_control().add_child(_window)
	_window.hide()

	_toolbar_button = Button.new()
	_toolbar_button.text = "Quick Add"
	_toolbar_button.tooltip_text = "Open the Quick Add palette (Ctrl+B)"
	_toolbar_button.pressed.connect(_open_window)
	add_control_to_container(CONTAINER_TOOLBAR, _toolbar_button)

func _exit_tree() -> void:
	remove_control_from_container(CONTAINER_TOOLBAR, _toolbar_button)
	_toolbar_button.queue_free()
	_window.queue_free()

## Ctrl+A opens the palette, unless a text field currently has focus — in
## which case we back off and let it do its normal "select all text" thing.
func _shortcut_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode != KEY_B or not event.ctrl_pressed or event.shift_pressed or event.alt_pressed:
		return
	var focus_owner: Control = get_editor_interface().get_base_control().get_viewport().gui_get_focus_owner()
	if focus_owner is LineEdit or focus_owner is TextEdit:
		return
	_open_window()
	get_viewport().set_input_as_handled()

func _open_window() -> void:
	_window.refresh_list()
	_window.popup_centered(Vector2i(420, 900))
