$input v_wpos, v_texcoord0

#include "common.sh"

SAMPLER2D(u_normal_buffer, 15);
SAMPLER2D(u_texture, 14);

uniform vec4 u_intensity; 
uniform vec4 u_radius; 


vec3 getViewNormal(vec2 tex_coord)
{
	vec3 wnormal = texture2D(u_normal_buffer, tex_coord).xyz * 2 - 1;
	vec4 vnormal = mul(u_camView, vec4(wnormal, 0));
	return vnormal.xyz;
}

// inspired by https://github.com/tobspr/RenderPipeline/blob/master/rpplugins/ao/shader/ue4ao.kernel.glsl
void main()
{
	const float max_distance = 1.0;
	
	vec3 view_pos = getViewPosition(u_texture, u_camInvProj, v_texcoord0);
	vec3 view_normal = getViewNormal(v_texcoord0);
	
	float occlusion = 0;
	float occlusion_count = 0;
	
	const int SAMPLE_COUNT = 16;
	
	float random_angle = rand(view_pos.xyz) * 6.283285;
	float s = sin(random_angle);
	float c = cos(random_angle);
	for (int i = 0; i < SAMPLE_COUNT; ++i)
	{
		vec2 sample = vec2(POISSON_DISK_16[i].x * c + POISSON_DISK_16[i].y * s, POISSON_DISK_16[i].x * -s + POISSON_DISK_16[i].y * c);
		sample = sample * u_radius.x / view_pos.z;
			
		vec3 vpos_a = getViewPosition(u_texture, u_camInvProj, v_texcoord0 + sample);
		vec3 vpos_b = getViewPosition(u_texture, u_camInvProj, v_texcoord0 - sample);

		vec3 sample_vec_a = normalize(vpos_a - view_pos);
		vec3 sample_vec_b = normalize(vpos_b - view_pos);

		float dist_a = distance(vpos_a, view_pos) / max_distance;
		float dist_b = distance(vpos_b, view_pos) / max_distance;

		float valid_a = step(dist_a - 1.0, 0.0);
		float valid_b = step(dist_b - 1.0, 0.0);

		float angle_a = max(0, dot(sample_vec_a, view_normal));
		float angle_b = max(0, dot(sample_vec_b, view_normal));

		if (valid_a != valid_b)
		{
			angle_a = mix(-angle_b, angle_a, valid_a);
			angle_b = mix(angle_a, -angle_b, valid_b);
			dist_a = mix(dist_b, dist_a, valid_a);
			dist_b = mix(dist_a, dist_b, valid_b);
		}

		if (valid_a > 0.5 || valid_b > 0.5)
		{
			occlusion += (angle_a + angle_b) * 0.25 * (2 - (dist_a + dist_b));
			occlusion_count += 1.0;
		}
		else
		{
			occlusion_count += 0.5;
		}
	}
	
	occlusion /= max(1.0, occlusion_count);
	gl_FragColor.rgb = vec3_splat(1 - occlusion * u_intensity.x);
	gl_FragColor.w = 1;
}
