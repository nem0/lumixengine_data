$input a_position, a_normal, a_tangent, a_texcoord0, i_data0, i_data1
$output v_wpos, v_view, v_texcoord0, v_common2

#include "common.sh"

//uniform sampler2D u_texHeightmap;
SAMPLER2D(u_texHeightmap, 0);
uniform vec4 u_relCamPos;
uniform vec4 u_terrainParams;
uniform vec4 u_terrainScale;
uniform mat4 u_terrainMatrix;

#define INNER_RADIUS morph_const.y
#define OUTER_RADIUS morph_const.x
#define QUAD_MIN i_data0.xyz
#define QUAD_SIZE i_data0.w
#define ROOT_SIZE u_terrainParams.x
#define MORPH_CONST i_data1.xy

float computeWeight(vec3 pos, vec3 quad_min, vec2 morph_const)
{
	
	float dist = distance(u_relCamPos.xz, quad_min.xz + pos.xz);
	float weight = (dist - INNER_RADIUS) / (OUTER_RADIUS - INNER_RADIUS);
	
	return saturate(weight);
}

void main()
{
	float m = QUAD_SIZE / 8.0;
	v_wpos = a_position;  
	v_wpos.xz *= QUAD_SIZE;
	
	vec2 fraction = fract(v_wpos.xz / m);

	float weight =  computeWeight(v_wpos, QUAD_MIN, MORPH_CONST);
	
	v_wpos.xz = v_wpos.xz - weight * fraction * m;
	
	v_wpos += QUAD_MIN;

	vec2 uv = (v_wpos.xz + 0.5) / ROOT_SIZE;

	v_texcoord0 = uv;

	v_wpos.y = u_terrainScale.y * texture2DLod(u_texHeightmap, uv, 0).x;
	v_wpos.xz *= u_terrainScale.xz;

	vec4 wpos = mul(u_terrainMatrix, vec4(v_wpos, 1.0));
	v_common2 = mul(u_viewProj, wpos); 
	gl_Position = v_common2;
	
    v_wpos = wpos.xyz;
	v_view = mul(u_invView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - v_wpos;
	
}
