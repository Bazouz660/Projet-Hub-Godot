shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled;
stencil_mode write, read, compare_always, 1;

uniform float radius = 3.0;
uniform float edge_softness = 0.1;
uniform bool use_hexagon = true;
uniform vec4 debug_color : source_color = vec4(1.0, 1.0, 1.0, 0.1);

void vertex() {
    // No special vertex processing needed
}

float hexagon(vec2 p, float size) {
    p = abs(p);
    vec2 q = vec2(p.x - p.y * 0.5, p.y);
    return max(q.x, q.y) - size;
}

void fragment() {
    // Get position in local space
    vec2 pos = vec2(VERTEX.x, VERTEX.z); // Assuming Y is up

    float dist;
    if (use_hexagon) {
        dist = hexagon(pos, radius);
    } else {
        dist = length(pos) - radius;
    }

    // For debugging - visualize the hexagon
    ALBEDO = debug_color.rgb;
    ALPHA = debug_color.a;

    // The stencil buffer operation is handled by the stencil_mode directive
}