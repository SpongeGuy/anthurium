shader_type spatial;

uniform vec3 top_color : source_color = vec3(0.0, 0.6, 0.3); // Default green-ish top
uniform vec3 middle_color : source_color = vec3(0.8, 0.4, 0.1); // Default orange middle
uniform vec3 bottom_color : source_color = vec3(0.9, 0.2, 0.1); // Default red-ish bottom
uniform float middle_pos : hint_range(0.0, 1.0, 0.01) = 0.5; // Position of the middle color in the gradient (0 to 1)
uniform bool enable_pixelation = false; // Toggle pixelated (banded) effect
uniform float pixel_steps : hint_range(1.0, 64.0, 1.0) = 8.0; // Number of steps for pixelation (higher = smoother)

varying float v_height;

void vertex() {
    // Normalize height assuming BoxMesh is centered at origin with height 1.0 (VERTEX.y from -0.5 to 0.5)
    // Adjust the offset and scale if your BoxMesh size changes (e.g., via script setting uniforms)
    v_height = VERTEX.y + 0.5; // Range: 0.0 (bottom) to 1.0 (top)
}

void fragment() {
    float h = v_height;
    
    // Apply pixelation if enabled (creates banded, pixel-art-like gradient)
    if (enable_pixelation) {
        h = floor(h * pixel_steps) / pixel_steps;
    }
    
    // Compute gradient color based on height
    vec3 col;
    if (h > middle_pos) {
        col = mix(middle_color, top_color, (h - middle_pos) / (1.0 - middle_pos));
    } else {
        col = mix(bottom_color, middle_color, h / middle_pos);
    }
    
    ALBEDO = col;
    
    // Remove all specular/reflective qualities (make fully matte/non-metallic)
    METALLIC = 0.0;
    ROUGHNESS = 1.0;
}