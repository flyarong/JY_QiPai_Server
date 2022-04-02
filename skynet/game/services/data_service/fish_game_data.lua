--
-- Author: yy
-- Date: 2018-9-6 20:44:19
-- 说明：普通比赛场的数据存储
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
require "data_func"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECTED = {}


-- 初始化比赛数据
function PROTECTED.init_data()


end



function base.CMD.query_fish_game_player_data(_player_id,_game_id)

	local sql = string.format("select * from fish_game_player_data where player_id='%s' and game_id=%s;"
								,_player_id,_game_id)

	local fish_game_player_data = base.DATA.db_mysql:query(sql)
	if( fish_game_player_data.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( fish_game_player_data )))
		return false
	end

	local sql = string.format("select * from fish_game_player_reward_data where player_id='%s' and game_id=%s;"
								,_player_id,_game_id)

	local fish_game_player_reward_data = base.DATA.db_mysql:query(sql)
	if( fish_game_player_reward_data.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( fish_game_player_reward_data )))
		return false
	end


	local sql = string.format("select * from fish_game_player_wave_data where player_id='%s' and game_id=%s;"
								,_player_id,_game_id)

	local fish_game_player_wave_data = base.DATA.db_mysql:query(sql)
	if( fish_game_player_wave_data.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( fish_game_player_wave_data )))
		return false
	end

	return {
			player_data = fish_game_player_data,
			player_reward_data = fish_game_player_reward_data,
			player_wave_data = fish_game_player_wave_data
		}

end




function base.CMD.save_fish_game_player_data(_data)
	
	-- 写入数据库
	base.DATA.sql_queue_slow:push_back(
		PUBLIC.format_sql([[
								SET @_player_id = %s;
								SET @_game_id = %s;
								SET @_laser_data = %s;
								SET @_real_all_fj = %s;
								SET @_real_laser_bc = %s;
								insert into fish_game_player_data
								(player_id,game_id,laser_data,real_all_fj,real_laser_bc)
								values(@_player_id,@_game_id,@_laser_data,@_real_all_fj,@_real_laser_bc)
								on duplicate key update
								laser_data = @_laser_data,
								real_all_fj = @_real_all_fj,
								real_laser_bc = @_real_laser_bc;]]
								,_data.player_data.player_id
								,_data.player_data.game_id
								,_data.player_data.laser_data
								,_data.player_data.real_all_fj
								,_data.player_data.real_laser_bc
	))

	for k,v in pairs(_data.player_wave_data) do
		
		base.DATA.sql_queue_slow:push_back(
			PUBLIC.format_sql([[
									SET @_player_id = %s;
									SET @_game_id = %s;
									SET @_pao_lv = %s;
									SET @_all_times = %s;
									SET @_cur_times = %s;
									SET @_store_value = %s;
									SET @_is_zheng = %s;
									SET @_bd_factor = %s;
									insert into fish_game_player_wave_data
									(player_id,game_id,pao_lv,all_times,cur_times,store_value,is_zheng,bd_factor)
									values(@_player_id,@_game_id,@_pao_lv,@_all_times,@_cur_times,@_store_value,@_is_zheng,@_bd_factor)
									on duplicate key update
									all_times = @_all_times,
									cur_times = @_cur_times,
									store_value = @_store_value,
									is_zheng = @_is_zheng,
									bd_factor = @_bd_factor;]]
									,v.player_id
									,v.game_id
									,v.pao_lv
									,v.all_times
									,v.cur_times
									,v.store_value
									,v.is_zheng
									,v.bd_factor
		))

	end

	for k,v in pairs(_data.player_reward_data) do
		
		base.DATA.sql_queue_slow:push_back(
			PUBLIC.format_sql([[
									SET @_player_id = %s;
									SET @_game_id = %s;
									SET @_pao_lv = %s;
									SET @_all_fj = %s;
									SET @_store_fj = %s;
									SET @_xyBuDy_fj = %s;
									SET @_laser_bc_fj = %s;
									SET @_dayu_fj = %s;
									SET @_act_fj = %s;
									insert into fish_game_player_reward_data
									(player_id,game_id,pao_lv,all_fj,store_fj,xyBuDy_fj,laser_bc_fj,dayu_fj,act_fj)
									values(@_player_id,@_game_id,@_pao_lv,@_all_fj,@_store_fj,@_xyBuDy_fj,@_laser_bc_fj,@_dayu_fj,@_act_fj)
									on duplicate key update
									all_fj = @_all_fj,
									store_fj = @_store_fj,
									xyBuDy_fj = @_xyBuDy_fj,
									laser_bc_fj = @_laser_bc_fj,
									dayu_fj = @_dayu_fj,
									act_fj = @_act_fj;]]
									,v.player_id
									,v.game_id
									,v.pao_lv
									,v.all_fj
									,v.store_fj
									,v.xyBuDy_fj
									,v.laser_bc_fj
									,v.dayu_fj
									,v.act_fj
		))
	end

end



function base.CMD.add_fish_game_race_player_log(_player_id,_game_id,_log)

	local sql = string.format([[
								insert into fish_game_race_player_log 
								values(NULL,'%s',%s,'%s','%s','%s','%s','%s','%s',FROM_UNIXTIME(%u));
								]]
								,_player_id
								,_game_id
								,_log.bullet_assets
								,_log.bullet_info
								,_log.return_bullet_assets
								,_log.return_bullet_info
								,_log.fish_dead_assets
								,_log.fish_dead_info
								,os.time()
								)

	base.DATA.sql_queue_slow:push_back(sql)

end





return PROTECTED