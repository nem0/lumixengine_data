-- LUMIX PROPERTY CAMERA_ENTITY entity
-- LUMIX PROPERTY PLAYER_SPEED float
-- LUMIX PROPERTY MOUSE_SENSITIVITY float

cmp = API_createComponent(API_getScene(g_universe_context, "physics"), "physical_controller", this)

local LSHIFT_KEY = 160

local LEFT_ACTION = 0
local RIGHT_ACTION = 1
local FORWARD_ACTION = 2
local BACK_ACTION = 3
local ROT_H_ACTION = 4
local SPRINT_ACTION = 5
local ROT_V_ACTION = 6

local yaw = 0
local pitch = 0

API_addInputAction(g_engine, LEFT_ACTION, 0, string.byte("A"))
API_addInputAction(g_engine, RIGHT_ACTION, 0, string.byte("D"))
API_addInputAction(g_engine, FORWARD_ACTION, 0, string.byte("W"))
API_addInputAction(g_engine, BACK_ACTION, 0, string.byte("S"))
API_addInputAction(g_engine, ROT_H_ACTION, 2, 0)
API_addInputAction(g_engine, ROT_V_ACTION, 3, 0)
API_addInputAction(g_engine, SPRINT_ACTION, 0, LSHIFT_KEY)


function update(dt)
	yaw = yaw + API_getInputActionValue(g_engine, ROT_H_ACTION) * -0.01 * MOUSE_SENSITIVITY;
	pitch = pitch + API_getInputActionValue(g_engine, ROT_V_ACTION) * -0.01 * MOUSE_SENSITIVITY;
	
	local PITCH_LIMIT = 0.7
	
	if pitch > PITCH_LIMIT then pitch = PITCH_LIMIT end
	if pitch < -PITCH_LIMIT then pitch = -PITCH_LIMIT end
	
	local speed = PLAYER_SPEED
	
	if API_getInputActionValue(g_engine, SPRINT_ACTION) > 0 then
		speed = speed * 3
	end
	
	API_setEntityLocalRotation(g_universe_context, CAMERA_ENTITY, 1, 0, 0, pitch)
	
	API_setEntityRotation(g_universe, this, 0, 1, 0, yaw);
	
	local scene = API_getScene(g_universe_context, "physics");
	if API_getInputActionValue(g_engine, LEFT_ACTION) > 0 then
		local v = API_multVecQuat(-speed, 0, 0, 0, 1, 0, yaw)
		API_moveController(scene, cmp, v[0], v[1], v[2], dt)
	end
	if API_getInputActionValue(g_engine, RIGHT_ACTION) > 0 then
		local v = API_multVecQuat(speed, 0, 0, 0, 1, 0, yaw)
		API_moveController(scene, cmp, v[0], v[1], v[2], dt)
	end
	if API_getInputActionValue(g_engine, FORWARD_ACTION) > 0 then
		local v = API_multVecQuat(0, 0, -speed, 0, 1, 0, yaw)
		API_moveController(scene, cmp, v[0], v[1], v[2], dt)
	end
	if API_getInputActionValue(g_engine, BACK_ACTION) > 0 then
		local v = API_multVecQuat(0, 0, speed, 0, 1, 0, yaw)
		API_moveController(scene, cmp, v[0], v[1], v[2], dt)
	end
end