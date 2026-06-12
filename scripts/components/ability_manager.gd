extends Component
class_name AbilityManager

# -----------------------------------------------
# interfaces with an inputcomponent to activate abilities
# -----------------------------------------------

@export var abilities: Array[Ability] = [null, null, null, null]
var _disabled: Array[bool] = [false, false, false, false]
@export var ichor_component: IchorComponent

@export var input: InputComponent


func _ready() -> void:
	input.input_just_pressed.connect(_on_input_just_pressed)
	input.input_just_released.connect(_on_input_just_released)
	
func is_full() -> bool:
	return abilities.get(0) and abilities.get(1) and abilities.get(2) and abilities.get(3)
	
			
func _on_registered() -> void:
	for ability in get_children():
		if ability is Ability:
			_setup_ability(ability)

func disable(id: int) -> void:
	_disabled[id] = true
	
func enable(id: int) -> void:
	_disabled[id] = false

func _on_input_just_pressed(id: int) -> void:
	if not abilities.get(id):
		return
	if _disabled[id]:
		return
	
	abilities[id].on_pressed(input.modifier)

func _on_input_just_released(id: int, held_time: float) -> void:
	if not abilities.get(id):
		return
	abilities[id].on_released(held_time, input.modifier)

func _process(delta: float) -> void:
	for i in range(input.is_held.size()):
		if input.is_held[i]:
			if i >= abilities.size():
				continue
			if abilities[i] == null:
				continue
			abilities[i].on_held(input.hold_time[i], delta, input.modifier)
			
func get_ability_from_id(id: int) -> Ability:
	if not abilities[id]:
		return
	return abilities[id]

func get_ability_from_string(action: String) -> Ability:
	var id: int = input.actions.bsearch(action)
	if not abilities[id]:
		return
	return abilities[id]
	
# ui hand "grabs" the ui ability from the hud
# ui hand, while holding the ui ability, activates the drop hud element
# ability is removed from player (cleaned up extra nodes)
# ability is transferred to the container of an inert ability shard
# when ability shard is used, the ability from its container is transferred to the player's ability_manager


func add_ability(ability: Ability) -> void:
	ability.reparent(self)
	_setup_ability(ability)
	
func _setup_ability(ability: Ability) -> void:
	ability.entity = entity
	ability.manager = self
	ability.initialize()
	register_to_nearest_slot(ability)
	
func remove_ability(slot: int) -> Ability:
	if abilities[slot] == null:
		return
	
	var ability: Ability = abilities[slot]
	
	abilities[slot].clean_up()
	abilities[slot].queue_free()
	
	abilities[slot] = null
	return ability
	

func drop_ability_shard_from_ability(ability: Ability, position: Vector2) -> void:
	ability.clean_up()
	var shard: Entity = EntityManager.spawn_safely(&"ability_shard", position)
	var container: AbilityContainer = shard.get_component(AbilityContainer)
	container.add_ability.call_deferred(ability)
	

func drop_ability_shard(slot: int, position: Vector2) -> void:
	var ability: Ability = abilities[slot]
	if ability == null:
		return
	abilities[slot] = null
	drop_ability_shard_from_ability(ability, position)
	
	

func register(ability: Ability, slot: int) -> void:
	if abilities.get(slot):
		return
	abilities[slot] = ability

func register_to_nearest_slot(ability: Ability) -> void:
	var slot: int = -1
	for i in range(abilities.size()):
		if abilities.get(i) == null:
			slot = i
			abilities[slot] = ability
			return
	
	if slot == -1:
		return
		
	
