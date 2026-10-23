extends CharacterBody2D
class_name Entity

@export var display_name: String
@export var visual: Sprite2D
@export var archetype: CreatureArchetype


## See [method SpatialUtil.z_ranges_overlap], [PhysicsComponent], and [Hitbox]/[Hurtbox]
@export var height: float = 1.0
## This entity's mass. Used by [PhysicsComponent] for collision response,
## and available directly here so behavior/AI code can compare relative
## size against other creatures
@export var mass: float = 1.0
@export var spawn_effect: EntityEffect
@export var show_in_debug: bool = true

var visible_state_flag: int = 0
enum VisibleStateFlag {
	FLEEING = 1 << 0,
	ALERT = 1 << 1,
	AGGRESSIVE = 1 << 2,
	DISPLAYING = 1 << 3,
	WOUNDED = 1 << 4,
	HUNTING = 1 << 5,
	HAPPY = 1 << 6
}

var _components: Dictionary[Script, Array] = {}

signal entity_initialized
signal died
signal points_changed
signal entity_spawned

## The filename of the scene this entity was instantiated from, without extension.
## Useful for identifying entity types at runtime without hardcoding class names.
var basename: StringName
var is_initialized: bool = false
var is_spawned: bool = false



var key: Entity = null


func _ready() -> void:
	if not is_initialized: # covers entities placed in scene directly, not spawned using EntityManager
		initialize()
	
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	_initialize_z_drive()
	
	WorldGrid.cell_hidden.connect(_on_cell_hidden)
	WorldGrid.cell_revealed.connect(_on_cell_revealed)
	WorldGrid.cells_visibled.connect(_on_cells_visibled)
	resolve_visibility(WorldGrid.safe_get_cell(WorldGrid.world_to_tile(global_position)))
	
	points = base_point_value
	is_spawned = true
	
	_out_of_bounds_despawn_timer = out_of_bounds_check_timer

# ------------------------------------------------------------------------------------------------------------------------------------------------------------
# COMPONENT MANAGEMENT
# ------------------------------------------------------------------------------------------------------------------------------------------------------------

func initialize() -> void:
	if is_initialized:
		return
	basename = get_basename()
	_register_components(self)
	is_initialized = true
	entity_initialized.emit()
	

func _register_components(node: Node) -> void:
	for child in node.get_children():
		if child is Component:
			_register_component(child)
		_register_components(child)


func _register_component(component: Component) -> void:
	var script: Script = component.get_script()
	while script:
		if not _components.has(script):
			_components.set(script, [])
		_components[script].append(component)
		script = script.get_base_script()
	component.entity = self
	component._on_registered()
	component.registered.emit()
	
	if is_initialized:
		component._on_entity_initialized()
	else:
		entity_initialized.connect(component._on_entity_initialized, CONNECT_ONE_SHOT)
	
	if is_spawned:
		component._on_entity_spawned()
	else:
		entity_spawned.connect(component._on_entity_spawned, CONNECT_ONE_SHOT)

## Registers [param component] to this entity and adds it as a child of [param to].
## Use this when creating components at runtime, e.g. inside [method Ability.initialize].
func add_component(to: Node, component: Component) -> void:
	_register_component(component)
	to.add_child(component)

## Returns the first registered component matching [param type], or [code]null[/code] if none exists.[br]
## Supports base class queries; passing [LocomotionHandler] will return a [NormalLocomotionHandler]
## if that is what is attached.
func get_component(type: Script) -> Variant:
	if not _components.has(type):
		return null
	var array: Array = _components.get(type)
	return array[0]

## Returns all registered components matching [param type] as an [Array],
## or [code]null[/code] if none exist.
func get_components(type: Script) -> Variant:
	if not _components.has(type):
		return null
	return _components.get(type)

## Returns [code]true[/code] if at least one component of [param type] is registered.
func has_component(type: Script) -> bool:
	return _components.has(type)


func get_basename() -> StringName:
	return StringName(get_scene_file_path().get_file().get_basename())


		

# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# age and out of bounds
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@export_category("Lifespan")
@export var ages: bool = true
@export var age: float = 0.0
@export var lifespan: float = -1
@export var out_of_bounds_despawn_timer: float = 5.0

var _out_of_bounds_despawn_timer: float = 0.0
var out_of_bounds_check_timer: float = 5.0
var _out_of_bounds_check_timer: float = 0.0

var is_out_of_bounds: bool = false:
	set(value):
		is_out_of_bounds = value
		if value == false:
			_out_of_bounds_despawn_timer = out_of_bounds_check_timer

signal expired

func _process(delta: float) -> void:
	if ages:
		_accumulate_age(delta)
	if _out_of_bounds_check_timer <= 0.0:
		_out_of_bounds_check_timer = out_of_bounds_check_timer
		is_out_of_bounds = WorldGrid.is_entity_out_of_bounds(self)
	if is_out_of_bounds:
		_out_of_bounds_despawn_timer -= delta
	if _out_of_bounds_despawn_timer <= 0.0:
		die_and_despawn()
	
	_tick_flower_cooldown(delta)

func _accumulate_age(delta: float) -> void:
	age += delta
	if age >= lifespan:
		expired.emit()

func die_and_despawn() -> void:
	died.emit()
	queue_free()

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# points
# -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@export_category("Points")
@export var base_point_value: float = 100.0
var points: float = 100

func transfer_points(to: Entity) -> void:
	to.points += points
	to.points_changed.emit()
	points = 0

func add_points(amount: float) -> void:
	points += amount
	points_changed.emit()

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# visibility
# -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

@export_category("Hiding")
@export var hide_in_invisible_cells: bool = true

func set_visibility(to: bool) -> void:
	visible = to
	visibility_changed.emit(to)



func _on_cell_hidden(coords: Vector2i) -> void:
	resolve_visibility(get_current_cell())
	
func _on_cell_revealed(coords: Vector2i) -> void:
	resolve_visibility(get_current_cell())
	
func _on_cells_visibled(batch: Dictionary[Vector2i, bool]) -> void:
	resolve_visibility(get_current_cell())

func get_current_cell() -> CellData:
	return WorldGrid.safe_get_cell(WorldGrid.world_to_tile(position))


func resolve_visibility(cell: CellData) -> void:
	if not cell:
		return
	if cell.invisible and visible == true:
		set_visibility(false)
	
	if not cell.invisible and visible == false:
		set_visibility(true)
	

# ----------------------------------------------
# master / slave
# ----------------------------------------------

## used in resolving attribution chains when trying to determine the causality of events
## if an entity is spawning a projectile or explosion, set master to that entity
## it is up to your discretion if you want to set an owner to living entities, this could cause some unintended behavior
## or it could be funy haha :)))))
var origin: Entity = null

func set_origin(entity: Entity) -> void:
	origin = entity

func get_ultimate_origin(entity: Entity) -> Entity:
	if not origin:
		return self
	if origin.origin == self:
		return origin
	else:
		return get_ultimate_origin(origin)
		
# -------------------------------------------------------------------
# friends
# -------------------------------------------------------------------

# if an entity is friends with this one, then its hurtboxes will not interact with this entity's hitboxes.
var friends: Array[Entity] = []



func add_friend(entity: Entity) -> void:
	_clean_up_invalid_friends()
	friends.append(entity)

func remove_friend(entity: Entity) -> void:
	_clean_up_invalid_friends()
	for i in range(friends.size() - 1):
		if friends[i] == entity:
			friends.remove_at(i)
			return
		
func is_friends_with(entity: Entity) -> bool:
	return friends.has(entity)

func _clean_up_invalid_friends() -> void:
	for i in range(friends.size() -1, -1, -1):
		if not is_instance_valid(friends[i]):
			friends.remove_at(i)
			continue


# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# z drive
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

@export_category("ZDrive")
var s: PackedScene = preload("uid://cimer7u58jm6v")

const GROUND_LEVEL: float = 0

signal z_updated(value: float)

var _z_tracked_nodes: Dictionary = {}

@export var render_shadow: bool = true
@export var base_z_level: float = 0.0
@export var collide_with_terrain: bool = true
@export var nodes_to_translate: Array[Node2D]
@export var apply_gravity: bool = true
@export var gravity: float = 300
@export_range(0, 1) var bounciness: float = 0.0
@export var min_bounce_velocity: float = 20
@export var min_z: float = -8
@export var max_z: float = 32

@export var is_subterranean: bool = false

@export var shadow_size_curve: Curve = preload("uid://cfvo42q61korj")
@export var jump_effect: EntityEffect = preload("uid://biw543fd31een")
@export var land_effect: EntityEffect = preload("uid://dly24jhonlofh")
@export var go_subterranean_effect: EntityEffect
@export var is_subterranean_effect: EntityEffect

var z: float = 0.0
var _vz: float = 0.0
var _is_on_ground: bool = true

var _last_broadcast_z: float = 0.0




var shadow: Shadow
var shadow_base_size: float

func go_subterranean() -> void:
	set_z_value(-4)
	is_subterranean = true

func _initialize_z_drive() -> void:
	if render_shadow:
		shadow = s.instantiate()
		self.add_child(shadow)
		if not visual:
			Log.error("No visual node set on entity type '%s'" % basename, true)
		shadow_base_size = (visual.texture.get_width() / visual.hframes)
		shadow.set_shadow_size(shadow_base_size)
		shadow.set_shadow_alpha(0.65)

	for node in nodes_to_translate:
		register_z_node(node)
	_update_terrain_collision_layers()

func register_z_node(node: Node2D) -> void:
	_z_tracked_nodes[node] = node.position.y

func unregister_z_node(node: Node2D) -> void:
	_z_tracked_nodes.erase(node)
	
func _apply_z_offset() -> void:
	if absf(z - _last_broadcast_z) < 0.01:
		return
	
	var offset: float = min(0.0, -z * 4.0)
	if visual:
		visual.offset.y = offset
	for node in _z_tracked_nodes.keys():
		if is_instance_valid(node):
			node.position.y = _z_tracked_nodes[node] + offset
		else:
			_z_tracked_nodes.erase(node)
	if render_shadow and shadow:
		shadow.set_shadow_size(shadow_base_size * shadow_size_curve.sample(z))
	
	_last_broadcast_z = z
	z_updated.emit(z)
	
func is_on_ground() -> bool:
	return z <= 0
	
func _update_terrain_collision_layers() -> void:
	if not collide_with_terrain:
		collision_mask &= ~(SpatialUtil.PhysicsLayers.TERRAIN | SpatialUtil.PhysicsLayers.TERRAIN_LOW)
		return
		
	var new_mask: int = collision_mask | SpatialUtil.PhysicsLayers.TERRAIN
	if z >= SpatialUtil.LOW_TERRAIN_CLEARANCE:
		new_mask &= ~SpatialUtil.PhysicsLayers.TERRAIN_LOW
	else:
		new_mask |= SpatialUtil.PhysicsLayers.TERRAIN_LOW
	
	if new_mask != collision_mask:
		collision_mask = new_mask
		
	
func jump(velocity: float, do_effect: bool = true) -> void:
	if not _is_on_ground:
		return
	_vz = velocity
	_is_on_ground = false
	if jump_effect and do_effect:
		jump_effect.execute(self)
	
	
func _physics_process(delta: float) -> void:
	if not _is_on_ground:
		if apply_gravity and not is_subterranean:
			_vz -= gravity * delta
		z += _vz * delta

		if z > GROUND_LEVEL and is_subterranean:
			is_subterranean = false

		if z <= GROUND_LEVEL and not is_subterranean:
			z = GROUND_LEVEL
			if bounciness > 0.0 and absf(_vz) * bounciness >= min_bounce_velocity:
				_vz = -_vz * bounciness
				if land_effect:
					land_effect.execute(self)
			else:
				_vz = 0.0
				_is_on_ground = true
				if land_effect:
					land_effect.execute(self)

	z = clamp(z, min_z, max_z)
	_update_terrain_collision_layers()
	_apply_z_offset()
	
func set_z_value(value: float) -> void:
	z = clamp(value, min_z, max_z)
	_vz = 0.0
	_is_on_ground = is_zero_approx(z)
	_apply_z_offset()


# ------------------------------------------------------------------------------------------------
# UTILITY
# ------------------------------------------------------------------------------------------------

## Walks up the scene tree from [param node] until an [Entity] ancestor is found.[br]
## Returns `null` if no [Entity] exists in the ancestry.[br][br]
## Useful for nodes that are nested inside an entity's scene tree but are not
## [Component] instances themselves, such as [Hitbox] or [Hurtbox].
static func find_entity(node: Node) -> Entity:
	if node == null:
		return null
	if node is Entity:
		return node
	return find_entity(node.get_parent())


func get_visual() -> CanvasItem:
	return visual


# ----------------------------------------
# flowers
# ------------------------------------------
var flower_collection_sound: VoiceProfile = preload("uid://d0h0hx6hotcbb")
var flowers_collected: int = 0
var _flower_combo_timer: float = 0
var flower_combo_timer: float = 1.5
var flower_combo_multiplier: int = 1

func _get_pitch_jump(n: int, max: float, rate: float, start: float) -> float:
	return (max - start) * (1.0 - exp(-rate * n)) + start

func flower_collected() -> void:
	flowers_collected += 1
	flower_combo_multiplier += 1
	_flower_combo_timer = 1.5
	AudioManager.play_voice(flower_collection_sound, self, false, true, 0.0, 1.0, AudioManager.AudioBus.SFX, 400, 2.0, {"frequency_start": _get_pitch_jump(flowers_collected, 0.65, 0.015, 0.2)})
	
func flower_collection_complete() -> void:
	var point_value: float = flowers_collected * flower_combo_multiplier
	add_points(point_value) 
	ParticleManager.spawn_number(point_value, global_position)
	flowers_collected = 0
	flower_combo_timer = 0
	flower_combo_multiplier = 0

func _tick_flower_cooldown(delta: float) -> void:
	if _flower_combo_timer > 0:
		_flower_combo_timer -= delta
		if _flower_combo_timer <= 0:
			flower_collection_complete()
