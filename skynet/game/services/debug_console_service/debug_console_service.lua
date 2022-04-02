--
-- Author: wss
-- Date: 2019/1/19
-- Time: 23:33
-- 说明：调试控制 中心服务
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"
require "normal_enum"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local loadstring = rawget(_G, "loadstring") or load


---- 打印某个服务的data数据
function CMD.get_service_debug_data( service_id , _name, ...)
	local ret = nil

	---- 中心服务调用
	if DATA.service_config[service_id] then
		ret = skynet.call( DATA.service_config[service_id] , "lua", "return_data_dump_str" , _name , ... )
	else
		ret = nodefunc.call( service_id , "return_data_dump_str" , _name , ... )
	end
	
	return ret
end

---- 获取玩家的 具体游戏信息
function CMD.get_player_debug_game_info(player_id)

	local ret  = nodefunc.call( player_id , "get_player_game_info" )

	if ret then
		return ret
	else
		return nil , 1
	end
end





----- 强行杀掉某个房间的 桌子
function CMD.force_break_room_table( room_id , t_num )
	local ret = nodefunc.call( room_id , "force_break_game" , t_num )

	return ret == 0 and 0 or 1
end

-----------------------------------------------------
local function get_gaming_player_id(out_match_players,out_table_players,players) 
    local p_id={}
    if players then

      for _,id in pairs(players) do
          local f=true
          if out_match_players then
            for _,_id in pairs(out_match_players) do
              if _id==id then
                f=false
                break
              end
            end
          end
          if f then
            if out_table_players then
              for _,_id in pairs(out_table_players) do
                if _id==id then
                  f=false
                  break
                end
              end
            end
          end
          if f then
            p_id[#p_id+1]=id
          end
      end
    end
    return p_id
end
---- 查看比赛 里面 所有还在游戏的玩家id
function CMD.get_match_gaming_id(service_id)
  --local data= CMD.get_service_debug_data( service_id,"DATA")

  local out_match_players = nodefunc.call( service_id , "return_data_dump_vec" , "DATA","out_match_players" ) -- CMD.get_service_debug_data( service_id,"DATA","out_match_players")
  local out_table_players = nodefunc.call( service_id , "return_data_dump_vec" , "DATA","out_table_players" )
  local players = nodefunc.call( service_id , "return_data_dump_vec" , "DATA","players" )

  --if data and type(data)=="table" then
  local ids = nil

  if out_match_players and type(out_match_players) == "table" and out_table_players and type(out_table_players) == "table"
  	and players and type(players) == "table" then
  	  ids = get_gaming_player_id(out_match_players,out_table_players,players)
  end
    if ids then
	    return ids
	else
	  	--end
	  	return nil,1
	end
end

function CMD.start(_service_config)
	DATA.service_config = _service_config
	
end

-- 启动服务
base.start_service()