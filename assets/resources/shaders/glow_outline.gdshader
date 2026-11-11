shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform float glow_width : hint_range(0.0, 8.0) = 2.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform float min_intensity : hint_range(0.0, 2.0) = 0.2;
uniform float max_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float phase_offset : hint_range(0.0, 10.0) = 0.0;
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * glow_width;

	float neighbor_max = 0.0;
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(px.x, px.y)).a);
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(-px.x, px.y)).a);
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(px.x, -px.y)).a);
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(-px.x, -px.y)).a);

	float neighbor_opaque = step(alpha_threshold, neighbor_max);
	float self_opaque = step(alpha_threshold, tex.a);
	float outline = neighbor_opaque * (1.0 - self_opaque);

	float pulse = mix(min_intensity, max_intensity,
		(sin((TIME + phase_offset) * pulse_speed) + 1.0) * 0.5);

	vec4 glow = vec4(glow_color.rgb, outline * glow_color.a * pulse);
	COLOR = mix(glow, tex, tex.a);
}