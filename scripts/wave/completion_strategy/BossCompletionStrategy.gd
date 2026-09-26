class_name BossCompletionStrategy
extends CompletionStrategy

var _boss_type: StringName
var _alive_count: int = 0

func _init(boss_type: StringName) -> void:
	_boss_type = boss_type

func on_entity_tracked(entity: Entity) -> void:
	if entity.basename != _boss_type:
		return
	_alive_count += 1
	entity.died.connect(func():
		_alive_count -= 1
		if _alive_count <= 0:
			_complete()
	, CONNECT_ONE_SHOT)
