enabled = true


function initPostprocess(pipeline, env)
	env.ctx.godrays_material = loadMaterial(pipeline, "shaders/godrays.mat")
end


function postprocess(pipeline, env)
	if not enabled then return end
	
	newView(pipeline, "godrays")
		setPass(pipeline, "MAIN")
		enableBlending(pipeline, "add")
		--disableBlending(pipeline)
		disableDepthWrite(pipeline)
		setFramebuffer(pipeline, env.ctx.main_framebuffer)
		bindFramebufferTexture(pipeline, "g_buffer", 3, env.ctx.texture_uniform)
		drawQuad(pipeline, 0, 0, 1, 1, env.ctx.godrays_material)
end