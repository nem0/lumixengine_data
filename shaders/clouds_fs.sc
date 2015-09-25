$input v_wpos, v_texcoord0

#include "common.sh"

// Weather. By David Hoskins, May 2014.
// @ https://www.shadertoy.com/view/4dsXWn
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Who needs mathematically correct simulations?! :)
// It ray-casts to the bottom layer then steps through to the top layer.
// It uses the same number of steps for all positions.
// The larger steps at the horizon don't cause problems as they are far away.
// So the detail is where it matters.
// Unfortunately this can't be used to go through the cloud layer,
// but it's fast and has a massive draw distance.

uniform vec4 u_lightDirFov; 
uniform vec4 u_time;
uniform mat4 u_camView;
uniform mat4 u_camInvProj;vec3 sunLight  = normalize( vec3(  -0.35, -0.14,  -0.3 ) );
const vec3 sunColour = vec3(1.0, .7, .55);
float gTime, cloudy;
vec3 flash;

#define CLOUD_LOWER 4000.0
#define CLOUD_UPPER 6800.0

//SAMPLER2D(iChannel0, 0);
//#define TEXTURE_NOISE

#define MOD2 vec2(.16632,.17369)
#define MOD3 vec3(.16532,.17369,.15787)

float iGlobalTime = 0.5;
vec2 iMouse = vec2(0.0, 0.0);

//--------------------------------------------------------------------------

//--------------------------------------------------------------------------
float Hash( float p )
{
	vec2 p2 = fract(vec2_splat(p) * MOD2);
    p2 += dot(p2.yx, p2.xy+19.19);
	return fract(p2.x * p2.y);
}
float Hash(vec3 p)
{
	p  = fract(p * MOD3);
    p += dot(p.xyz, p.yzx + 19.19);
    return fract(p.x * p.y * p.z);
}

//--------------------------------------------------------------------------
#ifdef TEXTURE_NOISE

//--------------------------------------------------------------------------
float Noise( in vec2 f )
{
    vec2 p = floor(f);
    f = fract(f);
    f = f*f*(3.0-2.0*f);
    float res = texture2D(iChannel0, (p+f+.5)/256.0).x;
    return res;
}
float Noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = texture2D( iChannel0, (uv+ 0.5)/256.0, -100.0 ).yx;
	return mix( rg.x, rg.y, f.z );
}
#else

//--------------------------------------------------------------------------


float Noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0;
    float res = mix(mix( Hash(n+  0.0), Hash(n+  1.0),f.x),
                    mix( Hash(n+ 57.0), Hash(n+ 58.0),f.x),f.y);
    return res;
}
float Noise(in vec3 p)
{
    vec3 i = floor(p);
	vec3 f = fract(p); 
	f *= f * (3.0-2.0*f);

    return mix(
		mix(mix(Hash(i + vec3(0.,0.,0.)), Hash(i + vec3(1.,0.,0.)),f.x),
			mix(Hash(i + vec3(0.,1.,0.)), Hash(i + vec3(1.,1.,0.)),f.x),
			f.y),
		mix(mix(Hash(i + vec3(0.,0.,1.)), Hash(i + vec3(1.,0.,1.)),f.x),
			mix(Hash(i + vec3(0.,1.,1.)), Hash(i + vec3(1.,1.,1.)),f.x),
			f.y),
		f.z);
}
#endif

//--------------------------------------------------------------------------
float FBM( vec3 p )
{
	p *= .25;
    float f;
	
	f = 0.5000 * Noise(p); p = p * 3.02; //p.y -= gTime*.2;
	f += 0.2500 * Noise(p); p = p * 3.03; //p.y += gTime*.06;
	f += 0.1250 * Noise(p); p = p * 3.01;
	f += 0.0625   * Noise(p); p =  p * 3.03;
	f += 0.03125  * Noise(p); p =  p * 3.02;
	f += 0.015625 * Noise(p);
    return f;
}


//--------------------------------------------------------------------------
float Map(vec3 p)
{
	p *= .002;
	float h = FBM(p);
	return h-cloudy-.5;
}


//--------------------------------------------------------------------------
// Grab all sky information for a given ray from camera
vec3 GetSky(in vec3 pos,in vec3 rd, out vec2 outPos)
{
	float sunAmount = max( dot( rd, sunLight), 0.0 );
	// Do the blue and sun...	
	vec3  sky = mix(vec3(.0, .1, .4), vec3(.3, .6, .8), 1.0-rd.y);
	sky = sky + sunColour * min(pow(sunAmount, 1500.0) * 5.0, 1.0);
	sky = sky + sunColour * min(pow(sunAmount, 10.0) * .6, 1.0);
	
	
	// Find the start and end of the cloud layer...
	float beg = ((CLOUD_LOWER-pos.y) / rd.y);
	float end = ((CLOUD_UPPER-pos.y) / rd.y);
	
	// Start position...
	vec3 p = vec3(pos.x + rd.x * beg, 0.0, pos.z + rd.z * beg);
	outPos = p.xz;
    beg +=  Hash(p)*150.0;

	// Trace clouds through that layer...
	float d = 0.0;
	vec3 add = rd * ((end-beg) / 45.0);
	vec2 shade;
	vec2 shadeSum = vec2(0.0, .0);
	float difference = CLOUD_UPPER-CLOUD_LOWER;
	shade.x = .01;
	// I think this is as small as the loop can be
	// for an reasonable cloud density illusion.
	for (int i = 0; i < 15; i++)
	{
		if (shadeSum.y >= 1.0) break;
		float h = Map(p);
		shade.y = max(-h, 0.0); 
		shadeSum += shade * (1.0 - shadeSum.y);
		p += add;
	}
	shadeSum.x /= 10.0;
	shadeSum = min(shadeSum, 1.0);
	
	vec3 clouds = mix(vec3_splat(pow(shadeSum.x, sin(cloudy*4)*.8)), sunColour, (1.0-shadeSum.y)*.4);
	
	clouds += min((1.0-sqrt(shadeSum.y)) * pow(sunAmount, 4.0), 1.0) * 2.0;
   
    clouds += flash * (shadeSum.y+shadeSum.x+.2) * .5;

	sky = mix(sky, min(clouds, 1.0), shadeSum.y);
	
	return clamp(sky, 0.0, 1.0);
}

vec3 get_world_normal(vec2 frag_coord)
{
    frag_coord = (frag_coord - 0.5) * 2.0;
    vec4 device_normal = vec4(frag_coord, 0.0, 1.0);
    vec3 eye_normal = normalize(mul(u_camInvProj, device_normal).xyz);
    vec3 world_normal = normalize(mul(u_camView,eye_normal));
	return world_normal;
}

//--------------------------------------------------------------------------
void main()
{
	vec2 fragCoord = vec2(v_texcoord0.x * 800, v_texcoord0.y * 600);
	vec2 iResolution = vec2(800, 600);
	float m = 0;
	gTime = u_time.x * 1; //iGlobalTime*.5 + m + 75.5;
	cloudy = cos(gTime * .25+.4) * .26;
    float lightning = 0.0;
    flash = clamp(vec3(1., 1.0, 1.2) * lightning, 0.0, 1.0);
	
    vec2 xy = fragCoord.xy / iResolution.xy;
	vec2 uv = (-1.0 + 2.0 * xy) * vec2(iResolution.x/iResolution.y,1.0);
	
	vec3 cw = mul(u_camView, vec4(0, 0, -1, 0)).xyz;
	vec3 cp = vec3(0.0, 1.0, 0.0);
	vec3 cu = cross(cw,cp);
	vec3 cv = cross(cu,cw);
	vec3 dir = get_world_normal(v_texcoord0); //normalize(uv.x*cu + uv.y*cv + 1.3*cw);
	mat3 camMat = mat3(cu, cv, cw);

	vec3 col;
	vec2 pos;
	vec3 cameraPos = vec3(cos(gTime*0.1)*10000, 300.0, 8800.0);
	col = GetSky(cameraPos, dir, pos); 
		
	float l = exp(-length(pos) * .00002);
	col = mix(vec3_splat(.6-cloudy*1.2)+flash*.3, col, max(l, .2));
	
	vec2 st =  uv * vec2(.5+(xy.y+1.0)*.3, .02)+vec2(gTime*.5+xy.y*.2, gTime*.2);

	// Stretch RGB upwards... 
	//col = (1.0 - exp(-col * 2.0)) * 1.1565;
	//col = (1.0 - exp(-col * 3.0)) * 1.052;
	col = pow(col, vec3_splat(.7));
	//col = (col*col*(3.0-2.0*col));

	// Vignette...
	
	gl_FragColor=vec4(col, 1.0);
}

//--------------------------------------------------------------------------
