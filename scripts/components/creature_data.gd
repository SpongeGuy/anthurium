extends Component
class_name CreatureData


enum CreatureTag{
	PLANTLIKE,
	PACK,
	LARGE,
	NOCTURNAL,
	TERRITORIAL,
	HOARDER,
	BURROWER,
	BUILDER,
	SUMMONER,
	CHARMER,
	HUNTER,
	WANDERER,
	SPINY,
	ARMORED,
	FRAGILE,
	EXPLOSIVE,
	FLAMMABLE,
	FRUGIVORE,
	CARNIVORE,
	OMNIVORE,
	PHOTOSYNTHETIC,
	SCAVENGER,
	FRIENDLY,
	SOLITARY,
	FEARFUL,
	WRATHFUL,
}
# ecology, behavior, physicality, diet, social


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




@export var display_name: String = ""
@export var behavior_class: BehaviorClass
@export var consumer_type: ConsumerType
@export var tags: Array[CreatureTag] = []
@export var liked_tags: Array[CreatureTag] = []
@export var feared_tags: Array[CreatureTag] = []
@export var prey_tags: Array[CreatureTag] = []


var spawn_weight: float = 1.0
var point_cost: int = 0
