extends Component
class_name VisibilityComponent


# ---------------------------------------------
# changes visibility of all sprites in the array
# ---------------------------------------------



@export var hide_in_invisible_cells: bool = true
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

func is_visible() -> bool:
	return _visible

func register_visibility_node(node: Node2D) -> void:
	nodes.append(node)


func _ready() -> void:
	WorldGrid.cell_hidden.connect(_on_cell_hidden)
	WorldGrid.cell_revealed.connect(_on_cell_revealed)
	WorldGrid.cells_visibled.connect(_on_cells_visibled)
	
func _on_registered() -> void:
	resolve_visibility(WorldGrid.safe_get_cell(WorldGrid.world_to_tile(entity.global_position)))

func _on_cell_hidden(coords: Vector2i) -> void:
	resolve_visibility(get_current_cell())
	
func _on_cell_revealed(coords: Vector2i) -> void:
	resolve_visibility(get_current_cell())
	
func _on_cells_visibled(batch: Dictionary[Vector2i, bool]) -> void:
	resolve_visibility(get_current_cell())

func get_current_cell() -> CellData:
	return WorldGrid.safe_get_cell(WorldGrid.world_to_tile(entity.global_position))


func resolve_visibility(cell: CellData) -> void:
	if not cell:
		return
	if cell.invisible and _visible == true:
		set_visibility(false)
	
	if not cell.invisible and _visible == false:
		set_visibility(true)
