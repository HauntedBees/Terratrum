shader_type spatial;

/*
MIT License

Copyright (c) 2021 John Wigg

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

const float PI = 3.1415926536f;

uniform vec4 albedo : hint_color = vec4(1.0f);
uniform sampler2D mask_texture:hint_albedo;
uniform vec4 albedo_a:hint_color = vec4(1.0f);
uniform sampler2D texture_a:hint_albedo;
uniform vec4 albedo_b:hint_color = vec4(1.0f);
uniform sampler2D texture_b:hint_albedo;

uniform bool clamp_diffuse_to_max = false;

uniform int cuts : hint_range(1, 8) = 3;
uniform float wrap : hint_range(-2.0f, 2.0f) = 0.0f;
uniform float steepness : hint_range(1.0f, 8.0f) = 1.0f;

uniform bool use_attenuation = true;

uniform bool use_specular = true;
uniform float specular_strength : hint_range(0.0f, 1.0f) = 1.0f;
uniform float specular_shininess : hint_range(0.0f, 32.0f) = 16.0f;
uniform sampler2D specular_map : hint_albedo;

float split_specular(float specular) {
	return step(0.5f, specular);
}

void fragment() {
	vec3 mask = texture(mask_texture, UV).rgb;
	vec3 a = albedo_a.rgb * texture(texture_a, UV).rgb;
	vec3 b = albedo_b.rgb * texture(texture_b, UV).rgb;
	vec3 color = mix(b, a, mask);
	ALBEDO = albedo.rgb * color;
}

void light() {
	float attenuation = 1.0f;
	if (use_attenuation) {
		attenuation = ATTENUATION.x;
	}
	
	float NdotL = dot(NORMAL, LIGHT);
	float diffuse_amount = NdotL + (attenuation - 1.0) + wrap;
	diffuse_amount *= steepness;
	float cuts_inv = 1.0f / float(cuts);
	float diffuse_stepped = clamp(diffuse_amount + mod(1.0f - diffuse_amount, cuts_inv), 0.0f, 1.0f);
	
	vec3 diffuse = ALBEDO.rgb * LIGHT_COLOR / PI;
	diffuse *= diffuse_stepped;
	
	if (clamp_diffuse_to_max) { // Clamp diffuse to max for multiple light sources.
		DIFFUSE_LIGHT = max(DIFFUSE_LIGHT, diffuse);
	} else {
		DIFFUSE_LIGHT += diffuse;
	}
	
	if (use_specular) {
		vec3 H = normalize(LIGHT + VIEW);
		float NdotH = dot(NORMAL, H);
		float specular_amount = max(pow(NdotH, specular_shininess*specular_shininess), 0.0f)
							    * texture(specular_map, UV).r
								* attenuation;
		specular_amount = split_specular(specular_amount);
		SPECULAR_LIGHT += specular_strength * specular_amount * LIGHT_COLOR;
	}
}