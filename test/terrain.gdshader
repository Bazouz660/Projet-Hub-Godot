shader_type spatial;

// Textures for different biomes
uniform vec4 sand : source_color;
uniform vec4 grass : source_color;
uniform vec4 forest : source_color;
uniform vec4 mountain : source_color;

// Noise texture for biome blending
uniform sampler2D noise_texture;

// Parameters
uniform float sand_threshold = 0.05;
uniform float grass_threshold = 0.2;
uniform float forest_threshold = 0.4;
uniform float mountain_threshold = 0.6;
uniform float blend_sharpness = 10.0;

// UV scales
uniform vec2 texture_scale = vec2(1.0);
uniform vec2 noise_scale = vec2(1.0);

varying float biome_value;

void vertex() {
    // UV2 contains the world position for biome sampling
    biome_value = texture(noise_texture, UV).r;
}

void fragment() {
    // Calculate biome weights with sharp transitions
    float sand_weight = 1.0 - smoothstep(sand_threshold - 0.01, sand_threshold + 0.01, biome_value);
    float grass_weight = smoothstep(sand_threshold - 0.01, sand_threshold + 0.01, biome_value) *
                        (1.0 - smoothstep(grass_threshold - 0.01, grass_threshold + 0.01, biome_value));
    float forest_weight = smoothstep(grass_threshold - 0.01, grass_threshold + 0.01, biome_value) *
                         (1.0 - smoothstep(forest_threshold - 0.01, forest_threshold + 0.01, biome_value));
    float mountain_weight = smoothstep(forest_threshold - 0.01, forest_threshold + 0.01, biome_value);

    // Blend final color
    ALBEDO = sand.rgb * sand_weight +
             grass.rgb * grass_weight +
             forest.rgb * forest_weight +
             mountain.rgb * mountain_weight;
}