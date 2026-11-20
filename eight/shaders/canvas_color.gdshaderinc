// The HDR canvas is linear in Forward+, while Compatibility blends in sRGB.
vec3 canvas_to_linear(vec3 color) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return mix(color / 12.92, pow(max((color + 0.055) / 1.055, vec3(0.0)), vec3(2.4)), step(0.04045, color));
#else
	return color;
#endif
}

vec3 linear_to_canvas(vec3 color) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return mix(12.92 * color, 1.055 * pow(max(color, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, step(0.0031308, color));
#else
	return color;
#endif
}
