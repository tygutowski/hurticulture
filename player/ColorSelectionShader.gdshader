shader_type spatial;

uniform sampler2D primary_texture_1; // Low detail
uniform sampler2D primary_texture_2; // Medium detail
uniform sampler2D primary_texture_3; // High detail

uniform sampler2D colormap_texture;

// Darkness control for area 0
uniform float hydraulics_detail : hint_range(0.0, 1.0);

// Color pickers for areas 1-7
uniform vec3 color_1 : source_color;
uniform vec3 color_2 : source_color;
uniform vec3 color_3 : source_color;
uniform vec3 color_4 : source_color;
uniform vec3 color_5 : source_color;
uniform vec3 color_6 : source_color;
uniform vec3 color_7 : source_color;

// Detail strength selection (1 = low, 2 = medium, 3 = high)
uniform int detail_strength : hint_range(1, 3);

void fragment() {
    vec4 base_tex;
    
    if (detail_strength == 1) {
        base_tex = texture(primary_texture_1, UV);
    } else if (detail_strength == 2) {
        base_tex = texture(primary_texture_2, UV);
    } else if (detail_strength == 3) {
        base_tex = texture(primary_texture_3, UV);
    }

    float mask = texture(colormap_texture, UV).r;
    vec3 color_choice;

    if (mask < 0.05) {
        color_choice = vec3(hydraulics_detail);
    } else if (mask < 0.15) {
        color_choice = color_1;
    } else if (mask < 0.25) {
        color_choice = color_2;
    } else if (mask < 0.35) {
        color_choice = color_3;
    } else if (mask < 0.45) {
        color_choice = color_4;
    } else if (mask < 0.55) {
        color_choice = color_5;
    } else if (mask < 0.65) {
        color_choice = color_6;
    } else {
        color_choice = color_7;
    }
    vec3 final_color = mix(color_choice, color_choice * base_tex.rgb, 1.0);

    ALBEDO = final_color;
}
