extends Component
class_name ZDrive

# z value goes from -8 to 16

var s: PackedScene = preload("uid://cimer7u58jm6v")

const GROUND_LEVEL: float = 0

signal layer_changed(new_layer: VerticalLayer, old_layer: VerticalLayer)
enum VerticalLayer{ SUBTERRANEAN, GROUND, AERIAL }

var _z_tracked_nodes: Dictionary = {}

@export var base_z_level: float = 0.0
@export var shadow_size_curve: Curve
@export var nodes_to_translate: Array[Node2D]
@export var main_sprite: Sprite2D
@export var jump_velocity: float = 60
@export var apply_gravity: bool = true
@export var gravity: float = 300
@export var min_z: float = -8
@export var max_z: float = 16
@export var is_subterranean: bool = false

@export var jump_effect: EntityEffect = preload("uid://biw543fd31een")
@export var land_effect: EntityEffect = preload("uid://dly24jhonlofh")
@export var go_subterranean_effect: EntityEffect
@export var is_subterranean_effect: EntityEffect

var z: float = 0.0
var _vz: float = 0.0
var _is_on_ground: bool = true

var layer: VerticalLayer

var shadow: Shadow
var shadow_base_size: float

func go_subterranean() -> void:
	set_z_value(-4)
	is_subterranean = true
	layer = VerticalLayer.SUBTERRANEAN

func _on_registered() -> void:
	shadow = s.instantiate()
	entity.add_child(shadow)
	shadow_base_size = main_sprite.texture.get_width() / 2
	shadow.set_shadow_size(shadow_base_size)
	shadow.set_shadow_alpha(0.65)

	for node in nodes_to_translate:
		register_z_node(node)

func register_z_node(node: Node2D) -> void:
	_z_tracked_nodes[node] = node.position.y

func unregister_z_node(node: Node2D) -> void:
	_z_tracked_nodes.erase(node)
	
func _apply_z_offset() -> void:
	var offset: float = min(0.0, -z * 4.0)
	main_sprite.offset.y = offset
	for node in _z_tracked_nodes.keys():
		if is_instance_valid(node):
			node.position.y = _z_tracked_nodes[node] + offset
		else:
			_z_tracked_nodes.erase(node)
	shadow.set_shadow_size(shadow_base_size * shadow_size_curve.sample(z))
	
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("action_modifier") and _is_on_ground:
		_vz = jump_velocity
		_is_on_ground = false
		jump_effect.execute(entity)

	if not _is_on_ground:
		if apply_gravity and not is_subterranean:
			_vz -= gravity * delta
		z += _vz * delta

		if z > GROUND_LEVEL and is_subterranean:
			is_subterranean = false

		if z <= GROUND_LEVEL and not is_subterranean:
			z = GROUND_LEVEL
			_vz = 0.0
			_is_on_ground = true
			land_effect.execute(entity)

	z = clamp(z, min_z, max_z)

	var old_layer: VerticalLayer = layer
	if z > 4:
		layer = VerticalLayer.AERIAL
	elif z < 0:
		layer = VerticalLayer.SUBTERRANEAN
	else:
		layer = VerticalLayer.GROUND

	if layer != old_layer:
		layer_changed.emit(layer, old_layer)
		if layer == VerticalLayer.SUBTERRANEAN and is_subterranean_effect:
			is_subterranean_effect.execute(entity)
		elif old_layer == VerticalLayer.SUBTERRANEAN and go_subterranean_effect:
			go_subterranean_effect.execute(entity)

	_apply_z_offset()
	
func set_z_value(value: float) -> void:
	z = clamp(value, min_z, max_z)
	_vz = 0.0
	_is_on_ground = is_zero_approx(z)
