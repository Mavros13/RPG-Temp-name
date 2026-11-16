shader_type spatial;

// World-space grain so flagstones, ashlar, and iron read as materials
// instead of a single flat color per surface. UVs on these meshes are
// not a shared scale, so the pattern follows meters.

varying vec3 world_pos;
varying vec3 world_normal;

uniform vec4 albedo : source_color = vec4(0.16, 0.13, 0.1, 1.0);
uniform float roughness_base : hint_range(0.0, 1.0) = 0.9;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float grain : hint_range(0.0, 1.0) = 0.22;
uniform float grain_scale = 2.6;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.4;
uniform float ao_strength : hint_range(0.0, 1.0) = 0.16;
uniform vec3 emission_color : source_color = vec3(0.0);
uniform float emission_energy = 0.0;
uniform float flicker = 0.0;

float hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

float value_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(i);
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));
	return mix(
		mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
		mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y),
		f.z
	);
}

float triplanar(vec3 p, vec3 n, float scale) {
	vec3 w = abs(n);
	w = w * w * w * w;
	w /= max(w.x + w.y + w.z, 0.0001);
	float s = scale;
	return value_noise(p * s) * w.x
		+ value_noise(p.yzx * s + vec3(17.2, 3.1, 9.4)) * w.y
		+ value_noise(p.zxy * s + vec3(5.5, 13.7, 2.2)) * w.z;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

void fragment() {
	vec3 n = normalize(world_normal);
	float broad = triplanar(world_pos, n, grain_scale * 0.37);
	float fine = triplanar(world_pos, n, grain_scale);
	float detail = broad * 0.58 + fine * 0.42;
	float micro = value_noise(world_pos * (grain_scale * 8.0));
	vec3 tint = mix(vec3(1.05, 0.98, 0.91), vec3(0.92, 0.95, 1.02), broad);
	float lift = mix(1.0 - grain, 1.0 + grain, detail);
	lift *= mix(0.97, 1.03, micro);
	ALBEDO = albedo.rgb * tint * lift;
	ROUGHNESS = clamp(roughness_base + (fine - 0.5) * 0.16, 0.04, 1.0);
	METALLIC = metallic;
	AO = mix(1.0 - ao_strength, 1.0, fine);
	float pulse = 1.0 + flicker * sin(TIME * 7.5 + world_pos.x * 8.0 + world_pos.z * 6.0);
	EMISSION = emission_color * emission_energy * pulse;

	float eps = 0.04;
	float dx = triplanar(world_pos + vec3(eps, 0.0, 0.0), n, grain_scale) - fine;
	float dy = triplanar(world_pos + vec3(0.0, eps, 0.0), n, grain_scale) - fine;
	float dz = triplanar(world_pos + vec3(0.0, 0.0, eps), n, grain_scale) - fine;
	vec3 bumped = normalize(n - vec3(dx, dy, dz) * normal_strength);
	NORMAL = normalize((VIEW_MATRIX * vec4(bumped, 0.0)).xyz);
}
