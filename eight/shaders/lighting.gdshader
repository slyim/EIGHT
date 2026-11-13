shader_type canvas_item;
render_mode blend_mul, unshaded;
// PLACEHOLDER-tunable darkness. The Lighting group's children (the lights) arrive in
// screen_texture; this pass multiplies the finished world by ambient + light. Light is read
// once per art pixel and stepped into dithered bands, so it sits on the pixel-art grid.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 ambient : source_color = vec4(0.32, 0.38, 0.50, 1.0);
uniform float art_pixel = 2.0;
// 0 bands is a smooth gradient; dither is the checkered share of each band edge.
uniform float bands : hint_range(0.0, 16.0, 1.0) = 6.0;
uniform float dither : hint_range(0.0, 1.0) = 0.28;
// Brightest light kept; overlapping lights saturate here instead of washing out to white.
uniform float max_light : hint_range(0.5, 4.0) = 2.4;
varying vec2 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
float bayer(vec2 cell) {
	const float M[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	ivec2 p = ivec2(mod(cell, 4.0));
	return (M[p.y * 4 + p.x] + 0.5) / 16.0;
}
void fragment() {
	// Every screen pixel inside one art pixel reads the light at that art pixel's centre.
	vec2 cell = floor(world / art_pixel);
	vec2 uv_per_world = vec2(dFdx(SCREEN_UV.x) / dFdx(world.x), dFdy(SCREEN_UV.y) / dFdy(world.y));
	vec3 light = textureLod(screen_texture, SCREEN_UV + ((cell + 0.5) * art_pixel - world) * uv_per_world, 0.0).rgb;
	float level = max(light.r, max(light.g, light.b));
	if (level > 0.0) {
		// Bands are spaced on a square-root curve so the dim outer rings stay visible.
		float t = sqrt(min(level, max_light) / max_light);
		if (bands > 0.0) {
			t = floor(t * bands + 0.5 + (bayer(cell) - 0.5) * dither) / bands;
		}
		light *= t * t * max_light / level;
	}
	COLOR = vec4(ambient.rgb + light, 1.0);
}
