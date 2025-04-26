// NOTE: Shader automatically converted from Godot Engine 4.4.rc's StandardMaterial3D.

shader_type spatial;
render_mode depth_draw_opaque, cull_back, unshaded, depth_prepass_alpha;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_disable;

// Added uniforms for multi-layer effect control
uniform int layers : hint_range(1, 10) = 3;
uniform float rotation_speed : hint_range(0.0, 5.0) = 1.0;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5;
uniform float pulse_amount : hint_range(0.0, 0.5) = 0.1;


void vertex() {
	// Billboard Mode: Enabled
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 base_uv = UV;
	vec3 accumulated_color = vec3(0.0);
	float accumulated_alpha = 0.0;

	for (int i = 0; i < layers; i++) {
		float layer_float = float(i);
		// Offset phase based on layer index to distribute effects over time
		float time_offset = layer_float * PI * 2.0 / float(layers);

		// --- Rotation ---
		// Slightly vary speed per layer and alternate direction
		float layer_rot_speed = rotation_speed * (1.0 + layer_float * 0.1);
		float angle = (TIME * layer_rot_speed + time_offset);
		if (i % 2 == 1) { // Alternate direction for odd layers
			angle *= -1.0;
		}
		float s = sin(angle);
		float c = cos(angle);
		// Corrected mat2 constructor arguments for standard rotation matrix
		mat2 rotation_matrix = mat2(vec2(c, s), vec2(-s, c)); // Column 0: (c, s), Column 1: (-s, c)

		// --- Pulsing (Scaling) ---
		// Slightly vary speed per layer
		float layer_pulse_speed = pulse_speed * (1.0 - layer_float * 0.05);
		// Calculate scale factor using sine wave for pulsing effect
		float scale = 1.0 + sin(TIME * layer_pulse_speed + time_offset) * pulse_amount;

		// --- UV Transformation ---
		vec2 uv = base_uv - vec2(0.5); // Center UV coordinates around (0,0)
		uv = rotation_matrix * uv;     // Apply rotation
		uv *= scale;                   // Apply scaling (pulsing)
		uv += vec2(0.5);               // Translate UV coordinates back to original origin

		// --- Sample Texture ---
		vec4 layer_tex = texture(texture_albedo, uv);

		// --- Accumulate Results (Additive Blending) ---
		accumulated_color += layer_tex.rgb;
		accumulated_alpha += layer_tex.a;
	}

	// Apply base color and alpha, modulated by accumulated results
	ALBEDO = albedo.rgb * accumulated_color;
	// Modulate the shader's alpha with the base alpha and the accumulated alpha
	ALPHA *= albedo.a * accumulated_alpha;
	// Clamp final alpha to ensure it stays within the valid range [0, 1]
	ALPHA = clamp(ALPHA, 0.0, 1.0);
}
