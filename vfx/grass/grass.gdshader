shader_type spatial;
render_mode cull_disabled;

uniform vec3 color : source_color;
uniform vec3 color2 : source_color;
uniform sampler2D noise;
uniform float noiseScale = 20.0;
uniform float heightScale = 0.3;
uniform float sway_strength = 0.1;
uniform float sway_speed = 1.0;
uniform float sway_scale = 1.0;

varying vec3 worldPos;

void vertex() {
	vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 noiseUV = world_vertex.xz / noiseScale;
	float noiseVal = texture(noise, noiseUV).r;

	float height_offset = max(0.0, (1.0 - noiseVal));
	float height = 1.0 + height_offset * heightScale;
	VERTEX.y *= height;

	float sway = sin(TIME * sway_speed + world_vertex.x * sway_scale) * sway_strength;
	VERTEX.x += sway * VERTEX.y;

	worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 noiseLevel = texture(noise, worldPos.xz / noiseScale).rgb;
	ALBEDO = mix(color, color2, UV.y) * mix(color, color2, noiseLevel.r) * 0.6;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
