shader_type sky;

uniform vec3 sky_color : source_color = vec3(0.2, 0.5, 0.9);
uniform vec3 horizon_color : source_color = vec3(0.5, 0.8, 1.0);
uniform float horizon_blur : hint_range(0.0, 1.0) = 0.1;

uniform vec3 sun_color : source_color = vec3(1.0, 1.0, 0.8);
uniform float sun_size : hint_range(0.01, 1.0) = 0.05;
uniform float sun_blur : hint_range(0.0, 0.5) = 0.01;

uniform vec3 cloud_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float cloud_edge_sharpness : hint_range(0.0, 1.0) = 0.1;
uniform float cloud_scale : hint_range(0.1, 10.0) = 2.0;
uniform float cloud_speed : hint_range(0.0, 0.5) = 0.02;

// Pseudo-random noise function for procedural cartoon clouds
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	
	return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Layered noise for cloud shapes
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 3; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void sky() {
	// 1. Base Sky Gradient (Two-Tone Cel Look)
	float sky_gradient = EYEDIR.y;
	float horizon_mask = smoothstep(-horizon_blur, horizon_blur, sky_gradient);
	vec3 final_sky = mix(horizon_color, sky_color, horizon_mask);
	
	// 2. Stylized Sun Disc
	// LIGHT0_DIRECTION is automatically provided by Godot's DirectionalLight3D
	float sun_distance = distance(EYEDIR, LIGHT0_DIRECTION);
	float sun_mask = smoothstep(sun_size, sun_size - sun_blur, sun_distance);
	final_sky = mix(final_sky, sun_color, sun_mask);
	
	// 3. Procedural Cartoon Clouds (Only calculated on upper hemisphere)
	if (EYEDIR.y > 0.0) {
		// Project sky direction onto a flat 2D plane for cloud mapping
		vec2 cloud_uv = EYEDIR.xz / (EYEDIR.y + 0.3);
		
		// Animate the clouds smoothly over time
		cloud_uv += TIME * cloud_speed;
		cloud_uv *= cloud_scale;
		
		// Sample noise and sharpen the edges to get a crisp "pop" anime style
		float cloud_noise = fbm(cloud_uv);
		float cloud_mask = smoothstep(0.4, 0.4 + cloud_edge_sharpness, cloud_noise);
		
		// Fade out clouds near the distant horizon so they don't look cut off
		cloud_mask *= smoothstep(0.0, 0.3, EYEDIR.y);
		
		final_sky = mix(final_sky, cloud_color, cloud_mask);
	}
	
	COLOR = final_sky;
}