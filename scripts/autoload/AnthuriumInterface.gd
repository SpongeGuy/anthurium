extends Node

var esoterica: Esoterica
var bloom_events: Array[BloomEvent]
var accessory_archetypes: Array[AccessoryArchetype]

var part_counts: Dictionary[StringName, int] = {}

func _ready() -> void:
	create_new_anthurium()
	EventBus.part_spawned.connect(_on_part_spawned)
	EventBus.part_destroyed.connect(_on_part_destroyed)

func create_new_anthurium() -> void:
	esoterica = Esoterica.new()
	part_counts.clear()
	
func _on_part_spawned(name: StringName) -> void:
	part_counts[name] = part_counts.get(name, 0) + 1

func _on_part_destroyed(name: StringName) -> void:
	part_counts[name] = maxi(0, part_counts.get(name, 0) - 1)
	
func select_accessory_type() -> StringName:
	var current: Esoterica = get_current_esoterica()
	var best_archetype: AccessoryArchetype
	var best_score: float = -INF
	for archetype in accessory_archetypes:
		if archetype.max_count >= 0 and part_counts.get(archetype.entity_id, 0) >= archetype.max_count:
			continue
		var similarity: float = current.cosine_similarity(archetype.archetype)
		if similarity > best_score:
			best_score = similarity
			best_archetype = archetype
	return best_archetype.entity_id if best_archetype else &""

func select_bloom_event() -> BloomEvent:
	var current: Esoterica = get_current_esoterica()
	var best_event: BloomEvent
	var best_score: float = -INF
	for event in bloom_events:
		var similarity: float = current.cosine_similarity(event.archetype)
		if similarity > best_score:
			best_score = similarity
			best_event = event
	return best_event
	
func trigger_bloom(source: Entity) -> void:
	Log.info("Triggering Bloom Event at %s, %s" % [source, source.global_position])
	var event: BloomEvent = select_bloom_event()
	var potency: float = esoterica.magnitude()
	if event:
		event.execute(potency)

func get_current_esoterica() -> Esoterica:
	return esoterica.duplicate()
