shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

uniform float color_steps = 5.0;
uniform float edge_strength = 1.5;
uniform float edge_threshold = 0.08;

void fragment()
{
    vec2 size = vec2(textureSize(screen_texture, 0));

    vec2 pixel = SCREEN_UV;

    vec3 color = texture(screen_texture, pixel).rgb;

    // Posterize colors
    color = floor(color * color_steps) / color_steps;

    // Edge Detection
    float dx =
        length(texture(screen_texture, pixel + vec2(1.0/size.x,0)).rgb -
               texture(screen_texture, pixel - vec2(1.0/size.x,0)).rgb);

    float dy =
        length(texture(screen_texture, pixel + vec2(0,1.0/size.y)).rgb -
               texture(screen_texture, pixel - vec2(0,1.0/size.y)).rgb);

    float edge = step(edge_threshold, dx + dy);

    color = mix(color, vec3(0.0), edge * edge_strength);

    COLOR = vec4(color,1.0);
}
