extends Resource
class_name CellData


var atlas_coordinate: Vector2 = Vector2.ZERO
@export var type: CellType
@export var invisible: bool = false
@export var max_health: float
@export var health: float

func take_damage(amount: float) -> bool:
	health = max(health - amount, 0.0)
	return health <= 0.0
