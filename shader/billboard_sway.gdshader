shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_disabled;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_nearest, repeat_enable;
uniform vec4 backlight : source_color;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform float wind_strength : hint_range(0.0, 1.0) = 0.1;
uniform float wind_speed : hint_range(0.0, 10.0) = 1.0;
uniform float wind_scale : hint_range(0.1, 10.0) = 1.0;
uniform sampler2D noise_texture : hint_default_white;
uniform float noise_scale : hint_range(0.1, 10.0) = 1.0;

global uniform vec3 player_position;
uniform float player_influence_radius : hint_range(0.0, 10.0) = 2.0;
uniform float player_influence_strength : hint_range(0.0, 1.0) = 0.5;

void vertex() {
    UV = UV * uv1_scale.xy + uv1_offset.xy;

    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float wind_time = TIME * wind_speed;

    vec2 noise_uv = world_pos.xz * noise_scale * 0.01;
    float noise_value = texture(noise_texture, noise_uv + wind_time * 0.1).r * 2.0 - 1.0;

    float wind_vertical_influence = smoothstep(0.0, 1.0, VERTEX.y);
    float position_variation = sin(world_pos.x * 0.1) * cos(world_pos.z * 0.1) * 2.0;

    float wind_horizontal = sin(wind_time + world_pos.x * wind_scale + world_pos.z * wind_scale + position_variation + noise_value) * wind_strength;
    float wind_depth = cos(wind_time * 0.7 + world_pos.x * wind_scale * 1.2 + world_pos.z * wind_scale + position_variation + noise_value) * wind_strength * 0.5;

    vec3 to_player = player_position - world_pos;
    float distance_to_player = length(to_player);
    float player_influence = 1.0 - smoothstep(0.0, player_influence_radius, distance_to_player);
    vec3 player_deformation = normalize(to_player) * player_influence * player_influence_strength;

    VERTEX.x += wind_horizontal * wind_vertical_influence - player_deformation.x;
    VERTEX.z += wind_depth * wind_vertical_influence - player_deformation.z;
    VERTEX.y -= player_deformation.y * wind_vertical_influence;

    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
            MAIN_CAM_INV_VIEW_MATRIX[0],
            MAIN_CAM_INV_VIEW_MATRIX[1],
            MAIN_CAM_INV_VIEW_MATRIX[2],
            MODEL_MATRIX[3]);
    MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
    vec2 base_uv = UV;
    vec4 albedo_tex = texture(texture_albedo, base_uv);
    ALBEDO = albedo.rgb * albedo_tex.rgb;
    ALPHA *= albedo.a * albedo_tex.a;
    ALPHA_SCISSOR_THRESHOLD = 0.5;
    BACKLIGHT = backlight.rgb;
}