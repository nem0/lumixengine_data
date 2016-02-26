enabled = true
blur_enabled = true
local SSAO_debug = false


function renderSSAODDebug(pipeline)
	if SSAO_debug then
		newView(pipeline, "ssao_debug")
			setPass(pipeline, "SCREEN_SPACE")
			disableBlending(pipeline)
			disableDepthWrite(pipeline)
			setFramebuffer(pipeline, "default")
			bindFramebufferTexture(pipeline, "SSAO", 0, texture_uniform)
			drawQuad(pipeline, 0.48, 0.48, 0.5, 0.5, screen_space_material)
	end
end


function initPostprocess(pipeline, env)
	env.ctx.ssao_material = loadMaterial(pipeline, "shaders/ssao.mat")

	addFramebuffer(pipeline,  "SSAO", {
		width = 512,
		height = 512,
		renderbuffers = {
			{format="rgba8"},
			{format = "depth24"}
		}
	})
		
	addFramebuffer(pipeline, "blur_rgba8", {
		width = 2048,
		height = 2048,
		renderbuffers = {
			{ format = "rgba8" }
		}
	})
	
end


function postprocess(pipeline, env)
	if not enabled then return end
	
	newView(pipeline, "ssao")
		setPass(pipeline, "SSAO")
		disableBlending(pipeline)
		disableDepthWrite(pipeline)
		setFramebuffer(pipeline, "SSAO")
		bindFramebufferTexture(pipeline, env.ctx.main_framebuffer, 1, env.ctx.texture_uniform)
		drawQuad(pipeline, -1, -1, 2, 2, env.ctx.ssao_material)

	if blur_enabled then
		newView(pipeline, "ssao_blur_h")
			setPass(pipeline, "BLUR_H")
			setFramebuffer(pipeline, "blur_rgba8")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "SSAO", 0, env.ctx.texture_uniform)
			drawQuad(pipeline, -1, -1, 2, 2, env.ctx.blur_material)
			enableDepthWrite(pipeline)
		
		newView(pipeline, "ssao_blur_v")
			setPass(pipeline, "BLUR_V")
			setFramebuffer(pipeline, "SSAO")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "blur_rgba8", 0, env.ctx.texture_uniform)
			drawQuad(pipeline, -1, -1, 2, 2, env.ctx.blur_material)
			enableDepthWrite(pipeline)		
			
		newView(pipeline, "ssao_postprocess")
			setPass(pipeline, "SCREEN_SPACE")
			enableBlending(pipeline, "multiply")
			disableDepthWrite(pipeline)
			setFramebuffer(pipeline, env.ctx.main_framebuffer)
			bindFramebufferTexture(pipeline, "SSAO", 0, env.ctx.texture_uniform)
			drawQuad(pipeline, -1.0, -1.0, 2, 2, env.ctx.screen_space_material)
	end
end