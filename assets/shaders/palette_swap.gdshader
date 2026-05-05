shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 0.5, 0.5, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.8;


void fragment() {
	vec4 original = texture(TEXTURE, UV);
	
	// get greyscale value (luminosity)
	float luma = dot(original.rgb, vec3(0.299, 0.587, 0.114));
	
	// calculate tint influence based on distance from extremes
	// midrange (0.5) gets full tint, black/white get less
	float distance_from_mid = abs(luma - 0.5) * 2.0;
	float tint_influence = (1.0 - distance_from_mid) * tint_strength;
	
	// blend between greyscale and color
	vec3 tinted = mix(vec3(luma), tint_color.rgb * luma, tint_influence);
	
	COLOR = vec4(tinted, original.a);
}
