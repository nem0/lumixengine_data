camera_entity = -1
PLAYER_SPEED = 1
MOUSE_SENSITIVITY = 1
Editor.setPropertyType("camera_entity", Editor.ENTITY_PROPERTY)
input_enabled = true

local yaw = 0
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
	rot_h = 0,
	rot_v = 0
}
function onInputEvent(event)
	if event.type == Engine.INPUT_EVENT_BUTTON then
		if event.device.type == Engine.INPUT_DEVICE_KEYBOARD then
			if event.scancode == Engine.INPUT_SCANCODE_W then
				actions.forward = event.state ~= 0
			elseif event.scancode == Engine.INPUT_SCANCODE_A then
				actions.left = event.state ~= 0
			elseif event.scancode == Engine.INPUT_SCANCODE_D then
				actions.right = event.state ~= 0
			elseif event.scancode == Engine.INPUT_SCANCODE_S then
				actions.back = event.state ~= 0
			elseif event.key_id == 1073742049 then
				actions.sprint = event.state ~= 0
			end
		end		
	elseif event.type == Engine.INPUT_EVENT_AXIS then
		if event.device.type == Engine.INPUT_DEVICE_MOUSE then
			yaw = yaw + event.x * -0.005 * MOUSE_SENSITIVITY;
			pitch = pitch + event.y * -0.005 * MOUSE_SENSITIVITY;
		end
	end
end

function init()
	Engine.createComponent(g_universe, this, "physical_controller")
end

function update(dt)
	if not input_enabled then return end
	local PITCH_LIMIT = 0.7
	
	if pitch > PITCH_LIMIT then pitch = PITCH_LIMIT end
	if pitch < -PITCH_LIMIT then pitch = -PITCH_LIMIT end
	
	local speed = PLAYER_SPEED
	
	if actions.sprint then
		speed = speed * 3
	end
	
	Engine.setEntityLocalRotation(g_universe, camera_entity, makeQuat({1, 0, 0}, pitch))
	
	Engine.setEntityRotation(g_universe, this, {0, 1, 0}, yaw);

	local scene = g_scene_physics;

	if actions.left then
		local v = Engine.multVecQuat({-speed, 0, 0}, {0, 1, 0}, yaw)
		Physics.moveController(scene, this, v, dt)
	end
	if actions.right then
		local v = Engine.multVecQuat({speed, 0, 0}, {0, 1, 0}, yaw)
		Physics.moveController(scene, this, v, dt)
	end
	if actions.forward then
		local v = Engine.multVecQuat({0, 0, -speed}, {0, 1, 0}, yaw)
		Physics.moveController(scene, this, v, dt)
	end
	if actions.back then
		local v = Engine.multVecQuat({0, 0, speed}, {0, 1, 0}, yaw)
		Physics.moveController(scene, this, v, dt)
	end
end
