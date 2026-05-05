extends Node


var active_anthurium_names: Dictionary[StringName, int] = {}
var active_anthurium_parts: Dictionary[Entity, StringName] = {}
var max_nutrition_points: float = 1500.0
var nutrition_points: float = 500.0
var nutrition_giga_unit: float = 500.0

## seeing meaningful patterns in randomness
var apophenia: float = 0.0
## an absent gap; something missing
var lacuna: float = 0.0
## overwhelming, terror-tinged awe
var tremendum: float = 0.0
## recollection of something beyond memory
var anamnesis: float = 0.0
## great happiness and satisfaction; a sense that everything is as it should
var felicity: float = 0.0
## divine, frenzied anger
var furor: float = 0.0

signal just_took_damage(damage_amount: float, source: Node2D)

func add_active_part(entity: Entity) -> void:
	var basename: StringName = entity.get_basename()
	if not active_anthurium_names.has(basename):
		active_anthurium_names.set(basename, 1)
	else:
		active_anthurium_names[basename] += 1
	
	active_anthurium_parts.set(entity, basename)
	
func remove_active_part(entity: Entity) -> void:
	var basename: StringName = entity.get_basename()
	active_anthurium_names[basename] -= 1
	
	active_anthurium_parts.erase(entity)
	
func resolve_needed_part() -> StringName:
	var checks_priority_1: Array[Dictionary] = [
		{&"anthurium_leaf": func(): return get_count_of_part(&"anthurium_leaf") < max_nutrition_points / nutrition_giga_unit},
		{&"anthurium_pitcher": func(): return get_count_of_part(&"anthurium_leaf") < max_nutrition_points / nutrition_giga_unit},
		{&"anthurium_flower": func(): return get_count_of_part(&"anthurium_flower") < nutrition_points / (max_nutrition_points / 3)},
	]
	print(nutrition_points / max_nutrition_points)
	if not &"anthurium_core" in active_anthurium_names:
		return &"anthurium_core"
	checks_priority_1.shuffle()
	for check in checks_priority_1:
		var key = check.keys()[0]
		if check[key].call():
			return key
	return &"anthurium_grass"
		
func get_count_of_part(name: StringName) -> int:
	var count: int = 0
	for entity in active_anthurium_parts:
		if active_anthurium_parts[entity] == name:
			count += 1
	return count
