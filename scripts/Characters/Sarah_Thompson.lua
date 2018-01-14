camera_entity = -1
camera_pitch_pivot_entity = -1
camera_yaw_pivot_entity = -1
aim_controller_entity = -1
Editor.setPropertyType("camera_entity", Editor.ENTITY_PROPERTY)
Editor.setPropertyType("camera_pitch_pivot_entity", Editor.ENTITY_PROPERTY)
Editor.setPropertyType("camera_yaw_pivot_entity", Editor.ENTITY_PROPERTY)
Editor.setPropertyType("aim_controller_entity", Editor.ENTITY_PROPERTY)
local ANIM_CONTROLLER_TYPE = Engine.getComponentType("anim_controller")
local anim_ctrl = -1
local forward_input_idx = -1
local backward_input_idx = -1
local rightward_input_idx = -1
local leftward_input_idx = -1
local sprint_input_idx = -1
input_enabled = true
PLAYER_SPEED = 0
MOUSE_SENSITIVITY = 1
Max_Speed = 0.325

camera_yaw = 0
player_yaw = 0
local pitch = 0

function makeQuat(axis, angle)
	local half_angle = angle * 0.5
	local s = math.sin(half_angle)
	return {
		axis[1] * s,
		axis[2] * s,
		axis[3] * s,
		math.cos(half_angle)
	}
end

local actions = {
	forward = false,
	left = false,
	right = false,
	back = false,
	sprint = false,
	aim = false,
	rot_h = 0,
	rot_v = 0
}
function onInputEvent(event)
	if event.type == Engine.INPUT_EVENT_BUTTON then
		if event.device.type == Engine.INPUT_DEVICE_KEYBOARD then
			if event.key_id == 119 then
				actions.forward = event.state ~= 0
			elseif event.key_id == 97 then
				actions.left = event.state ~= 0
			elseif event.key_id == 100 then
				actions.right = event.state ~= 0
			elseif event.key_id == 115 then
				actions.back = event.state ~= 0
			elseif event.key_id == 1073742049 then
				actions.sprint = event.state ~= 0
			end
			elseif event.device.type == Engine.INPUT_DEVICE_MOUSE then
				if event.key_id == 3 then
					actions.aim = event.state ~= 0
				end 
		end		
	elseif event.type == Engine.INPUT_EVENT_AXIS then
		if event.device.type == Engine.INPUT_DEVICE_MOUSE then
			camera_yaw = camera_yaw + event.x * -0.005 * MOUSE_SENSITIVITY;
			pitch = pitch + event.y * -0.005 * MOUSE_SENSITIVITY;
		end
	end
end

function init()
    cmp = Engine.createComponent(g_universe, this, "physical_controller")
    anim_ctrl = Engine.getComponent(g_universe, this, ANIM_CONTROLLER_TYPE)
	forward_input_idx = Animation.getControllerInputIndex(g_scene_animation, anim_ctrl, "forward")
	backward_input_idx = Animation.getControllerInputIndex(g_scene_animation, anim_ctrl, "backward")
	rightward_input_idx = Animation.getControllerInputIndex(g_scene_animation, anim_ctrl, "rightward")
	leftward_input_idx = Animation.getControllerInputIndex(g_scene_animation, anim_ctrl, "leftward")
	sprint_input_idx = Animation.getControllerInputIndex(g_scene_animation, anim_ctrl, "sprint")
end

function angleDiff(a, b)
	local PI2 = 3.14159265 * 2
	local diff = (b - a) % PI2
	if diff > 3.14159265 then
		diff = diff - PI2
	end
	return diff
end
function update(dt)
	if not input_enabled then return end
	local PITCH_LIMIT = 0.7
	
	if pitch > PITCH_LIMIT then pitch = PITCH_LIMIT end
	if pitch < -PITCH_LIMIT then pitch = -PITCH_LIMIT end

	local ROT_SPEED = 3.5
	local speed = PLAYER_SPEED
	if actions.sprint then
		speed = speed * 3
		ROT_SPEED = ROT_SPEED * 0.5
		Animation.setControllerBoolInput(g_scene_animation, anim_ctrl, sprint_input_idx, true)
	else 
		Animation.setControllerBoolInput(g_scene_animation, anim_ctrl, sprint_input_idx, false)
	end 
	if actions.aim then
		speed = speed * 0.2
		ROT_SPEED = ROT_SPEED + 7
		actions.sprint = false
	end

	local scene = g_scene_physics;

	if actions.forward then
		local dir = 1
		local old_diff = angleDiff(player_yaw, camera_yaw)
		if old_diff < 0 then dir = -1 end
		dir = dir * dt * ROT_SPEED
		player_yaw = player_yaw + dir
		local new_diff = angleDiff(player_yaw, camera_yaw) * 0.99
		if new_diff < dt * ROT_SPEED and new_diff > -dt * ROT_SPEED then
			player_yaw = camera_yaw
		end
		Engine.setEntityRotation(g_universe, this, {0, 1, 0}, player_yaw);
	end

	if actions.left then
		local dir = 1
		local old_diff = angleDiff(player_yaw, camera_yaw + 89.55)
		if old_diff < 0 then dir = -1 end
		dir = dir * dt * ROT_SPEED
		player_yaw = player_yaw + dir
		local new_diff = angleDiff(player_yaw, camera_yaw + 89.55) * 0.99
		if new_diff < dt * ROT_SPEED and new_diff > -dt * ROT_SPEED then
			player_yaw = camera_yaw + 89.55
		end
		Engine.setEntityRotation(g_universe, this, {0, 1, 0}, player_yaw);
	end

	if actions.left and actions.forward then
		local dir = 1
		local old_diff = angleDiff(player_yaw, camera_yaw + 44.775)
		if old_diff < 0 then dir = -1 end
		dir = dir * dt * ROT_SPEED
		player_yaw = player_yaw + dir
		local new_diff = angleDiff(player_yaw, camera_yaw + 44.775) * 0.99
		if new_diff < dt * ROT_SPEED and new_diff > -dt * ROT_SPEED then
			player_yaw = camera_yaw + 44.775
		end
		Engine.setEntityRotation(g_universe, this, {0, 1, 0}, player_yaw);
	end


	if actions.back then
		local dir = 1
		local old_diff = angleDiff(player_yaw, camera_yaw + 179.2)
		if old_diff < 0 then dir = -1 end
		dir = dir * dt * ROT_SPEED
		player_yaw = player_yaw + dir
		local new_diff = angleDiff(player_yaw, camera_yaw + 179.2) * 0.99
		if new_diff < dt * ROT_SPEED and new_diff > -dt * ROT_SPEED then
			player_yaw = camera_yaw + 179.2
		end
		Engine.setEntityRotation(g_universe, this, {0, 1, 0}, player_yaw);
	end

	if actions.back and actions.left then
		local dir = 1
		local old_diff = angleDiff(player_yaw, camera_yaw + 90.5)
		if old_diff < 0 then dir = -1 end
		dir = dir * dt * ROT_SPEED
		player_yaw = player_yaw + dir
		local new_diff = angleDiff(player_yaw, camera_yaw + 90.5) * 0.99
		if new_diff < dt * ROT_SPEED and new_diff > -dt * ROT_SPEED then
			player_yaw = camera_yaw + 90.5
		end
		Engine.setEntityRotation(g_universe, this, {0, 1, 0}, player_yaw);
	end

	if actions.right then
		local dir = 1
		local old_diff = angleDiff(player_yaw, camera_yaw - 89.4)
		if old_diff < 0 then dir = -1 end
		dir = dir * dt * ROT_SPEED
		player_yaw = player_yaw + dir
		local new_diff = angleDiff(player_yaw, camera_yaw - 89.4) * 0.99
		if new_diff < dt * ROT_SPEED and new_diff > -dt * ROT_SPEED then
			player_yaw = camera_yaw - 89.4
		end
		Engine.setEntityRotation(g_universe, this, {0, 1, 0}, player_yaw);
	end

	if actions.back and actions.right then
		local dir = 1
		local old_diff = angleDiff(player_yaw, camera_yaw - 90.4)
		if old_diff < 0 then dir = -1 end
		dir = dir * dt * ROT_SPEED
		player_yaw = player_yaw + dir
		local new_diff = angleDiff(player_yaw, camera_yaw - 90.4) * 0.99
		if new_diff < dt * ROT_SPEED and new_diff > -dt * ROT_SPEED then
			player_yaw = camera_yaw - 90.4
		end
		Engine.setEntityRotation(g_universe, this, {0, 1, 0}, player_yaw);
	end

	if actions.forward and actions.right then
		local dir = 1
		local old_diff = angleDiff(player_yaw, camera_yaw - 44.775)
		if old_diff < 0 then dir = -1 end
		dir = dir * dt * ROT_SPEED
		player_yaw = player_yaw + dir
		local new_diff = angleDiff(player_yaw, camera_yaw - 44.775) * 0.99
		if new_diff < dt * ROT_SPEED and new_diff > -dt * ROT_SPEED then
			player_yaw = camera_yaw - 44.775
		end
		Engine.setEntityRotation(g_universe, this, {0, 1, 0}, player_yaw);
	end


	Engine.setEntityLocalRotation(g_universe, camera_pitch_pivot_entity, makeQuat({-1, 0, 0}, pitch))
	
	Engine.setEntityRotation(g_universe, camera_yaw_pivot_entity, {0, 1, 0}, camera_yaw);
	local v = Engine.multVecQuat({0, 0, speed}, {0, 1, 0}, player_yaw)
	Physics.moveController(scene, cmp, v, dt)
	
	if actions.forward or actions.back or actions.left or actions.right then
		PLAYER_SPEED = PLAYER_SPEED + 0.03
		if PLAYER_SPEED > Max_Speed then PLAYER_SPEED = Max_Speed end
		Animation.setControllerBoolInput(g_scene_animation, anim_ctrl, forward_input_idx, true)
	else
		PLAYER_SPEED = PLAYER_SPEED - 0.025
		if PLAYER_SPEED < 0 then PLAYER_SPEED = 0 end
		Animation.setControllerBoolInput(g_scene_animation, anim_ctrl, forward_input_idx, false)
	end
--	if actions.aim then
--		speed = speed * 0.5
--		actions.sprint = false
--		local cmp_type = Engine.getComponentType("anim_controller")
--		local cmp = Engine.getComponent(g_universe, this, cmp_type)
--		if cmp < 0 then return end
--
--		local pos = Engine.getEntityPosition(g_universe, aim_controller_entity)
--		Animation.setIK(g_scene_animation, cmp, 0, 1.0, pos, "spine03", "spine02", "spine01")
--	else
--		pitch = 0
--	end --]]
end