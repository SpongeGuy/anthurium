class_name SpawnEntry extends Resource

## one spawnable entity in the global [SpawnTable]

@export var entity_type: StringName
## weight once fully ramped in. higher = picked more often relative to other entries
@export var weight: float = 1.0
## free-form tags (eg "aquatic", "flying", "creepy", "loser", etc)[br]
## level themes can boost or suppres tags
@export var tags: Array[StringName] = []
## when this entity appears / fades. leave empty = always available at full weight
@export var curve: EscalationCurve

func weight_at(escalation: float) -> float:
	if curve == null:
		return weight
	return weight * curve.evaluate(escalation)
