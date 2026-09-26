class_name CompositeAnyStrategy
extends CompletionStrategy

var _children: Array[CompletionStrategy]

func _init(children: Array[CompletionStrategy]) -> void:
	_children = children

func start(ctx: WaveRuntime) -> void:
	for c in _children:
		c.completed.connect(_complete, CONNECT_ONE_SHOT)
		c.start(ctx)

func tick(delta: float) -> void:
	for c in _children: c.tick(delta)

func on_entity_tracked(entity: Entity) -> void:
	for c in _children: c.on_entity_tracked(entity)
