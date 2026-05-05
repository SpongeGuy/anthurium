extends Component
class_name SpriteFlipper

@export var facing: FacingComponent
@export var sprite: Sprite2D

func _process(delta: float) -> void:
	if facing:
		flip_sprite(facing.get_direction())
	
func flip_sprite(new_direction: Vector2) -> void:
	if new_direction.x > 0:
		sprite.flip_h = false
	else:
		sprite.flip_h = true
