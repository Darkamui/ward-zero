// Fullscreen pre-rendered background. Parented to the active camera just inside the far
// plane. Samples by SCREEN_UV, like proxy.gdshader, so both always line up.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;

global uniform sampler2D wz_background : source_color, filter_linear;

void fragment() {
	ALBEDO = texture(wz_background, SCREEN_UV).rgb;
}
