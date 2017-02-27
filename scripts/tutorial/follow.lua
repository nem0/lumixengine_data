followed_entity = -1
speed = 5.0
Editor.setPropertyType("followed_entity", Editor.ENTITY_PROPERTY)
local next_follow = 2

function update(time_delta)
	next_follow = next_follow - time_delta
	if next_follow > 0 then return end
	
	Engine.logError("follow")
	next_follow = 2
	local pos = Engine.getEntityPosition(g_universe, followed_entity)
	Navigation.navigate(g_scene_navigation, this, pos, speed)
end