extends EsotericaResponse
class_name DamagedResponse

@export var felicity_delta: float = -5.0
@export var furor_delta: float = 1.0
@export var scale_with_damage: bool = true

func get_delta(context: Dictionary) -> Esoterica:
	var scale: float = context.get("damage", 1.0) if scale_with_damage else 1.0
	return Esoterica.new(felicity_delta * scale, furor_delta * scale, 0, 0, 0, 0)
