local debug_navmesh = false
local debug_heightfield = false
local debug_compact_heightfield = false
local debug_contours = true
local debug_paths = true
function onGUI()
    if ImGui.Button("Generate navmesh") then
        Navigation.generateNavmesh(g_scene_navigation)
    end
    local tmp
    tmp, debug_navmesh = ImGui.Checkbox("Debug navmesh", debug_navmesh)
    tmp, debug_heightfield = ImGui.Checkbox("Debug heightfield", debug_heightfield)
    tmp, debug_compact_heightfield = ImGui.Checkbox("Debug compact heightfield", debug_compact_heightfield)
    tmp, debug_contours = ImGui.Checkbox("Debug contours", debug_contours)

    if debug_navmesh then
        Navigation.debugDrawNavmesh(g_scene_navigation)
    end
    if debug_compact_heightfield then
        Navigation.debugDrawCompactHeightfield(g_scene_navigation)
    end
    if debug_heightfield then
        Navigation.debugDrawHeightfield(g_scene_navigation)
    end
    if debug_contours then
        Navigation.debugDrawContours(g_scene_navigation)
    end
	if ImGui.Button("Generate tile") then
		Navigation.generateTile(g_scene_navigation, 1, 0, true)
	end
	
	changed, debug_paths = ImGui.Checkbox("Debug paths", debug_paths)
	if debug_paths then
		Navigation.debugDrawPaths(g_scene_navigation)
	end

end 