extends Component
class_name EsotericaResponseComponent

@export var mappings: Array[StimulusMapping] = []

var _lookup: Dictionary[GameEvent.Stimulus, EsotericaResponse] = {} # a cache

func _ready() -> void:
	for m in mappings:
		_lookup[m.stimulus] = m.response
	EventBus.behavior_stimulus_event.connect(_on_behavior_stimulus_event)
	
func _on_behavior_stimulus_event(stimulus: GameEvent.Stimulus, context: Dictionary) -> void:
	if context.get("target") != entity:
		return
	var response: EsotericaResponse = _lookup.get(stimulus)
	if response:
		AnthuriumInterface.esoterica.add(response.get_delta(context))
