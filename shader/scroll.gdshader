shader_type canvas_item;

uniform float x_speed = 0.1;
uniform float y_speed = 0.1;

void vertex() {
	UV.x += TIME * x_speed;
	UV.y += TIME * y_speed;
}