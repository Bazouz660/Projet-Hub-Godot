shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded, depth_test_disabled;
stencil_mode read, compare_equal, 1; // Only render where stencil == 1

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 0.7);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

// Optional outline effect
uniform bool use_outline = true;
uniform float outline_width = 0.02;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void vertex() {
    UV = UV * uv1_scale.xy + uv1_offset.xy;
}

void fragment() {
    vec2 base_uv = UV;
    vec4 albedo_tex = texture(texture_albedo, base_uv);

    // Apply x-ray effect - semi-transparent
    ALBEDO = albedo.rgb * albedo_tex.rgb;
    ALPHA = albedo.a * albedo_tex.a;

    // Optional: Add outline effect
    if (use_outline) {
        // Check if we're near an edge
        float edge = 0.0;
        edge += step(1.0 - outline_width, UV.x) + step(UV.x, outline_width);
        edge += step(1.0 - outline_width, UV.y) + step(UV.y, outline_width);

        if (edge > 0.0) {
            ALBEDO = outline_color.rgb;
            ALPHA = outline_color.a;
        }
    }
}