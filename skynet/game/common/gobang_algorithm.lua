-- 创建时间:2019-02-25
local basefunc = require "basefunc"

local gobang_algorithm = basefunc.class()

-- 解析坐标
function gobang_algorithm.parse_pos(pos)
	local x = math.floor(pos / 1000)
	local y = math.floor(pos%1000 / 10)
	local c = pos % 10
	return {x=x, y=y, c=c}
end
-- 封装坐标
function gobang_algorithm.pack_pos(data)
	local x = data.x
	local y = data.y
	local c = data.c
	return x*1000 + y *10 + c
end

-- 检查操作
function gobang_algorithm.check_operation(x, y, chessboard)
	if chessboard[x][y] == 0 then
		return true
	end
end

function gobang_algorithm.check_win(x, y, chessboard)
	local grid_steps = {
	{1,0},
	{0,1},
	{1,-1},
	{1,1}}
	local chessW = #chessboard
	local chessH = #chessboard[1]
	local chess = chessboard[x][y]
	local chess_cnt = 0
	local chess_line = {}

	local check_line = function(x, y, step_x, step_y)
		local tmp_x = x
		local tmp_y = y

		while true do
			tmp_x = tmp_x + step_x
			tmp_y = tmp_y + step_y
			if tmp_x < 1 or tmp_x > chessW or tmp_y < 1 or tmp_y > chessH then
				return false
			end
			if chessboard[tmp_x][tmp_y] ~= chess then
				return false
			end

			chess_cnt = chess_cnt + 1
			table.insert(chess_line, {tmp_x, tmp_y})
		end
	end

	local lines = {}
	for i = 1, 4 do
		chess_line = {{x,y}}
		chess_cnt = 1
		check_line(x, y, grid_steps[i][1], grid_steps[i][2])
		check_line(x, y, -grid_steps[i][1], -grid_steps[i][2])
		if chess_cnt >= 5 then
			lines[#lines + 1] = basefunc.deepcopy(chess_line)
		end
	end
	if #lines > 0 then
		return true,lines
	else
		return false
	end
end

-- 棋子数据结构
-- 颜色 1黑 2白
-- color
-- 行列
-- row
-- column

return gobang_algorithm





