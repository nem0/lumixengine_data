$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_texture, 0);

vec4 getViewPos(vec2 texCoord)
{
	float x = texCoord.x * 2.0 - 1.0;
	float y = texCoord.y * 2.0 - 1.0;
	
	// Assume we have a normal depth range between 0.0 and 1.0
	float z = texture2D(u_texture, texCoord).r * 2.0 - 1.0;
	
	vec4 posProj = vec4(x, y, z, 1.0);
	
	vec4 posView = mul(u_invProj, posProj);
	
	posView /= posView.w;
	
	return posView;
}

void main()
{

	const float CAP_MIN_DISTANCE = 0.000001;
	const float CAP_MAX_DISTANCE = 0.005;

	vec4 view_pos = getViewPos(v_texcoord0);

	vec4 color = texture2D(u_texture, v_texcoord0);
	float occlusion = 0;
	
	const int KERNEL_SIZE = 24;
	const float RADIUS = 1 / 128.0f;
	const vec3 SAMPLES[KERNEL_SIZE] = {
		vec3(-RADIUS, 0, 			0),
		vec3(0, -RADIUS, 			0),
		vec3(RADIUS, 0, 			0),
		vec3(0, RADIUS, 			0),
		vec3(-RADIUS, -RADIUS, 		0),
		vec3(RADIUS, -RADIUS, 		0),
		vec3(RADIUS, RADIUS, 		0),
		vec3(-RADIUS, RADIUS, 		0),
		
		vec3(-RADIUS, 0, 			RADIUS),
		vec3(0, -RADIUS, 			RADIUS),
		vec3(RADIUS, 0, 			RADIUS),
		vec3(0, RADIUS, 			RADIUS),
		vec3(-RADIUS, -RADIUS, 		RADIUS),
		vec3(RADIUS, -RADIUS, 		RADIUS),
		vec3(RADIUS, RADIUS, 		RADIUS),
		vec3(-RADIUS, RADIUS, 		RADIUS),

		vec3(-RADIUS, 0, 			-RADIUS),
		vec3(0, -RADIUS, 			-RADIUS),
		vec3(RADIUS, 0, 			-RADIUS),
		vec3(0, RADIUS, 			-RADIUS),
		vec3(-RADIUS, -RADIUS, 		-RADIUS),
		vec3(RADIUS, -RADIUS, 		-RADIUS),
		vec3(RADIUS, RADIUS, 		-RADIUS),
		vec3(-RADIUS, RADIUS, 		-RADIUS)

	};
	
	for (int i = 0; i < KERNEL_SIZE; ++i)
	{
		vec4 sample_pos = view_pos;
		sample_pos.xyz += SAMPLES[i];
		
		vec4 sample_pos_proj = mul(u_proj, sample_pos);
		sample_pos_proj /= sample_pos_proj.w;
		vec2 sample_pos_texcoord = sample_pos_proj.xy * 0.5 + 0.5;
		
		float sample_z = texture2D(u_texture, sample_pos_texcoord).r * 2.0 - 1.0;
		
		float delta = sample_pos_proj.z - sample_z;
		
		if (delta > CAP_MIN_DISTANCE && delta < CAP_MAX_DISTANCE)
		{
			occlusion += 1.0;
		}
	}
	
	occlusion = clamp(occlusion - KERNEL_SIZE/2, 0, KERNEL_SIZE);
	
	gl_FragColor.rgb = vec3_splat(1 - occlusion / KERNEL_SIZE);
	gl_FragColor.w = 1;
}
