require "pipelines/common"

addFramebuffer(this, "default", {
	width = 1024,
	height = 1024,
	renderbuffers = {
		{ format = "rgba8" },
	}
})

addFramebuffer(this,  "g_buffer", {
	width = 1024,
	height = 1024,
	screen_size = true,
	renderbuffers = {
		{ format = "rgba8" },
		{ format = "rgba8" },
		{ format = "rgba8" },
		{ format = "depth32" }
	}
})

addFramebuffer(this,  "blur", {
	width = 2048,
	height = 2048,
	renderbuffers = {
		{ format = "r32f" }
	}
})

parameters.hdr = true
parameters.render_gizmos = true
parameters.debug_gbuffer0 = false
parameters.debug_gbuffer1 = false
parameters.debug_gbuffer2 = false
parameters.debug_gbuffer_depth = false
parameters.sky_enabled = true

function initScene(this)
	hdr_exposure_param = addRenderParamFloat(this, "HDR exposure", 1.0)
end


texture_uniform = createUniform(this, "u_texture")
gbuffer0_uniform = createUniform(this, "u_gbuffer0")
gbuffer1_uniform = createUniform(this, "u_gbuffer1")
gbuffer2_uniform = createUniform(this, "u_gbuffer2")
gbuffer_depth_uniform = createUniform(this, "u_gbuffer_depth")
shadowmap_uniform = createUniform(this, "u_texShadowmap")
blur_material = loadMaterial(this, "shaders/blur.mat")
deferred_material = loadMaterial(this, "shaders/deferred.mat")
screen_space_material = loadMaterial(this, "shaders/screen_space.mat")
deferred_point_light_material =loadMaterial(this, "shaders/deferredpointlight.mat")
avg_luminance_uniform = createUniform(this, "u_avgLuminance")
hdr_buffer_uniform = createUniform(this, "u_hdrBuffer")
hdr_material = loadMaterial(this, "shaders/hdr.mat")
lum_material = loadMaterial(this, "shaders/hdrlum.mat")
lum_size_uniform = createVec4ArrayUniform(this, "u_offset", 16)
sky_material = loadMaterial(this, "shaders/sky.mat")
initHDR(this)
initShadowmap(this)


function deferred()
	setPass(this, "DEFERRED")
		setFramebuffer(this, "g_buffer")
		applyCamera(this, "editor")
		clear(this, CLEAR_ALL, 0x00000000)
		
		setStencil(this, STENCIL_OP_PASS_Z_REPLACE 
			| STENCIL_OP_FAIL_Z_KEEP 
			| STENCIL_OP_FAIL_S_KEEP 
			| STENCIL_TEST_ALWAYS)
		setStencilRMask(this, 0xff)
		setStencilRef(this, 1)
		
		renderModels(this)
		clearStencil(this)
		
	beginNewView(this, "copyRenderbuffer");
		copyRenderbuffer(this, "g_buffer", 3, "hdr", 1)
		
	setPass(this, "MAIN")
		setFramebuffer(this, "hdr")
		applyCamera(this, "editor")
		clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0x00000000)
		
		bindFramebufferTexture(this, "g_buffer", 0, gbuffer0_uniform)
		bindFramebufferTexture(this, "g_buffer", 1, gbuffer1_uniform)
		bindFramebufferTexture(this, "g_buffer", 2, gbuffer2_uniform)
		bindFramebufferTexture(this, "g_buffer", 3, gbuffer_depth_uniform)
		bindFramebufferTexture(this, "shadowmap", 0, shadowmap_uniform)
		drawQuad(this, -1, 1, 2, -2, deferred_material)

	beginNewView(this, "DEFERRED_LOCAL_LIGHT")
		setFramebuffer(this, "hdr")
		disableDepthWrite(this)
		enableBlending(this, "add")
		applyCamera(this, "editor")
		local bufs = {
			{ "g_buffer", 0, gbuffer0_uniform },
			{ "g_buffer", 1, gbuffer1_uniform },
			{ "g_buffer", 2, gbuffer2_uniform },
			{ "g_buffer", 3, gbuffer_depth_uniform },
			{ "shadowmap", 0, shadowmap_uniform }
		}
		deferredLocalLightLoop(this, deferred_point_light_material, bufs)
		
		disableBlending(this)
		
	if parameters.sky_enabled then
		setPass(this, "SKY")
			setStencil(this, STENCIL_OP_PASS_Z_KEEP 
				| STENCIL_OP_FAIL_Z_KEEP 
				| STENCIL_OP_FAIL_S_KEEP 
				| STENCIL_TEST_NOTEQUAL)
			setStencilRMask(this, 1)
			setStencilRef(this, 1)

			setFramebuffer(this, "hdr")
			setActiveGlobalLightUniforms(this)
			disableDepthWrite(this)
			drawQuad(this, -1, -1, 2, 2, sky_material)
			clearLightCommandBuffer(this)
			clearStencil(this)
	end
end


function debugDeferred()
	setPass(this, "SCREEN_SPACE")
	local x = 0.5
	if parameters.debug_gbuffer0 then
			setFramebuffer(this, "default")
			bindFramebufferTexture(this, "g_buffer", 0, texture_uniform)
			drawQuad(this, x, 1.0, 0.5, -0.5, screen_space_material);
			x = x - 0.51
	end
	if parameters.debug_gbuffer1 then
		beginNewView(this, "debug_gbuffer1")
			setFramebuffer(this, "default")
			bindFramebufferTexture(this, "g_buffer", 1, texture_uniform)
			drawQuad(this, x, 1.0, 0.5, -0.5, screen_space_material);
			x = x - 0.51
	end
	if parameters.debug_gbuffer2 then
		beginNewView(this, "debug_gbuffer2")
			setFramebuffer(this, "default")
			bindFramebufferTexture(this, "g_buffer", 2, texture_uniform)
			drawQuad(this, x, 1.0, 0.5, -0.5, screen_space_material);
			x = x - 0.51
	end
	if parameters.debug_gbuffer_depth then
		beginNewView(this, "debug_gbuffer_depth")
			setFramebuffer(this, "default")
			bindFramebufferTexture(this, "g_buffer", 3, texture_uniform)
			drawQuad(this, x, 1.0, 0.5, -0.5, screen_space_material);
			x = x - 0.51
	end
end


function render()
	shadowmap(this)
	deferred(this)
	renderDebugShapes(this)
	particles(this)
	hdr(this)

	editor(this)
	debugDeferred(this)
	shadowmapDebug(this)
end
