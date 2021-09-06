shader_type canvas_item;
uniform sampler2D mask_texture;
uniform float sprite_ratio = 0.25;
uniform vec2 offset = vec2(0, 0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 adjusted_uv = vec2(UV.x, UV.y);
	while(adjusted_uv.x > sprite_ratio) { adjusted_uv.x -= sprite_ratio; }
	while(adjusted_uv.y > sprite_ratio) { adjusted_uv.y -= sprite_ratio; }
	c.a *= 1.0 - texture(mask_texture, adjusted_uv + offset).r;
	COLOR = c;
}