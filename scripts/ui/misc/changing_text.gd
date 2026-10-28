extends Label

var _timer: float = 0.0
@export var timer: float = 2
@export var possibilities: Array[String] = []
@export var random: bool = false

var i: int = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0:
		_timer = timer
		
		i = cycle_text(self, i + 1, possibilities)

func cycle_text(label: Label, current_index: int, possibilities: Array[String]) -> int:
	var index_pick: int = current_index
	if random:
		index_pick = randi_range(0, possibilities.size() - 1)
		label.text = possibilities[index_pick]
		return index_pick
	
	if index_pick >= possibilities.size():
		index_pick = 0
	
	label.text = possibilities[index_pick]
	return index_pick
