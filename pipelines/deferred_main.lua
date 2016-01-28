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
		name = "blur",
		width = 2048,
		height = 2048,
		renderbuffers = {
			{ format = "r32f" }
		}
	}
}


parameters = {
	render_gizmos = true,
	debug_gbuffer0 = false,
	debug_gbuffer1 = false,
	debug_gbuffer2 = false,
	debug_gbuffer_depth = false,
	blur_shadowmap = true,
	particles_enabled = true,
	render_shadowmap_debug = false
}


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
	hdr_buffer_uniform = createUniform(pipeline, "u_hdrBuffer")
	hdr_material = loadMaterial(pipeline, "shaders/hdr.mat")
end



function shadowmap(pipeline)
	setPass(pipeline, "SHADOW")         
		applyCamera(pipeline, "editor")
		setFramebuffer(pipeline, "shadowmap")
		renderShadowmap(pipeline, 1, "editor") 
	
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
		clear(pipeline, "all", 0xbbd3edff)
		renderModels(pipeline, 1, false)

	beginNewView(pipeline, "copyRenderbuffer");
		copyRenderbuffer(pipeline, "g_buffer", 3, "hdr", 1)
		
	setPass(pipeline, "MAIN")
		setFramebuffer(pipeline, "hdr")
		applyCamera(pipeline, "editor")
		clear(pipeline, "all", 0xbbd3edff)
		
		bindFramebufferTexture(pipeline, "g_buffer", 0, gbuffer0_uniform)
		bindFramebufferTexture(pipeline, "g_buffer", 1, gbuffer1_uniform)
		bindFramebufferTexture(pipeline, "g_buffer", 2, gbuffer2_uniform)
		bindFramebufferTexture(pipeline, "g_buffer", 3, gbuffer_depth_uniform)
		bindFramebufferTexture(pipeline, "shadowmap", 0, shadowmap_uniform)
		drawQuad(pipeline, -1, -1, 2, 2, deferred_material);
		
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
end

function editor(pipeline)
	if parameters.render_gizmos then
		setPass(pipeline, "EDITOR")
			setFramebuffer(pipeline, "default")
			enableDepthWrite(pipeline)
			disableBlending(pipeline)
			clear(pipeline, "depth", 0)
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

function hdr(pipeline)
	setPass(pipeline, "HDR")
		setFramebuffer(pipeline, "default")
		applyCamera(pipeline, "editor")
		clear(pipeline, "all", 0xbbd3edff)
		bindFramebufferTexture(pipeline, "hdr", 0, hdr_buffer_uniform)
		drawQuad(pipeline, -1, -1, 2, 2, hdr_material)
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
