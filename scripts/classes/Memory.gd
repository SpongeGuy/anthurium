extends Component
class_name Memory

# ------------------------------------------------------------------------------------------
# essentially just a blackboard component to store memories
# ---------------------------------------------------------------------------------------------------

enum Key{
	TARGET,
	NEMESIS,
	SHORT_TERM_DESTINATION,
	LONG_TERM_DESTINATION,
	FAVORITE_ITEM,
	HOME_POSITION,
	LAST_KNOWN_POS,
	ALLY_TARGET,
}

var _data: Array = []

func _process(delta: float) -> void:
	for i in _data.size():
		if not is_instance_valid(_data[i]):
			_data[i] = null

func _ready() -> void:
	_data.resize(Key.size())
	
func set_value(key: Memory.Key, value: Variant) -> void:
	_data[key] = value
	
func get_value(key: Memory.Key) -> Variant:
	return _data.get(key)
	
func has(key: Memory.Key) -> bool:
	return _data[key] != null
	
func erase(key: Memory.Key) -> void:
	_data[key] = null
	

	

