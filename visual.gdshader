shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform float color_depth : hint_range(2.0, 32.0) = 8.0; 
uniform float dither_intensity : hint_range(0.0, 0.1) = 0.02;

float dither_pattern(vec2 positional_uv) {
	return fract(sin(dot(positional_uv.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	// Create screen space dithering mesh overlay
	float noise = dither_pattern(floor(UV * vec2(320.0, 240.0)));
	screen_color.rgb += (noise - 0.5) * dither_intensity;
	
	screen_color.rgb = floor(screen_color.rgb * color_depth) / color_depth;
	
	COLOR = vec4(screen_color.rgb, 1.0);
}
