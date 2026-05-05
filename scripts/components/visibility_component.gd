extends Component
class_name VisibilityComponent


# ---------------------------------------------
# changes visibility of all sprites in the array
# ---------------------------------------------


@export var nodes: Array[Node2D]

var _visible: bool = true

signal visibility_changed(to: bool)

func set_visibility(to: bool) -> void:
	_visible = to
	visibility_changed.emit(to)
	if to == true:
		for node in nodes:
			node.visible = true
	else:
		for node in nodes:
			node.visible = false
