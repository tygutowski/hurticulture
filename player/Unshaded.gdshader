shader_type spatial;

uniform vec4 emission_color : source_color;

void fragment() {
    ALBEDO = vec3(0.0);
    EMISSION = emission_color.rgb;
}
