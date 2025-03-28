shader_type canvas_item;

uniform float hue : hint_range(0.0, 1.0); // Hue from slider

// Function to convert HSV to RGB
vec3 hsv2rgb(float h, float s, float v) {
    float c = v * s;
    float x = c * (1.0 - abs(mod(h * 6.0, 2.0) - 1.0));
    float m = v - c;

    vec3 color;
    if (h < 1.0/6.0)      color = vec3(c, x, 0.0);
    else if (h < 2.0/6.0) color = vec3(x, c, 0.0);
    else if (h < 3.0/6.0) color = vec3(0.0, c, x);
    else if (h < 4.0/6.0) color = vec3(0.0, x, c);
    else if (h < 5.0/6.0) color = vec3(x, 0.0, c);
    else                  color = vec3(c, 0.0, x);

    return color + vec3(m);
}

void fragment() {
    vec2 uv = UV;
    float s = uv.x; // Saturation from left to right
    float v = 1.0 - uv.y; // Value from top to bottom

    vec3 color = hsv2rgb(hue, s, v);
    COLOR = vec4(color, 1.0);
}
