shader_type canvas_item;

uniform float num_channels = 20.0f;
uniform bool dithering = false;
uniform float dithering_amount = 0.5f;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

bool xor(bool a, bool b) {
	return (a || b) && !(a && b);
}


float dither(float col, bool x_true, bool y_true) {
	float channel = round(col);
	if(abs((floor(col) + 0.5f) - col) < dithering_amount || abs((ceil(col) - 0.5f) - col) < dithering_amount) {
		if(x_true && y_true) {
			return channel - 1.0f;
		}
		else {
			return channel;
		}
	}
	return channel;
}


// quantises the colour of each pixel, and optionally adds a dither effect to the quantisation
void fragment() {
	vec3 col = texture(screen_texture, SCREEN_UV).xyz;
	
	if(dithering) {
		bool x_true = mod(SCREEN_UV.x * float(textureSize(screen_texture, 0).x), 3.0f) < 0.99f;
		bool y_true = mod(SCREEN_UV.y * float(textureSize(screen_texture, 0).y), 3.0f) < 0.99f;
		
		col *= num_channels;
		
		col.x = dither(col.x, x_true, y_true);
		col.x = col.x / num_channels;
		
		col.y = dither(col.y, x_true, y_true);
		col.y = col.y / num_channels;
		
		col.z = dither(col.z, x_true, y_true);
		col.z = col.z / num_channels;
	}
	else {
		col *= num_channels;
		col.x = round(col.x) / num_channels;
		col.y = round(col.y) / num_channels;
		col.z = round(col.z) / num_channels;
	}
	
	COLOR.xyz = col;
}