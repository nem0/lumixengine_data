local board = {}
for j = 1,8 do
	board[j] = {}
	for i = 1,8 do
		board[j][i] = nil
	end
end

local white_pieces = {}
local black_pieces = {}
local cursor

--pieces
for i = 1, 8 do
	local piece = {}
	white_pieces[i] = piece
	piece.entity = Engine.createEntity(g_universe)
	local x = -3.5 + (i - 1)
	local y = i % 2 == 0 and -3.5 or -2.5
	local j = i % 2 == 0 and 1 or 2
	board[j][i] = piece
	Engine.setEntityPosition(g_universe, piece.entity, {x, 0, y})
	piece.cmp = Engine.createComponent(g_scene_renderer, "renderable", piece.entity)
	local path = "models/manmade/chessboard/pawn.msh"
	Engine.setRenderablePath(g_scene_renderer, piece.cmp, path)
end

-- cursor
cursor = {}
cursor.entity = Engine.createEntity(g_universe)
cursor.pos = {0, 0, 0}
Engine.setEntityPosition(g_universe, cursor.entity, cursor.pos)
cursor.cmp = Engine.createComponent(g_scene_renderer, "renderable", cursor.entity)
local path = "models/utils/cube/cube.msh"
Engine.setRenderablePath(g_scene_renderer, cursor.cmp, path)

local X_ACTION = 0
local Y_ACTION = 1
Engine.addInputAction(g_engine, X_ACTION, 2, 0, -1)
Engine.addInputAction(g_engine, Y_ACTION, 3, 0, -1)


function update(dt)
	local SPEED = 0.1
	local x = Engine.getInputActionValue(g_engine, X_ACTION) * SPEED
	local y = Engine.getInputActionValue(g_engine, Y_ACTION) * SPEED
	
	cursor.pos[1] = cursor.pos[1] - x
	cursor.pos[3] = cursor.pos[3] - y
	
	if cursor.pos[1] < -3.5 then cursor.pos[1] = -3.5 end
	if cursor.pos[1] > 3.5 then cursor.pos[1] = 3.5 end
	if cursor.pos[3] < -3.5 then cursor.pos[3] = -3.5 end
	if cursor.pos[3] > 3.5 then cursor.pos[3] = 3.5 end
	
	Engine.setEntityPosition(g_universe, cursor.entity, cursor.pos)
end