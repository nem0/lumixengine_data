$input a_position, a_normal, a_tangent, a_texcoord0
$output v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_texcoord1

/*
 * Copyright 2011-2015 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#include "common.sh"

SAMPLER2D(u_heightmap, 0);
uniform vec4 u_quadMinAndSize;
uniform vec4 u_relCamPos;
uniform vec4 u_morphConst;
uniform vec4 u_mapSize;
uniform vec4 u_terrainScale;

float computeWeight(vec3 pos)
{
	vec3 cp = u_relCamPos.xyz;
	cp.y = 0.0;
	vec3 pp = pos;
	pp.y = 0.0;           
	
	float dist = distance(cp, u_quadMinAndSize.xyz + pp.xyz);
	float weight = (dist - u_morphConst.y) / (u_morphConst.x - u_morphConst.y);
	//return 0.0;
	return clamp(weight, 0.0, 1.0);
}

void main()
{

	float m = u_quadMinAndSize.w / 8.0;
	v_wpos = a_position;  
	v_wpos.x *= u_quadMinAndSize.w;
	v_wpos.z *= u_quadMinAndSize.w;
	
	float fraction_x = fract(v_wpos.x / m) * m;
	float fraction_z = fract(v_wpos.z / m) * m;

	float weight = computeWeight(v_wpos);

	v_wpos.x = v_wpos.x - weight * fraction_x;
	v_wpos.z = v_wpos.z - weight * fraction_z;
	v_wpos += u_quadMinAndSize.xyz;

	vec2 uv = v_wpos.xz / (u_mapSize.x);
	uv.x += 0.5/u_mapSize.x;
	uv.y += 0.5/u_mapSize.x;
	
	v_texcoord1 = uv;

	v_wpos.y = u_terrainScale.y * texture2D(u_heightmap, uv).x;
	v_wpos.x *= u_terrainScale.x;
	v_wpos.z *= u_terrainScale.z;

	gl_Position = mul(u_modelViewProj, vec4(v_wpos, 1.0)); 
	
	/*global_uv = uv;
	tex_coords = uv * map_size * texture_scale;
	cam_dist = dist;
	  */

	v_normal = mul(u_model[0], vec4(0.0, 1.0, 0.0, 0.0) ).xyz;
	v_tangent = mul(u_model[0], vec4(1.0, 0.0, 0.0, 0.0) ).xyz;
    v_bitangent = cross(v_normal, v_tangent);
	v_texcoord0 = uv * u_mapSize.x;
    v_wpos = mul(u_model[0], vec4(v_wpos, 1.0) ).xyz;
	v_view = mul(u_view, vec4(0.0, 0.0, 1.0, 0.0)).xyz;

	//gl_Position = mul(u_viewProj, vec4(v_wpos, 1.0) );
}
/*

void main()
{
	vec3 wpos = mul(u_model[0], vec4(a_position, 1.0) ).xyz;
	gl_Position = mul(u_viewProj, vec4(wpos, 1.0) );
	
	vec4 normal = a_normal * 2.0 - 1.0;
	vec3 wnormal = mul(u_model[0], vec4(normal.xyz, 0.0) ).xyz;

	vec4 tangent = a_tangent * 2.0 - 1.0;
	vec3 wtangent = mul(u_model[0], vec4(tangent.xyz, 0.0) ).xyz;

	vec3 viewNormal = normalize(mul(u_view, vec4(wnormal, 0.0) ).xyz);
	vec3 viewTangent = normalize(mul(u_view, vec4(wtangent, 0.0) ).xyz);
	vec3 viewBitangent = cross(viewNormal, viewTangent) * tangent.w;
	mat3 tbn = mat3(viewTangent, viewBitangent, viewNormal);

	v_wpos = wpos;

	vec3 view = mul(u_view, vec4(wpos, 0.0) ).xyz;
	v_view = mul(view, tbn);

	v_normal = viewNormal;
	v_tangent = viewTangent;
	v_bitangent = viewBitangent;

	v_texcoord0 = a_texcoord0;
}
		  */