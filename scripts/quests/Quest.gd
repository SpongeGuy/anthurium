class_name Quest extends RefCounted

# signal progress_changed(quest: Quest)
signal completed(quest: Quest)

var is_complete: bool = false
var call_on_completion: Callable

func start(_ctx: Dictionary) -> void:
	pass

func tick(_delta: float) -> void:
	pass

func finish() -> void:
	if is_complete: return
	is_complete = true
	completed.emit(self)

## override this to disconnect from signals or something like that
func shutdown() ->  void:
	pass
