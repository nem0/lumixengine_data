$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_texture, 15);
SAMPLER2D(u_texShadowmap, 14);
uniform vec4 u_light_screen_pos;
uniform vec4 u_godrays_params;
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_textureSize;
uniform vec4 u_time;
uniform vec4 u_fogColorDensity; 

#define exposure u_godrays_params.x
#define decay u_godrays_params.y
#define weight u_godrays_params.z
#define timer u_time.x * 0.01

    
vec4 rnm(in vec2 tc) 
{
    float noise =  sin(dot(tc + vec2(timer,timer),vec2(12.9898,78.233))) * 43758.5453;

	float noiseR =  fract(noise)*2.0-1.0;
	float noiseG =  fract(noise*1.2154)*2.0-1.0; 
	float noiseB =  fract(noise*1.3453)*2.0-1.0;
	float noiseA =  fract(noise*1.3647)*2.0-1.0;
	
	return vec4(noiseR,noiseG,noiseB,noiseA);
}

float fade(float t) {
	return t*t*t*(t*(t*6.0-15.0)+10.0);
}

float pnoise3D(vec3 p)
{
	const float permTexUnit = 1.0 / 256.0;
	const float permTexUnitHalf = 0.5 / 256.0;

	vec3 pi = permTexUnit * floor(p) + permTexUnitHalf; // Integer part, scaled so +1 moves permTexUnit texel
	vec3 pf = fract(p);									// Fractional part for interpolation

	float perm00 = rnm(pi.xy).a;
	vec3 grad000 = rnm(vec2(perm00, pi.z)).rgb * 4.0 - 1.0;
	float n000 = dot(grad000, pf);
	vec3 grad001 = rnm(vec2(perm00, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n001 = dot(grad001, pf - vec3(0.0, 0.0, 1.0));

	float perm01 = rnm(pi.xy + vec2(0.0, permTexUnit)).a;
	vec3 grad010 = rnm(vec2(perm01, pi.z)).rgb * 4.0 - 1.0;
	float n010 = dot(grad010, pf - vec3(0.0, 1.0, 0.0));
	vec3 grad011 = rnm(vec2(perm01, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n011 = dot(grad011, pf - vec3(0.0, 1.0, 1.0));

	float perm10 = rnm(pi.xy + vec2(permTexUnit, 0.0)).a;
	vec3 grad100 = rnm(vec2(perm10, pi.z)).rgb * 4.0 - 1.0;
	float n100 = dot(grad100, pf - vec3(1.0, 0.0, 0.0));
	vec3 grad101 = rnm(vec2(perm10, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n101 = dot(grad101, pf - vec3(1.0, 0.0, 1.0));

	float perm11 = rnm(pi.xy + vec2(permTexUnit, permTexUnit)).a;
	vec3 grad110 = rnm(vec2(perm11, pi.z)).rgb * 4.0 - 1.0;
	float n110 = dot(grad110, pf - vec3(1.0, 1.0, 0.0));
	vec3 grad111 = rnm(vec2(perm11, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n111 = dot(grad111, pf - vec3(1.0, 1.0, 1.0));

	vec4 n_x = mix(vec4(n000, n001, n010, n011), vec4(n100, n101, n110, n111), fade(pf.x));

	vec2 n_xy = mix(n_x.xy, n_x.zw, fade(pf.y));

	float n_xyz = mix(n_xy.x, n_xy.y, fade(pf.z));

	return n_xyz;
}


vec2 coordRot(vec2 tex_coord, float angle)
{
	float aspect = u_textureSize.x / u_textureSize.y;
	float s = sin(angle);
	float c = cos(angle);
	vec2 tc = tex_coord * 2.0 - 1.0;
	float rotX = (tc.x * aspect * c) - (tc.y * s);
	float rotY = (tc.y * c) + (tc.x * aspect * s);
	rotX = rotX / aspect;
	rotY = rotY;
	return vec2(rotX, rotY) * 0.5 + 0.5;
}

void main()
{
	vec3 fragment_wpos = getViewPosition(u_texture, u_camInvViewProj, v_texcoord0);
	vec3 camera_wpos = mul(u_camInvView, vec4(0, 0, 0, 1)).xyz;
	
	vec2 rotCoordsR = coordRot(v_texcoord0, timer);
	vec3 noise = vec3_splat(pnoise3D(vec3(rotCoordsR * vec2(u_textureSize.xy / 1.6),0.0)));
	
	vec2 lightPositionOnScreen = u_light_screen_pos.xy;
	const int NUM_SAMPLES = 30;
	float illuminationDecay = 0.5;

	float l = length(camera_wpos - fragment_wpos);
	
	float res = 0;
	for(int i=0; i < NUM_SAMPLES; i++)
	{
		vec3 pos = mix(fragment_wpos, camera_wpos, clamp(noise.x*0.1 + float(i) / NUM_SAMPLES, 0, 1));
		float sample = directionalLightShadowSimple(u_texShadowmap, u_shadowmapMatrices, vec4(pos, 1), 1);

		sample *= illuminationDecay * weight * l;
		res += sample;
		illuminationDecay *= decay;
	}
	gl_FragColor = res * exposure * vec4(u_fogColorDensity.rgb, 1);
}

