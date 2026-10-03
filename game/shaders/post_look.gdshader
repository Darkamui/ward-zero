// Unified look over backgrounds and characters (GDD §9.3 step 8, docs/01-foundation.md §8.5):
// 3D LUT, film grain, chromatic aberration, vignette. Each effect has an intensity for
// the accessibility sliders (GDD §12).
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
// 32x32x32 LUT as a 1024x32 strip (slices left to right, blue increasing).
uniform sampler2D lut : filter_linear;
uniform bool use_lut = false;
uniform float lut_strength : hint_range(0.0, 1.0) = 1.0;
uniform float grain : hint_range(0.0, 0.3) = 0.06;
uniform float aberration : hint_range(0.0, 0.01) = 0.0015;
uniform float vignette : hint_range(0.0, 1.0) = 0.35;

vec3 apply_lut(vec3 c) {
	float size = 32.0;
	float b = c.b * (size - 1.0);
	float slice0 = floor(b);
	float slice1 = min(slice0 + 1.0, size - 1.0);
	vec2 uv = vec2((c.r * (size - 1.0) + 0.5) / (size * size), (c.g * (size - 1.0) + 0.5) / size);
	vec3 a = texture(lut, uv + vec2(slice0 / size, 0.0)).rgb;
	vec3 d = texture(lut, uv + vec2(slice1 / size, 0.0)).rgb;
	return mix(a, d, b - slice0);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 off = (uv - 0.5) * aberration;
	vec3 col;
	col.r = texture(screen_tex, uv + off).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - off).b;
	if (use_lut) {
		col = mix(col, apply_lut(clamp(col, 0.0, 1.0)), lut_strength);
	}
	float n = hash(uv * vec2(1920.0, 1080.0) + fract(TIME * 7.0) * 100.0) - 0.5;
	col += n * grain;
	float v = smoothstep(0.85, 0.25, length(uv - 0.5));
	col *= mix(1.0, v, vignette);
	COLOR = vec4(col, 1.0);
}
