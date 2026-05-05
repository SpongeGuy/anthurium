extends Component
class_name AnthuriumGrassComponent

var growth: int = 0
@export var sprite: Sprite2D
@export var proximity: ProximityDetector
@export var state_machine: StateMachine
var spiny: bool = false
@export var hurtbox: Hurtbox

var spritesheets: Array = [
	load("res://assets/textures/characters/plants/flower1.png"),
	load("res://assets/textures/characters/plants/flower2.png"),
	load('res://assets/textures/characters/plants/flower3.png'),
]

var spiny_spritesheet = load("res://assets/textures/characters/plants/spiny_grass.png")

func _ready() -> void:
	if spiny:
		sprite.texture = spiny_spritesheet
		hurtbox.set_active(true)
	else:
		sprite.texture = spritesheets.pick_random()
	growth = randi_range(0, sprite.hframes - 1)
	sprite.frame = growth
	proximity.detected.connect(_on_proximity_detected)
	
func _on_proximity_detected(source: Entity, target: Entity) -> void:
	state_machine.switch_to_death_state()
