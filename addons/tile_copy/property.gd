@tool
extends HBoxContainer

const Tool = preload("uid://bqr3fxrvrmc32")

var property_tree_item: TreeItem
var copied_tiles: Dictionary[Vector2i, TileData]
var property_items: Dictionary[Vector2i, Array]
var property_tree_items: Dictionary[String, TreeItem]
var row_tree_items: Dictionary
var coords_tree_items: Dictionary
var path_tree_items: Dictionary

@onready var property_tree: Tree = %PropertyTree

func update_copied_tiles(value: Dictionary[Vector2i, TileData]) -> void:
	if copied_tiles.values() != value.values(): copied_tiles = value
	else: return

	property_items.clear()
	property_tree_items.clear(); row_tree_items.clear(); coords_tree_items.clear(); path_tree_items.clear()
	property_tree.clear(); property_tree_item = create_check_item(property_tree, null, "Property")
	for coords: Vector2i in value:
		var tile_data: TileData = value[coords]
		var properties: Dictionary[StringName, Variant] = Tool.get_flat_tile_data_properties(tile_data)
		for property_name: StringName in properties: init_property_tree(property_name, properties[property_name], coords)
	for tree_item: TreeItem in property_tree_item.get_children(): tree_item.set_collapsed_recursive(true)

func init_property_tree(property_name: StringName, value: Variant, coords: Vector2i) -> void:
	var parts: PackedStringArray = String(property_name).split("/")
	var property_key: String = parts[0]
	if not property_tree_items.has(property_key):
		property_tree_items[property_key] = create_check_item(property_tree, property_tree_item, property_key)
		row_tree_items[property_key] = {}; coords_tree_items[property_key] = {}; path_tree_items[property_key] = {}
	var property_item: TreeItem = property_tree_items[property_key]
	var rows: Dictionary = row_tree_items[property_key]
	var row_text: String = "Row: %d" % coords.y
	if not rows.has(coords.y): rows[coords.y] = create_check_item(property_tree, property_item, row_text)
	var row_item: TreeItem = rows[coords.y]
	var property_coords: Dictionary = coords_tree_items[property_key]
	if not property_coords.has(coords):
		property_coords[coords] = create_check_item(property_tree, row_item, "(%d, %d)" % [coords.x, coords.y])
		property_coords[coords].set_metadata(0, coords)
		if not property_items.has(coords): property_items[coords] = []
		property_items[coords].append(property_coords[coords])
	var coords_item: TreeItem = property_coords[coords]
	var property_paths: Dictionary = path_tree_items[property_key]
	if not property_paths.has(coords): property_paths[coords] = {}
	var paths: Dictionary = property_paths[coords]
	var path: String = property_key
	var value_item: TreeItem = coords_item
	for index: int in range(1, parts.size()):
		path += "/%s" % parts[index]
		if not paths.has(path): paths[path] = create_check_item(property_tree, value_item, parts[index])
		value_item = paths[path]
	value_item.set_text(1, var_to_str(value)); value_item.set_metadata(1, property_name)

func create_check_item(tree: Tree, parent: TreeItem, text: String, column: int = 0) -> TreeItem:
	var item: TreeItem = tree.create_item(parent)
	item.set_cell_mode(column, TreeItem.CELL_MODE_CHECK)
	item.set_editable(column, true); item.set_text(column, text); item.set_checked(column, true)
	return item

func update_children(parent: TreeItem, checked: bool, column: int = 0) -> void:
	for child: TreeItem in parent.get_children():
		if child.get_child_count() > 0: update_children(child, checked, column)
		child.set_checked(column, checked); child.set_indeterminate(column, false)

func update_parent(child: TreeItem, column: int = 0) -> void:
	var parent: TreeItem = child.get_parent()
	while parent:
		var has_checked: bool; var has_unchecked: bool; var has_indeterminate: bool
		for tree_item: TreeItem in parent.get_children():
			if tree_item.is_indeterminate(column): has_indeterminate = true
			elif tree_item.is_checked(column): has_checked = true
			else: has_unchecked = true
		parent.set_indeterminate(column, has_indeterminate or (has_checked and has_unchecked))
		parent.set_checked(column, has_checked and not has_unchecked and not has_indeterminate)
		parent = parent.get_parent()

func get_selected_properties(enabled_coords: Dictionary[Vector2i, bool]) -> Dictionary:
	var selected_properties: Dictionary
	for coords: Vector2i in copied_tiles:
		var property_names: Array[StringName]
		if enabled_coords.has(coords):
			for item: TreeItem in property_items.get(coords, []): get_selected_property_names(item, property_names)
		selected_properties[coords] = property_names
	return selected_properties

func get_selected_property_names(item: TreeItem, property_names: Array[StringName]) -> void:
	if item.get_child_count() > 0:
		for child: TreeItem in item.get_children(): get_selected_property_names(child, property_names)
		return
	var property_name: Variant = item.get_metadata(1)
	if item.is_checked(0) and property_name is StringName: property_names.append(property_name)

func property_edited(source: Tree) -> void:
	var editor_tree_item: TreeItem = source.get_edited()
	var column: int = source.get_edited_column(); var checked: bool = editor_tree_item.is_checked(column)
	editor_tree_item.set_indeterminate(column, false)
	update_children(editor_tree_item, checked, column); update_parent(editor_tree_item, column)
