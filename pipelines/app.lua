common = require "pipelines/common"
ctx = { pipeline = this, main_framebuffer = "default" }

common.init(ctx)
common.initShadowmap(ctx)


local texture_uniform = createUniform(this, "u_texture")
local screen_space_material = Engine.loadResource(g_engine, "pipelines/screenspace/screenspace.mat", "material")


function main()
	main_view = newView(this, "MAIN")
		setPass(this, "MAIN")
		enableDepthWrite(this)
		clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0xffffFFFF)
		enableRGBWrite(this)
		setFramebuffer(this, ctx.main_framebuffer)
		applyCamera(this, "main")
		setActiveGlobalLightUniforms(this)
		renderDebugShapes(this)
end


function fur()
	fur_view = newView(this, "FUR")
		setPass(this, "FUR")
		setFramebuffer(this, ctx.main_framebuffer)
		disableDepthWrite(this)
		enableBlending(this, "alpha")
		applyCamera(this, "main")
		setActiveGlobalLightUniforms(this)
		renderModels(this, {main_view, fur_view})
end


function pointLight()
	newView(this, "POINT_LIGHT")
		setPass(this, "POINT_LIGHT")
		setFramebuffer(this, ctx.main_framebuffer)
		disableDepthWrite(this)
		enableBlending(this, "add")
		applyCamera(this, "main")
		renderPointLightLitGeometry(this)
end


function render()
	common.shadowmap(ctx, "main")
	main(this)
	common.particles(ctx, "main")
	pointLight(this)		
	fur(this)

	if not postprocessCallback(this, "main") then
		-- todo SRGB
	end
end

