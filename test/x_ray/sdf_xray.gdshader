shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

// Player position (updated every frame)
uniform vec3 player_position = vec3(0.0, 0.0, 0.0);
uniform float cutout_radius = 3.0;
uniform float edge_softness = 0.1;
uniform bool use_hexagon = true;

// Original material properties (copy from your standard material)
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float roughness : hint_range(0.0, 1.0);
uniform float specular;
uniform float metallic;

varying vec3 world_vertex;

// Signed distance field for hexagon
float sdHexagon(vec2 p, float r) {
    const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
    p = abs(p);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
    return length(p) * sign(p.y);
}

// Signed distance field for circle
float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

void vertex() {
    // Pass world position to fragment shader
    world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Get base color from texture
    vec4 albedo_tex = texture(texture_albedo, UV);

    // Calculate distance from player in XZ plane (assuming Y is up)
    vec2 diff = vec2(world_vertex.x - player_position.x, world_vertex.z - player_position.z);

    // Calculate signed distance
    float dist;
    if (use_hexagon) {
        dist = sdHexagon(diff, cutout_radius);
    } else {
        dist = sdCircle(diff, cutout_radius);
    }

    // Apply regular material properties
    ALBEDO = albedo.rgb * albedo_tex.rgb;
    METALLIC = metallic;
    ROUGHNESS = roughness;
    SPECULAR = specular;

    // Apply cutout effect
    if (dist < 0.0) {
        // Inside cutout area - discard fragment
        discard;
    } else if (dist < edge_softness) {
        // Edge transition - apply smoothstep for soft edge
        float edge_factor = smoothstep(0.0, edge_softness, dist);
        ALPHA = edge_factor;
    }
}