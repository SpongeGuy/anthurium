extends Node

# autoload AbilityRegistry


const SCAN_PATHS: Array[String] = [
	"res://assets/resources/abilities/",
	"user://assets/mods/abilities"
	]

var registry: Dictionary[StringName, String] = {}
var _cache: Dictionary[StringName, AbilityDefinition]

signal all_abilities_registered

# ----------------------- public api -----------------------
# ------------------------------------------------------------

func get_ability_defn(ability_name: StringName) -> AbilityDefinition:
	if not registry.has(ability_name):
		Log.error("Unknown type '%s'" % ability_name)
		return null
	if not _cache.has(ability_name):
		_cache[ability_name] = load(registry[ability_name])
	return _cache[ability_name]

func clear_cache() -> void:
	_cache.clear()

func get_all_types() -> Array[StringName]:
	var types: Array[StringName] = []
	for key in registry:
		types.append(key)
	return types

func make_ability_from_id(id: StringName) -> Ability:
	var def: AbilityDefinition = get_ability_defn(id)
	return make_ability_from_definition(def)
	

func make_ability_from_definition(def: AbilityDefinition) -> Ability:
	var a: Ability = def.definition.new()
	a.set_display(def.display_name, def.icon)
	for key in def.properties:
		a.set(key, def.properties[key])
	return a



# ----------------------- internal -----------------------------
# ---------------------------------------------------------------


func scan_all() -> void:
	registry.clear()
	ResourceScanner.scan(SCAN_PATHS, ".tres", _register)
	Log.info("%d ability definitions registered." % registry.size())
	all_abilities_registered.emit()
		
func _register(resource_path: String) -> void:
	var key: StringName = StringName(resource_path.get_file().get_basename())
	
	if registry.has(key):
		Log.warn("Duplicate key '%s'\n\tkeeping: %s\n\tskipping: %s" % [key, registry[key], resource_path])
		return
	registry[key] = resource_path
