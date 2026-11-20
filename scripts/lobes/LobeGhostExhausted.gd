class_name LobeGhostExhausted extends BrainLobe


func get_priority(entity: Entity) -> float:
	var ghost_component: GhostComponent = entity.get_component(GhostComponent)
	if not ghost_component:
		ghost_component = entity.get_component(GhostComponent)
	if ghost_component.exhausted:
		return 1.0
	return 0.0

