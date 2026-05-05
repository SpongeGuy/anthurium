extends Component
class_name ProximityDetector

@export var area: Area2D

@export_group("Filter")
@export var whitelist: Array[Script]
@export_enum("has all", "has any") var whitelist_inclusion: int = 0

@export var blacklist: Array[Script]
@export_enum("has all", "has any") var blacklist_inclusion: int = 0

@export var include_self: bool = false

@export_group("Collision", "collision")
@export_flags_2d_physics var collision_layer: int
@export_flags_2d_physics var collision_mask: int

signal detected(source: Entity, target: Entity)
signal lost(source: Entity, target: Entity)
signal detected_wall(tile_pos: Vector2i)
signal lost_wall(tile_pos: Vector2i)

func _ready() -> void:
	area.collision_layer = collision_layer
	area.collision_mask = collision_mask
	area.area_entered.connect(_on_area_entered)
	area.area_exited.connect(_on_area_exited)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_area_entered(other: Area2D) -> void:
	var target: Entity = _resolve_entity(other)
	if target and _passes_filter(target):
		detected.emit(entity, target)

func _on_area_exited(other: Area2D) -> void:
	var target: Entity = _resolve_entity(other)
	if target and _passes_filter(target):
		lost.emit(entity, target)

func _resolve_entity(other: Area2D) -> Entity:
	if other.owner is not Entity:
		return null
	if not include_self and other.owner == entity:
		return null
	return other.owner as Entity

func _passes_filter(subject: Entity) -> bool:
	if not blacklist.is_empty():
		var blacklisted: bool
		if blacklist_inclusion == 0:
			blacklisted = blacklist.all(func(c): return subject.has_component(c))
		else:
			blacklisted = blacklist.any(func(c): return subject.has_component(c))
		if blacklisted:
			return false

	if not whitelist.is_empty():
		if whitelist_inclusion == 0:
			return whitelist.all(func(c): return subject.has_component(c))
		else:
			return whitelist.any(func(c): return subject.has_component(c))
	return true

func _resolve_body(other: Node2D) -> TileMapLayer:
	if other is TileMapLayer:
		return other as TileMapLayer
	return null

func _on_body_entered(other: Node2D) -> void:
	if _resolve_body(other):
		detected_wall.emit(WorldGrid.world_to_tile(area.global_position))

func _on_body_exited(other: Node2D) -> void:
	if _resolve_body(other):
		lost_wall.emit(WorldGrid.world_to_tile(area.global_position))
