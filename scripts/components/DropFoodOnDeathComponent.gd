extends Component
class_name DropFoodOnDeathComponent

@export var health: HealthComponent
@export var ichor: IchorComponent
@export var food_to_spawn: StringName = "meat_shank"


func _on_registered() -> void:
	health.died.connect(_on_death)


func _on_death() -> void:
	var food: Entity = EntityManager.spawn_safely(food_to_spawn, entity.global_position, false)
	await food.entity_initialized
	var food_ichor: IchorComponent = food.get_component(IchorComponent)
	food_ichor.ichor = ichor.ichor * randf_range(0.5, 1)
	food_ichor.max_ichor = ichor.ichor
	var food_stage: ItemStageManager = food.get_component(ItemStageManager)
	food_stage.set_correct_stage(food_ichor.ichor, food_ichor.max_ichor)
	var food_health: HealthComponent = food.get_component(HealthComponent)
	food_health.set_invincibility_timer(3.0)
