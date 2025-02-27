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

float calculate_biome_score(int biome_index, float height, float humidity, float temperature, float difficulty) {
	// Convert height from 0-1 to min_height-max_height if needed
	height = mix(min_height, max_height, height);

	// Check if height is in range - if not, return a very low score
	if (height < height_ranges[biome_index].x || height > height_ranges[biome_index].y) {
		return -10000.0;
	}

	float score = 0.0;

	// Height is in range, give a base score
	score += 3.0;

	// --- Humidity Scoring (smooth falloff) ---
	float humidity_center = (humidity_ranges[biome_index].x + humidity_ranges[biome_index].y) * 0.5;
	float humidity_range = (humidity_ranges[biome_index].y - humidity_ranges[biome_index].x) * 0.5;
	float safe_humidity_range = max(humidity_range, EPSILON);
	float humidity_diff = abs(humidity - humidity_center);

	// Smoother falloff for humidity
	float humidity_factor = 1.0 / (1.0 + pow(humidity_diff / safe_humidity_range, 2.0));
	score += humidity_factor;

	// --- Temperature Scoring (smooth falloff) ---
	float temperature_center = (temperature_ranges[biome_index].x + temperature_ranges[biome_index].y) * 0.5;
	float temperature_range = (temperature_ranges[biome_index].y - temperature_ranges[biome_index].x) * 0.5;
	float safe_temperature_range = max(temperature_range, EPSILON);
	float temperature_diff = abs(temperature - temperature_center);

	// Smoother falloff for temperature
	float temperature_factor = 1.0 / (1.0 + pow(temperature_diff / safe_temperature_range, 2.0));
	score += temperature_factor;

	// Similar handling for difficulty

	return score;
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

	// Find the best matching biome based on the weighted scores
	float best_score = -10000.0;
	int best_biome = 0;

	for (int i = 0; i < biome_count; i++) {
		float current_score = calculate_biome_score(i, height, humidity, temperature, difficulty);
		if (current_score > best_score) {
			best_score = current_score;
			best_biome = i;
		}
	}

	//ALBEDO = world_normal;

	// Set the final color based on the best matching biome
	ALBEDO = biome_colors[best_biome];
	BACKLIGHT = vec3(1.0);
}
