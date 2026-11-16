shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

// Double-sided flame cards. Additive and no depth write, so the two
// sides of a thin tongue do not z-fight, and the core reads hotter
// than the tips.

varying vec3 world_pos;

uniform vec4 albedo : source_color = vec4(1.0, 0.35, 0.05, 1.0);
uniform float energy = 1.4;
uniform float flicker = 0.2;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float along = clamp((world_pos.y - 1.05) / 0.4, 0.0, 1.0);
	float pulse = 1.0 + flicker * sin(TIME * 11.0 + world_pos.y * 16.0 + world_pos.x * 6.0);
	vec3 tip = vec3(albedo.r * 0.55, albedo.g * 0.28, albedo.b * 0.08);
	vec3 color = mix(albedo.rgb, tip, along);
	ALBEDO = color * energy * pulse;
}
