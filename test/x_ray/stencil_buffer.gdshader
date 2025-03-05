shader_type spatial;
render_mode unshaded, depth_draw_never;
stencil_mode read, write, compare_not_equal, 1;

uniform float radius = 3.0;
uniform bool use_hexagon = true;

// Properties needed for hexagon shape
varying vec3 world_position;
varying vec3 player_position;

void vertex() {
    world_position = VERTEX;
    player_position = MODEL_MATRIX[3].xyz;
}

float hexagon(vec2 p, float size) {
    p = abs(p);
    float hex = max(dot(p, normalize(vec2(1.0, 0.577))), p.x);
    return step(hex, size);
}

void fragment() {
    // Calculate distance from player in XZ plane (assuming Y is up)
    vec2 offset = vec2(world_position.x - player_position.x, world_position.z - player_position.z);
    
    float mask;
    if (use_hexagon) {
        mask = hexagon(offset, radius);
    } else {
        mask = step(length(offset), radius);
    }
    
    // Only write to stencil buffer, not to color buffer
    ALBEDO = vec3(0.0);
    ALPHA = mask > 0.5 ? 0.0 : 1.0; // Invert mask for stencil
}