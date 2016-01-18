-- MIT license 


function toWorldPos(i, j)
	local x = -3.5 + (i - 1)
	local y = -3.5 + (j - 1)
	return {x, 0, y}
end


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
for side = 1,2 do
	for i = 1, 8 do
		local piece = {}
		local j = i % 2 == 0 and 2 or 1
		if side == 1 then
			piece.is_white = true
			white_pieces[i] = piece
		else
			piece.is_white = false
			black_pieces[i] = piece
			j = i % 2 == 0 and 8 or 7
		end
		piece.entity = Engine.createEntity(g_universe)
		board[j][i] = piece
		piece.x = i
		piece.y = j
		Engine.setEntityPosition(g_universe, piece.entity, toWorldPos(i, j))
		piece.cmp = Engine.createComponent(g_scene_renderer, "renderable", piece.entity)
		local path = "models/manmade/chessboard/pawn.msh"
		Engine.setRenderablePath(g_scene_renderer, piece.cmp, path)
	end
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


table.indexOf = function( t, object )
    if "table" == type( t ) then
        for i = 1, #t do
            if object == t[i] then
                return i
            end
        end
        return -1
    else
            error("table.indexOf expects table for first argument, " .. type(t) .. " given")
    end
end


function destroyPiece(piece)
	local f = function(t, piece)
		local i = table.indexOf(t, piece)
		if i > 0 then 
			table.remove(t, i)
			Engine.setEntityPosition(g_universe, piece.entity, {15, 0, 15})
			--Engine.destroyEntity(piece.entity) -- TODO in engine
		end
	end
	
	f(white_pieces, piece)
	f(black_pieces, piece)
end


function move(piece, x, y)
	if x < 1 or y < 1 or x > 8 or y > 8 then return end
	if board[y][x] ~= nil then return end
	if piece.is_white and piece.y > y then return end
	if not piece.is_white and piece.y < y then return end

	local is_valid_move = (piece.x -x == 1 or piece.x - x == -1) and (piece.y - y == 1 or piece.y - y == -1)
	local jump_piece = nil
	if (piece.x -x == 2 or piece.x - x == -2) and (piece.y - y == 2 or piece.y - y == -2) then
		jump_piece = board[(piece.y + y) / 2][(piece.x + x) / 2]
		if jump_piece and jump_piece.is_white ~= piece.is_white then
			is_valid_move = true
		end
	end
	
	if is_valid_move then
		board[piece.y][piece.x] = nil
		piece.x = x;
		piece.y = y;
		board[x][y] = piece
		Engine.setEntityPosition(g_universe, piece.entity, toWorldPos(x, y))
		
		if jump_piece then
			destroyPiece(jump_piece)
		end
	end
end


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