shader_type spatial;

// Textures to blend
uniform sampler2D texture1;
uniform float scale1 = 1.0;

uniform sampler2D texture2;
uniform float scale2 = 1.0;

// Noise texture used as blend mask
uniform sampler2D noise_texture;
uniform float noise_scale = 1.0;

// Blend weights based on how aligned surface normal is to each axis
vec3 blend_weights(vec3 normal) {
	return pow(abs(normal), vec3(4.0));
}

// Triplanar projection with weighted sampling from each axis
vec4 triplanar_sample(sampler2D tex, vec3 world_pos, vec3 normal, float scale) {
	vec3 weights = blend_weights(normal);
	weights /= (weights.x + weights.y + weights.z);

	vec2 xz = world_pos.xz * scale;
	vec2 yz = world_pos.yz * scale;
	vec2 xy = world_pos.xy * scale;

	vec4 x_proj = texture(tex, yz);
	vec4 y_proj = texture(tex, xz);
	vec4 z_proj = texture(tex, xy);

	return x_proj * weights.x + y_proj * weights.y + z_proj * weights.z;
}

void fragment() {
	// Get world-space position and convert normal to world-space
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

	// Triplanar sample both main textures
	vec4 tex1 = triplanar_sample(texture1, world_pos, world_normal, scale1);
	vec4 tex2 = triplanar_sample(texture2, world_pos, world_normal, scale2);

	// Triplanar sample the noise blend texture
	float noise_val = triplanar_sample(noise_texture, world_pos, world_normal, noise_scale).r;
	float blend = clamp(noise_val, 0.0, 1.0);

	// Final blended result
	ALBEDO = mix(tex1.rgb, tex2.rgb, blend);
}
