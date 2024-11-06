shader_type spatial;
render_mode cull_back, diffuse_toon, specular_disabled;

uniform float mountain_threshold = 0.7;
uniform float forest_threshold = 0.4;
uniform float beach_threshold = 0.2;

uniform vec4 mountain_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 forest_color : source_color = vec4(0.0, 0.5, 0.0, 1.0);
uniform vec4 plains_color : source_color = vec4(0.4, 0.8, 0.2, 1.0);
uniform vec4 beach_color : source_color = vec4(0.9, 0.9, 0.6, 1.0);

uniform vec3 backlight_color : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
    // UV.x contains the biome noise value
    float biome_noise = UV.x;

    // Determine biome color based on thresholds
    vec4 biome_color;
    if (biome_noise >= mountain_threshold) {
        biome_color = mountain_color;
    } else if (biome_noise >= forest_threshold) {
        biome_color = forest_color;
    } else if (biome_noise >= beach_threshold) {
        biome_color = plains_color;
    } else {
        biome_color = beach_color;
    }

    ALBEDO = biome_color.rgb;
	BACKLIGHT = backlight_color;
}