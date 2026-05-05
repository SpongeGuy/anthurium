extends Component
class_name StageController

# -------------------------
# generic component for controlling a stage in an entity's life cycle
# ------------------------

signal advanced_to_stage(stage: int)
signal demoted_to_stage(stage: int)

var stage: int = 0


@export var set_initial_stage: int = 0
@export var min_stage: int = 0
@export var max_stage: int = 0

func _on_registered() -> void:
	pass # replace with function body

func _init_set_stage() -> void:
	if set_initial_stage > 0:
		for i in set_initial_stage:
			increment_stage()
	else:
		for i in abs(set_initial_stage):
			decrement_stage()
		
func increment_stage() -> void:
	if stage + 1 > max_stage:
		return
	
	stage += 1
	advanced_to_stage.emit(stage)
	
func decrement_stage() -> void:
	if stage - 1 < min_stage:
		return
	
	stage -= 1
	demoted_to_stage.emit(stage)

func _ready() -> void:
	_init_set_stage()
