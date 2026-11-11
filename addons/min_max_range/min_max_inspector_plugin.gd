@tool
extends EditorInspectorPlugin

const MinMaxEditor = preload("min_max_editor_property.gd")

func _can_handle(object: Object) -> bool:
	return true

func _parse_property(object: Object, type: int, name: String, hint: int, hint_string: String, usage: int, wide: bool) -> bool:
	# Trigger on properties ending with _range that are Vector2
	if type == TYPE_VECTOR2 and (name.ends_with("_range") or name.ends_with("Range")):
		var editor = MinMaxEditor.new()
		add_property_editor(name, editor)
		return true  # Hide default editor
	return false
