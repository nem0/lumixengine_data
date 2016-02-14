framebuffers = {
	{
		name = "default",
		width = 1024,
		height = 1024,
		renderbuffers = {
			{ format = "rgba8" },
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
		name = "g_buffer",
		width = 1024,
		height = 1024,
		screen_size = true,
		renderbuffers = {
			{ format = "rgba8" },
			{ format = "rgba8" },
			{ format = "rgba8" },
			{ format = "depth32" }
		}
	},
	
	{
		name = "shadowmap",
		width = 2048,
		height = 2048,
		renderbuffers = {
			{ format = "r32f" },
			{ format = "depth32" }
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
			{ format = "r32f" }
		}
	},
	
}


parameters = {
	hdr = true,
	render_gizmos = true,
	debug_gbuffer0 = false,
	debug_gbuffer1 = false,
	debug_gbuffer2 = false,
	debug_gbuffer_depth = false,
	blur_shadowmap = true,
	particles_enabled = true,
	render_shadowmap_debug = false,
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
	texture_uniform = createUniform(pipeline, "u_texture")
	gbuffer0_uniform = createUniform(pipeline, "u_gbuffer0")
	gbuffer1_uniform = createUniform(pipeline, "u_gbuffer1")
	gbuffer2_uniform = createUniform(pipeline, "u_gbuffer2")
	gbuffer_depth_uniform = createUniform(pipeline, "u_gbuffer_depth")
	shadowmap_uniform = createUniform(pipeline, "u_texShadowmap")
	blur_material = loadMaterial(pipeline, "shaders/blur.mat")
	deferred_material = loadMaterial(pipeline, "shaders/deferred.mat")
	screen_space_material = loadMaterial(pipeline, "shaders/screen_space.mat")
	deferred_point_light_material =loadMaterial(pipeline, "shaders/deferredpointlight.mat")
	avg_luminance_uniform = createUniform(pipeline, "u_avgLuminance")
	hdr_buffer_uniform = createUniform(pipeline, "u_hdrBuffer")
	hdr_material = loadMaterial(pipeline, "shaders/hdr.mat")
	lum_material = loadMaterial(pipeline, "shaders/hdrlum.mat")
	lum_size_uniform = createVec4ArrayUniform(pipeline, "u_offset", 16)
	sky_material = loadMaterial(pipeline, "shaders/sky.mat")
	
	computeLumUniforms()
end



function shadowmap(pipeline)
	setPass(pipeline, "SHADOW")         
		applyCamera(pipeline, "editor")
		setFramebuffer(pipeline, "shadowmap")
		renderShadowmap(pipeline, 1) 
	
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


function deferred(pipeline)
	setPass(pipeline, "DEFERRED")
		setFramebuffer(pipeline, "g_buffer")
		applyCamera(pipeline, "editor")
		clear(pipeline, CLEAR_ALL, 0x00000000)
		
		setStencil(pipeline, STENCIL_OP_PASS_Z_REPLACE 
			| STENCIL_OP_FAIL_Z_KEEP 
			| STENCIL_OP_FAIL_S_KEEP 
			| STENCIL_TEST_ALWAYS)
		setStencilRMask(pipeline, 0xff)
		setStencilRef(pipeline, 1)
		
		renderModels(pipeline)
		clearStencil(pipeline)
		
	beginNewView(pipeline, "copyRenderbuffer");
		copyRenderbuffer(pipeline, "g_buffer", 3, "hdr", 1)
		
	setPass(pipeline, "MAIN")
		setFramebuffer(pipeline, "hdr")
		applyCamera(pipeline, "editor")
		clear(pipeline, CLEAR_COLOR | CLEAR_DEPTH, 0x00000000)
		
		bindFramebufferTexture(pipeline, "g_buffer", 0, gbuffer0_uniform)
		bindFramebufferTexture(pipeline, "g_buffer", 1, gbuffer1_uniform)
		bindFramebufferTexture(pipeline, "g_buffer", 2, gbuffer2_uniform)
		bindFramebufferTexture(pipeline, "g_buffer", 3, gbuffer_depth_uniform)
		bindFramebufferTexture(pipeline, "shadowmap", 0, shadowmap_uniform)
		drawQuad(pipeline, -1, 1, 2, -2, deferred_material)

	beginNewView(pipeline, "DEFERRED_LOCAL_LIGHT")
		setFramebuffer(pipeline, "hdr")
		disableDepthWrite(pipeline)
		enableBlending(pipeline, "add")
		applyCamera(pipeline, "editor")
		local bufs = {
			{ "g_buffer", 0, gbuffer0_uniform },
			{ "g_buffer", 1, gbuffer1_uniform },
			{ "g_buffer", 2, gbuffer2_uniform },
			{ "g_buffer", 3, gbuffer_depth_uniform },
			{ "shadowmap", 0, shadowmap_uniform }
		}
		deferredLocalLightLoop(pipeline, deferred_point_light_material, bufs)
		
		disableBlending(pipeline)
		
	if parameters.sky_enabled then
		setPass(pipeline, "SKY")
			setStencil(pipeline, STENCIL_OP_PASS_Z_KEEP 
				| STENCIL_OP_FAIL_Z_KEEP 
				| STENCIL_OP_FAIL_S_KEEP 
				| STENCIL_TEST_NOTEQUAL)
			setStencilRMask(pipeline, 1)
			setStencilRef(pipeline, 1)

			setFramebuffer(pipeline, "hdr")
			setActiveDirectionalLightUniforms(pipeline)
			disableDepthWrite(pipeline)
			drawQuad(pipeline, -1, -1, 2, 2, sky_material)
			clearLightCommandBuffer(pipeline)
			clearStencil(pipeline)
	end
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

function shadowmapDebug(pipeline)
	if parameters.render_shadowmap_debug then
		setPass(pipeline, "SCREEN_SPACE")
		setFramebuffer(pipeline, "default")
		bindFramebufferTexture(pipeline, "shadowmap", 0, texture_uniform)
		drawQuad(pipeline, 0.48, 0.48, 0.5, 0.5, screen_space_material);
		--drawQuad(pipeline, -1.0, -1.0, 2, 2, screen_space_material);
	end
end

function debugDeferred(pipeline)
	setPass(pipeline, "SCREEN_SPACE")
	local x = 0.5
	if parameters.debug_gbuffer0 then
			setFramebuffer(pipeline, "default")
			bindFramebufferTexture(pipeline, "g_buffer", 0, texture_uniform)
			drawQuad(pipeline, x, 1.0, 0.5, -0.5, screen_space_material);
			x = x - 0.51
	end
	if parameters.debug_gbuffer1 then
		beginNewView(pipeline, "debug_gbuffer1")
			setFramebuffer(pipeline, "default")
			bindFramebufferTexture(pipeline, "g_buffer", 1, texture_uniform)
			drawQuad(pipeline, x, 1.0, 0.5, -0.5, screen_space_material);
			x = x - 0.51
	end
	if parameters.debug_gbuffer2 then
		beginNewView(pipeline, "debug_gbuffer2")
			setFramebuffer(pipeline, "default")
			bindFramebufferTexture(pipeline, "g_buffer", 2, texture_uniform)
			drawQuad(pipeline, x, 1.0, 0.5, -0.5, screen_space_material);
			x = x - 0.51
	end
	if parameters.debug_gbuffer_depth then
		beginNewView(pipeline, "debug_gbuffer_depth")
			setFramebuffer(pipeline, "default")
			bindFramebufferTexture(pipeline, "g_buffer", 3, texture_uniform)
			drawQuad(pipeline, x, 1.0, 0.5, -0.5, screen_space_material);
			x = x - 0.51
	end
end


function particles(pipeline)
	if parameters.particles_enabled then
		setPass(pipeline, "PARTICLES")
		disableDepthWrite(pipeline)
		applyCamera(pipeline, "editor")
		renderParticles(pipeline)
	end	
end

local current_lum1 = "lum1a"

function hdr(pipeline)
	setPass(pipeline, "HDR_LUMINANCE")
		setFramebuffer(pipeline, "lum128")
		disableDepthWrite(pipeline)
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
		applyCamera(pipeline, "editor")
		clear(pipeline, CLEAR_COLOR | CLEAR_DEPTH, 0x00000000)
		bindFramebufferTexture(pipeline, "hdr", 0, hdr_buffer_uniform)
		bindFramebufferTexture(pipeline, current_lum1, 0, avg_luminance_uniform)
		drawQuad(pipeline, -1, 1, 2, -2, hdr_material)
	
end

function render(pipeline)
	shadowmap(pipeline)
	deferred(pipeline)
	renderDebugShapes(pipeline)
	particles(pipeline)
	hdr(pipeline)

	editor(pipeline)
	debugDeferred(pipeline)
	shadowmapDebug(pipeline)
end
