shader_type spatial;
render_mode blend_mix, cull_disabled; // Enable alpha blending and show both sides

uniform float wave_amplitude = 0.1; // Controls wave height
uniform float wave_frequency = 3.0; // Controls number of waves
uniform float wave_speed = 2.0; // Controls wave speed
uniform sampler2D albedo_texture : source_color, filter_nearest; // Texture with alpha channel

void vertex() {
    vec2 uv = UV;
    float time = TIME;
    // Apply wave displacement across the entire surface (no pinned edge)
    float wave = sin(uv.x * wave_frequency + time * wave_speed) * wave_amplitude;
    VERTEX.z += wave; // Uniform wave along Z-axis
}

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = tex.rgb; // Use RGB from texture
    ALPHA = tex.a; // Use alpha channel for transparency
}