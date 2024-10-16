shader_type spatial;
render_mode depth_prepass_alpha;

uniform sampler2D noise_texture;
uniform vec2 cloud_direction = vec2(1.0, 1.0);
uniform float cloud_speed = 0.05;
uniform float cut_threshold = 0.5;

void fragment() {
    vec2 moving_uv = UV + cloud_direction * TIME * cloud_speed;
    float noise = texture(noise_texture, moving_uv).r;
    float shadow = step(cut_threshold, noise);
    ALBEDO = vec3(255.0);
    ALPHA = 1.0 - shadow;
}