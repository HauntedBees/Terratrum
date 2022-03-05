shader_type spatial;

uniform sampler2D mask_texture:hint_albedo;
uniform vec4 albedo_a:hint_color = vec4(1.0f);
uniform sampler2D texture_a:hint_albedo;
uniform vec4 albedo_b:hint_color = vec4(1.0f);
uniform sampler2D texture_b:hint_albedo;

void fragment() {
	vec4 mask = texture(mask_texture, UV).rgba;
	vec4 a = albedo_a * texture(texture_a, UV).rgba;
	vec4 b = albedo_b * texture(texture_b, UV).rgba;
	vec4 color = mix(b, a, mask);
	ALBEDO = color.rgb;
	ALPHA = color.a;
	
}