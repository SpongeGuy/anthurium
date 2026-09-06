## Autoload: AccessoryArchetypeRegistry
##
## Scans [member SCAN_PATHS] for [AccessoryArchetype] resources ([code].tres[/code])
## and holds them in [member archetypes] for [AnthuriumInterface] to pick from
## when choosing which accessory to grow next.
extends Node


## Directories scanned for accessory archetype resources — [code]res://[/code]
## for built-in content, [code]user://[/code] for creator mods.
const SCAN_PATHS: Array[String] = [
	"res://assets/resources/accessory_archetypes",
	"user://mods/accessory_archetypes"
]

## Every [AccessoryArchetype] resource found by the last [method scan_all].
var archetypes: Array[AccessoryArchetype] = []

## Clears [member archetypes] and rescans [member SCAN_PATHS], registering
## every valid [AccessoryArchetype] resource found.
func scan_all() -> void:
	archetypes.clear()
	ResourceScanner.scan(SCAN_PATHS, ".tres", _register)
	var register_size: int = archetypes.size()
	if register_size > 0:
		Log.info("%d anthurium accessory archetypes registered." % archetypes.size())
	else:
		Log.warn("0 anthurium accessory archetypes registered!")

## Loads [param resource_path] and appends it to [member archetypes] if it's
## an [AccessoryArchetype]; otherwise logs a warning and skips it.
func _register(resource_path: String) -> void:
	var resource: Resource = load(resource_path)
	if resource is AccessoryArchetype:
		archetypes.append(resource)
	else:
		Log.warn("Skipping '%s': not an AccessoryArchetype" % resource_path)
