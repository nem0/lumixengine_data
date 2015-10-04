$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_texcoord1, v_common, v_common2 // in...

#include "common.sh"

SAMPLER2D(u_texHeightmap, 0);
SAMPLER2D(u_texSplatmap, 1);
SAMPLER2D(u_texSatellitemap, 2);
SAMPLER2D(u_texColormap, 3);
SAMPLER2D(u_texColor, 4);
SAMPLER2D(u_texNormal, 5);
SAMPLER2D(u_texShadowmap, 6);

uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbInnerR;
uniform vec4 u_ambientColor;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity; 
uniform vec4 u_terrainParams;
uniform vec4 u_lightSpecular;
uniform vec4 u_materialSpecularShininess;
uniform vec4 detail_texture_distance;
uniform vec4 texture_scale;
uniform vec4 u_attenuationParams;
uniform vec4 u_relCamPos;


vec3 shadePointLight(vec4 dirFov, vec3 _wpos, vec3 _normal, vec3 _view, vec2 uv)
{
	vec3 lp = u_lightPosRadius.xyz - _wpos;
	float dist = length(lp);
	float attn = pow(max(0, 1 - dist / u_attenuationParams.x), u_attenuationParams.y);
	
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


vec2 getSubtextureUV4(vec2 uv, int z)
{
	static const float o = 1.0/(2.0*2*2);
	static const vec2 origin[4] = {
		vec2(0.0 + o, 0.0 + o),
		vec2(0.5 + o, 0.0 + o),
		vec2(0.0 + o, 0.5 + o),
		vec2(0.5 + o, 0.5 + o)
	};

	return origin[z] + uv / 4.0;
}


vec2 getSubtextureUV9(vec2 uv, int z)
{
	static const float o = 1.0/(3.0*2*2);
	static const vec2 origin[9] = {
		vec2(0.0 + o, 0.0 + o),			vec2(1/3.0 + o, 0.0 + o),		vec2(2/3.0 + o, 0.0 + o),
		vec2(0.0 + o, 1/3.0 + o),		vec2(1/3.0 + o, 1/3.0 + o),		vec2(2/3.0 + o, 1/3.0 + o),
		vec2(0.0 + o, 2/3.0 + o),		vec2(1/3.0 + o, 2/3.0 + o),		vec2(2/3.0 + o, 2/3.0 + o)
	};
	return origin[z] + uv / 6.0;
}


vec2 getSubtextureUV16(vec2 uv, int z)
{
	static const float o = 1.0/(4.0*2*2);
	static const vec2 origin[16] = {
		vec2(0.0, 0.0 + o),			vec2(1/4.0, 0.0 + o),		vec2(2/4.0, 0.0 + o),		vec2(3/4.0, 0.0 + o),
		vec2(0.0, 1/4.0 + o),		vec2(1/4.0, 1/4.0 + o),		vec2(2/4.0, 1/4.0 + o),		vec2(3/4.0, 1/4.0 + o),
		vec2(0.0, 2/4.0 + o),		vec2(1/4.0, 2/4.0 + o),		vec2(2/4.0, 2/4.0 + o),		vec2(3/4.0, 2/4.0 + o),
		vec2(0.0, 3/4.0 + o),		vec2(1/4.0, 3/4.0 + o),		vec2(2/4.0, 3/4.0 + o),		vec2(3/4.0, 3/4.0 + o)
	};
	return origin[z] + uv / 8.0;
}

float mipmapLevel(vec2 uv, vec2 textureSize)
{
    vec2 dx = dFdx(uv * textureSize.x);
    vec2 dy = dFdy(uv * textureSize.y);
    float d = max(dot(dx, dx), dot(dy, dy));
    return 0.5 * log2(d);
}

void main()
{
	#ifdef SHADOW
		float depth = v_common2.z/v_common2.w;
		gl_FragColor = vec4_splat(depth);
	#else
		vec2 detail_uv = v_texcoord0.xy * texture_scale.x;

		mat3 tbn = mat3(
					normalize(v_tangent),
					normalize(v_normal),
					normalize(v_bitangent)
					);
		tbn = transpose(tbn);

		float splatmap_size = u_terrainParams.y;
		float half_texel = 0.5 / splatmap_size;
		int texture_count = u_terrainParams.z * u_terrainParams.z;
		int detail_splatmap_size = u_terrainParams.y / (2*u_terrainParams.z);
					
		vec2 ff = fract(detail_uv);

		float u = v_texcoord1.x * splatmap_size - 1.0;
		float v = v_texcoord1.y * splatmap_size - 1.0;
		int x = floor(u);
		int y = floor(v);
		float u_ratio = u - x;
		float v_ratio = v - y;
		float u_opposite = 1 - u_ratio;
		float v_opposite = 1 - v_ratio;
		vec4 splat00 = texture2D(u_texSplatmap, vec2(x/splatmap_size, y/splatmap_size)).rgba;
		vec4 splat01 = texture2D(u_texSplatmap, vec2(x/splatmap_size, (y+1)/splatmap_size)).rgba;
		vec4 splat10 = texture2D(u_texSplatmap, vec2((x+1)/splatmap_size, y/splatmap_size)).rgba;
		vec4 splat11 = texture2D(u_texSplatmap, vec2((x+1)/splatmap_size, (y+1)/splatmap_size)).rgba;
	
		vec2 duv00, duv01, duv10, duv11;
		if(texture_count < 5)
		{
			duv00 = getSubtextureUV4(ff, splat00.x * 256);
			duv01 = getSubtextureUV4(ff, splat01.x * 256);
			duv10 = getSubtextureUV4(ff, splat10.x * 256);
			duv11 = getSubtextureUV4(ff, splat11.x * 256);
		}
		else if(texture_count < 10)
		{
			duv00 = getSubtextureUV9(ff, splat00.x * 256);
			duv01 = getSubtextureUV9(ff, splat01.x * 256);
			duv10 = getSubtextureUV9(ff, splat10.x * 256);
			duv11 = getSubtextureUV9(ff, splat11.x * 256);
		}
		else
		{
			duv00 = getSubtextureUV16(ff, splat00.x * 256);
			duv01 = getSubtextureUV16(ff, splat01.x * 256);
			duv10 = getSubtextureUV16(ff, splat10.x * 256);
			duv11 = getSubtextureUV16(ff, splat11.x * 256);
		}
		
		float mipmap_level = max(mipmapLevel(v_texcoord0, vec2(detail_splatmap_size, detail_splatmap_size)), 0);

		mipmap_level = min(mipmap_level, log2(detail_splatmap_size) - 1);
		
		vec4 c00 = texture2DLod(u_texColor, duv00, mipmap_level);
		vec4 c01 = texture2DLod(u_texColor, duv01, mipmap_level);
		vec4 c10 = texture2DLod(u_texColor, duv10, mipmap_level);
		vec4 c11 = texture2DLod(u_texColor, duv11, mipmap_level);

		vec4 bicoef = vec4(
			u_opposite * v_opposite,
			u_opposite * v_ratio,
			u_ratio * v_opposite,
			u_ratio * v_ratio
		);
			
		float a00 = (splat00.y * c00.a) * bicoef.x;
		float a01 = (splat01.y * c01.a) * bicoef.y;
		float a10 = (splat10.y * c10.a) * bicoef.z;
		float a11 = (splat11.y * c11.a) * bicoef.w;

		float ma = max(a00, a01);
		ma = max(ma, a10);
		ma = max(ma, a11); 
		ma = ma - 0.05;
		
		float b1 = max(a00 - ma, 0);
		float b2 = max(a01 - ma, 0);
		float b3 = max(a10 - ma, 0);
		float b4 = max(a11 - ma, 0);
		
		vec4 color = 
			texture2D(u_texColormap, v_texcoord1) * 
			vec4((c00.rgb * b1 + c01.rgb * b2 + c10.rgb * b3 + c11.rgb * b4) / (b1 + b2 + b3 + b4), 1);
			
		vec3 normal;
		#ifdef NORMAL_MAPPING
			vec4 n00 = texture2DLod(u_texNormal, duv00, mipmap_level);
			vec4 n01 = texture2DLod(u_texNormal, duv01, mipmap_level);
			vec4 n10 = texture2DLod(u_texNormal, duv10, mipmap_level);
			vec4 n11 = texture2DLod(u_texNormal, duv11, mipmap_level);
			normal.xz = (n00.xy * b1 + n01.xy * b2 + n10.xy * b3 + n11.xy * b4) / (b1 + b2 + b3 + b4);
			normal.xz = normal.xz * 2.0 - 1.0;
			normal.y = sqrt(1 - dot(normal.xz, normal.xz));
		#else
			normal = vec3(0.0, 1.0, 0.0);
		#endif

		// http://www.gamasutra.com/blogs/AndreyMishkinis/20130716/196339/Advanced_Terrain_Texture_Splatting.php
		// without height blend
		//color = (c00 * u_opposite  + c10  * u_ratio) * v_opposite + (c01 * u_opposite  + c11 * u_ratio) * v_ratio;

		vec3 view = normalize(v_view);
		
		float dist = length(v_view);
		
		float t = (dist - detail_texture_distance.x) / detail_texture_distance.x;
		color = mix(color, texture2D(u_texSatellitemap, v_texcoord1), clamp(t, 0, 1));
					 
		vec3 diffuse;
		#ifdef POINT_LIGHT
			diffuse = shadePointLight(u_lightDirFov, v_wpos, mul(tbn, normal), view, detail_uv.xy);
			diffuse = diffuse.xyz * color.rgb;
			#ifdef HAS_SHADOWMAP
				diffuse = diffuse * pointLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(v_wpos, 1.0), u_lightDirFov.w); 
			#endif
		#else
			diffuse = calcGlobalLight(u_lightDirFov.xyz, u_lightRgbInnerR.rgb, mul(tbn, normal));
			diffuse = diffuse.xyz * color.rgb;
			diffuse = diffuse * directionalLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(v_wpos, 1.0)); 			
		#endif

		#ifdef MAIN
			vec3 ambient = u_ambientColor.rgb * color.rgb;
		#else
			vec3 ambient = vec3(0, 0, 0);
		#endif  

		vec4 view_pos = mul(u_view, vec4(v_wpos, 1.0));
		float fog_factor = getFogFactor(view_pos.z / view_pos.w, u_fogColorDensity.w);
		fog_factor = fog_factor * clamp((7.0 - v_wpos.y) / 10, 0, 1);
		
		#ifdef POINT_LIGHT
			gl_FragColor.xyz = (1 - fog_factor) * (diffuse + ambient);
		#else
			gl_FragColor.xyz = mix(diffuse + ambient, u_fogColorDensity.rgb, fog_factor);
		#endif
		gl_FragColor.w = 1.0;
	#endif // else SHADOW
}
