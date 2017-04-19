followed_entity = -1
spawner = -1
speed = 5.0
Editor.setPropertyType("spawner", Editor.ENTITY_PROPERTY)
Editor.setPropertyType("followed_entity", Editor.ENTITY_PROPERTY)
local ANIM_CONTROLLER_TYPE = Engine.getComponentType("anim_controller")
local anim_ctrl = -1
local speed_input_idx = -1
local attack_input_idx = -1
local dead_input_idx = -1
local next_follow = 2
local is_enabled = true

function init()
	-- cache some stuff
	anim_ctrl = Engine.getComponent(g_universe, this, ANIM_CONTROLLER_TYPE)
	speed_input_idx = Animation.getControllerInputIndex(g_scene_animation, anim_ctrl, "speed")
	attack_input_idx = Animation.getControllerInputIndex(g_scene_animation, anim_ctrl, "attack")
	dead_input_idx = Animation.getControllerInputIndex(g_scene_animation, anim_ctrl, "dead")
end

function kill()
    -- play dead animation
    Animation.setControllerBoolInput(g_scene_animation, anim_ctrl, dead_input_idx, true)
    -- stop following player
    stopFollowing()
	-- despawn
	local spawner_env = LuaScript.getEnvironment(g_scene_lua_script, spawner, 1)
	spawner_env.despawn(this)
end

function stopFollowing()
	is_enabled = false
	Navigation.cancelNavigation(g_scene_navigation, this)
end

function onPathFinished()
	-- when the enemy finish walking, play attack animation
	Animation.setControllerBoolInput(g_scene_animation, anim_ctrl, attack_input_idx, true)
end

function update(time_delta)
	if not is_enabled then return end

	-- get agent speed from navigation and set it as input to animation controller
	-- so it can play the right animation
	local agent_speed = Navigation.getAgentSpeed(g_scene_navigation, this)
	Animation.setControllerFloatInput(g_scene_animation, anim_ctrl, speed_input_idx, agent_speed)

    -- try to move to where player is every few seconds
	next_follow = next_follow - time_delta
	if next_follow > 0 then return end
	
	next_follow = 5
	-- get player's position
	local pos = Engine.getEntityPosition(g_universe, followed_entity)
	-- move to where player is
	Navigation.navigate(g_scene_navigation, this, pos, speed, 0.1)
end