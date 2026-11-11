class_name PlayerOverlay extends Node2D
## World-space clues attached to a player entity:
##  - a blinking arrow above the head, tinted with the player's color
##  - a ring of hearts around the entity that appears when health changes, then fades
## Attached by UiController when PlayerManager binds an entity to a slot.

# Both textures should be white so they can be tinted. Heart bottom should face down in the image.
const ARROW_TEXTURE: Texture2D = preload("uid://cxugdwwpu6n8p") # continue_arrow.png
const HEART_TEXTURE: Texture2D = preload("uid://qs7flg2ehke2") # white_heart.png
const HEART_FULL: Color = Color(1.0, 0.23, 0.31)
const HEART_EMPTY: Color = Color(0.3, 0.3, 0.36)

@export var radius: float = 10.0
@export var arrow_gap: float = 5.0 ## extra distance above the heart ring
@export var blink_interval: float = 0.35
@export var heart_show_time: float = 1.6
@export var heart_fade_time: float = 0.4

var slot: int = 0
var color: Color = Color.WHITE

var _entity: Entity
var _health: HealthComponent
var _center: Vector2 ## the entity's visual position, which everything is placed around
var _arrow: Sprite2D
var _hearts: Node2D ## parent of the heart sprites; its alpha handles the fade
var _heart_count: int = 0
var _last_health: int = -1
var _blink_t: float = 0.0
var _heart_t: float = 0.0


## Adds (or re-colors) the overlay on [param entity]. Safe to call on every bind: players carried
## between levels keep their existing overlay.
static func attach(entity: Entity, slot: int) -> PlayerOverlay:
	var overlay: PlayerOverlay = entity.get_node_or_null("PlayerOverlay") as PlayerOverlay
	if overlay == null:
		overlay = PlayerOverlay.new()
		overlay.name = "PlayerOverlay"
		overlay.slot = slot
		overlay.color = PlayerPalette.color_for(slot)
		entity.add_child(overlay)
	else:
		overlay.slot = slot
		overlay.color = PlayerPalette.color_for(slot)
		overlay._arrow.modulate = overlay.color
	return overlay


func _ready() -> void:
	_entity = get_parent() as Entity
	if _entity == null:
		queue_free()
		return
	z_index = 20
	_entity.register_z_node(self) # rides along with jumps
	_center = _entity.visual.position if _entity.visual else Vector2.ZERO

	_arrow = Sprite2D.new()
	_arrow.texture = ARROW_TEXTURE
	_arrow.modulate = color
	_arrow.position = _center + Vector2.UP * (radius + arrow_gap)
	add_child(_arrow)

	_hearts = Node2D.new()
	_hearts.modulate.a = 0.0
	add_child(_hearts)

	_health = _entity.get_component(HealthComponent)
	if _health:
		_last_health = roundi(_health.health)
		_health.health_changed.connect(_on_health_changed)


func _process(delta: float) -> void:
	_blink_t += delta
	if _blink_t >= blink_interval:
		_blink_t = 0.0
		_arrow.visible = not _arrow.visible

	if _heart_t > 0.0:
		_heart_t -= delta
		_hearts.modulate.a = clampf(_heart_t / heart_fade_time, 0.0, 1.0)


func _on_health_changed(value: float, max_value: float) -> void:
	var health: int = roundi(value)
	var max_health: int = roundi(max_value)
	if health == _last_health and max_health == _heart_count:
		return
	_last_health = health
	_update_hearts(health, max_health)
	_heart_t = heart_show_time


func _update_hearts(health: int, max_health: int) -> void:
	# rebuild the ring only when max health changes
	if max_health != _heart_count:
		_heart_count = max_health
		for old in _hearts.get_children():
			old.queue_free()
		for i in max_health:
			var angle: float = TAU * i / max_health
			var heart: Sprite2D = Sprite2D.new()
			heart.texture = HEART_TEXTURE
			heart.position = _center + Vector2.UP.rotated(angle) * radius
			heart.rotation = angle # its bottom now faces the entity
			_hearts.add_child(heart)

	# color is just "is this heart's index below current health"
	for i in _hearts.get_child_count():
		var heart: Sprite2D = _hearts.get_child(i)
		heart.modulate = HEART_FULL if i < health else HEART_EMPTY
