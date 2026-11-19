class_name OnboardingQuest extends Quest

var pool: Array[StringName] = ["attack", "water_bomb", "water_bomb", "attack"]

func start(_ctx: Dictionary) -> void:
	var peds: Array = Engine.get_main_loop().get_nodes_in_group("pedestals")
	peds.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.global_position.x < b.global_position.x)
	for i in peds.size():
		peds[i].get_component(PedestalComponent).assign(pool[i % pool.size()])
	EventBus.pedestal_purchased.connect(_on_purchased)

func _on_purchased(_buyer: Entity, _id: StringName) -> void:
	finish(QuestResult.SUCCESS)

func shutdown() ->  void:
	if EventBus.pedestal_purchased.is_connected(_on_purchased):
		EventBus.pedestal_purchased.disconnect(_on_purchased)
