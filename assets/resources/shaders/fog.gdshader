shader_type canvas_item;

uniform float clear_radius : hint_range(0.0, 2000.0) = 100.0;
uniform float edge_softness : hint_range(0.0, 300.0) = 140.0;
uniform vec2 center_pos = vec2(0.0, 0.0);
uniform vec4 fog_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

varying vec2 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    float dist = length(world_position - center_pos);
    float alpha = smoothstep(clear_radius - edge_softness, clear_radius + edge_softness, dist);
    COLOR = vec4(fog_color.rgb, fog_color.a * alpha);
}