extends Path3D

var is_pathing: bool = true
var is_transitioning: bool = false
var elapsed_time: float = 0
var transition_time: float = 0.0
var final_positions: Array[Vector3] = []
@export var logo_letters_eng_offset_values: Array[float] = [
	15, 26, 35, 42, 52, 62, 69, 76, 87
]
@export var transition_duration: float = 2

func _process(delta: float) -> void:
	elapsed_time += delta


func ease_in_out_cubic(t: float) -> float:
	if t < 0.5:
		return 4.0 * t * t * t
	else:
		return 1.0 - pow(-2.0 * t + 2.0, 3) / 2.0
		



func logo_animation(elements: Array[Sprite3D], delta: float, total_duration: float, stagger_delay: float, start_time: float = 0) -> void:
	if is_pathing:
		if elements.is_empty() or curve == null:
			return
		var smooth_curve: Curve3D = curve
		var baked_length: float = curve.get_baked_length()
		var current_time: float = elapsed_time
		
		for i in range(elements.size()):
			var element: Sprite3D = elements[i]
			var staggered_start: float = start_time + i * stagger_delay
			
			var progress_ratio: float
			if current_time < staggered_start:
				progress_ratio = 0.0
			else:
				progress_ratio = (current_time - staggered_start) / total_duration
				if progress_ratio > 1.0:
					progress_ratio = 1.0
				progress_ratio = ease_in_out_cubic(progress_ratio)
			if i == elements.size() - 1 and progress_ratio == 1.0:
				is_pathing = false
				is_transitioning = true
				transition_time = 0.0
				final_positions.clear()
				for j in range(elements.size()):
					var local_pos: Vector3 = Vector3(
						smooth_curve.sample_baked(baked_length).x + logo_letters_eng_offset_values[j] * 0.015,
						smooth_curve.sample_baked(baked_length).y,
						smooth_curve.sample_baked(baked_length).z
					)
					final_positions.append(self.to_global(local_pos))
			var distance_along_curve: float = progress_ratio * baked_length
			var local_position: Vector3 = Vector3(
				smooth_curve.sample_baked(distance_along_curve).x + logo_letters_eng_offset_values[i] * 0.015, 
				smooth_curve.sample_baked(distance_along_curve).y, 
				smooth_curve.sample_baked(distance_along_curve).z
			)
			var global_pos: Vector3 = self.to_global(local_position)
			element.global_position = global_pos
	#else:
		#transition_time += delta
		#var blend_factor: float = min(transition_time / transition_duration, 1.0)
		#blend_factor = ease_in_out_cubic(blend_factor)
		#for i in range(elements.size()):
			#var element = elements[i]
			#var multiplier = 0.1
			#var target_pos: Vector3 = final_positions[i] if i < final_positions.size() else element.global_position
			#var osc_amplitude: float = multiplier * blend_factor
			#var osc_pos: Vector3 = Vector3(
				#target_pos.x + sin(elapsed_time + (i * multiplier)) * osc_amplitude,
				#target_pos.y + sin(elapsed_time + PI/3 + (i * multiplier)) * osc_amplitude,
				#target_pos.z + sin(elapsed_time + PI/4 + (i * multiplier)) * osc_amplitude
			#)
			#if is_transitioning and blend_factor < 1.0:
				#element.global_position = lerp(final_positions[i], osc_pos, blend_factor)
			#else:
				#is_transitioning = false
				#element.global_position = osc_pos
