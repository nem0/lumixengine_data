sky_material = -1
Editor.setPropertyType("sky_material", Editor.RESOURCE_PROPERTY, "material")


_postprocess_slot = "pre_transparent"



function postprocess(pipeline, env)
	if sky_material < 0 then return end
	newView(pipeline, "sky")
		setPass(pipeline, "MAIN")
		setStencil(pipeline, STENCIL_OP_PASS_Z_KEEP 
			| STENCIL_OP_FAIL_Z_KEEP 
			| STENCIL_OP_FAIL_S_KEEP 
			| STENCIL_TEST_NOTEQUAL)
		setStencilRMask(pipeline, 1)
		setStencilRef(pipeline, 1)

		setFramebuffer(pipeline, env.ctx.main_framebuffer)
		setActiveGlobalLightUniforms(pipeline)
		disableDepthWrite(pipeline)
		drawQuad(pipeline, 0, 0, 1, 1, sky_material)
end