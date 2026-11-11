shader_type canvas_item;

uniform float scale : hint_range(0.1, 100.0) = 1.0; // < 1.0 = wider bands, > 1.0 = more repetitions
uniform float speed : hint_range(0.1, 5.0) = 1.0;
uniform float saturation : hint_range(0.0, 1.0) = 1.0;
uniform float value : hint_range(0.0, 1.0) = 1.0;
uniform bool use_uv_x = true; // false = uniform color across whole object

vec3 hsv_to_rgb(float h, float s, float v) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(vec3(h) + K.xyz) * 6.0 - K.www);
	return v * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), s);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float hue_offset = use_uv_x ? (UV.x / scale) : 0.0;
	float hue = fract(TIME * speed * 0.1 + hue_offset);
	vec3 rainbow = hsv_to_rgb(hue, saturation, value);
	COLOR = vec4(rainbow * tex.rgb, tex.a);
}