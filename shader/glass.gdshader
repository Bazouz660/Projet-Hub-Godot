shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, blend_mix, depth_prepass_alpha, cull_back;

group_uniforms albedo;
uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_nearest_mipmap;

group_uniforms roughness;
uniform float roughness : hint_range(0.0, 1.0) = 0.15;
uniform sampler2D roughness_texture : hint_roughness_r, filter_nearest_mipmap;

group_uniforms refraction;
uniform float refraction : hint_range(-16,16) = 0.5;
uniform sampler2D texture_refraction : filter_nearest_mipmap, repeat_enable;
uniform vec4 refraction_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest_mipmap;

group_uniforms normal;
uniform float normal_strength : hint_range(-16.0, 16.0) = 0.0;
uniform sampler2D normal_map : hint_normal, filter_nearest_mipmap;

group_uniforms misc;
uniform vec4 edge_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float surface_contribution = 0.2;
uniform float specular_contribution = 0.2;
uniform float refraction_contribution = 1.0;

group_uniforms uv;
uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(0.0);

//
// Add a mask texture for controlling the glass effect.
// White = glass effect applied, Black = no glass effect
//
uniform sampler2D glass_mask : source_color, hint_default_white, filter_nearest_mipmap;

float SchlickFresnel(float u) {
	float m = 1.0 - u;
	float m2 = m * m;
	return m2 * m2 * m;
}

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
}

void fragment() {
	// Sample the mask
	float mask = 1.0 - texture(glass_mask, UV).r;

	NORMAL_MAP = texture(normal_map, UV).xyz;
	NORMAL_MAP_DEPTH = normal_strength;

	float VdotN = dot(VIEW, NORMAL);
	float fresnel = clamp(SchlickFresnel(VdotN), 0.0, 1.0);

	vec4 albedo_mix = texture(albedo_texture, UV) * albedo;
	float roughness_mix = clamp(texture(roughness_texture, UV).r * roughness, 0.0, 1.0);

	float a = mix(0.001, 1.0, albedo_mix.a);
	float a_factor_0 = mix(fresnel * edge_color.a, 1.0, a);
	float a_factor_1 = 0.5 * sqrt(a);
	float a_factor_2 = a_factor_0 + a_factor_1;

	float surface_contribution_f = 1.0 - mask;

	ALBEDO = mix(edge_color.rgb * edge_color.a, albedo_mix.rgb * surface_contribution_f, a);
	ROUGHNESS = roughness_mix;
	SPECULAR = 0.5 * inversesqrt(specular_contribution) * mask;

	// Compute normal with normal map influence
	vec3 unpacked_normal = NORMAL_MAP * 2.0 - 1.0;
	unpacked_normal.z = sqrt(max(0.0, 1.0 - dot(unpacked_normal.xy, unpacked_normal.xy)));
	vec3 ref_normal = normalize(mix(
		NORMAL,
		TANGENT * unpacked_normal.x + BINORMAL * unpacked_normal.y + NORMAL * unpacked_normal.z,
		NORMAL_MAP_DEPTH
	));

	// Compute refraction offset
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * dot(texture(texture_refraction, UV), refraction_texture_channel) * refraction;

	// Glass refraction amount is now modulated by the mask
	float ref_amount = (1.0 - albedo_mix.a) * mask;

	// Only apply the EMISSION (i.e., the refracted background) if mask > 0
	if (ref_amount > 0.0) {
		vec3 refracted_col = textureLod(screen_texture, ref_ofs, ROUGHNESS * 8.0).rgb;
		vec3 tint = mix(vec3(mix(0.02, 0.1, a)), albedo_mix.rgb * refraction_contribution, a);
		EMISSION += refracted_col * ref_amount * EXPOSURE * tint / a_factor_2;
	}

	// For non-glass parts (mask=0), you can choose to keep them opaque or adjust accordingly
	// Current logic: ALBEDO is already set, and since ref_amount=0, no refraction EMISSION is added.
	ALBEDO *= 1.0 - ref_amount;
}
