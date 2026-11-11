class_name SpawnModifierEntry extends Resource

## one possible modifier in the [SpawnDirector]'s modifier list.
## every spawn rolls each entry independently: chance * curve(escalation)

@export var modifier: SpawnModifier
## chance per spawn once the curve is at full strength
@export_range(0, 1) var chance: float = 0.1
## when this modifier becomes possible / fades. leave empty = always at full chance
@export var curve: EscalationCurve
## only applies to entities with at least one of these tags. empty = applies to anything.
@export var requires_any_tag: Array[StringName] = []

func chance_at(escalation: float) -> float:
	if curve == null:
		return chance
	return chance * curve.evaluate(escalation)

func applies_to(tags: Array[StringName]) -> bool:
	if requires_any_tag.is_empty():
		return true
	for t in requires_any_tag:
		if tags.has(t):
			return true
	return false
