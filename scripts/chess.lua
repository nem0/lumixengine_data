-- MIT license 


function toWorldPos(i, j, selected)
	local x = -3.5 + (i - 1)
	local z = -3.5 + (j - 1)
	local y = 0.36
	if selected then
		y = 2
	end
	return {x, y, z}
end


function round(num)
  return math.floor(num + 0.5)
end


function fromWorld(x, z)
	local i = round(x + 1 + 3.5)
	local j = round(z + 1 + 3.5)
	return i, j
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
local selected_piece = nil
local is_black_turn = false

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
		board[j][i] = piece
		piece.x = i
		piece.y = j
		piece.entity = Engine.createEntityEx(g_engine, g_universe, 
		{
			position = toWorldPos(i, j),
			renderable = {
				Source = "models/manmade/chessboard/pawn.msh"
			}
		})
	end
end
	
-- cursor
local cursor = {}
cursor.pos = {0, 0, 0}
cursor.entity = Engine.createEntityEx(g_engine, g_universe,
{
	position = cursor.pos,
	renderable = {
		Source = "models/utils/cube/cube.msh"
	}
})

local LEFT_MOUSE_BUTTON = 1
local X_ACTION = 0
local Y_ACTION = 1
local SELECT_ACTION = 2
Engine.addInputAction(g_engine, X_ACTION, 2, 0, -1)
Engine.addInputAction(g_engine, Y_ACTION, 3, 0, -1)
Engine.addInputAction(g_engine, SELECT_ACTION, 1, LEFT_MOUSE_BUTTON, -1)


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
	board[piece.y][piece.x] = nil
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


function addMove(moves, piece, dx, dy)
	local move = {}
	move.piece = piece
	move.x = piece.x + dx
	move.y = piece.y + dy
	table.insert(moves, move)
end


function gatherMoves(piece, moves)
	local can_go_back = false
	if piece.y > 1 and piece.x > 1 then
		if board[piece.y - 1][piece.x - 1] == nil then
			addMove(moves, piece, -1, -1)
		elseif piece.y > 2 and piece.x > 2 and board[piece.y - 2][piece.x - 2] == nil  and board[piece.y - 1][piece.x - 1].is_white then
			addMove(moves, piece, -2, -2)
		end
	end
	if can_go_back and piece.y < 8 and piece.x < 8 then
		if board[piece.y + 1][piece.x + 1] == nil then
			addMove(moves, piece, 1, 1)
		elseif piece.y < 7 and piece.x < 7 and board[piece.y + 2][piece.x + 2] == nil  and board[piece.y + 1][piece.x + 1].is_white then
			addMove(moves, piece, 2, 2)
		end
	end
	if piece.y > 1 and piece.x < 8 then 
		if board[piece.y - 1][piece.x + 1] == nil then
			addMove(moves, piece, 1, -1)
		elseif piece.y > 2 and piece.x < 7 and board[piece.y - 2][piece.x + 2] == nil and board[piece.y - 1][piece.x + 1].is_white then
			addMove(moves, piece, 2, -2)
		end
	end
	if can_go_back and piece.y < 8 and piece.x > 1 then 
		if board[piece.y + 1][piece.x - 1] == nil then
			addMove(moves, piece, -1, 1)
		elseif piece.y < 7 and piece.x > 2 and board[piece.y + 2][piece.x - 2] == nil and board[piece.y + 1][piece.x - 1].is_white then
			addMove(moves, piece, -2, 2)
		end
	end
end


function getBestMove(moves)
	local best_move = 1;
	local best_move_value = 0;
	for i = 1, #moves do
		local move = moves[i]
		if move.piece.x - move.x > 1 or move.piece.x -move.x < -1 then
			return moves[i]
		elseif move.x == 1 or move.y == 1 or move.x == 8 or move.y == 8 then
			if best_move_value == 0 then
				best_move_value = 1
				best_move = i
			end
		else
			if best_move_value == 0 then
				best_move_value = 1
				best_move = i
			end
		end
	end
	return moves[best_move]
end


function doAITurn()
	moves = {}
	for i = 1, #black_pieces do
		gatherMoves(black_pieces[i], moves)
	end
	local best_move = getBestMove(moves)
	
	Engine.logError("AI moves from " .. best_move.piece.x .. ", " .. best_move.piece.y .. " to " .. best_move.x .. ", " .. best_move.y)
	
	if not move(best_move.piece, best_move.x, best_move.y) then
		Engine.logError("move faield")
	end
end


function move(piece, x, y)
	if x < 1 or y < 1 or x > 8 or y > 8 then return false end
	if board[y][x] ~= nil then return false end
	if piece.is_white and piece.y > y then return false end
	if not piece.is_white and piece.y < y then return false end

	local is_valid_move = (piece.x - x == 1 or piece.x - x == -1) and (piece.y - y == 1 or piece.y - y == -1)
	local jump_piece = nil
	if (piece.x - x == 2 or piece.x - x == -2) and (piece.y - y == 2 or piece.y - y == -2) then
		jump_piece = board[(piece.y + y) / 2][(piece.x + x) / 2]
		if jump_piece and jump_piece.is_white ~= piece.is_white then
			is_valid_move = true
		end
	end
	
	if is_valid_move then
		board[piece.y][piece.x] = nil
		piece.x = x;
		piece.y = y;
		board[y][x] = piece
		Engine.setEntityPosition(g_universe, piece.entity, toWorldPos(x, y))
		
		if jump_piece then
			destroyPiece(jump_piece)
		end
		return true
	end
end


function click()
	local i,j = fromWorld(cursor.pos[1], cursor.pos[3])
	
	if selected_piece then
		if move(selected_piece, i, j) then
			selected_piece = nil
			doAITurn()
		end
		return
	end
	
	local piece = board[j][i]
	
	if not piece or not piece.is_white then return end
	
	if piece == selected_piece then return end
	
	if piece then
		if selected_piece ~= nil then
			Engine.setEntityPosition(g_universe, selected_piece.entity, toWorldPos(selected_piece.x, selected_piece.y))
		end
		
		selected_piece = piece
		Engine.setEntityPosition(g_universe, selected_piece.entity, toWorldPos(i, j, true))
	end
end


function update(dt)
	local SPEED = 0.03
	local x = Engine.getInputActionValue(g_engine, X_ACTION) * SPEED
	local y = Engine.getInputActionValue(g_engine, Y_ACTION) * SPEED
	
	if Engine.getInputActionValue(g_engine, SELECT_ACTION) > 0 then
		click()
	end
	
	cursor.pos[1] = cursor.pos[1] - x
	cursor.pos[3] = cursor.pos[3] - y
	
	if cursor.pos[1] < -3.5 then cursor.pos[1] = -3.5 end
	if cursor.pos[1] > 3.5 then cursor.pos[1] = 3.5 end
	if cursor.pos[3] < -3.5 then cursor.pos[3] = -3.5 end
	if cursor.pos[3] > 3.5 then cursor.pos[3] = 3.5 end
	
	Engine.setEntityPosition(g_universe, cursor.entity, cursor.pos)
end