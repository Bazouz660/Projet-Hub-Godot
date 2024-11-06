shader_type spatial;
render_mode cull_disabled, shadows_disabled;

// Water Color
uniform vec4 color : source_color;
uniform vec4 deep_water_color : source_color;
uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float metallic : hint_range(0.0, 1.0) = 0;

// Water Speed
uniform float speed : hint_range(-1, 1) = 0.02;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Depth fade parameters
uniform float depth_fade_distance : hint_range(0.0, 10.0) = 4.0;
uniform float depth_fade_power : hint_range(0.1, 5.0) = 1.0;

// Water foam
uniform vec4 edge_color : source_color;
uniform float edge_scale : hint_range(0.0, 1.0) = 0.1;
uniform float near = 0.1;
uniform float far = 100.0;

// Water Wave
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.025;
uniform float height_scale = 0.15;
uniform float noise_scale = 10.0;

// Refraction parameters
uniform float refraction_strength : hint_range(0.0, 1.0) = 0.2;
uniform float refraction_depth_multiplier : hint_range(0.0, 10.0) = 2.0;

// Water Noise
uniform sampler2D wave;
uniform sampler2D normalmap : hint_normal;
uniform sampler2D normalmap2 : hint_normal;

// Varying variables
varying float height;
varying vec3 world_pos;
varying vec3 world_normal;
varying vec3 vertex_pos;

// Triplanar blend sharpness
const float TRIPLANAR_SHARPNESS = 4.0;

float fresnel(float amount, vec3 normal, vec3 view) {
    return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

float linearize_depth(float depth) {
    depth = 1.0 - 2.0 * depth;
    return (2.0 * near * far) / (far + near - depth * (far - near));
}

float calculate_depth_fade(float depth_difference) {
    return clamp(exp(-depth_difference * depth_fade_power / depth_fade_distance), 0.0, 1.0);
}

vec3 get_triplanar_weights(vec3 normal) {
    vec3 blend_weights = abs(normal);
    blend_weights = pow(blend_weights, vec3(TRIPLANAR_SHARPNESS));
    blend_weights /= (blend_weights.x + blend_weights.y + blend_weights.z);
    return blend_weights;
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos, float time_offset) {
    vec4 samp = vec4(0.0);
    p_triplanar_pos /= noise_scale;

    samp += texture(p_sampler, p_triplanar_pos.xy + vec2(time_offset)) * p_weights.z;
    samp += texture(p_sampler, p_triplanar_pos.xz + vec2(time_offset)) * p_weights.y;
    samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0) + vec2(time_offset)) * p_weights.x;

    return samp;
}

// Modified to sample multiple points for smooth transitions
vec4 sample_screen_texture(vec2 uv, float depth_difference) {
    vec2 texel_size = vec2(1.0) / vec2(textureSize(SCREEN_TEXTURE, 0));

    // Sample multiple points around the current pixel
    vec4 _color = textureLod(SCREEN_TEXTURE, uv, 0.0);
    vec4 color_up = textureLod(SCREEN_TEXTURE, uv + vec2(0.0, texel_size.y), 0.0);
    vec4 color_down = textureLod(SCREEN_TEXTURE, uv + vec2(0.0, -texel_size.y), 0.0);
    vec4 color_left = textureLod(SCREEN_TEXTURE, uv + vec2(-texel_size.x, 0.0), 0.0);
    vec4 color_right = textureLod(SCREEN_TEXTURE, uv + vec2(texel_size.x, 0.0), 0.0);

    // Calculate weights based on depth difference
    float blend_weight = smoothstep(0.0, 0.01, abs(depth_difference));

    // Blend between center sample and average of neighbors
    vec4 avg_color = (color_up + color_down + color_left + color_right) / 4.0;
    return mix(_color, avg_color, blend_weight * 0.5);
}

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
    vertex_pos = VERTEX;

    vec3 blend_weights = get_triplanar_weights(world_normal);
    height = triplanar_texture(wave, blend_weights, world_pos, TIME * time_scale).r;

    VERTEX.y += height * height_scale;
}

void fragment() {
    float time = TIME * speed;
    vec3 blend_weights = get_triplanar_weights(world_normal);

    // Sample and blend normal maps
    vec4 normal1 = triplanar_texture(normalmap, blend_weights, world_pos, time * 4.0);
    vec4 normal2 = triplanar_texture(normalmap2, blend_weights, world_pos, -time * 3.0);
    vec4 normal3 = triplanar_texture(normalmap, blend_weights, world_pos, -time);

    vec3 combined_normal = mix(mix(normal1.rgb, normal2.rgb, 0.5), normal3.rgb, 0.5);
    NORMAL_MAP = combined_normal;

    vec3 normal_screen_space = normalize(combined_normal * 2.0 - 1.0);
    vec2 ref_offset = normal_screen_space.xy * refraction_strength;

    float scene_depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    float water_depth = FRAGCOORD.z;

    float scene_depth_linear = linearize_depth(scene_depth);
    float water_depth_linear = linearize_depth(water_depth);
    float depth_difference = scene_depth_linear - water_depth_linear;

	ref_offset *= (scene_depth + water_depth) * refraction_depth_multiplier;

    vec2 refracted_uv = SCREEN_UV + ref_offset;

    // Recalculate depth at refracted position with smooth transition
    float refracted_scene_depth = texture(DEPTH_TEXTURE, refracted_uv).r;
    float refracted_scene_depth_linear = linearize_depth(refracted_scene_depth);
    depth_difference = refracted_scene_depth_linear - water_depth_linear;

    if (depth_difference < 0.0001) {
        refracted_uv = SCREEN_UV;
        scene_depth = texture(DEPTH_TEXTURE, refracted_uv).r;
        scene_depth_linear = linearize_depth(scene_depth);
        depth_difference = scene_depth_linear - water_depth_linear;
    }

    float visibility = calculate_depth_fade(depth_difference);
    float edge_factor = 1.0 - step(edge_scale, abs(depth_difference * 10.0));

    vec4 water_color = mix(deep_water_color, color, visibility);
    vec4 depth_color_adj = mix(water_color, edge_color, edge_factor);

    // Use the new sampling function for smoother transitions
    vec4 refracted_color = sample_screen_texture(refracted_uv, depth_difference);

    float fresnel_factor = fresnel(3.0, combined_normal, VIEW);

    vec3 final_color = mix(refracted_color.rgb, depth_color_adj.rgb, max(0.3, fresnel_factor * 0.7));
    final_color = mix(deep_water_color.rgb, final_color, visibility);

    ALBEDO = final_color;
    METALLIC = metallic;
    ROUGHNESS = roughness;
}