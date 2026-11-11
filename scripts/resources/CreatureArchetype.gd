extends Resource
class_name CreatureArchetype


enum Tag{
	AMBUSH, ARMORED, BURROWER, BUILDER, CARNIVORE, CHARMER, EXPLOSIVE,
	FEARFUL, FLAMMABLE, FRIENDLY, FRAGILE, FRUGIVORE, HOARDER, HUNTER,
	ILLUSIONIST, LARGE, MIMIC, MULTIPLIER, NESTING, NOCTURNAL, OMNIVORE,
	PACK, PHOTOSYNTHETIC, PLANTLIKE, PRODUCER, RANGED, SCAVENGER,
	SHAPESHIFTER, SOLITARY, SPELLCASTER, SPINY, SUMMONER, TERRAFORMER,
	TERRITORIAL, TRADEABLE, WANDERER, WRATHFUL
}
# ecology, behavior, physicality, diet, social

enum Locomotion {
	GROUND, FLYING, AQUATIC, BURROWING, PHASING,
	JUMPING, ROLLING, STATIONARY, CARDINAL_ONLY, DIAGONAL_ONLY,
}

enum Rarity{
	COMMON,
	UNCOMMON,
	RARE,
	LEGENDARY,
}

enum BehaviorClass{
	## does not attack other creatures or flees when nearby other creatures
	PASSIVE, 
	## only retaliates if provoked
	REACTIVE, 
	## actively hunts other creatures
	PREDATORY, 
	## violent towards other creatures
	FERAL, 
	## does not care about other creatures
	ALOOF
	}



enum ConsumerType{
	## hunger is lessened passively over time given a condition
	AMBIENT, 
	## hunger is lessened when nearby a specific entity
	PROXIMITY, 
	## hunger is lessened by consuming entities
	CONSUMER, 
	## hunger is lessened through unconventional means
	ESOTERIC, 
	## does not have hunger
	EXEMPT
	}


@export var esoterica_profile: Esoterica
@export var rarity: Rarity
@export var behavior_class: BehaviorClass
@export var consumer_type: ConsumerType
@export var locomotion: Locomotion = Locomotion.GROUND
@export var tags: Array[Tag] = []
## -1 is unlimited
@export var max_instances: int = -1
