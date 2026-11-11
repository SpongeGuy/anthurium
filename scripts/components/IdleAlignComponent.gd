class_name IdleAlignComponent extends Component

const EPSILON: float = 1

@export var physics: PhysicsComponent
@export var min_idle_time: float = 3.0
@export var safe_tile_type: CellType.TerrainType = CellType.TerrainType.GROUND
@export var align_force: float = 25

var _idle_timer: float = 0.0
var aligned: bool = false

func _on_entity_initialized() -> void:
	_idle_timer = min_idle_time

func _physics_process(delta: float) -> void:
	if entity.velocity.is_zero_approx() and not aligned:
		_idle_timer += delta
	else:
		_idle_timer = 0
		aligned = false
	
	if aligned or _idle_timer < min_idle_time:
		return
	
	var safe_pos: Vector2 = WorldGrid.tile_to_world(WorldGrid.get_safe_coords(WorldGrid.world_to_tile(entity.global_position), safe_tile_type))
	
	if entity.global_position.distance_to(safe_pos) < EPSILON:
		entity.global_position = safe_pos
		aligned = true
		return
	
	entity.global_position = lerp(entity.global_position, safe_pos, 1 - (exp(-align_force * delta)))
