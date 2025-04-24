shader_type spatial;
render_mode world_vertex_coords, specular_toon, diffuse_toon, skip_vertex_transform;

// Maximum number of biomes
const int MAX_BIOMES = 32;

// Biome data
uniform vec3 biome_colors[MAX_BIOMES];
uniform vec2 height_ranges[MAX_BIOMES];
uniform vec2 humidity_ranges[MAX_BIOMES];
uniform vec2 temperature_ranges[MAX_BIOMES];
uniform vec2 difficulty_ranges[MAX_BIOMES];
uniform int biome_count;
uniform float max_height;
uniform float min_height;
uniform sampler2D gradient : source_color;

varying vec3 noise_values1; // continentalness, erosion, peaks_valleys
varying vec3 noise_values2; // humidity, temperature, difficulty
varying vec3 world_position;
varying vec3 world_normal;

// A small constant to avoid division by zero
const float EPSILON = 0.0001;

float calculate_biome_distance(int biome_index, float height, float humidity, float temperature, float difficulty) {
    // Normalize height to [min_height, max_height]
    height = mix(min_height, max_height, height);

    // Enforce height range constraint: return a large distance if height is outside biome's range
    if (height < height_ranges[biome_index].x || height > height_ranges[biome_index].y) {
        return 10000.0; // Large value to disqualify this biome
    }

    // Compute centers
    float height_center = (height_ranges[biome_index].x + height_ranges[biome_index].y) * 0.5;
    float humidity_center = (humidity_ranges[biome_index].x + humidity_ranges[biome_index].y) * 0.5;
    float temperature_center = (temperature_ranges[biome_index].x + temperature_ranges[biome_index].y) * 0.5;
    float difficulty_center = (difficulty_ranges[biome_index].x + difficulty_ranges[biome_index].y) * 0.5;

    // Compute safe half-ranges
    float safe_height_range = max((height_ranges[biome_index].y - height_ranges[biome_index].x) * 0.5, EPSILON);
    float safe_humidity_range = max((humidity_ranges[biome_index].y - humidity_ranges[biome_index].x) * 0.5, EPSILON);
    float safe_temperature_range = max((temperature_ranges[biome_index].y - temperature_ranges[biome_index].x) * 0.5, EPSILON);
    float safe_difficulty_range = max((difficulty_ranges[biome_index].y - difficulty_ranges[biome_index].x) * 0.5, EPSILON);

    // Compute normalized differences
    float height_diff = (height - height_center) / safe_height_range;
    float humidity_diff = (humidity - humidity_center) / safe_humidity_range;
    float temperature_diff = (temperature - temperature_center) / safe_temperature_range;
    float difficulty_diff = (difficulty - difficulty_center) / safe_difficulty_range;

    // Weighted squared distance
    float distance = (4.0 * height_diff * height_diff +
                      humidity_diff * humidity_diff +
                      temperature_diff * temperature_diff +
                      0.5 * difficulty_diff * difficulty_diff);
    return distance;
}

void vertex() {
    VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = NORMAL;
    NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

    noise_values1 = CUSTOM0.rgb;
    noise_values2 = CUSTOM1.rgb;
    world_position = VERTEX;
}

void fragment() {
    float height      = noise_values1.r;
    float humidity    = noise_values1.g;
    float temperature = noise_values1.b;
    float difficulty  = noise_values2.r;

    float best_distance = 10000.0;
    int best_biome = 0;

    // Find the biome with the smallest distance
    for (int i = 0; i < biome_count; i++) {
        float distance = calculate_biome_distance(i, height, humidity, temperature, difficulty);
        if (distance < best_distance) {
            best_distance = distance;
            best_biome = i;
        }
    }

    // Apply the color of the best biome directly (no blending)
    ALBEDO = biome_colors[best_biome];
    BACKLIGHT = vec3(1.0);
}