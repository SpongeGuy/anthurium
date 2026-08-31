extends Node

var esoterica: Esoterica
var bloom_events: Array[BloomEvent]

func _ready() -> void:
	create_new_anthurium()

func create_new_anthurium() -> void:
	esoterica = Esoterica.new()

func select_bloom_event(esoterica: Esoterica) -> BloomEvent:
	var best_event: BloomEvent
	var best_score: float = -INF
	for event in bloom_events:
		var similarity: float = esoterica.cosine_similarity(event.archetype)
		if similarity > best_score:
			best_score = similarity
			best_event = event
	return best_event
	
func trigger_bloom(source: Entity) -> void:
	Log.info("Triggering Bloom Event at %s, %s" % [source, source.global_position])
	var current_esoterica: Esoterica = get_current_esoterica()
	var event: BloomEvent = select_bloom_event(current_esoterica)
	var potency: float = esoterica.magnitude()
	if event:
		event.execute(potency)
	
func grow_new_accessory(source: Entity) -> Entity:
	# some algorithm to determine which type of plant part to spawn in
	var accessory: Entity
	return accessory
	
func grow_new_root(source: Entity) -> Entity:
	# some algorithm to pick an angle and distance from the source
	# pick the right sprite
	var root: Entity
	return root

func get_current_esoterica() -> Esoterica:
	return esoterica.duplicate()
