extends Component
class_name AnthuriumIchorAccumulator

@export var ichor_per_time: float = 1.0
@export var time: float = 1.0
var _timer: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_timer = time
	
# Called when the component is registered to the entity.
func _on_registered() -> void:
	pass

func _process(delta: float) -> void:
	if _timer <= 0.0:
		_timer = time
		AnthuriumBrain.ichor = min(AnthuriumBrain.ichor + ichor_per_time, AnthuriumBrain.max_ichor)
	
	_timer -= delta
	
