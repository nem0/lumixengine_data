framebuffers = {
	
}
 
function init(pipeline)
	screen_space_material = loadMaterial(pipeline, "models/editor/screen_space.mat")
end
 
 
function render(pipeline)
		setPass(pipeline, "IMGUI")
			clear(pipeline, "all")
end
