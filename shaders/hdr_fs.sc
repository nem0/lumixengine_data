$input v_wpos, v_texcoord0 // in...

/*
Film Grain based on:
Martins Upitis (martinsh) devlog-martinsh.blogspot.com
2013
This work is licensed under a Creative Commons Attribution 3.0 Unported License.

Perlin noise shader by toneburst:
http://machinesdontcare.wordpress.com/2009/06/25/3d-perlin-noise-sphere-vertex-shader-sourcecode/
*/

#include "common.sh"

SAMPLER2D(u_hdrBuffer, 15);
SAMPLER2D(u_avgLuminance, 14);
#ifdef DOF
	SAMPLER2D(u_dofBuffer, 13);
	SAMPLER2D(u_depthBuffer, 12);
#endif

uniform vec4 exposure;
uniform vec4 midgray;
uniform mat4 u_camInvProj;
uniform vec4 focal_distance;
uniform vec4 focal_range;
uniform vec4 u_time;
uniform vec4 u_textureSize;
uniform vec4 u_grainAmount;
uniform vec4 u_grainSize;
uniform vec4 max_dof_blur;
uniform vec4 clear_range;
uniform vec4 dof_near_multiplier;

#define timer u_time.x * 0.01
#define grainamount u_grainAmount.x
#define grainsize u_grainSize.x

static const float permTexUnit = 1.0/256.0;
static const float permTexUnitHalf = 0.5/256.0;

static const float lumamount = 1.0;

float reinhard2(float x, float whiteSqr)
{
	return (x * (1.0 + x/whiteSqr) ) / (1.0 + x);
}

// Unchared2 tone mapping (See http://filmicgames.com)
vec3 Uncharted2Tonemap(vec3 x)
{
	const float A = 0.15;
	const float B = 0.50;
	const float C = 0.10;
	const float D = 0.20;
	const float E = 0.02;
	const float F = 0.30;
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

    
vec4 rnm(in vec2 tc) 
{
    float noise =  sin(dot(tc + vec2(timer,timer),vec2(12.9898,78.233))) * 43758.5453;

	float noiseR =  fract(noise)*2.0-1.0;
	float noiseG =  fract(noise*1.2154)*2.0-1.0; 
	float noiseB =  fract(noise*1.3453)*2.0-1.0;
	float noiseA =  fract(noise*1.3647)*2.0-1.0;
	
	return vec4(noiseR,noiseG,noiseB,noiseA);
}

float fade(in float t) {
	return t*t*t*(t*(t*6.0-15.0)+10.0);
}

float pnoise3D(in vec3 p)
{
	vec3 pi = permTexUnit*floor(p)+permTexUnitHalf; // Integer part, scaled so +1 moves permTexUnit texel
	vec3 pf = fract(p);     // Fractional part for interpolation

	float perm00 = rnm(pi.xy).a ;
	vec3  grad000 = rnm(vec2(perm00, pi.z)).rgb * 4.0 - 1.0;
	float n000 = dot(grad000, pf);
	vec3  grad001 = rnm(vec2(perm00, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n001 = dot(grad001, pf - vec3(0.0, 0.0, 1.0));

	float perm01 = rnm(pi.xy + vec2(0.0, permTexUnit)).a ;
	vec3  grad010 = rnm(vec2(perm01, pi.z)).rgb * 4.0 - 1.0;
	float n010 = dot(grad010, pf - vec3(0.0, 1.0, 0.0));
	vec3  grad011 = rnm(vec2(perm01, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n011 = dot(grad011, pf - vec3(0.0, 1.0, 1.0));

	float perm10 = rnm(pi.xy + vec2(permTexUnit, 0.0)).a ;
	vec3  grad100 = rnm(vec2(perm10, pi.z)).rgb * 4.0 - 1.0;
	float n100 = dot(grad100, pf - vec3(1.0, 0.0, 0.0));
	vec3  grad101 = rnm(vec2(perm10, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n101 = dot(grad101, pf - vec3(1.0, 0.0, 1.0));

	float perm11 = rnm(pi.xy + vec2(permTexUnit, permTexUnit)).a ;
	vec3  grad110 = rnm(vec2(perm11, pi.z)).rgb * 4.0 - 1.0;
	float n110 = dot(grad110, pf - vec3(1.0, 1.0, 0.0));
	vec3  grad111 = rnm(vec2(perm11, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n111 = dot(grad111, pf - vec3(1.0, 1.0, 1.0));

	vec4 n_x = mix(vec4(n000, n001, n010, n011), vec4(n100, n101, n110, n111), fade(pf.x));

	vec2 n_xy = mix(n_x.xy, n_x.zw, fade(pf.y));

	float n_xyz = mix(n_xy.x, n_xy.y, fade(pf.z));

	return n_xyz;
}

vec2 coordRot(in vec2 tc, in float angle)
{
	float aspect = u_textureSize.x/u_textureSize.y;
	float rotX = ((tc.x*2.0-1.0)*aspect*cos(angle)) - ((tc.y*2.0-1.0)*sin(angle));
	float rotY = ((tc.y*2.0-1.0)*cos(angle)) + ((tc.x*2.0-1.0)*aspect*sin(angle));
	rotX = ((rotX/aspect)*0.5+0.5);
	rotY = rotY*0.5+0.5;
	return vec2(rotX,rotY);
}

vec3 filmGrain(vec3 in_col, vec2 texCoord) 
{
	vec3 rotOffset = vec3(1.425,3.892,5.835); //rotation offset values	
	vec2 rotCoordsR = coordRot(texCoord, timer + rotOffset.x);
	vec3 noise = vec3_splat(pnoise3D(vec3(rotCoordsR*vec2(u_textureSize.x/grainsize,u_textureSize.y/grainsize),0.0)));
	vec3 col = in_col;
	vec3 lumcoeff = vec3(0.299,0.587,0.114);
	float luminance = mix(0.0,dot(col, lumcoeff),lumamount);
	float lum = smoothstep(0.2,0.0,luminance);
	lum += luminance;
	
	noise = mix(noise,vec3_splat(0.0),pow(lum,4.0));
	col = col+noise*grainamount;
   
	return col;
}

void main()
{
	float avg_loglum = max(0.1, exp(texture2D(u_avgLuminance, half2(0.5, 0.5)).r));
	vec3 hdr_color = texture2D(u_hdrBuffer, v_texcoord0).xyz;
	#ifdef DOF
	
		float depth = texture2D(u_depthBuffer, v_texcoord0).x;
		vec4 linear_depth_v = mul(u_camInvProj, vec4(0, 0, depth, 1));
		linear_depth_v /= linear_depth_v.w;

		#if 0
			float depth2 = texture2D(u_depthBuffer, vec2(0.5, 0.5)).x;
			vec4 linear_depth2_v = mul(u_camInvProj, vec4(0, 0, depth2, 1));
			linear_depth2_v /= linear_depth2_v.w;
			float t = clamp(abs(-linear_depth_v.z - -linear_depth2_v.z) / focal_range.x, 0, 1);
		#else 
			float depth_dif = abs(-linear_depth_v.z - focal_distance.x);	
			float near_multiplier = -linear_depth_v.z < focal_distance.x ? dof_near_multiplier.x : 1;
			float t = clamp((depth_dif - clear_range.x) / focal_range.x * near_multiplier, 0, 1);
		#endif
		
		t = min(t, max_dof_blur.x);
		vec3 dof_color = texture2D(u_dofBuffer, v_texcoord0).xyz;
		if (-linear_depth_v.z > 10000) t = 0;
		hdr_color = lerp(hdr_color, dof_color, t);
	#endif		
	hdr_color *= exposure.x;
	float lum = luma(hdr_color);

	float map_middle = (midgray.r / (avg_loglum + 0.001)) * lum;
	
	//float ld = reinhard2(map_middle, 1.1*1.1);
	//float ld = map_middle / (map_middle + 1);
	
	float ld = Uncharted2Tonemap(map_middle) / Uncharted2Tonemap(11);
	
	vec3 finalColor = (hdr_color / lum) * ld;
	#ifdef FILM_GRAIN
		vec3 grained = filmGrain(toGamma(finalColor), v_texcoord0);
		gl_FragColor =  vec4(grained, 1.0f);
	#else
		gl_FragColor =  vec4(toGamma(finalColor), 1.0f);
	#endif	
}



