common = require "pipelines/common"
ctx = { pipeline = this, main_framebuffer = "default" }

local sky_enabled = true
  
common.init(ctx)
common.initShadowmap(ctx)


local texture_uniform = createUniform(this, "u_texture")
local blur_material = loadMaterial(this, "shaders/blur.mat")
local screen_space_material = loadMaterial(this, "shaders/screen_space.mat")
local sky_material = loadMaterial(this, "shaders/sky.mat")


function main()
	if sky_enabled then
		newView(this, "sky")
			setPass(this, "SKY")
			setFramebuffer(this, ctx.main_framebuffer)
			disableDepthWrite(this)
			clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0xffffFFFF)
			setActiveGlobalLightUniforms(this, sky_material)
			drawQuad(this, -1, -1, 2, 2, sky_material)
	end

	main_view = newView(this, "MAIN")
		setPass(this, "MAIN")
		enableDepthWrite(this)
		if not sky_enabled then
			clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0xffffFFFF)
		end
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

