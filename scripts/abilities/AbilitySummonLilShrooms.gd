class_name AbilitySummonLilShrooms extends Ability

var n: String = "Shroom Swarm"
var d: Texture2D = load("uid://ba5umeowwg1fm")

var rng: RandomNumberGenerator

func initialize() -> void:
	display_name = n
	display_icon = d
	
	rng = RunRng.get_stream("entity")
	
## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	for i in randi_range(2, 4):
		var rand_offset: Vector2 = entity.position + Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, 5))
		var shroom: Entity = EntityManager.simple_spawn("lilshroom", rand_offset, false)
		shroom.set_origin(entity)
		shroom.add_friend(entity)

func on_pressed(modifier: bool) -> void:
	execute()
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass



