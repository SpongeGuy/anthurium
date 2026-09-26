class_name CompositeAnyFactory extends CompletionFactory
@export var factories: Array[CompletionFactory]
func build() -> CompletionStrategy:
	var strategies: Array[CompletionStrategy]
	for f in factories:
		strategies.append(f.build())
	return CompositeAnyStrategy.new(strategies)
