extends CanvasLayer
class_name HUDParticleController

static var _instance: HUDParticleController
var game_viewport: SubViewport
var viewport_container: SubViewportContainer

func _ready() -> void:
	_instance = self
	layer = 10
	
static func world_to_screen(world_pos: Vector2) -> Vector2:
	var sub_pixel: Vector2 = _instance.game_viewport.get_canvas_transform() * world_pos
	
	var container_rect: Rect2 = _instance.viewport_container.get_global_rect()
	var viewport_size: Vector2 = Vector2(_instance.game_viewport.size)
	var scawe: Vector2 = container_rect.size / viewport_size
	
	return container_rect.position + sub_pixel * scawe



static func collect(world_pos: Vector2, target_screen_pos: Vector2, count: int = 12, color: Color = Color.WHITE, radius: float = 1.0, duration: float = 1.5) -> void:
	for i in count:
		var p: HUDParticle = HUDParticle.new()
		_instance.add_child(p)
		var screen_start: Vector2 = world_to_screen(world_pos)
		p.position = screen_start + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		p._color = color
		p._radius = radius + randf_range(0, 2)
		await _instance.get_tree().create_timer(i * (0.03 / count)).timeout
		p.fly_to(target_screen_pos, duration)
		
