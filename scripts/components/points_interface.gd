extends Component
class_name PointsInterface

@export var game_score: int = 0
@export var nutri_score: int = 0

func add_game_score(amount: int, source: Entity) -> void:
	game_score += amount
	EventBus.added_game_score_to.emit(entity, amount, source)

func add_nutri_score(amount: int, source: Entity) -> void:
	nutri_score += amount
	EventBus.added_nutri_score_to.emit(entity, amount, source)
