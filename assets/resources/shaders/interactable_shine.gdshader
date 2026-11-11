shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float width : hint_range(0.01, 0.5) = 0.15;
uniform float softness : hint_range(0.01, 0.3) = 0.05;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float angle : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float proj = mix(UV.x, (UV.x + UV.y) * 0.5, angle);
	float pos = progress * (1.0 + width * 2.0) - width;
	float dist = abs(proj - pos);
	float shine = smoothstep(width, width - softness, dist);
	shine *= tex.a;
	COLOR = vec4(mix(tex.rgb, shine_color.rgb, shine * intensity * shine_color.a), tex.a);
}