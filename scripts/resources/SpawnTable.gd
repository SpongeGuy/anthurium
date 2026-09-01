extends Resource
class_name SpawnTable

@export var rarity_weights: Dictionary[CreatureArchetype.Rarity, float]
@export var tag_weights: Dictionary[CreatureArchetype.Tag, float]
@export var behavior_weights: Dictionary[CreatureArchetype.BehaviorClass, float]
@export var consumer_weights: Dictionary[CreatureArchetype.ConsumerType, float]
@export var locomotion_weights: Dictionary[CreatureArchetype.Locomotion, float]

@export var use_esoterica: bool = false
## how much cosine similarity contributes vs categorical weights
@export var esoterica_weight: float = 1.0

func roll_entity_type(esoterica_target: Esoterica = null) -> StringName:
	var candidates: Dictionary[StringName, float] = {}
	for key in EntityRegistry._archetypes:
		var archetype: CreatureArchetype = EntityRegistry._archetypes[key]
		var score: float = rarity_weights.get(archetype.rarity, 0.0)
		for tag in archetype.tags:
			score += tag_weights.get(tag, 0.0)
		score += behavior_weights.get(archetype.behavior_class, 0.0)
		score += consumer_weights.get(archetype.consumer_type, 0.0)
		score += consumer_weights.get(archetype.locomotion, 0.0)
		
		if use_esoterica and esoterica_target and archetype.esoterica_profile:
			var similarity: float = esoterica_target.cosine_similarity(archetype.esoterica_profile)
			score += similarity * esoterica_weight
			
		if score > 0.0:
			candidates[key] = score
	
	if candidates.is_empty():
		return &""
	
	var result: StringName = WeightUtil.weighted_pick(candidates) as StringName
	return result if result != null else &""
