shader_type canvas_item;

uniform float speed : hint_range(0.1, 5.0) = 1.0;
uniform float width : hint_range(0.01, 0.5) = 0.1;
uniform float softness : hint_range(0.01, 0.3) = 0.05;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float angle : hint_range(0.0, 1.0) = 0.5; // 0 = horizontal, 1 = diagonal

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	
	// Project UV onto the shine axis
	float proj = mix(UV.x, (UV.x + UV.y) * 0.5, angle);
	
	// Scroll position loops -width to 1+width so entry/exit are clean
	float pos = fract(TIME * speed * 0.15) * (1.0 + width * 2.0) - width;
	
	float dist = abs(proj - pos);
	float shine = smoothstep(width, width - softness, dist);
	
	// Only shine where the texture has alpha (won't bleed outside sprite edges)
	shine *= tex.a;
	
	COLOR = vec4(mix(tex.rgb, shine_color.rgb, shine * intensity * shine_color.a), tex.a);
}