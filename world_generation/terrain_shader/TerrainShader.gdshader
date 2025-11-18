shader_type spatial;

uniform sampler2D biome_index_map : filter_nearest;
uniform sampler2DArray flat_textures;
uniform int biome_count;

void fragment() {
	// UV comes from mesh per-vertex
	vec2 uv = UV;

	// biome index stored in R channel
	float idx_f = texture(biome_index_map, uv).r;
	int idx = int(idx_f + 0.5);

	// safety
	idx = clamp(idx, 0, biome_count - 1);

	// sample the correct layer
	vec4 col = texture(flat_textures, vec3(uv, float(idx)));

	ALBEDO = col.rgb;
	ALPHA = col.a;
}
