class_name Quest extends RefCounted

# signal progress_changed(quest: Quest)
signal completed(quest: Quest)

enum QuestResult{ SUCCESS, FAILURE}
var result: QuestResult
var is_complete: bool = false

var call_on_completion: Callable


func start(_ctx: Dictionary) -> void:
	pass

func tick(_delta: float) -> void:
	pass

func finish(quest_result: QuestResult) -> void:
	if is_complete: return
	is_complete = true
	result = quest_result
	completed.emit(self)

## override this to disconnect from signals or something like that
func shutdown() ->  void:
	pass
