local module = {}


module.particles_enabled = true
module.render_gizmos = true
module.blur_shadowmap = true
module.render_shadowmap_debug = false
module.render_shadowmap_debug_fullsize = false

function module.renderEditorIcons(ctx)
	if module.render_gizmos then
		newView(ctx.pipeline, "copy_depth_editor")
			copyRenderbuffer(ctx.pipeline, ctx.main_framebuffer, 1, "default", 1)
		
		newView(ctx.pipeline, "editor")
			bindFramebufferTexture(ctx.pipeline, ctx.main_framebuffer, 1, ctx.depth_buffer_uniform)
			setPass(ctx.pipeline, "EDITOR")
			setFramebuffer(ctx.pipeline, "default")
			enableDepthWrite(ctx.pipeline)
			enableBlending(ctx.pipeline, "alpha")
			applyCamera(ctx.pipeline, "editor")
			renderIcons(ctx.pipeline)
	end
end

function module.renderGizmo(ctx)
	if module.render_gizmos then
		newView(ctx.pipeline, "gizmo")
			setPass(ctx.pipeline, "EDITOR")
			disableDepthWrite(ctx.pipeline)
			setFramebuffer(ctx.pipeline, "default")
			applyCamera(ctx.pipeline, "editor")
			renderGizmos(ctx.pipeline)
	end
end

function module.shadowmapDebug(ctx, x, y)
	if module.render_shadowmap_debug then
		newView(ctx.pipeline, "shadowmap_debug")
			setPass(ctx.pipeline, "SCREEN_SPACE")
			setFramebuffer(ctx.pipeline, "default")
			bindFramebufferTexture(ctx.pipeline, "shadowmap", 0, ctx.texture_uniform)
			drawQuad(ctx.pipeline, 0.01 + x, 0.01 + y, 0.23, 0.23, ctx.screen_space_material)
	end
	if module.render_shadowmap_debug_fullsize then
		newView(ctx.pipeline, "shadowmap_debug_fullsize")
			setPass(ctx.pipeline, "SCREEN_SPACE")
			setFramebuffer(ctx.pipeline, "default")
			bindFramebufferTexture(ctx.pipeline, "shadowmap", 0, ctx.texture_uniform)
			drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.screen_space_material)
	end
end

function module.initShadowmap(ctx)
	addFramebuffer(ctx.pipeline, "shadowmap_blur", {
		width = 2048,
		height = 2048,
		renderbuffers = {
			{ format = "r32f" }
		}
	})

	addFramebuffer(ctx.pipeline, "shadowmap", {
		width = 2048,
		height = 2048,
		renderbuffers = {
			{format="r32f"},
			{format = "depth24"}
		}
	})

	addFramebuffer(ctx.pipeline, "point_light_shadowmap", {
		width = 1024,
		height = 1024,
		renderbuffers = {
			{format = "depth24"}
		}
	})

	addFramebuffer(ctx.pipeline, "point_light2_shadowmap", {
		width = 1024,
		height = 1024,
		renderbuffers = {
			{format = "depth24"}
		}
	})
	ctx.shadowmap_uniform = createUniform(ctx.pipeline, "u_texShadowmap")
	module.blur_shadowmap = true
	module.render_shadowmap_debug = false
end


function module.init(ctx)
	ctx.screen_space_material = Engine.loadResource(g_engine, "pipelines/screenspace/screenspace.mat", "material")
	ctx.texture_uniform = createUniform(ctx.pipeline, "u_texture")
	ctx.blur_material = Engine.loadResource(g_engine, "pipelines/common/blur.mat", "material")
	ctx.depth_buffer_uniform = createUniform(ctx.pipeline, "u_depthBuffer")
end


function module.shadowmap(ctx, camera_slot)
	newView(ctx.pipeline, "shadow0")
		setPass(ctx.pipeline, "SHADOW")         
		applyCamera(ctx.pipeline, camera_slot)
		setFramebuffer(ctx.pipeline, "shadowmap")
		renderShadowmap(ctx.pipeline, 0) 

	newView(ctx.pipeline, "shadow1")
		setPass(ctx.pipeline, "SHADOW")         
		applyCamera(ctx.pipeline, camera_slot)
		setFramebuffer(ctx.pipeline, "shadowmap")
		renderShadowmap(ctx.pipeline, 1) 

	newView(ctx.pipeline, "shadow2")
		setPass(ctx.pipeline, "SHADOW")         
		applyCamera(ctx.pipeline, camera_slot)
		setFramebuffer(ctx.pipeline, "shadowmap")
		renderShadowmap(ctx.pipeline, 2) 

	newView(ctx.pipeline, "shadow3")
		setPass(ctx.pipeline, "SHADOW")         
		applyCamera(ctx.pipeline, camera_slot)
		setFramebuffer(ctx.pipeline, "shadowmap")
		renderShadowmap(ctx.pipeline, 3) 
		
		renderLocalLightsShadowmaps(ctx.pipeline, camera_slot, { "point_light_shadowmap", "point_light2_shadowmap" })
		
	if module.blur_shadowmap then
		newView(ctx.pipeline, "blur_shadowmap_h")
			setPass(ctx.pipeline, "BLUR_H")
			setFramebuffer(ctx.pipeline, "shadowmap_blur")
			disableDepthWrite(ctx.pipeline)
			bindFramebufferTexture(ctx.pipeline, "shadowmap", 0, ctx.shadowmap_uniform)
			drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.blur_material)
			enableDepthWrite(ctx.pipeline)

		newView(ctx.pipeline, "blur_shadowmap_v")
			setPass(ctx.pipeline, "BLUR_V")
			setFramebuffer(ctx.pipeline, "shadowmap")
			disableDepthWrite(ctx.pipeline)
			bindFramebufferTexture(ctx.pipeline, "shadowmap_blur", 0, ctx.shadowmap_uniform)
			drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.blur_material);
			enableDepthWrite(ctx.pipeline)
	end
end

function module.particles(ctx, camera_slot)
	if module.particles_enabled then
		newView(ctx.pipeline, "particles")
			setPass(ctx.pipeline, "PARTICLES")
			disableDepthWrite(ctx.pipeline)
			applyCamera(ctx.pipeline, camera_slot)
			bindFramebufferTexture(ctx.pipeline, "g_buffer", 3, ctx.depth_buffer_uniform)
			renderParticles(ctx.pipeline)
	end	
end


return module
