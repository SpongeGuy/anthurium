// pixel perfect rotation
// 1. no new colors are created (no blending / interpolation)
// 2. original texels (pixels) are preserved and "moved" as whole units during rotation
// 3. no anti-aliasing or smoothing occurs between pixels


// this shit doesn't work right now, but might work some day!! :))))))

uniform vec2 tex_size;

vec4 effect(vec4 color, sampler2D texture, vec2 texcoords, vec2 screencoords) {
	// snap uvs to nearest texel center
	vec2 snapped_uv = (floor(texcoords * tex_size) + 0.5) / tex_size;
	return texture2D(texture, snapped_uv) * color;
}