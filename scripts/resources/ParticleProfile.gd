extends Resource
class_name ParticleProfile

@export var texture: Texture2D
@export var lifetime: float = 0.6
@export var amount: int = 12
@export_range(0, 1) var amount_ratio: float = 1
@export_range(0, 1) var explosiveness: float = 0
@export_range(0, 1) var randomness: float = 0
@export var process_material: ParticleProcessMaterial

@export_range(0, 1) var flip_h_ratio: float = 0.0
@export_range(0, 1) var flip_v_ratio: float = 0.0


@export_group("Sprite Animation")
@export var animation: SpriteAnimation
@export var h_frames: int = 1
@export var v_frames: int = 1
