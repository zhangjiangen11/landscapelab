shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

#include "res://Layers/Renderers/Terrain/Materials/Hue.gdshaderinc"

global uniform vec3 HCY_SHIFT;

uniform float alpha_hash_scale;

uniform float roughness : hint_range(0,1);
uniform float specular;
uniform float metallic;
uniform vec4 backlight : source_color;

uniform int sprite_count = 3;

uniform sampler2D spritesheet_albedo: source_color, filter_linear_mipmap;
uniform sampler2D spritesheet_normal: hint_normal, filter_linear_mipmap;

uniform vec3 most_extreme_random_color: source_color;

varying flat float spritesheet_index;
varying flat float random_instance_factor;
varying flat float is_detailed;

uniform float sway_speed = 5.0;
uniform float sway_strength = 0.03;
uniform float sway_phase_len = 8.0;
uniform vec3 wind_dir = vec3(1, 1, 0.5);

void vertex() {
	float start_point = 0.25;
	vec3 mid_point = vec3(0., 0.5, 0.);
	float dist = distance(VERTEX, mid_point) * 0.1;

	float time = TIME + float(INSTANCE_ID) / 10.0;

	float strength = dist * sway_strength * float(VERTEX.y > start_point);
	VERTEX.x += sin(VERTEX.x * sway_phase_len * 1.123 + time * sway_speed) * strength * wind_dir.x;
	VERTEX.y += sin(VERTEX.y * sway_phase_len + time * sway_speed * 1.12412) * strength * wind_dir.y;
	VERTEX.z += sin(VERTEX.z * sway_phase_len * 0.9123 + time * sway_speed * 1.3123) * strength * wind_dir.z;

	spritesheet_index = INSTANCE_CUSTOM.r;
	random_instance_factor = INSTANCE_CUSTOM.g;
	is_detailed = INSTANCE_CUSTOM.b;
}

void fragment() {
	vec2 base_uv = UV;

	base_uv.x -= floor(base_uv.x);
	base_uv.y -= floor(base_uv.y);

	base_uv.y /= float(sprite_count);
	base_uv.y += spritesheet_index / float(sprite_count);

	vec4 albedo_tex = texture(spritesheet_albedo, base_uv);

	vec3 color = albedo_tex.rgb * mix(vec3(1.0), most_extreme_random_color, random_instance_factor);

	// Hue shift to make plant appear e.g. dryer
	vec3 hcy = RGBtoHCY(color.rgb);

	float begin = mix(-0.6, -PI, min(HCY_SHIFT.r * 2.0, 1.0));
	float end = -0.6;

	if (hcy.x > begin && hcy.x < end) {
		// `factor` is the position of hcy.x within the range of begin to end, scaled to -PI/2 to +PI/2.
		// This way, by getting the cosine of the factor, we get a smooth curve from 0..1..0.
		float factor = hcy.x - begin;
		factor /= end - begin;
		factor -= 0.5;
		factor *= PI;

		float addition = cos(factor) * (end - begin) / 2.0;
		hcy.x += addition;
		hcy.y += addition * 0.01;
	}

	//hcy.r += random_hue_shift;
	//hcy.g *= HCY_SHIFT.g * (random_hue_shift + 1.0);
	//hcy.b *= HCY_SHIFT.b * (random_hue_shift + 1.0);

	ALBEDO = HCYtoRGB(hcy);

	NORMAL_MAP = texture(spritesheet_normal, base_uv).rgb;

	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;

	ALPHA = albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = 0.35;

	BACKLIGHT = backlight.rgb * (0.3 + is_detailed * 0.7);
	RIM = 0.3 * (0.3 + is_detailed * 0.7);
}
