shader_type canvas_item;

uniform int stage = 0;
uniform float fade: hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	if (base.a < 0.01) discard;
	
	float luma = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	float is_outline = step(luma, 0.08);
	
	vec4 result = base;
	
	if (stage == 0) {
		// invert colors. outline -> dark red
		vec3 inverted = 1.0 - base.rgb;
		vec3 dark_red = vec3(0.5, 0.0, 0.0);
		result.rgb = mix(inverted, dark_red, is_outline);
		
	} else if (stage == 1) {
		// entire sprite white. outline -> red
		vec3 white = vec3(1.0);
		vec3 red = vec3(1.0, 0.0, 0.0);
		result.rgb = mix(white, red, is_outline);
		
	} else if (stage == 2) {
		// normal colors. outline -> white
		vec3 white = vec3(1.0);
		result.rgb = mix(base.rgb, white, is_outline);
		
	} else if (stage == 3) {
		// normal colors tinted red, fading away
		vec3 red_tint = mix(base.rgb, vec3(1.0, 0.2, 0.2), 0.6);
		result.rgb = mix(red_tint, base.rgb, fade);
		
	}
	
	COLOR = vec4(result.rgb, base.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
