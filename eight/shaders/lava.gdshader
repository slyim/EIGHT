shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/canvas_color.gdshaderinc"
// Cooling plates and narrow hot seams in the molten fill. The rim and bubbles keep their ink.
uniform float shimmer : hint_range(0.0, 0.5) = 0.12;
uniform float art_pixel = 2.0;
uniform float step_time = 0.12;
varying vec2 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
void fragment() {
	vec4 color = COLOR;
	vec3 ink = canvas_to_linear(color.rgb);
	// LavaPools draws just the molten layer with this midrange orange.
	if (ink.r > 0.35 && ink.g > 0.10 && ink.g < 0.32) {
		vec2 cell = floor(world / art_pixel);
		float t = floor(TIME / step_time) * step_time * shimmer;
		float flow = sin(cell.y * 0.17 + 1.8 * sin(cell.x * 0.13) - t * 3.8);
		flow += 0.72 * cos(cell.x * 0.19 - 1.6 * sin(cell.y * 0.11) + t * 2.8);
		float seam = abs(flow - 0.30);
		vec3 molten = mix(vec3(0.20, 0.028, 0.018), vec3(0.58, 0.095, 0.028), step(flow, 0.45));
		molten = mix(molten, vec3(0.86, 0.21, 0.052), 1.0 - step(0.40, seam));
		molten = mix(molten, vec3(1.13, 0.44, 0.11), 1.0 - step(0.13, seam));
		color.rgb = linear_to_canvas(molten);
	}
	COLOR = color;
}
