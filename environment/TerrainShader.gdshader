shader_type spatial;

const int MAX_BIOMES = 3; // Maximum number of biomes supported

uniform int biome_count = 3; // Actual number of biomes in use

// Biome weightmaps
uniform sampler2D weightmaps[MAX_BIOMES];

// Textures for flat and sloped regions for each biome
uniform sampler2D flat_biome_textures[MAX_BIOMES];
uniform sampler2D sloped_biome_textures[MAX_BIOMES];

// Slope map
uniform sampler2D slopemap;

// Noise texture for blending
uniform sampler2D noise_texture;

// Threshold to determine if a fragment is on a slope
uniform float slope_threshold = 0.5;

// Scaling factor for noise blending
uniform float noise_blend_scale = 0.1;

void fragment() {
    // Initialize biome weights
    float biome_weights[MAX_BIOMES];
    float total_weight = 0.0;

    // Sample biome weights from biome maps
    for (int i = 0; i < biome_count; i++) {
        float weight = texture(weightmaps[i], UV).r; // Assuming weight is in the red channel
        biome_weights[i] = weight;
        total_weight += weight;
    }

    // Normalize biome weights
    if (total_weight > 0.0) {
        for (int i = 0; i < biome_count; i++) {
            biome_weights[i] /= total_weight;
        }
    } else {
        // Assign equal weights if total weight is zero
        float equal_weight = 1.0 / float(biome_count);
        for (int i = 0; i < biome_count; i++) {
            biome_weights[i] = equal_weight;
        }
    }

    // Get the slope value from the slopemap
    float slope = texture(slopemap, UV).r;

    // Sample noise for blending
    float noise = texture(noise_texture, UV * 10.0).r * noise_blend_scale;

    // For each biome, blend the flat and sloped textures using slope and noise
    vec4 blended_biome_textures[MAX_BIOMES];
    for (int i = 0; i < biome_count; i++) {
        vec4 flat_color = texture(flat_biome_textures[i], UV * 15.0);
        vec4 sloped_color = texture(sloped_biome_textures[i], UV * 5.0);

        // Blend flat and sloped textures based on slope, noise, and slope threshold
        float blend_factor = clamp((slope - slope_threshold + noise) / (1.0 - slope_threshold), 0.0, 1.0);
        blended_biome_textures[i] = mix(flat_color, sloped_color, blend_factor);
    }

    // Blend the biome textures according to the biome weights
    vec4 final_color = vec4(0.0);
    for (int i = 0; i < biome_count; i++) {
        final_color += blended_biome_textures[i] * biome_weights[i];
    }

    // Assign the final color to the fragment
    ALBEDO = final_color.rgb;
}
