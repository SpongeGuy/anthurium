class_name WaveGenerator
extends Resource
@export var tiered_entity_pools: Array[EntityPool]
@export var base_budget: float = 100.0
@export var budget_growth: float = 1.2
@export var base_completion_factory: CompletionFactory
@export var waves_per_tier: int = 3
@export var blend_overlap_waves: int = 1

func generate_wave(wave_value: int) -> WaveDefinition:
	var def: WaveDefinition = WaveDefinition.new()
	def.entity_pool = tiered_entity_pools[clampi(wave_value / waves_per_tier, 0, tiered_entity_pools.size() - 1)]
	def.point_budget = base_budget * pow(budget_growth, wave_value)
	def.completion_factory = base_completion_factory
	return def

func _resolve_pool(wave_value: int) -> EntityPool:
	var tier_index: int = clampi(wave_value / waves_per_tier, 0, tiered_entity_pools.size())
	var current: EntityPool = tiered_entity_pools[tier_index]
	
	if tier_index >= tiered_entity_pools.size() - 1 or blend_overlap_waves <= 0:
		return current # last tier (or blending disabled), no next tier to blend towards
	
	var waves_into_tier: int = wave_value % waves_per_tier
	var waves_remaining: int = waves_per_tier - waves_into_tier
	if waves_remaining > blend_overlap_waves:
		return current # not yet in overlap window
	
	var next: EntityPool = tiered_entity_pools[tier_index + 1]
	var blend_t: float = 1.0 - float(waves_remaining) / blend_overlap_waves
	return _blend_pools(current, next, blend_t)

func _blend_pools(a: EntityPool, b: EntityPool, t: float) -> EntityPool:
	var merged: EntityPool = EntityPool.new()
	for entry in a.entries:
		var scaled: EntityPoolEntry = EntityPoolEntry.new()
		scaled.entity_type = entry.entity_type
		scaled.cost = entry.cost
		scaled.weight = entry.weight * (1 - t)
		merged.entries.append(scaled)
	for entry in b.entries:
		var scaled: EntityPoolEntry = EntityPoolEntry.new()
		scaled.entity_type = entry.entity_type
		scaled.cost = entry.cost
		scaled.weight = entry.weight * t
		merged.entries.append(scaled)
	return merged
