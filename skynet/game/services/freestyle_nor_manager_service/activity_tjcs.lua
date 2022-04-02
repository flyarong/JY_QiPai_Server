--[[
	-- 天降财神相关
--]]
local base=require "base"
local nodefunc = require "nodefunc"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local PROTECTED = {}

DATA.tjcs_activity_id = 0
---- 天降财神出现的间隔局数
DATA.tjcs_show_round_delay = nil
---- 当前已经经过的轮数
DATA.tjcs_now_round = 0
---- 奖励
DATA.tjcs_award = nil
---- 是否出现财神
DATA.is_show_caishen = false

---- 天降财神活动启动，参数:round为每隔多少局出现一次财神
function CMD.freestyle_activity_tjcs_begin( activity_id , round , award)
	DATA.tjcs_activity_id = activity_id
	DATA.tjcs_show_round_delay = round or 9999
	DATA.tjcs_now_round = 0
	DATA.tjcs_award = award
end

---- 天降财神活动关闭，参数:round为每隔多少局出现一次财神
function CMD.freestyle_activity_tjcs_end( )
	DATA.tjcs_activity_id = 0
	DATA.tjcs_show_round_delay = nil
	DATA.tjcs_now_round = 0
	DATA.tjcs_award = nil
end

---- 每次开局
function MSG.freestyle_game_begin()
	DATA.tjcs_now_round = DATA.tjcs_now_round + 1
	if DATA.tjcs_show_round_delay and DATA.tjcs_now_round > DATA.tjcs_show_round_delay then
		DATA.tjcs_now_round = 0
		DATA.is_show_caishen = true
	end
	DATA.is_show_caishen = false
end

function PROTECTED.init()
	DATA.msg_dispatcher:register(MSG,MSG)

end


return PROTECTED
