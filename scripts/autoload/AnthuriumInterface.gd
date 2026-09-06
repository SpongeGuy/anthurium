## Autoload: AnthuriumInterface
##
## Orchestrates the "anthurium" growth system: owns the current
## [Esoterica] state, tracks how many of each accessory part currently
## exist, and picks which [AccessoryArchetype] or [BloomEvent] best matches
## the current esoterica via cosine similarity.
extends Node

## The anthurium's current esoterica vector, driving archetype/event
## selection. Reset by [method create_new_anthurium].
var esoterica: Esoterica
#var bloom_events: Array[BloomEvent]
#var accessory_archetypes: Array[AccessoryArchetype]

## Live count of spawned parts, keyed by part name, maintained via
## [signal EventBus.part_spawned]/[signal EventBus.part_destroyed].
var part_counts: Dictionary[StringName, int] = {}

## Initializes a fresh anthurium and starts listening for part
## spawn/destroy events.
func _ready() -> void:
	create_new_anthurium()
	EventBus.part_spawned.connect(_on_part_spawned)
	EventBus.part_destroyed.connect(_on_part_destroyed)

## Resets [member esoterica] to a fresh [Esoterica] and clears
## [member part_counts].
func create_new_anthurium() -> void:
	esoterica = Esoterica.new()
	part_counts.clear()
	
## Connected to [signal EventBus.part_spawned]; increments the count for
## [param name].
func _on_part_spawned(name: StringName) -> void:
	part_counts[name] = part_counts.get(name, 0) + 1

## Connected to [signal EventBus.part_destroyed]; decrements the count for
## [param name], floored at zero.
func _on_part_destroyed(name: StringName) -> void:
	part_counts[name] = maxi(0, part_counts.get(name, 0) - 1)
	
## Returns the [member AccessoryArchetype.entity_id] of the best-matching
## registered accessory archetype for the current esoterica — the one with
## the highest cosine similarity that hasn't hit its
## [member AccessoryArchetype.max_count] limit. Returns an empty
## [StringName] if none qualify.
func select_accessory_type() -> StringName:
	var current: Esoterica = get_current_esoterica()
	var best_archetype: AccessoryArchetype
	var best_score: float = -INF
	for archetype in AccessoryArchetypeRegistry.archetypes:
		if archetype.max_count >= 0 and part_counts.get(archetype.entity_id, 0) >= archetype.max_count:
			continue
		var similarity: float = current.cosine_similarity(archetype.archetype)
		if similarity > best_score:
			best_score = similarity
			best_archetype = archetype
	return best_archetype.entity_id if best_archetype else &""

## Returns the registered [BloomEvent] whose archetype most closely matches
## (highest cosine similarity to) the current esoterica.
func select_bloom_event() -> BloomEvent:
	var current: Esoterica = get_current_esoterica()
	var best_event: BloomEvent
	var best_score: float = -INF
	for event in BloomEventRegistry.events:
		var similarity: float = current.cosine_similarity(event.archetype)
		if similarity > best_score:
			best_score = similarity
			best_event = event
	return best_event
	
## Selects the best-matching [BloomEvent] via [method select_bloom_event]
## and executes it with a potency equal to the current esoterica's
## magnitude. [param source] is used only for logging.
func trigger_bloom(source: Entity) -> void:
	Log.info("Triggering Bloom Event at %s, %s" % [source, source.global_position])
	var event: BloomEvent = select_bloom_event()
	var potency: float = esoterica.magnitude()
	if event:
		event.execute(potency)

## Returns a duplicate of the current [member esoterica], safe for the
## caller to inspect or mutate without affecting the live state.
func get_current_esoterica() -> Esoterica:
	return esoterica.duplicate()
