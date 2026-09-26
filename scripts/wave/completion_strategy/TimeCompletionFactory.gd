class_name TimeCompletionFactory
extends CompletionFactory
@export var duration: float = 30.0
func build() -> CompletionStrategy:
	return TimeCompletionStrategy.new(duration)
