$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0

#include "common.sh"

SAMPLER2D(u_texColor, 0);
#ifdef NORMAL_MAPPING
	SAMPLER2D(u_texNormal, 1);
#endif
#ifdef SPECULAR_TEXTURE
	SAMPLER2D(u_texSpecular, 2);
#endif
SAMPLER2D(u_texShadowmap, 3);
uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbInnerR;
uniform vec4 u_ambientColor;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity; 
uniform vec4 u_lightSpecular;
uniform vec4 u_materialSpecularShininess;


vec3 calcLight(vec4 dirFov, vec3 _wpos, vec3 _normal, vec3 _view, vec2 uv)
{
	vec3 lp = u_lightPosRadius.xyz - _wpos;
	float radius = u_lightPosRadius.w;
	float dist = length(lp);
	float attn = 1.0 / (1.0 + 0.02 * dist + 0.04 * dist * dist);
	attn = attn * attn;
	
	vec3 toLightDir = normalize(lp);
	
	if(dirFov.w < 3.14159)
	{
		float cosDir = dot(normalize(dirFov.xyz), normalize(-toLightDir));
		float cosCone = cos(dirFov.w * 0.5);
	
		if(cosDir < cosCone)
			discard;
		attn *= (cosDir - cosCone) / (1 - cosCone);
	}
		
   vec2 bln = blinn(toLightDir, _normal, _view);
	vec4 lc = lit(bln.x, bln.y, u_materialSpecularShininess.w);
	vec3 rgb = 
		attn * (u_lightRgbInnerR.xyz * saturate(lc.y) 
		+ u_lightSpecular.xyz * u_materialSpecularShininess.xyz *
		#ifdef SPECULAR_TEXTURE
			texture2D(u_texSpecular, uv).rgb * 
		#endif
		saturate(lc.z));
	return rgb;
}

float VSM(sampler2D depths, vec2 uv, float compare)
{
	return smoothstep(compare-0.0001, compare, texture2D(depths, uv).x * 0.5 + 0.5);
}

float getShadowmapValue(vec4 position)
{
	vec3 shadow_coord[4];
	shadow_coord[0] = mul(u_shadowmapMatrices[0], position).xyz;
	shadow_coord[1] = mul(u_shadowmapMatrices[1], position).xyz;
	shadow_coord[2] = mul(u_shadowmapMatrices[2], position).xyz;
	shadow_coord[3] = mul(u_shadowmapMatrices[3], position).xyz;

	vec2 tt[4];
	tt[0] = vec2(shadow_coord[0].x * 0.5, shadow_coord[0].y * 0.5);
	tt[1] = vec2(0.5 + shadow_coord[1].x * 0.5, shadow_coord[1].y * 0.5);
	tt[2] = vec2(shadow_coord[2].x * 0.5, 0.5 + shadow_coord[2].y * 0.5);
	tt[3] = vec2(0.5 + shadow_coord[3].x * 0.5, 0.5 + shadow_coord[3].y * 0.5);

	int split_index = 3;
	if(step(shadow_coord[0].x, 0.99) * step(shadow_coord[0].y, 0.99)
		* step(0.01, shadow_coord[0].x)	* step(0.01, shadow_coord[0].y) > 0.0)
		split_index = 0;
	else if(step(shadow_coord[1].x, 0.99) * step(shadow_coord[1].y, 0.99)
		* step(0.01, shadow_coord[1].x)	* step(0.01, shadow_coord[1].y) > 0.0)
		split_index = 1;
	else if(step(shadow_coord[2].x, 0.99) * step(shadow_coord[2].y, 0.99)
		* step(0.01, shadow_coord[2].x)	* step(0.01, shadow_coord[2].y) > 0.0)
		split_index = 2;
	else if(step(shadow_coord[3].x, 0.99) * step(shadow_coord[3].y, 0.99)
		* step(0.01, shadow_coord[3].x)	* step(0.01, shadow_coord[3].y) > 0.0)
		split_index = 3;
	else
		return 1.0;

	return step(shadow_coord[split_index].z, 1) * VSM(u_texShadowmap, tt[split_index], shadow_coord[split_index].z);
}


float getPLShadowmapValue(vec4 position, float fov)
{
	if(fov > 3.15159)
	{
		vec4 a = mul(u_shadowmapMatrices[0], position);
		vec4 b = mul(u_shadowmapMatrices[1], position);
		vec4 c = mul(u_shadowmapMatrices[2], position);
		vec4 d = mul(u_shadowmapMatrices[3], position);
		
		a = a / a.w;
		b = b / b.w;
		c = c / c.w;
		d = d / d.w;

		float l0 = length(a.xy - vec2_splat(0.5));
		float l1 = length(b.xy - vec2_splat(0.5));
		float l2 = length(c.xy - vec2_splat(0.5));
		float l3 = length(d.xy - vec2_splat(0.5));
		
		float m = min(min(l0, l1), min(l2, l3));
		
		bool selection0 = all(lessThan(a.xy, vec2_splat(0.99))) && all(greaterThan(a.xy, vec2_splat(0.01))) && a.z < 1;
		bool selection1 = all(lessThan(b.xy, vec2_splat(0.99))) && all(greaterThan(b.xy, vec2_splat(0.01))) && b.z < 1;
		bool selection2 = all(lessThan(c.xy, vec2_splat(0.99))) && all(greaterThan(c.xy, vec2_splat(0.01))) && c.z < 1;
		bool selection3 = all(lessThan(d.xy, vec2_splat(0.99))) && all(greaterThan(d.xy, vec2_splat(0.01))) && d.z < 1;
		

		if(selection0)
			return step(a.z, 1) * VSM(u_texShadowmap, vec2(a.x*0.5, a.y*0.5), a.z);
			//gl_FragColor = texture2D(u_texShadowmap, vec2(a.x*0.5, a.y*0.5));
		else if(selection1)
			return step(b.z, 1) * VSM(u_texShadowmap, vec2(0.5+b.x*0.5, b.y*0.5), b.z);
			//gl_FragColor = texture2D(u_texShadowmap, vec2(0.5+b.x*0.5, b.y*0.5));
		else if(selection2)
			return step(c.z, 1) * VSM(u_texShadowmap, vec2(c.x*0.5, 0.5+c.y*0.5), c.z);
			//gl_FragColor = texture2D(u_texShadowmap, vec2(c.x*0.5, 0.5+c.y*0.5));
		else 
			return step(d.z, 1) * VSM(u_texShadowmap, vec2(0.5+d.x*0.5, 0.5+d.y*0.5), d.z);
			//gl_FragColor = texture2D(u_texShadowmap, vec2(0.5+d.x*0.5, 0.5+d.y*0.5));
	}
	else
	{
		vec4 tmp = mul(u_shadowmapMatrices[0], position);
		vec3 shadow_coord = tmp.xyz / tmp.w;
		return step(shadow_coord.z, 1) * VSM(u_texShadowmap, shadow_coord.xy, shadow_coord.z);
	}
}


void main()
{     
	#ifdef SHADOW
		vec4 color = texture2D(u_texColor, v_texcoord0);
		if(color.a < 0.3)
			discard;
		gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
	#else
		mat3 tbn = mat3(
					normalize(v_tangent),
					normalize(v_normal),
					normalize(v_bitangent)
					);
		tbn = transpose(tbn);
					
		vec3 normal;
		#ifdef NORMAL_MAPPING
			normal.xz = texture2D(u_texNormal, v_texcoord0).xy * 2.0 - 1.0;
			normal.y = sqrt(1.0 - dot(normal.xz, normal.xz) );
		#else
			normal = vec3(0.0, 1.0, 0.0);
		#endif
		//normal = vec3(0, 1, 0);
		vec3 view = normalize(v_view);
		gl_FragColor = vec4(mul(tbn, normal), 1);
		//return;

		vec4 color = /*toLinear*/(texture2D(u_texColor, v_texcoord0) );
		if(color.a < 0.3)
			discard;
					 
		vec3 diffuse;
		#ifdef POINT_LIGHT
			diffuse = calcLight(u_lightDirFov, v_wpos, mul(tbn, normal), view, v_texcoord0);
			diffuse = diffuse.xyz * color.rgb;
			#ifdef HAS_SHADOWMAP
				diffuse = diffuse * getPLShadowmapValue(vec4(v_wpos, 1.0), u_lightDirFov.w); 
			#endif
		#else
			diffuse = calcGlobalLight(u_lightDirFov.xyz, u_lightRgbInnerR.rgb, mul(tbn, normal));
			diffuse = diffuse.xyz * color.rgb;
			diffuse = diffuse * getShadowmapValue(vec4(v_wpos, 1.0)); 
		#endif

		#ifdef MAIN
			vec3 ambient = u_ambientColor.rgb * color.rgb;
		#else
			vec3 ambient = vec3(0, 0, 0);
		#endif  

		vec4 view_pos = mul(u_view, vec4(v_wpos, 1.0));
		float fog_factor = getFogFactor(view_pos.z / view_pos.w, u_fogColorDensity.w);
		#ifdef POINT_LIGHT
			gl_FragColor.xyz = (1 - fog_factor) * (diffuse + ambient);
		#else
			gl_FragColor.xyz = mix(diffuse + ambient, u_fogColorDensity.rgb, fog_factor);
		#endif
		gl_FragColor.w = 1.0;
		
		//gl_FragColor = vec4(getShadowmapValue(vec4(v_wpos, 1.0)), 0, 0, 1);
		//gl_FragColor = toGamma(gl_FragColor);
	#endif                  
}
