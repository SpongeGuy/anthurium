extends Resource
class_name CellType

enum TerrainType{GROUND, WALL, GAP, OUT_OF_BOUNDS}
enum TileMode{TILING, RANDOM}

@export_group("Texture Properties")
@export var terrain: TerrainType
## tileset that this celltype points to
@export var tileset_id: int
## does this tileset tile or does it pick random textures from the tileset?
@export var tile_mode: TileMode
## if RANDOM tile_mode is on, will choose one of these textures.
## if this array is empty, RANDOM will choose any available tile from the tileset.
@export var possible_textures: Array[Vector2i]
## does this tileset tile with cells that don't own the same tileset_id?
@export var tile_with_aliens: bool

@export_group("Other Properties")
@export var max_health: float = 10
@export var destroyed_type: StringName = &""
