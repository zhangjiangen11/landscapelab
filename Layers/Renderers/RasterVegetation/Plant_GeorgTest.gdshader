shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

#include "res://Layers/Renderers/Terrain/Materials/Hue.gdshaderinc"
#include "res://Util/Shading/generate_normal_from_albedo.gdshaderinc"

global uniform vec3 HCY_SHIFT;

uniform sampler2D[100] texture_map : source_color, repeat_disable;
uniform sampler2D albedo_test_map: source_color, repeat_disable; // Georg Test
uniform sampler2D world_space_normal_map: hint_normal, repeat_enable;
uniform float world_space_normal_scale = 0.007;

uniform int sprite_size = 2048;

uniform float amplitude = 0.1;
uniform vec2 speed = vec2(0.5, 0.4);
uniform vec2 scale = vec2(0.06, 0.11);

uniform vec2 heightmap_size = vec2(300.0, 300.0);
uniform vec2 offset;

uniform float max_distance;
uniform bool camera_facing;
uniform bool billboard_enabled = false;

uniform float fake_shadow_height = 1.2;
uniform float fake_shadow_min_multiplier = 0.25;

varying vec3 worldpos;
varying vec3 camera_pos;

varying float size;
varying float dist_id;

uniform float hue_factor: hint_range(0, 3.14) = 1.0;
uniform float chroma_factor: hint_range(0.0, 3.0) = 2.0;
uniform float luminance_factor: hint_range(0.0, 3.0) = 2.0;


// Workaround for a bug in `texelFetch` - use this instead!
// More info at https://github.com/godotengine/godot/issues/31732
vec4 texelGet ( sampler2D tg_tex, ivec2 tg_coord, int tg_lod ) {
	vec2 tg_texel = 1.0 / vec2(textureSize(tg_tex, 0));
	vec2 tg_getpos = (vec2(tg_coord) * tg_texel) + (tg_texel * 0.5);
	return texture(tg_tex, tg_getpos, float(tg_lod));
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void vertex() {
	camera_pos = INV_VIEW_MATRIX[3].xyz;
	worldpos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

	// Move the upper vertices around for a wind wave effect
	if (VERTEX.y > 0.3) {
		VERTEX.x += amplitude * sin(worldpos.x * scale.x * 0.75 + TIME * speed.x) * cos(worldpos.z * scale.x + TIME * speed.x * 0.25);
		VERTEX.z += amplitude * sin(worldpos.x * scale.y + TIME * speed.y * 0.35) * cos(worldpos.z * scale.y * 0.80 + TIME * speed.y);

		// Also bend them away from the camera to make it look better from above
		//VERTEX.xz += (inverse(MODELVIEW_MATRIX) * vec4(0.0, 0.5, 0.0, 0.0)).xz * VERTEX.y;
	}

	// Scale by the size
	size = INSTANCE_CUSTOM.r * 40.0;
	// Georg Test
	//VERTEX *= size;

	// Georg Test //
	NORMAL = mix(vec3(0.0, 1.0, 1.0), (texture(world_space_normal_map, worldpos.xz * world_space_normal_scale).xyz - vec3(0.5, 0.5, 0.5)).xzy * 2.0, 0.5);
	//NORMAL = mix(COLOR.xyz, (texture(world_space_normal_map, worldpos.xz * world_space_normal_scale).xyz - vec3(0.5, 0.5, 0.5)).xzy * 2.0, 0.5);

	// Update the world position again with the scaled Vertex (otherwise the distance fade-out is off)
	worldpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	dist_id = INSTANCE_CUSTOM.g * 255.0;

	ivec2 texture_size = textureSize(texture_map[int(round(dist_id))], 0);
	VERTEX.xz *= float(texture_size.x) / float(texture_size.y);  // Account for the texture's aspect ratio
}

void fragment() {
	// See https://github.com/godotengine/godot/issues/42411
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}

	float blend_start_distance = max_distance - max_distance / 4.0;
	float dist = length(camera_pos.xz - worldpos.xz);

	float dist_alpha = clamp((dist -  blend_start_distance) / (max_distance - blend_start_distance), 0.0, 1.0);

	vec4 color = texture(texture_map[int(round(dist_id))], UV);

	// Georg Test
	ALPHA = texture(albedo_test_map, UV).a;
	ALPHA_SCISSOR_THRESHOLD = 0.7;
	//ALPHA = color.a;
	//ALPHA_SCISSOR_THRESHOLD = 0.7 + dist_alpha * 0.3;

	// Vary the transmission based on how bright and/or green the plant is here
	// (This is to approximate a higher transmission for leaves)
	BACKLIGHT = vec3(1.0, 1.0, 0.5) * min(color.g * 2.0, 1.0);

	// Make the plant darker at the bottom to simulate some shadowing
//	float size_scaled_uv = (1.0 - UV.y) * size; // ranges from 0 (bottom) to size (top)
//	color.rgb *= min(max(size_scaled_uv, fake_shadow_min_multiplier), fake_shadow_height) / fake_shadow_height;

	// Hue shift to make plant appear e.g. dryer
	vec3 hcy = RGBtoHCY(color.rgb);

	float begin = -PI;
	float end = 0.0;

	// FIXME: Make this scaleable by HCY_SHIFT.r
	if (hcy.x > begin && hcy.x < end) {
		float factor = hcy.x - begin;
		factor /= end - begin;
		factor -= 0.5;
		factor *= PI;

		hcy.x += cos(factor);
	}

	hcy.g *= HCY_SHIFT.g;
	hcy.b *= HCY_SHIFT.b;

	//Georg Test
	ALBEDO = texture(albedo_test_map, UV).rgb;
	//ALBEDO = HCYtoRGB(hcy);

	//albedo_channel_influence_for_normalgen = vec4(1.0, 1.0, 1.0, 5.0);
	NORMAL_MAP = generate_normal_from_albedo(albedo_test_map, UV);
	//NORMAL_MAP = generate_normal_from_albedo(texture_map[int(round(dist_id))], UV);
	NORMAL_MAP_DEPTH = 20.0;

	// Other material parameters
	//RIM = 0.4;
	METALLIC = 0.0;
	ROUGHNESS = 0.6;// - color.g * 0.5;
	SPECULAR = 1.0;
}