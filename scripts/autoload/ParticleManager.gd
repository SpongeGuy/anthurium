## Autoload: ParticleManager
##
## Spawns one-shot [GPUParticles2D] bursts from a [ParticleProfile], handling
## the flip-h split, velocity injection, and shader-driven sprite animation.
## Emitters free themselves when finished.
extends Node

## Shader applied to every spawned particle emitter's material, providing
## flip and sprite-sheet animation support (see [method _apply_animation]).
const PARTICLE_SHADER = preload("res://assets/resources/shaders/particle_animated.gdshader")

## Spawns a particle burst at [param world_pos] using [param profile],
## splitting the total particle count between normal and horizontally
## flipped emitters according to [member ParticleProfile.flip_h_ratio].
## [param inherited_vel] is blended into the particles' initial velocity
## (e.g. from a moving source).
func burst(profile: ParticleProfile, world_pos: Vector2, inherited_vel: Vector2 = Vector2.ZERO) -> void:
	var normal_amount := int(round(float(profile.amount) * (1.0 - profile.flip_h_ratio)))
	var flipped_amount := profile.amount - normal_amount

	if normal_amount > 0:
		_spawn_emitter(profile, world_pos, inherited_vel, normal_amount, false, false)
	if flipped_amount > 0:
		_spawn_emitter(profile, world_pos, inherited_vel, flipped_amount, true, false)


## Builds and starts a single [GPUParticles2D] emitter configured from
## [param profile]: duplicates its process material, injects
## [param inherited_vel], applies [constant PARTICLE_SHADER] with the given
## flip flags, applies sprite-sheet animation via [method _apply_animation],
## and frees itself on [signal GPUParticles2D.finished].
func _spawn_emitter(
	profile: ParticleProfile,
	world_pos: Vector2,
	inherited_vel: Vector2,
	amount: int,
	flip_h: bool,
	flip_v: bool
) -> GPUParticles2D:
	var emitter := GPUParticles2D.new()
	EntityManager._entity_container.add_child(emitter)
	emitter.global_position = world_pos

	var mat: ParticleProcessMaterial = profile.process_material.duplicate()
	_inject_velocity(mat, inherited_vel)
	emitter.process_material = mat

	var draw_mat := ShaderMaterial.new()
	draw_mat.shader = PARTICLE_SHADER
	draw_mat.set_shader_parameter("flip_h", flip_h)
	draw_mat.set_shader_parameter("flip_v", flip_v)
	emitter.material = draw_mat

	emitter.texture = profile.texture
	emitter.amount = amount
	emitter.one_shot = profile.one_shot
	emitter.explosiveness = profile.explosiveness
	emitter.amount_ratio = profile.amount_ratio
	emitter.randomness = profile.randomness
	emitter.local_coords = false

	_apply_animation(emitter, mat, draw_mat, profile)

	emitter.emitting = true
	emitter.finished.connect(emitter.queue_free)
	
	return emitter


## Sets [param mat]'s direction/spread/initial velocity so spawned particles
## inherit [param vel] (e.g. from a moving source entity). No-op if
## [param vel] is zero.
func _inject_velocity(mat: ParticleProcessMaterial, vel: Vector2) -> void:
	if vel == Vector2.ZERO:
		return
	var speed := vel.length()
	# GPUParticles2D uses 3D direction vectors internally
	mat.direction = Vector3(vel.x / speed, vel.y / speed, 0.0)
	mat.spread = 0.0   # caller's profile spread still applies after this
	mat.initial_velocity_min = speed * 0.85
	mat.initial_velocity_max = speed * 1.15


## Configures [param draw_mat]'s sprite-sheet shader parameters from
## [param profile]'s [member ParticleProfile.animation], and sets
## [param emitter]'s lifetime to match the animation's duration so the
## particle dies exactly when its animation finishes. No-op if the profile
## has no animation.
func _apply_animation(emitter: GPUParticles2D, mat: ParticleProcessMaterial, draw_mat: ShaderMaterial, profile: ParticleProfile) -> void:
	var anim: SpriteAnimation = profile.animation
	if not anim:
		return

	var start_frame := anim.row * profile.h_frames + anim.column

	draw_mat.set_shader_parameter("h_frames", profile.h_frames)
	draw_mat.set_shader_parameter("v_frames", profile.v_frames)
	draw_mat.set_shader_parameter("anim_frames", anim.frames)
	draw_mat.set_shader_parameter("start_frame", start_frame)
	draw_mat.set_shader_parameter("anim_loop", anim.loop)

	# Particle lifetime = animation duration; dying = animation finishing
	emitter.lifetime = float(anim.frames) / anim.speed
