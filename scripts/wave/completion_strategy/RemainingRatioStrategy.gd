class_name RemainingRatioStrategy
extends CompletionStrategy

var _threshold: float
var _alive: int = 0
var _total: int = 0

func _init(threshold_ratio: float) -> void:
	_threshold = threshold_ratio

func on_entity_tracked(entity: Entity) -> void:
	_total += 1
	_alive += 1
	entity.tree_exiting.connect(func():
		_alive -= 1
		if _total > 0 and float(_alive) / _total <= _threshold:
			_complete()
	, CONNECT_ONE_SHOT)
