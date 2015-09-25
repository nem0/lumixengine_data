framebuffers = {
}
 
function init(pipeline)
end
 
 
function render(pipeline)
		setPass(pipeline, "IMGUI")
			clear(pipeline, "all")
end
