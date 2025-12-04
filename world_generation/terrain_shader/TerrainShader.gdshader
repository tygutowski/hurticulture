shader_type spatial;
render_mode cull_back; // or whatever you use

uniform sampler2D biome_index_map : filter_nearest;
uniform sampler2DArray flat_textures;
uniform int biome_count;

void fragment() {
    vec2 uv = UV;

    float idx_f = texture(biome_index_map, uv).r;
    int idx = int(idx_f + 0.5);
    idx = clamp(idx, 0, biome_count - 1);

    vec4 col = texture(flat_textures, vec3(uv, float(idx)));

    ALBEDO = col.rgb;
    ALPHA = col.a;

    // Ensure lighting stays enabled
    NORMAL = normalize(NORMAL);
}
