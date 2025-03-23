varying vec2 v_texcoord;

vec4 position(mat4 transform_proj, vec4 vertex_pos) {
	v_texcoord = VertexTexCoord.st;
	return transform_proj * vertex_pos;
}

