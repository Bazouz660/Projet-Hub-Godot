shader_type canvas_item;

uniform float x_offset = 0;
uniform float y_offset = 0;

void vertex() {
	UV.x += x_offset;
	UV.y += y_offset;
}