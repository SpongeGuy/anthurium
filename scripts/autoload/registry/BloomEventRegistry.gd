extends Node

const SCAN_PATHS: Array[String] = [
	"res://assets/resources/bloom_events",
	"user://mods/bloom_events"
]

var events: Array[BloomEvent] = []

func scan_all() -> void:
	events.clear()
	ResourceScanner.scan(SCAN_PATHS, ".tres", _register)
	var register_size: int = events.size()
	if register_size > 0:
		Log.info("%d bloom events registered." % register_size)
	else:
		Log.warn("0 bloom events registered!")

func _register(resource_path: String) -> void:
	var resource: Resource = load(resource_path)
	if resource is BloomEvent:
		events.append(resource)
	else:
		Log.warn("Skipping '%s': not a BloomEvent" % resource_path)
