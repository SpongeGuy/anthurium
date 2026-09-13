extends BrainLobe
class_name LobeHunger


@export var hungry_threshold_ratio: float = 0.3
@export var satiated_threshold_ratio: float = 0.9

var _hungry: bool = false

var ichor: IchorComponent

func _on_registered(entity: Entity) -> void:
	ichor = entity.get_component(IchorComponent)

func get_priority(entity: Entity) -> float:
	var hunger_ratio: float = ichor.ichor / ichor.max_ichor
	if hunger_ratio <= hungry_threshold_ratio:
		_hungry = true
	elif hunger_ratio >= satiated_threshold_ratio:
		_hungry = false
		
	var hunger_bonus: float = 0.0
	hunger_bonus = 0.5 if _hungry else 0.0
	return 1 - ((hunger_ratio * 0.75)) + hunger_bonus

