shader_type canvas_item;
render_mode blend_mix;
uniform float radius_x = 10.0;
uniform float radius_y = 10.0;
uniform bool center = false;
void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 ps = TEXTURE_PIXEL_SIZE;
	if(radius_y != 0.0) {
		col += texture(TEXTURE, UV + vec2(0.0, -radius_y) * ps);
		col += texture(TEXTURE, UV + vec2(0.0, radius_y) * ps);
	}
	if(center) { col += texture(TEXTURE, UV + vec2(0.0, 0.0) * ps); }
	if(radius_x != 0.0) {
		col += texture(TEXTURE, UV + vec2(-radius_x, 0.0) * ps);
		col += texture(TEXTURE, UV + vec2(radius_x, 0.0) * ps);
	}
	col /= 5.0;
	COLOR = col;
}