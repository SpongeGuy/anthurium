class_name PedestalComponent extends Component

signal purchased(buyer: Entity, ability_id: StringName)

@export var interactable: InteractableComponent
@export var ability_display: AbilityDisplayComponent
@export var ability_id: StringName
@export var price: float = 0.0

var sold: bool = false

func _on_entity_initialized() -> void:
	interactable.interacted.connect(_on_interacted)
	if ability_id != &"":
		assign(ability_id)

func assign(id: StringName) -> void:
	ability_id = id
	entity.get_component(AbilityDisplayComponent).set_ability(id, price)

func _on_interacted(source: Entity) -> void:
	if sold:
		return
	if source.points < price:
		return # TODO: shake/flash fx
	source.remove_points(price)
	sold = true
	var shard: Entity = EntityManager.simple_spawn(&"ability_shard", entity.global_position)
	var container: AbilityContainer = shard.get_component(AbilityContainer)
	container.add_ability.call_deferred(AbilityRegistry.make_ability_from_id(ability_id))
	ability_display.clear()
	purchased.emit(source, ability_id)
	EventBus.pedestal_purchased.emit(source, ability_id)
