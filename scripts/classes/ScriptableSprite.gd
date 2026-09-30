class_name ScriptableSprite extends Sprite2D

var rx: float = 600
var _tween: Tween
var animation_duration: float = 2.5
signal finished_animating

var effects: Array[EntityEffect] = [
	load("uid://62yqvwawjtyu"),
	load("uid://cl26hsjnpeeep")
	]
var voice_id: int = 0


func _init(entity_name: StringName, target: Vector2, origin: Vector2, duration: float = 2.5, sound_id: int = 0) -> void:
	var entity: Entity = EntityManager.create_entity(entity_name)
	entity.global_position = target
	play_sound(entity, sound_id)
	set_sprite(entity.visual)
	entity.queue_free()
	global_position = origin
	animation_duration = duration
	_tween_to(target)
	
	
func set_sprite(source: Sprite2D) -> void:
	texture = source.texture
	hframes = source.hframes
	vframes = source.vframes
	frame = source.frame

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotation_degrees += rx * delta


func play_sound(entity: Entity, id: int) -> void:
	effects[id].execute(entity)

func _tween_to(target: Vector2) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", target, animation_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_tween.chain().tween_callback(func(): 
		finished_animating.emit()
		queue_free())
	
