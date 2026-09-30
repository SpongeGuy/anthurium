extends EditorInspectorPlugin

const Tool = preload("uid://bqr3fxrvrmc32")
const ActionButtonScene = preload("uid://cxasq8wcxx21c")
const SettingsPopupScene = preload("uid://dyyawj2ata8gu")

var action_button: VBoxContainer
var copy_button: Button
var paste_button: Button
var setting_button: Button
var settings_popup: AcceptDialog
var tree_box: HBoxContainer
var tile_panel: Control

var base_control: Control
var tileset_editor: Node
var atlas_source_editor: Node
var atlas_source_proxy: Object
var atlas_source: TileSetAtlasSource
var copied_atlas_source: TileSetAtlasSource

var selected_tiles: Array[TileData]
var copied_tiles: Dictionary[Vector2i, TileData]
var copied_property_filters: Dictionary

func get_current_atlas_source() -> TileSetAtlasSource:
	tileset_editor = base_control.find_children("*", "TileSetEditor", true, false).front()
	atlas_source_editor = tileset_editor.find_children("*", "TileSetAtlasSourceEditor", true, false).front()
	atlas_source_proxy = Tool.get_connected_objects_by_class(atlas_source_editor, "TileSetAtlasSourceProxyObject").back()
	return Tool.get_source(atlas_source_proxy)

func _can_handle(object: Object) -> bool:
	return object.is_class("AtlasTileProxyObject")

func _parse_begin(object: Object) -> void:
	base_control = EditorInterface.get_base_control()
	action_button = ActionButtonScene.instantiate(); add_custom_control(action_button)
	copy_button = action_button.find_child("CopyButton", true, false); copy_button.pressed.connect(copy_tiles)
	paste_button = action_button.find_child("PasteButton", true, false); paste_button.pressed.connect(paste_tiles)
	setting_button = action_button.find_child("SettingButton", true, false); setting_button.pressed.connect(open_setting)

	selected_tiles = Tool.get_selected_tiles(object); atlas_source = get_current_atlas_source()
	copy_button.disabled = selected_tiles == copied_tiles.values(); paste_button.disabled = copied_tiles.is_empty(); setting_button.disabled = copied_tiles.is_empty()
	if not settings_popup:
		settings_popup = SettingsPopupScene.instantiate()
		tree_box = settings_popup.find_child("TreeBox"); tile_panel = settings_popup.find_child("TilePanel")
		settings_popup.confirmed.connect(apply_setting)

	var change_terrain_button: Button = action_button.find_child("ChangeTerrainButton", true, false)
	var source_terrain_input: SpinBox = action_button.find_child("SourceTerrainInput", true, false)
	var target_terrain_input: SpinBox = action_button.find_child("TargetTerrainInput", true, false)
	change_terrain_button.pressed.connect(change_terrain.bind(source_terrain_input, target_terrain_input))

func copy_tiles() -> void:
	copied_tiles = Tool.get_copied_tiles(selected_tiles, atlas_source)
	copied_atlas_source = atlas_source
	copy_button.disabled = true; paste_button.disabled = copied_tiles.is_empty(); setting_button.disabled = copied_tiles.is_empty()
	copied_property_filters.clear()
	var coords_keys: Array[Vector2i] = copied_tiles.keys().duplicate(true)
	coords_keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x if a.y == b.y else a.y < b.y)
	var sort_copied_tiles: Dictionary[Vector2i, TileData]
	for coords: Vector2i in coords_keys: sort_copied_tiles.set(coords, copied_tiles.get(coords))
	copied_tiles = sort_copied_tiles

func paste_tiles() -> void:
	var paste_tiles: Dictionary[Vector2i, TileData] = Tool.get_copied_tiles(selected_tiles, atlas_source)
	Tool.paste_tile_data_properties(copied_tiles, paste_tiles, copied_property_filters)

func change_terrain(source_terrain_input: SpinBox, target_terrain_input: SpinBox) -> void:
	var source_terrain: int = source_terrain_input.value; var target_terrain: int = target_terrain_input.value
	Tool.change_terrain(selected_tiles, source_terrain, target_terrain)

func open_setting() -> void:
	settings_popup.show() if settings_popup.get_parent() else EditorInterface.popup_dialog(settings_popup)
	tree_box.update_copied_tiles(copied_tiles)
	tile_panel.set("atlas_source", copied_atlas_source); tile_panel.update_copied_tiles(copied_tiles)

func apply_setting() -> void:
	var enabled_coords: Dictionary[Vector2i, bool] = tile_panel.get_enabled_coords()
	copied_property_filters = tree_box.get_selected_properties(enabled_coords)
