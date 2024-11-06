shader_type spatial;

// The noise texture used for biome determination
uniform sampler2D biome_noise : hint_default_white;
// We need the noise settings to match the GDScript sampling
uniform float noise_scale = 1.0;
uniform vec2 noise_offset = vec2(0.0);
uniform float noise_lacunarity = 2.0;
uniform int noise_octaves = 5;
uniform float noise_gain = 0.5;

// Biome thresholds (matching the GDScript constants)
uniform float sand_threshold = 0.05;
uniform float grass_threshold = 0.2;
uniform float forest_threshold = 0.4;
uniform float mountain_threshold = 0.6;

// Debug visualization
uniform bool show_noise_value = false;

// This function matches FastNoiseLite's get_noise_2d implementation
float get_noise_2d(vec2 pos) {
    // Sample the noise texture at the correct position
    // We need to move from [-1,1] to [0,1] range for texture sampling
    vec2 uv = (pos * noise_scale + noise_offset) * 0.5 + 0.5;

    // Sample noise
    float noise = texture(biome_noise, uv).r;

    // Convert back to [-1,1] range to match FastNoiseLite
    return noise * 2.0 - 1.0;
}

void fragment() {
    // Get world position
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Calculate noise value the same way as in GDScript
    float noise_val = get_noise_2d(world_pos.xz);

    // Determine biome color based on noise value
    vec3 color;
    if (show_noise_value) {
        // Debug visualization - show raw noise value
        color = vec3(noise_val * 0.5 + 0.5);
    } else {
        // Normal biome coloring
        if (noise_val < sand_threshold) {
            color = vec3(0.96, 0.87, 0.70); // Sand
        } else if (noise_val < grass_threshold) {
            color = vec3(0.48, 0.73, 0.32); // Grass
        } else if (noise_val < forest_threshold) {
            color = vec3(0.23, 0.45, 0.23); // Forest
        } else if (noise_val < mountain_threshold) {
            color = vec3(0.55, 0.55, 0.55); // Mountain base
        } else {
            color = vec3(0.80, 0.80, 0.80); // Mountain peak/snow
        }
    }

    ALBEDO = color;
}