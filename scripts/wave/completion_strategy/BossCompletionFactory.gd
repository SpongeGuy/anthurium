class_name BossCompletionFactory extends CompletionFactory

@export var boss_entity_type: StringName

func build() -> CompletionStrategy:
	return BossCompletionStrategy.new(boss_entity_type)
