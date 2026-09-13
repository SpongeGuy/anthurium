shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform float min_intensity : hint_range(0.0, 2.0) = 0.2;
uniform float max_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float phase_offset : hint_range(0.0, 10.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float silhouette = step(alpha_threshold, tex.a);
	float pulse = mix(min_intensity, max_intensity,
		(sin((TIME + phase_offset) * pulse_speed) + 1.0) * 0.5);
	COLOR = vec4(glow_color.rgb, silhouette * glow_color.a * pulse);
}