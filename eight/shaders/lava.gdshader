shader_type canvas_item;
// PLACEHOLDER-tunable lava shimmer: bright and dark ripples crawl across the molten fill only
// (crust and bubbles untouched), read once per art pixel and stepped in time, so the heat
// moves in pixel-sized beats. 0 switches it off.
uniform float shimmer : hint_range(0.0, 0.5) = 0.14;
uniform float art_pixel = 2.0;
uniform float step_time = 0.12;
varying vec2 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
void fragment() {
	vec4 color = COLOR;
	// The molten fill is the only bright orange the lava draws (bubbles are yellower).
	if (shimmer > 0.0 && color.r > 0.8 && color.g < 0.6 && color.b < 0.2) {
		vec2 cell = floor(world / art_pixel);
		float t = floor(TIME / step_time) * step_time;
		float wave = sin(cell.y * 0.35 + sin(cell.x * 0.12) * 2.0 - t * 5.0);
		color.rgb *= 1.0 + shimmer * (wave > 0.55 ? 1.0 : (wave < -0.6 ? -0.6 : 0.0));
	}
	COLOR = color;
}
