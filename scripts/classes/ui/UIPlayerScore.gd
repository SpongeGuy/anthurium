class_name UIPlayerScore extends Control

## manages one [PlayerScore] per player slot. Even slots sit top-left, odd slots top-right

var _scene: PackedScene = load("uid://biwtjip4gpueg") # PlayerScore.tscn
var _scores: Array[PlayerScore] = []
var _entity_ids: Array[int] = []
var _callables: Array[Callable] = []
var _bound: Array[WeakRef]

func _ready() -> void:
	var hbox: HBoxContainer = find_child("CONTAINER")
	for slot in DeviceManager.MAX_PLAYERS:
		var cell: Control = Control.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(cell)

		var s: PlayerScore = _scene.instantiate()
		cell.add_child(s)
		s.setup(slot)

		s.set_anchors_and_offsets_preset(PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE)

		_scores.append(s)
		_entity_ids.append(0)
		_callables.append(Callable())
		_bound.append(null)

func bind(slot: int, entity: Entity) -> void:
	unbind(slot)
	if entity.get_instance_id() != _entity_ids[slot]:
		_scores[slot].reset(entity.score)
		_entity_ids[slot] = entity.get_instance_id()
	_callables[slot] = func() -> void: _scores[slot].set_score(entity.score)
	entity.score_changed.connect(_callables[slot])
	_bound[slot] = weakref(entity)

func unbind(slot: int) -> void:
	var e: Entity = _bound[slot].get_ref() if _bound[slot] else null
	if e and e.score_changed.is_connected(_callables[slot]):
		e.score_changed.disconnect(_callables[slot])
	_bound[slot] = null
	_callables[slot] = Callable()

func reset_all() -> void:
	for slot in _scores.size():
		_scores[slot].reset(0)
		_entity_ids[slot] = 0
