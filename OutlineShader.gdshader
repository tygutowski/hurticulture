shader_type spatial;
render_mode unshaded;

uniform vec3 color : source_color = vec3(0,0,0);

void fragment() {
	ALBEDO = color;
}