shader_type spatial;
render_mode depth_prepass_alpha;

uniform sampler2D noise_texture;
uniform vec2 cloud_direction = vec2(1.0, 1.0);
uniform float cloud_speed = 0.05;
uniform float cut_threshold = 0.5;

varying vec3 uv1_triplanar_pos;
uniform float uv1_blend_sharpness : hint_range(0.0, 150.0, 0.001) = 1.0;
varying vec3 uv1_power_normal;
uniform vec3 uv1_scale = vec3(0.5, 0.5, 0.5);

void vertex() {
	vec3 normal = MODEL_NORMAL_MATRIX * NORMAL;
    vec2 moving_uv = cloud_direction * TIME * cloud_speed;
	vec3 moving_uv3 = vec3(moving_uv.x, 0, moving_uv.y);

	// UV1 Triplanar: Enabled (with World Triplanar)
	uv1_power_normal = pow(abs(normal), vec3(uv1_blend_sharpness));
	uv1_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * uv1_scale + moving_uv3;
	uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}

void fragment() {
    float noise = triplanar_texture(noise_texture, uv1_power_normal, uv1_triplanar_pos).r;
    float shadow = step(cut_threshold, noise);
    ALBEDO = vec3(255.0);
    ALPHA = 1.0 - shadow;
}