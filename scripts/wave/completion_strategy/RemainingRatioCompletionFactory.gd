class_name RemainingRatioCompletionFactory extends CompletionFactory
@export var threshold_ratio: float = 0.2
func build() -> CompletionStrategy:
	return RemainingRatioStrategy.new(threshold_ratio)
