shader_type canvas_item;
// PLACEHOLDER-tunable lava shimmer: bright and dark ripples crawl across the molten fill only
// (crust and bubbles untouched), read once per art pixel and stepped in time, so the heat
// moves in pixel-sized beats. 0 switches it off.
uniform float shimmer : hint_range(0.0, 0.5) = 0.12;
uniform float art_pixel = 2.0;
uniform float step_time = 0.12;
varying vec2 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
void fragment() {
	vec4 color = COLOR;
	// The molten fill and core are the only medium-bright oranges the lava draws (crust/rim are darker, bubbles are yellower).
	if (shimmer > 0.0 && color.r > 0.22 && color.g < 0.45 && color.b < 0.08) {
		vec2 cell = floor(world / art_pixel);
		float t = floor(TIME / step_time) * step_time;
		float w1 = sin(cell.y * 0.24 + sin(cell.x * 0.13 + t * 1.4) * 2.2 - t * 4.2);
		float w2 = cos(cell.x * 0.19 - sin(cell.y * 0.17 - t * 1.1) * 1.8 + t * 2.8);
		float wave = w1 * 0.6 + w2 * 0.4;
		if (wave > 0.38) {
			color.rgb *= vec3(1.0 + shimmer * 1.6, 1.0 + shimmer * 2.2, 1.0 + shimmer * 1.2);
		} else if (wave < -0.28) {
			color.rgb *= max(vec3(0.0), vec3(1.0 - shimmer * 2.0, 1.0 - shimmer * 2.2, 1.0 - shimmer * 1.5));
		}
	}
	COLOR = color;
}
