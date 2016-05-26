$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_texture, 15);
uniform vec4 intensity; 
uniform vec4 radius; 
uniform mat4 u_camInvProj;
uniform mat4 u_camProj;

// todo: make it same as in deferred_fs.sc
vec4 getViewPos(vec2 texCoord)
{
	float z = texture2D(u_texture, texCoord).r * 2.0 - 1.0; 
	
	vec4 posProj = vec4(texCoord * 2 - 1, z, 1.0);
	
	vec4 posView = mul(u_camInvProj, posProj);
	
	posView /= posView.w;
	
	return posView;
}

void main()
{
	const float CAP_MIN_DISTANCE = 0.000001;
	const float CAP_MAX_DISTANCE = 0.005;

	vec4 view_pos = getViewPos(v_texcoord0);

	float occlusion = 0;
	
	const int SAMPLE_COUNT = 16;
	const vec2 SAMPLES[SAMPLE_COUNT] = {
		vec2( -0.94201624,  -0.39906216 ),
		vec2(  0.94558609,  -0.76890725 ),
		vec2( -0.094184101, -0.92938870 ),
		vec2(  0.34495938,   0.29387760 ),
		vec2( -0.91588581,   0.45771432 ),
		vec2( -0.81544232,  -0.87912464 ),
		vec2( -0.38277543,   0.27676845 ),
		vec2(  0.97484398,   0.75648379 ),
		vec2(  0.44323325,  -0.97511554 ),
		vec2(  0.53742981,  -0.47373420 ),
		vec2( -0.26496911,  -0.41893023 ),
		vec2(  0.79197514,   0.19090188 ),
		vec2( -0.24188840,   0.99706507 ),
		vec2( -0.81409955,   0.91437590 ),
		vec2(  0.19984126,   0.78641367 ),
		vec2(  0.14383161,  -0.14100790 )
	};

	
	for (int i = 0; i < SAMPLE_COUNT; ++i)
	{
		vec2 sample = SAMPLES[i] * radius.x; // TODO randomize
		/*sample = vec2(random(v_texcoord0), random(v_texcoord0 * 2)) * 2 - 1;
		float dist = random(v_texcoord0 * 3);
		sample *= dist * dist * radius.x;/**/
		vec4 sample_pos = view_pos;
		sample_pos.xy += sample * radius.x;
		
		vec4 sample_pos_proj = mul(u_camProj, sample_pos);
		sample_pos_proj /= sample_pos_proj.w;
		vec2 sample_pos_texcoord = sample_pos_proj.xy * 0.5 + 0.5;
		
		sample_pos_proj.z = texture2D(u_texture, sample_pos_texcoord).r * 2.0 - 1.0;
		sample_pos = mul(u_camInvProj, sample_pos_proj);
		sample_pos /= sample_pos.w;
		
		float delta = sample_pos.z - view_pos.z;
		
		if(delta < radius.x)
		{
			occlusion += step(CAP_MIN_DISTANCE, delta) 
				* smoothstep(0, 1, delta / CAP_MAX_DISTANCE)
				/ (3 * length(sample / radius.x));
		}
	}
	
	occlusion = clamp(occlusion - SAMPLE_COUNT/4, 0, SAMPLE_COUNT) * intensity.x;
	gl_FragColor.rgb = vec3_splat(1 - occlusion / SAMPLE_COUNT);
	gl_FragColor.w = 1;
}
