class_name WaveGenerator
extends Resource
## every entity the generator may spawn. each entry's escalation curve decides when it appears, how common it gets, and whether it fades out later.
@export var entity_pool: EntityPool
@export var base_budget: float = 100.0
@export var budget_growth: float = 1.2
@export var base_completion_factory: CompletionFactory
@export var escalation_soft_cap: int = 60
@export var modifier_unlocks: Array[ModifierUnlock] = []

func generate_wave(wave_value: int) -> WaveDefinition:
	var def: WaveDefinition = WaveDefinition.new()
	def.entity_pool = _resolve_pool(wave_value)
	def.point_budget = _budget_for(wave_value)
	def.completion_factory = base_completion_factory
	for u in modifier_unlocks:
		if wave_value >= u.unlocks_at_escalation:
			def.spawn_modifiers.append(u.modifier)
	return def

func _budget_for(wave_value: int) -> float:
	var effective: int = mini(wave_value, escalation_soft_cap) + int(sqrt(maxf(0.0, wave_value - escalation_soft_cap)) * 3.0)
	return base_budget * pow(budget_growth, effective)

func _resolve_pool(wave_value: int) -> EntityPool:
	var pool: EntityPool = entity_pool.resolve_at(wave_value)
	if pool.entries.is_empty():
		Log.warn("No entity is unlocked at escalation %d (check unlock_at values)" % wave_value)
	return pool
