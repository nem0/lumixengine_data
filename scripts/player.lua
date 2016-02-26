camera_entity = -1
PLAYER_SPEED = 1
MOUSE_SENSITIVITY = 1

Editor.setPropertyType("camera_entity", Editor.ENTITY_PROPERTY)

local LSHIFT_KEY = 160

local LEFT_ACTION = 0
local RIGHT_ACTION = 1
local FORWARD_ACTION = 2
local BACK_ACTION = 3
local ROT_H_ACTION = 4
local SPRINT_ACTION = 5
local ROT_V_ACTION = 6

local CONTROLLER_ROT_X = 7
local CONTROLLER_ROT_Y = 8
local CONTROLLER_MOVE_X = 9
local CONTROLLER_MOVE_Y = 10

local yaw = 0
local pitch = 0

function init()
	cmp = Engine.createComponent(g_scene_physics, "physical_controller", this)

	Engine.addInputAction(g_engine, LEFT_ACTION, 0, string.byte("A"), -1)
	Engine.addInputAction(g_engine, RIGHT_ACTION, 0, string.byte("D"), -1)
	Engine.addInputAction(g_engine, FORWARD_ACTION, 0, string.byte("W"), -1)
	Engine.addInputAction(g_engine, BACK_ACTION, 0, string.byte("S"), -1)
	Engine.addInputAction(g_engine, ROT_H_ACTION, 2, 0, -1)
	Engine.addInputAction(g_engine, ROT_V_ACTION, 3, 0, -1)
	Engine.addInputAction(g_engine, SPRINT_ACTION, 0, LSHIFT_KEY, -1)

	Engine.addInputAction(g_engine, CONTROLLER_ROT_X, 6, 0, 0)
	Engine.addInputAction(g_engine, CONTROLLER_ROT_Y, 7, 0, 0)
	Engine.addInputAction(g_engine, CONTROLLER_MOVE_X, 4, 0, 0)
	Engine.addInputAction(g_engine, CONTROLLER_MOVE_Y, 5, 0, 0)
end

function update(dt)
	yaw = yaw + Engine.getInputActionValue(g_engine, ROT_H_ACTION) * -0.01 * MOUSE_SENSITIVITY;
	pitch = pitch + Engine.getInputActionValue(g_engine, ROT_V_ACTION) * -0.01 * MOUSE_SENSITIVITY;
	
	yaw = yaw + Engine.getInputActionValue(g_engine, CONTROLLER_ROT_X) * -0.03 * MOUSE_SENSITIVITY;
	pitch = pitch + Engine.getInputActionValue(g_engine, CONTROLLER_ROT_Y) * 0.03 * MOUSE_SENSITIVITY;

	local PITCH_LIMIT = 0.7
	
	if pitch > PITCH_LIMIT then pitch = PITCH_LIMIT end
	if pitch < -PITCH_LIMIT then pitch = -PITCH_LIMIT end
	
	local speed = PLAYER_SPEED
	
	if Engine.getInputActionValue(g_engine, SPRINT_ACTION) > 0 then
		speed = speed * 3
	end
	
	Engine.setEntityLocalRotation(g_scene_hierarchy, camera_entity, {1, 0, 0}, pitch)
	
	Engine.setEntityRotation(g_universe, this, {0, 1, 0}, yaw);

	local scene = g_scene_physics;

	local v = Engine.multVecQuat({Engine.getInputActionValue(g_engine, CONTROLLER_MOVE_X) * 0.1, 0, 0}, {0, 1, 0}, yaw)
	Physics.moveController(scene, cmp, v, dt)

	local v = Engine.multVecQuat({0, 0, -Engine.getInputActionValue(g_engine, CONTROLLER_MOVE_Y) * 0.1}, {0, 1, 0}, yaw)
	Physics.moveController(scene, cmp, v, dt)
	
	if Engine.getInputActionValue(g_engine, LEFT_ACTION) > 0 then
		local v = Engine.multVecQuat({-speed, 0, 0}, {0, 1, 0}, yaw)
		Physics.moveController(scene, cmp, v, dt)
	end
	if Engine.getInputActionValue(g_engine, RIGHT_ACTION) > 0 then
		local v = Engine.multVecQuat({speed, 0, 0}, {0, 1, 0}, yaw)
		Physics.moveController(scene, cmp, v, dt)
	end
	if Engine.getInputActionValue(g_engine, FORWARD_ACTION) > 0 then
		local v = Engine.multVecQuat({0, 0, -speed}, {0, 1, 0}, yaw)
		Physics.moveController(scene, cmp, v, dt)
	end
	if Engine.getInputActionValue(g_engine, BACK_ACTION) > 0 then
		local v = Engine.multVecQuat({0, 0, speed}, {0, 1, 0}, yaw)
		Physics.moveController(scene, cmp, v, dt)
	end
end