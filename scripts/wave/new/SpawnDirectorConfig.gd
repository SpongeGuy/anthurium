class_name SpawnDirectorConfig extends Resource

## global spawning setup

## every entity the game can spawn, with weights and escalation curves
@export var spawn_table: SpawnTable
## possible spawn modifiers, each with its own chance and escalation curve
@export var modifiers: Array[SpawnModifierEntry] = []

@export_group("Pacing")
## seconds between spawn ticks (random in this range)
@export var spawn_interval_range: Vector2 = Vector2(1.0, 4.0)
## entities picked per tick (inclusive range)
@export var batch_range: Vector2i = Vector2i(1, 3)

@export_group("Escalation")
## escalation = seconds_in_level / seconds_per_escalation + level_value
@export var seconds_per_escalation: float = 100.0

@export_group("Entity Cap")
## cap grows with board size
@export var entities_per_ground_tile: float = 0.05
@export var entities_per_level: float = 0.1
@export var min_entities: int = 6
@export var hard_cap: int = 120

func max_entities_for(ground_tile_count: int, level_value: int) -> int:
	var raw: float = ground_tile_count * entities_per_ground_tile + level_value * entities_per_level
	return clampi(roundi(raw), min_entities, hard_cap)
