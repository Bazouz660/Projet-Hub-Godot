shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha, diffuse_toon, specular_toon;

// Uniforms for textures and blend color
uniform sampler2D grass_texture : filter_nearest, source_color;
uniform sampler2D gradient : source_color;
uniform vec4 blend_color : source_color;  // The color to blend with
uniform float sway_x = 0.2;
uniform float sway_z = 0.15;

varying float sway_amount;

void vertex() {
    NORMAL = vec3(0.0, 1.0, 0.0);
    sway_amount = sin(NODE_POSITION_WORLD.x + TIME * 1.25 + UV.y) * (1.0 - UV.y) * sway_x;
    VERTEX.x += sway_amount;
    VERTEX.z += cos(NODE_POSITION_WORLD.z + TIME * 0.45 + UV.y) * (1.0 - UV.y) * sway_z;
}

void fragment() {
    vec4 grass_color = texture(grass_texture, UV);

    // Rotate the gradient texture by 90 degrees counterclockwise
    vec2 rotatedUV = vec2(1.0 - UV.y, UV.x);
    vec4 gradient_color = texture(gradient, rotatedUV);

    // Calculate blend factor based on sway and UV.y
    float blend_factor = sway_amount;

    // Output the final color mixed with the gradient color
    ALBEDO = mix(gradient_color.rgb, blend_color.rgb, clamp(abs(-blend_factor * 5.0), 0.0, 1.0) * (1.0 - UV.y));
    ALPHA = grass_color.a;

    BACKLIGHT = vec3(1.0, 1.0, 1.0);  // Backlight remains the same
}
