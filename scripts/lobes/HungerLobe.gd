extends BrainLobe
class_name LobeHunger


@export var hungry_threshold_ratio: float = 0.3
@export var satiated_threshold_ratio: float = 0.9


func get_priority(entity: Entity) -> float:
	var ichor: IchorComponent = entity.get_component(IchorComponent)
	var hunger_ratio: float = ichor.ichor / ichor.max_ichor
	var hunger_bonus: float = 0.0
	if hunger_ratio <= hungry_threshold_ratio:
		hunger_bonus = 0.5

	return 1 - ((hunger_ratio * 0.75)) + hunger_bonus

