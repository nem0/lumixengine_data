local is_enabled = false
local RENDERABLE_TYPE = Engine.getComponentType("renderable") 

function onGUI()
	local changed
	changed, is_enabled = ImGui.Checkbox("Visualize", is_enabled)
	
	if is_enabled then
		local renderable = Engine.getComponent(g_universe, this, RENDERABLE_TYPE)
		local model = Renderer.getModelInstanceModel(g_scene_renderer, renderable)
		local bone_count = Model.getBoneCount(model)
		for i = 0, bone_count-1 do
			local pos = Renderer.getPoseBonePosition(g_scene_renderer, renderable, i)
			
			local parent_idx = Model.getBoneParent(model, i)
			if parent_idx >= 0 then
				local parent_pos = Renderer.getPoseBonePosition(g_scene_renderer, renderable, parent_idx)
				Renderer.addDebugLine(g_scene_renderer, pos, parent_pos, 0xffff00FF, 0)
			end
		end
	end
end