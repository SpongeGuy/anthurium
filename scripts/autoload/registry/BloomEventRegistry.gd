## Autoload: BloomEventRegistry
##
## Scans [member SCAN_PATHS] for [BloomEvent] resources ([code].tres[/code])
## and holds them in [member events] for [AnthuriumInterface] to select from
## when a Bloom is triggered.
extends Node


## Directories scanned for bloom event resources — [code]res://[/code] for
## built-in content, [code]user://[/code] for creator mods.
const SCAN_PATHS: Array[String] = [
	"res://assets/resources/bloom_events",
	"user://mods/bloom_events"
]

## Every [BloomEvent] resource found by the last [method scan_all].
var events: Array[BloomEvent] = []

## Clears [member events] and rescans [member SCAN_PATHS], registering every
## valid [BloomEvent] resource found.
func scan_all() -> void:
	events.clear()
	ResourceScanner.scan(SCAN_PATHS, ".tres", _register)
	var register_size: int = events.size()
	if register_size > 0:
		Log.info("%d bloom events registered." % register_size)
	else:
		Log.warn("0 bloom events registered!")

## Loads [param resource_path] and appends it to [member events] if it's a
## [BloomEvent]; otherwise logs a warning and skips it.
func _register(resource_path: String) -> void:
	var resource: Resource = load(resource_path)
	if resource is BloomEvent:
		events.append(resource)
	else:
		Log.warn("Skipping '%s': not a BloomEvent" % resource_path)
