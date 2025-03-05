shader_type spatial;
render_mode depth_draw_always;
stencil_mode read, compare_not_equal, 1;

void fragment() {
    ALBEDO = vec3(1.0); // White
	ALPHA = 1.0; // Force to transparency pipeline 
}