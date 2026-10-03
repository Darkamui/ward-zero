// Proxy geometry (floor_, occ_ meshes) in game mode (docs/01-foundation.md §8.4).
// Draws the pre-rendered background at this pixel, so the proxy is invisible, but it
// writes depth, hiding the character wherever the proxy is in front of it.
// Receives the character's shadow from directional (key) lights only.
shader_type spatial;
render_mode specular_disabled, ambient_light_disabled;

global uniform sampler2D wz_background : source_color, filter_linear;
global uniform float wz_debug_proxies;

// 0 = no shadow received, 1 = full black shadow.
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec3 bg = texture(wz_background, SCREEN_UV).rgb;
	ALBEDO = mix(bg, vec3(1.0, 0.0, 1.0), wz_debug_proxies * 0.45);
}

void light() {
	// Only the key (directional) light contributes, and only its shadow term, so an
	// unshadowed pixel is exactly the background colour.
	if (LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += vec3(mix(1.0 - shadow_strength, 1.0, ATTENUATION));
	}
}
