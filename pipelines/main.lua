framebuffers = {
	{
		name = "default",
		width = 1024,
		height = 768,
		renderbuffers = {
			{format="rgba8"},
		}
	},

	{
		name = "hdr",
		width = 1024,
		height = 1024,
		screen_size = true;
		renderbuffers = {
			{ format = "rgba16f" },
			{ format = "depth32" }
		}
	},

	{
		name = "SSAO",
		width = 512,
		height = 512,
		renderbuffers = {
			{format="rgba8"},
			{format = "depth24"}
		}
	},

	{
		name = "SSAO_blurred",
		width = 512,
		height = 512,
		renderbuffers = {
			{format="rgba8"},
			{format = "depth24"}
		}
	},

	
	{
		name = "shadowmap",
		width = 2048,
		height = 2048,
		renderbuffers = {
			{format="r32f"},
			{format = "depth32"}
		}
	},
	
	{
		name = "point_light_shadowmap",
		width = 1024,
		height = 1024,
		renderbuffers = {
			{format = "depth32"}
		}
	},

	{
		name = "point_light2_shadowmap",
		width = 1024,
		height = 1024,
		renderbuffers = {
			{format = "depth32"}
		}
	},

	
	{
		name = "lum128",
		width = 128,
		height = 128,
		renderbuffers = {
			{ format = "r32f" }
		}
	},
	
	{
		name = "lum64",
		width = 64,
		height = 64,
		renderbuffers = {
			{ format = "r32f" }
		}
	},
	
	{
		name = "lum16",
		width = 16,
		height = 16,
		renderbuffers = {
			{ format = "r32f" }
		}
	},

	{
		name = "lum4",
		width = 4,
		height = 4,
		renderbuffers = {
			{ format = "r32f" }
		}
	},

	{
		name = "lum1a",
		width = 1,
		height = 1,
		renderbuffers = {
			{ format = "r32f" }
		}
	},

	{
		name = "lum1b",
		width = 1,
		height = 1,
		renderbuffers = {
			{ format = "r32f" }
		}
	},

	
	{
		name = "blur",
		width = 2048,
		height = 2048,
		renderbuffers = {
			{format = "r32f"}
		}
	},
}


parameters = {
	particles_enabled = true,
	blur_shadowmap = true,
	render_shadowmap_debug = false,
	render_gizmos = true,
	SSAO = false,
	SSAO_debug = false,
	SSAO_blur = false,
	sky_enabled = true
}


local lum_uniforms = {}

function computeLumUniforms()
	local sizes = {64, 16, 4, 1 }
	for key,value in ipairs(sizes) do
		lum_uniforms[value] = {}
		for j = 0,3 do
			for i = 0,3 do
				local x = (i) / value; 
				local y = (j) / value; 
				lum_uniforms[value][1 + i + j * 4] = {x, y, 0, 0}
			end
		end
	end

	lum_uniforms[128] = {}
	for j = 0,1 do
		for i = 0,1 do
			local x = i / 128; 
			local y = j / 128; 
			lum_uniforms[128][1 + i + j * 4] = {x, y, 0, 0}
		end
	end
end
 
function init(pipeline)
	shadowmap_uniform = createUniform(pipeline, "u_texShadowmap")
	texture_uniform = createUniform(pipeline, "u_texture")
	blur_material = loadMaterial(pipeline, "shaders/blur.mat")
	screen_space_material = loadMaterial(pipeline, "shaders/screen_space.mat")
	ssao_material = loadMaterial(pipeline, "shaders/ssao.mat")
	avg_luminance_uniform = createUniform(pipeline, "u_avgLuminance")
	hdr_buffer_uniform = createUniform(pipeline, "u_hdrBuffer")
	hdr_material = loadMaterial(pipeline, "shaders/hdr.mat")
	lum_material = loadMaterial(pipeline, "shaders/hdrlum.mat")
	lum_size_uniform = createVec4ArrayUniform(pipeline, "u_offset", 16)
	sky_material = loadMaterial(pipeline, "shaders/sky.mat")
	
	computeLumUniforms()
end


function shadowmapDebug(pipeline)
	if parameters.render_shadowmap_debug then
		setPass(pipeline, "SCREEN_SPACE")
		beginNewView(pipeline, "SHADOWMAP_DEBUG")
		setFramebuffer(pipeline, "default")
		bindFramebufferTexture(pipeline, "shadowmap", 0, texture_uniform)
		drawQuad(pipeline, 0.48, 0.98, 0.5, -0.5, screen_space_material);
	end
end


function renderSSAODDebug(pipeline)
	if parameters.SSAO_debug then
		setPass(pipeline, "SCREEN_SPACE")
		beginNewView(pipeline, "SHADOWMAP_DEBUG")
		disableBlending(pipeline)
		disableDepthWrite(pipeline)
		setFramebuffer(pipeline, "default")
		bindFramebufferTexture(pipeline, "SSAO", 0, texture_uniform)
		drawQuad(pipeline, 0.48, 0.48, 0.5, 0.5, screen_space_material);
	end
end


function renderSSAODPostprocess(pipeline)
	if parameters.SSAO then
		setPass(pipeline, "SCREEN_SPACE")
		enableBlending(pipeline, "multiply")
		disableDepthWrite(pipeline)
		setFramebuffer(pipeline, "hdr")
		bindFramebufferTexture(pipeline, "SSAO", 0, texture_uniform)
		drawQuad(pipeline, -1.0, -1.0, 2, 2, screen_space_material);
	end
end


function SSAO(pipeline)
	if parameters.SSAO then
		setPass(pipeline, "SSAO")
		disableBlending(pipeline)
		disableDepthWrite(pipeline)
		setFramebuffer(pipeline, "SSAO")
		bindFramebufferTexture(pipeline, "hdr", 1, texture_uniform)
		drawQuad(pipeline, -1, -1, 2, 2, ssao_material);		

		if parameters.SSAO_blur then
			setPass(pipeline, "BLUR_H")
				beginNewView(pipeline, "h");
				setFramebuffer(pipeline, "blur")
				disableDepthWrite(pipeline)
				bindFramebufferTexture(pipeline, "SSAO", 0, shadowmap_uniform)
				drawQuad(pipeline, -1, -1, 2, 2, blur_material)
				enableDepthWrite(pipeline)
			
			setPass(pipeline, "BLUR_V")
				beginNewView(pipeline, "v");
				setFramebuffer(pipeline, "SSAO")
				disableDepthWrite(pipeline)
				bindFramebufferTexture(pipeline, "blur", 0, shadowmap_uniform)
				drawQuad(pipeline, -1, -1, 2, 2, blur_material);
				enableDepthWrite(pipeline)		
		end
	end
end

 
function shadowmap(pipeline)
	setPass(pipeline, "SHADOW")         
		applyCamera(pipeline, "editor")
		--disableRGBWrite(pipeline)
		--disableAlphaWrite(pipeline)
		setFramebuffer(pipeline, "shadowmap")
		renderShadowmap(pipeline, 1) 

	renderLocalLightsShadowmaps(pipeline, 1, {"point_light_shadowmap", "point_light2_shadowmap"}, "editor")

	if parameters.blur_shadowmap then
		setPass(pipeline, "BLUR_H")
		setFramebuffer(pipeline, "blur")
		disableDepthWrite(pipeline)
		bindFramebufferTexture(pipeline, "shadowmap", 0, shadowmap_uniform)
		drawQuad(pipeline, -1, -1, 2, 2, blur_material)
		enableDepthWrite(pipeline)
		
		setPass(pipeline, "BLUR_V")
		setFramebuffer(pipeline, "shadowmap")
		disableDepthWrite(pipeline)
		bindFramebufferTexture(pipeline, "blur", 0, shadowmap_uniform)
		drawQuad(pipeline, -1, -1, 2, 2, blur_material);
		enableDepthWrite(pipeline)
	end
end


function main(pipeline)
	if parameters.sky_enabled then
		setPass(pipeline, "SKY")
			setFramebuffer(pipeline, "hdr")
			disableDepthWrite(pipeline)
			clear(pipeline, CLEAR_COLOR | CLEAR_DEPTH, 0xffffFFFF)
			setActiveDirectionalLightUniforms(pipeline, sky_material)
			drawQuad(pipeline, -1, -1, 2, 2, sky_material)
			clearLightCommandBuffer(pipeline)
	end

	setPass(pipeline, "MAIN")
		enableDepthWrite(pipeline)
		if not parameters.sky_enabled then
			clear(pipeline, CLEAR_COLOR | CLEAR_DEPTH, 0xffffFFFF)
		end
		enableRGBWrite(pipeline)
		setFramebuffer(pipeline, "hdr")
		applyCamera(pipeline, "editor")
		renderModels(pipeline)
		renderDebugShapes(pipeline)
		
end


function particles(pipeline)
	if parameters.particles_enabled then
		setPass(pipeline, "PARTICLES")
		disableDepthWrite(pipeline)
		applyCamera(pipeline, "editor")
		renderParticles(pipeline)
	end	
end


function pointLight(pipeline)
	setPass(pipeline, "POINT_LIGHT")
		setFramebuffer(pipeline, "hdr")
		disableDepthWrite(pipeline)
		enableBlending(pipeline, "add")
		applyCamera(pipeline, "editor")
		renderPointLightLitGeometry(pipeline)
end


function editor(pipeline)
	if parameters.render_gizmos then
		setPass(pipeline, "EDITOR")
			setFramebuffer(pipeline, "default")
			disableDepthWrite(pipeline)
			disableBlending(pipeline)
			applyCamera(pipeline, "editor")
			renderIcons(pipeline)

		beginNewView(pipeline, "gizmo")
			setFramebuffer(pipeline, "default")
			applyCamera(pipeline, "editor")
			renderGizmos(pipeline)
	end
end


function hdr(pipeline)
	setPass(pipeline, "HDR_LUMINANCE")
		setFramebuffer(pipeline, "lum128")
		disableDepthWrite(pipeline)
		disableBlending(pipeline)
		setUniform(pipeline, lum_size_uniform, lum_uniforms[128])
		bindFramebufferTexture(pipeline, "hdr", 0, hdr_buffer_uniform)
		drawQuad(pipeline, -1, -1, 2, 2, lum_material)
	
	setPass(pipeline, "HDR_AVG_LUMINANCE")
		setFramebuffer(pipeline, "lum64")
		setUniform(pipeline, lum_size_uniform, lum_uniforms[64])
		bindFramebufferTexture(pipeline, "lum128", 0, hdr_buffer_uniform)
		drawQuad(pipeline, -1, -1, 2, 2, lum_material)

	beginNewView(pipeline, "lum16")
		setFramebuffer(pipeline, "lum16")
		setUniform(pipeline, lum_size_uniform, lum_uniforms[16])
		bindFramebufferTexture(pipeline, "lum64", 0, hdr_buffer_uniform)
		drawQuad(pipeline, -1, -1, 2, 2, lum_material)
	
	beginNewView(pipeline, "lum4")
		setFramebuffer(pipeline, "lum4")
		setUniform(pipeline, lum_size_uniform, lum_uniforms[4])
		bindFramebufferTexture(pipeline, "lum16", 0, hdr_buffer_uniform)
		drawQuad(pipeline, -1, -1, 2, 2, lum_material)

	local old_lum1 = "lum1b"
	if current_lum1 == "lum1a" then 
		current_lum1 = "lum1b" 
		old_lum1 = "lum1a"
	else 
		current_lum1 = "lum1a" 
	end

	setPass(pipeline, "LUM1")
		setFramebuffer(pipeline, current_lum1)
		setUniform(pipeline, lum_size_uniform, lum_uniforms[1])
		bindFramebufferTexture(pipeline, "lum4", 0, hdr_buffer_uniform)
		bindFramebufferTexture(pipeline, old_lum1, 0, avg_luminance_uniform)
		drawQuad(pipeline, -1, -1, 2, 2, lum_material)

	setPass(pipeline, "HDR")
		setFramebuffer(pipeline, "default")
		disableBlending(pipeline)
		applyCamera(pipeline, "editor")
		disableDepthWrite(pipeline)
		clear(pipeline, CLEAR_COLOR | CLEAR_DEPTH, 0x00000000)
		bindFramebufferTexture(pipeline, "hdr", 0, hdr_buffer_uniform)
		bindFramebufferTexture(pipeline, current_lum1, 0, avg_luminance_uniform)
		drawQuad(pipeline, -1, 1, 2, -2, hdr_material)
end

 
function render(pipeline)
	shadowmap(pipeline)
	main(pipeline)
	particles(pipeline)
	pointLight(pipeline)		
	SSAO(pipeline)
	renderSSAODPostprocess(pipeline)

	hdr(pipeline)
	editor(pipeline)
	renderSSAODDebug(pipeline)
	shadowmapDebug(pipeline)
end

