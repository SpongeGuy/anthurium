extends Node



const SCAN_PATHS: Array[String] = [
	"res://assets/resources/accessory_archetypes",
	"user://mods/accessory_archetypes"
]

var archetypes: Array[AccessoryArchetype] = []

func scan_all() -> void:
	archetypes.clear()
	ResourceScanner.scan(SCAN_PATHS, ".tres", _register)
	var register_size: int = archetypes.size()
	if register_size > 0:
		Log.info("%d anthurium accessory archetypes registered." % archetypes.size())
	else:
		Log.warn("0 anthurium accessory archetypes registered!")

func _register(resource_path: String) -> void:
	var resource: Resource = load(resource_path)
	if resource is AccessoryArchetype:
		archetypes.append(resource)
	else:
		Log.warn("Skipping '%s': not an AccessoryArchetype" % resource_path)
