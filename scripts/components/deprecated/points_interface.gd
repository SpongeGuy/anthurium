extends Component
class_name PointsInterface

@export var opal_score: int = 0
@export var aura_score: int = 0

func add_opal_score(amount: int, source: Entity) -> void:
	opal_score += amount
	EventBus.added_opal_score_to.emit(entity, amount, source)

func add_aura_score(amount: int, source: Entity) -> void:
	aura_score += amount
	EventBus.added_aura_score_to.emit(entity, amount, source)
