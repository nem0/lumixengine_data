cube_sky_enabled = true


function initPostprocess(pipeline, env)
	env.ctx.sky_material = loadMaterial(pipeline, "shaders/sky.mat")
	env.ctx.cube_sky_material = loadMaterial(pipeline, "models/sky/miramar/sky.mat")
end


function postprocess(pipeline, env)
	newView(pipeline, "sky")
		setPass(pipeline, "SKY")
		setStencil(pipeline, STENCIL_OP_PASS_Z_KEEP 
			| STENCIL_OP_FAIL_Z_KEEP 
			| STENCIL_OP_FAIL_S_KEEP 
			| STENCIL_TEST_NOTEQUAL)
		setStencilRMask(pipeline, 1)
		setStencilRef(pipeline, 1)

		setFramebuffer(pipeline, env.ctx.main_framebuffer)
		setActiveGlobalLightUniforms(pipeline)
		disableDepthWrite(pipeline)
		if cube_sky_enabled then
			drawQuad(pipeline, 0, 0, 1, 1, env.ctx.cube_sky_material)
		else
			drawQuad(pipeline, 0, 0, 1, 1, env.ctx.sky_material)
		end
end