shader_type spatial;
render_mode blend_mix, depth_draw_never; // Blend overlay, test depth to respect occlusion, no depth write to avoid fighting

uniform int color_levels : hint_range(2, 32, 1) = 4; // Levels per RGB channel (lower = more dithered)
uniform float dither_strength : hint_range(0.0, 1.0, 0.01) = 0.2; // Dither intensity (lowered default for subtler effect)
uniform float overlay_opacity : hint_range(0.0, 1.0, 0.01) = 1.0; // How much to blend the dithered overlay (1.0 = full replace)

// 4x4 Bayer matrix for ordered dithering (values in [0,1])
const mat4 bayer_matrix = mat4(
    vec4( 0.0/16.0, 12.0/16.0,  3.0/16.0, 15.0/16.0),
    vec4( 8.0/16.0,  4.0/16.0, 11.0/16.0,  7.0/16.0),
    vec4( 2.0/16.0, 14.0/16.0,  1.0/16.0, 13.0/16.0),
    vec4(10.0/16.0,  6.0/16.0,  9.0/16.0,  5.0/16.0)
);

uniform sampler2D screen_tex : hint_screen_texture; // Samples the previous rendered screen (including base material)

void fragment() {
    // Sample the previous pass's color using screen UV (captures base material's lit albedo for this mesh's pixels)
    vec2 screen_uv = SCREEN_UV;
    vec3 color = texture(screen_tex, screen_uv).rgb;
    
    // Compute dither offset based on screen position (for consistent pattern)
    ivec2 coord = ivec2(FRAGCOORD.xy) % 4;
    float dither = bayer_matrix[coord.y][coord.x] * dither_strength; // Note: y,x for matrix indexing
    
    // Quantize with dithering (add offset before flooring)
    float levels_float = float(color_levels);
    vec3 quantized = floor(color * (levels_float - 1.0) + dither) / (levels_float - 1.0);
    
    // Output the dithered color with opacity for blending
    ALBEDO = quantized;
    ALPHA = overlay_opacity; // Controls how much of the dither replaces/blends with base
}