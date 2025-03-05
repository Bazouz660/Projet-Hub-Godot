shader_type spatial;
render_mode depth_prepass_alpha, cull_back;
stencil_mode write, compare_always, 1;

uniform sampler2D noise_texture : hint_default_white;
uniform float speed : hint_range(0.01, 1.0) = 0.2;
uniform float noise_scale : hint_range(0.1, 5.0) = 1.0;
uniform float distortion : hint_range(0.01, 0.5) = 0.1;

void vertex() {
    // Calculate spherical UV coordinates for noise texture
    vec3 normal_normalized = normalize(VERTEX);
    vec2 sphere_uv = vec2(
        atan(normal_normalized.x, normal_normalized.z) / (2.0 * 3.14159) + 0.5,
        acos(normal_normalized.y) / 3.14159
    );

    // Sample noise texture with animation
    vec2 noise_uv = sphere_uv * noise_scale + vec2(TIME * speed, TIME * speed);
    float noise_val = texture(noise_texture, noise_uv).r;

    // Apply displacement along normal
    VERTEX += NORMAL * noise_val * distortion;

	//// Billboard Mode: Enabled
	//MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			//MAIN_CAM_INV_VIEW_MATRIX[0],
			//MAIN_CAM_INV_VIEW_MATRIX[1],
			//MAIN_CAM_INV_VIEW_MATRIX[2],
			//MODEL_MATRIX[3]);
	//MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);

	// Billboard Mode: Y-Billboard
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);

	// Billboard Keep Scale: Enabled
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	ALBEDO = vec3(1.0);
	ALPHA = 0.00;
}