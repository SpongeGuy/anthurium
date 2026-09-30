@tool
extends Control

const Tool = preload("uid://bqr3fxrvrmc32")
const TilePreviewScene: PackedScene = preload("uid://dn48owpjbw5q7")

var atlas_source: TileSetAtlasSource
var copied_tiles: Dictionary[Vector2i, TileData]
var tiles_rect: Rect2i

@onready var grid_container: GridContainer = $GridContainer

func update_copied_tiles(value: Dictionary[Vector2i, TileData]) -> void:
	if copied_tiles.values() == value.values(): return
	copied_tiles = value
	for child: Node in grid_container.get_children(): child.queue_free()
	update_tiles_rect()
	draw_atlas_texture()

func update_tiles_rect() -> void:
	var region_size: Vector2i = atlas_source.texture_region_size
	var front_tile_coords: Vector2i = copied_tiles.keys().front()
	var back_tile_coords: Vector2i = copied_tiles.keys().back()
	tiles_rect.position = front_tile_coords * region_size
	tiles_rect.size = (back_tile_coords - front_tile_coords) * region_size + region_size

func draw_atlas_texture() -> void:
	var max_col: int; var max_row: int
	for coords: Vector2i in copied_tiles:
		max_col = max(max_col, coords.x); max_row = max(max_row, coords.y)

	grid_container.custom_minimum_size = tiles_rect.size
	grid_container.columns = max_col + 1
	grid_container.pivot_offset = grid_container.size / 2

	var atlas_texture: Texture2D = atlas_source.texture
	var atlas_image: Image = atlas_texture.get_image()
	var image_format: Image.Format = atlas_image.get_format()
	var tile_size: Vector2i = atlas_source.texture_region_size
	var coords_offset: Vector2i = Tool.get_tile_data_coords(atlas_source, copied_tiles.values().front())
	for y: int in max_row + 1:
		for x: int in max_col + 1:
			var coords: Vector2i = Vector2i(x, y)
			var tile_preview: TextureRect = TilePreviewScene.instantiate()
			var tile_image: Image = Image.create_empty(tile_size.x, tile_size.y, true, image_format)
			tile_image.blend_rect(atlas_image, Rect2i((coords + coords_offset) * tile_size, tile_size), Vector2i.ZERO)
			tile_preview.texture = ImageTexture.create_from_image(tile_image)
			tile_preview.set("disable", not copied_tiles.has(coords))
			grid_container.add_child(tile_preview)

func get_enabled_coords() -> Dictionary[Vector2i, bool]:
	var enabled_coords: Dictionary[Vector2i, bool]
	for coords: Vector2i in copied_tiles:
		var index: int = coords.y * grid_container.columns + coords.x
		var tile_preview: TextureRect = grid_container.get_child(index)
		if tile_preview.get("enable"): enabled_coords[coords] = true
	return enabled_coords
