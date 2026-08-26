shader_type canvas_item;

// 0.0 = fully white, 1.0 = original color
uniform float progress : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    COLOR = vec4(mix(vec3(1.0), tex_color.rgb, progress), tex_color.a);
}