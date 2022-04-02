--- 生财之道 ， 数据文件

local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local skynet = require "skynet_plus"
require "data_func"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECT = {}

--************
--nil表示没有 空表表示 数据为空
--************

--数据结构
--[[
  玩家明细
  key 玩家ID
  valuye {
    -- base****************************** 
            my_income_details={   --我的收入明细
              [1] = {
                player_id                 -- 玩家id
                name               -- 玩家昵称
                treasure_type      -- 财富产生类型原因
                treasure_value     -- 产生的财富值
                time               -- 产生的时间
                is_active          -- 是否激活
              }
              ...
            }  
            my_spending_details={  --我的支出明细
              [1] = {
                spending_value       --- 提现的值
                spending_time        --- 提现的时间
              }
              ...
              } 
            
            base_info = {    --- 基本数据

              is_activate_bbsc_profit    -- 是否激活下级bbsc收益
              is_activate_xj_profit      -- 是否激活推广下级玩家奖
              is_activate_tglb_profit    -- 是否激活推广礼包返利
              is_activate_tglb_cache     -- 是否激活推广礼包缓存(下级的推广礼包奖励缓存，买了之后反)
              gjhhr_status               -- 高级合伙人  状态
              is_activate_tgy_tx_profit  -- 是否激活推广员提现
              is_activate_bisai_profit   -- 是否比赛奖

              total_get_award  --总共已得金额
              all_son_count  --我所有的下级数量
			  
              -- is_active_tglb1_profit --我是否激活推广礼包1收益,这个不记数据库，从购买记录拿
              --- add by wss
              goldpig_profit_cache    -- 未领取的金猪礼包缓存值
            }
          
    
            --- 玩家给邀请人产生的主信息
            my_main_info_for_parent={ --关键信息  根据客户端界面层次决定
                id                  --id8619714
                
                name             --我的名字
                logined       --登录状态 是否登录过 0 未登录
                my_all_gx=0         --我对邀请人的总贡献
                register_time     --我的注册时间
                last_login_time     --最后登录时间
            }
    -- base******************************


    --- 玩家给邀请人产生的详情信息
    my_deatails_info_for_parent={  --我对邀请人的贡献的详细数据  根据客户端界面层次决定
        --my_is_buy_tgli=0 --我是否购买过推广礼包
        my_tgli_gx=0 --我对邀请人的推广礼包贡献

        my_bbsc_gx=0 --我对邀请人的步步生财贡献
        my_vip_lb_gx = 0   --我对邀请人的vip礼包的贡献

        my_bbsc_progress=0 --我的步步生财进度
      }
   
    my_contribute_details_for_parent={  --我对邀请人的明细
      [1] = {
        treasure_type      -- 财富产生类型原因
        treasure_value     -- 产生的财富值
        time               -- 产生的时间
        is_active          -- 是否激活
      }
      ...
    }
      
    --控制数据 ************
    online_num = 1          --- 上线次数标志
    online_num_clear = 1    --- 上线次数标志的减少次数,第一波创建出来的不要清理，避免错误
    is_online     --- 是否在线

  }
--]]
DATA.player_details = DATA.player_details or {
  
}
--[[
        玩家的人物关系     
        key=player_id  
        value={
				parent_id,
        is_gjhhr,
        
        --下级数量
        son_count
        }
--]]
DATA.player_relation = DATA.player_relation or {
  
}
--[[
  玩家邀请的人的数据  
  key=playerID  
  value={ }  --数组   内容是 DATA.player_details[p_ID].my_main_info_for_yqr

--]]
DATA.player_all_son_data = DATA.player_all_son_data or {
  

}

---- 玩家在线次数清理周期,单位秒
DATA.online_num_clear_delay = 24*3600

---- 当前数据保存在内存中的玩家的数量
DATA.cache_data_player_num = 0
---- 最大缓存数量，大于之后清理数据
DATA.max_cache_data_player_num = 200000
---- 清理缓存 到指定的数量
DATA.clear_cache_data_player_num = 100000

---------- 查询次数限制
DATA.query_num_limit = 100
DATA.now_query_num = 0



-- 查询数据，返回结果集，出错则返回 nil
local function query_data(_sql)

	local ret = skynet.call(DATA.service_config.data_service,"lua","db_query",_sql)
	if( ret.errno ) then
		print(string.format("query_data sql error: sql=%s\nerr=%s\n",_sql,basefunc.tostring( ret )))
		return nil
  end
  
	
	return ret
end

--- 把sql插入队列中
local function db_exec(_sql , _queue_name)
  skynet.send(DATA.service_config.data_service,"lua","db_exec",_sql , _queue_name)
end

function PUBLIC.load_player_relation()

	DATA.player_relation = {}
	
	local ret = query_data("select * from sczd_relation_data")
	
	if ret then

		for i,v in ipairs(ret) do
			DATA.player_relation[v.id] = v
		end
  end
  --dump(DATA.player_relation,"xxxxxxxxxxxxxxxxxxx DATA.player_relation loaded:")
end
--[[
  data={
	parent_id=xx
	is_tgy=xx
  son_count  --包含自己
  }
--]]
function PUBLIC.add_player_relation(player_id,data)
    if data and not DATA.player_relation[player_id] then
      DATA.player_relation[player_id]=data
      DATA.player_relation[player_id].son_count=1
      DATA.player_relation[player_id].is_tgy=1

      PUBLIC.update_son_count(CMD.query_all_parents(player_id),1)
      ----  --写入数据库 

      --print("xxxxxxxxxxxxxxxxxxxxxxxxxx add_player_relation:",player_id,basefunc.tostring(data))
      skynet.call(DATA.service_config.data_service,"lua","db_exec",string.format(
        [[insert into sczd_relation_data(id,parent_id,is_tgy,is_gjhhr,son_count) values('%s',%s,1,0,1) on duplicate key update
                parent_id = %s;]]
                ,player_id
                ,PUBLIC.value_to_sql(data.parent_id)
                ,PUBLIC.value_to_sql(data.parent_id)
      ))


      if data.parent_id then

          --更新父亲的数据   -- ###_test
          if not DATA.player_details[data.parent_id] or not DATA.player_details[data.parent_id].base_info then
            --
            PUBLIC.load_base_info(data.parent_id)
          end

          if DATA.player_details[data.parent_id] and DATA.player_details[data.parent_id].base_info then
              DATA.player_details[data.parent_id].base_info.all_son_count = DATA.player_details[data.parent_id].base_info.all_son_count + 1
          end

          --- 加索引,,只要有父亲的这个表，就一定要加
          if DATA.player_all_son_data[data.parent_id] then
            if not DATA.player_details[player_id] or not DATA.player_details[player_id].my_main_info_for_parent then
              PUBLIC.load_base_info(player_id)
            elseif DATA.player_details[player_id] and DATA.player_details[player_id].my_main_info_for_parent then
              DATA.player_all_son_data[data.parent_id][#DATA.player_all_son_data[data.parent_id] + 1] = DATA.player_details[player_id].my_main_info_for_parent
            end

            --- load_base_info 里面会自己加一次下面这个引用
            --[[if DATA.player_details[player_id].my_main_info_for_parent then
              DATA.player_all_son_data[data.parent_id][#DATA.player_all_son_data[data.parent_id] + 1] = DATA.player_details[player_id].my_main_info_for_parent
            end--]]
          end

          db_exec(string.format( "update sczd_player_base_info set all_son_count = all_son_count + 1 where player_id = '%s';", data.parent_id) )

      end
      --sczd_change_parent_log   
      skynet.call(DATA.service_config.data_service,"lua","db_exec",PUBLIC.format_sql("insert into sczd_change_parent_log(player_id,old_parent,new_parent,achievements,tuikuan) values(%s,%s,%s,%s,%s)",player_id,nil,data.parent_id,0,0))
      
      return 0
    end
    return 1
end

function PUBLIC.update_son_count(parents,num)
    if parents then
          --dump({parents,DATA.player_relation},"xxxxxxxxxxxxxxxxx update_son_count parents:")
          local sqls = {}
          for _,id in pairs(parents) do
            DATA.player_relation[id].son_count=DATA.player_relation[id].son_count + num

            sqls[#sqls + 1] = string.format("update sczd_relation_data set son_count=%d where id='%s';",
                  DATA.player_relation[id].son_count,id)
          end

          if next(sqls) then
            skynet.send(DATA.service_config.data_service,"lua","db_exec",table.concat(sqls,"\n"))
          end
    end
end

function PUBLIC.update(player_id,data)
end

function PUBLIC.load_base_info(player_id , is_not_load_main_info)
	
	if not player_id then 
		return 
	end

	if DATA.player_details[player_id] and DATA.player_details[player_id].base_info then
		return
	end

	-- base_info
	local sql_str = string.format( [[
                                  set @total_get_award = 0;
                                  set @is_activate_bbsc_profit = 0;
                                  set @is_activate_xj_profit = 0;
                                  set @is_activate_tglb_profit = 0;
                                  set @is_activate_tglb_cache = 0;
                                  set @is_activate_tgy_tx_profit = 1;
                                  set @is_activate_bisai_profit = 0;
                                  set @gjhhr_status = '';
                                  set @my_all_gx = 0;
                                  set @all_son_count = 0;
                                  set @goldpig_profit_cache = 0;

                                  # set @is_active_tglb1_profit = 0;
                              
                                  call get_sczd_base_info('%s' 
                                    , @total_get_award 
                                    , @is_activate_bbsc_profit 
                                    , @is_activate_xj_profit 
                                    , @is_activate_tglb_profit
                                    , @is_activate_tglb_cache 
                                    , @is_activate_tgy_tx_profit
                                    , @is_activate_bisai_profit
                                    , @gjhhr_status
                                    , @my_all_gx
                                    , @all_son_count
                                    , @goldpig_profit_cache);

                                  select @total_get_award
                                  ,@is_activate_bbsc_profit
                                  ,@is_activate_xj_profit
                                  ,@is_activate_tglb_profit
                                  ,@is_activate_tglb_cache 
                                  ,@is_activate_tgy_tx_profit
                                  ,@is_activate_bisai_profit
                                  ,@gjhhr_status
                                  ,@my_all_gx
                                  ,@all_son_count
                                  ,@goldpig_profit_cache;
                                  ]] , player_id)


	local ret = query_data( sql_str )

  if not ret then
    print("load_base_info not ret!!!",player_id , is_not_load_main_info)
		return
  else
    ret = ret[#ret]
	end	

  local player_data = skynet.call(DATA.service_config.data_service,"lua","get_player_info",player_id)
  local player_info = player_data.player_info
  local player_register = player_data.player_register
  local player_last_login_time = skynet.call(DATA.service_config.data_service,"lua","get_player_status_time",player_id)

  local player_register_time = 1514736000    --- 防止报错，用2018-1-1 0:0:0 初始

  if player_register and player_register.register_time then
      player_register_time = basefunc.get_time_by_date(player_register.register_time)
  end

  dump(player_data , "----------------------------- player_data")

  ------ 
  if DATA.player_details[player_id] and DATA.player_details[player_id].base_info then
    print("end sql , have data !!!!!!!!!!" , player_id , is_not_load_main_info)
    return 
  end

  local _d = DATA.player_details[player_id] or {}
  DATA.player_details[player_id] = _d

	if ret[1] then
    local data = ret[1]
    if not _d.base_info then
		  _d.base_info = _d.base_info or {     --- {
        is_activate_bbsc_profit = data["@is_activate_bbsc_profit"],
        is_activate_xj_profit = data["@is_activate_xj_profit"],
        is_activate_tglb_profit = data["@is_activate_tglb_profit"],
        is_activate_tglb_cache = data["@is_activate_tglb_cache"],
        is_activate_tgy_tx_profit = data["@is_activate_tgy_tx_profit"],
        is_activate_bisai_profit = data["@is_activate_bisai_profit"],

        gjhhr_status = data["@gjhhr_status"],
        total_get_award = data["@total_get_award"],
        all_son_count = data["@all_son_count"],
        --is_active_tglb1_profit = data["@is_active_tglb1_profit"],
        goldpig_profit_cache = data["@goldpig_profit_cache"],
      }
    end 

    if not _d.my_main_info_for_parent and not is_not_load_main_info then
      _d.my_main_info_for_parent = _d.my_main_info_for_parent or {         -- or {
        id = player_id,
        name = player_info and player_info.name or "x" , --data["@name"],
        logined = player_info and player_info.logined or 0 ,--data["@logined"],
        my_all_gx = data["@my_all_gx"],
        register_time = player_register_time , --data["@register_time"],
        last_login_time = player_last_login_time and player_last_login_time or nil,   --data["@last_login_time"],
        last_gx_time = 0,
      }

      ---- 父亲的引用关系加上
      local parent_id = DATA.player_relation[player_id] and DATA.player_relation[player_id].parent_id or nil
      if parent_id then
        if DATA.player_all_son_data[parent_id] then
          local data_ref = DATA.player_all_son_data[parent_id] 
          data_ref[#data_ref + 1] = _d.my_main_info_for_parent
        end
      end

    end
	else
		--[[_d.base_info =  {
			is_activate_profit = 0,
			total_get_award = 0,
			all_son_count = 0,
			is_active_tglb1_profit = 0,
		}--]]

	end

  

  DATA.player_details[player_id].online_num = 0
  DATA.player_details[player_id].is_online = false
  DATA.player_details[player_id].online_num_clear = 1

  DATA.cache_data_player_num = DATA.cache_data_player_num + 1

  PUBLIC.check_is_clear_palyer_cache()

end

function PUBLIC.check_relation_is_safe(player_id,parent)

  if not parent then
    return true
  end
  if player_id==parent then
    return false
  end

  if player_id == parent then
    return false
  end

  if  DATA.player_relation[parent] and DATA.player_relation[player_id] then 
      local ps=CMD.query_all_parents(parent)
      if ps then
        for _,id in pairs(ps) do
          if id==player_id then
            return false
          end
        end
      end
      return true
  end
  return false
end
-- 查询我的上级高级合伙人
function PUBLIC.query_frist_gjhhr(player_id)
    if not player_id or not DATA.player_relation[player_id] then
      return nil
    end
    if DATA.player_relation[player_id].is_gjhhr==1  then
        return player_id
    end

    local p_id=player_id
    while p_id and DATA.player_relation[p_id] do
      if DATA.player_relation[p_id].is_gjhhr==1  then
        return p_id
      end 
      p_id=DATA.player_relation[p_id].parent_id
    end

    return nil
end

--[[
c_or_d_status 1 or 0
base_info
    real_name --真实姓名
    phone  --电话
    weixin --微信号码
    shengfen --省份
    chengshi --城市
    qu      --区
gjhhr_status  nor or freeze    
--]]
function PUBLIC.change_player_gjhhr_status(player_id,c_or_d_status,gjhhr_status,base_info,op_player)
    if not DATA.player_relation[player_id] then

      --dump({DATA.player_relation,player_id,c_or_d_status,gjhhr_status,base_info,op_player},"xxxxxxxxxxxxxxxxxx change_player_gjhhr_status error:")

      --没有人此人的数据
      return 1004
    end
   
    if base_info then
      skynet.send(DATA.service_config.data_service,"lua","change_player_other_baseinfo",player_id,base_info,op_player)
    end
    local return_status=0
    if c_or_d_status~="normal" then
      local old=DATA.player_relation[player_id].is_gjhhr
      DATA.player_relation[player_id].is_gjhhr=c_or_d_status
      if old~=c_or_d_status then
        
          -- 写入数据库  --sczd_relation_data
          skynet.send(DATA.service_config.data_service,"lua","db_exec",
                  string.format([[insert into sczd_relation_data(id,parent_id,is_tgy,is_gjhhr) value('%s',%s,1,%d)  
                  on duplicate key update is_gjhhr=%d;]],player_id,PUBLIC.value_to_sql(DATA.player_relation[player_id].parent_id),
                  c_or_d_status,c_or_d_status))
        
        local parent_gjhhr=PUBLIC.query_frist_gjhhr(DATA.player_relation[player_id].parent_id)
        if c_or_d_status==1 then
            --通知相关服务 
            return_status=skynet.call(DATA.service_config.sczd_gjhhr_service,"lua","set_new_gjhhr_msg" , player_id,parent_gjhhr,DATA.player_relation[player_id].parent_id,op_player)
        else
           --通知相关服务 
            return_status=skynet.call(DATA.service_config.sczd_gjhhr_service,"lua","delete_gjhhr_msg" , player_id,parent_gjhhr,op_player)
        end

      end
    end
    
    local return_status_1=0
    if DATA.player_relation[player_id].is_gjhhr==1 then
      return_status_1=skynet.call(DATA.service_config.sczd_gjhhr_service,"lua","change_gjhhr_status_msg" , player_id,gjhhr_status,op_player)
    end
    if return_status~=0 and return_status_1~=0 then
      return 4407
    end
    if return_status~=0  then
      return return_status
    end
    if return_status_1~=0  then
      return return_status_1
    end
    return 0
end



function PUBLIC.load_income_details(player_id)

	if not player_id then
		return 
	end

	if DATA.player_details[player_id] and DATA.player_details[player_id].my_income_details then
		return 
	end

  if not DATA.player_details[player_id] or not DATA.player_details[player_id].base_info then
      PUBLIC.load_base_info(player_id)
  end

	local _d = DATA.player_details[player_id] or {}
	DATA.player_details[player_id] = _d

	-- 返回值按倒序排列 最新的在最后 DATA.income_details_max_num
	local ret = query_data(string.format([[
		select a.player_id,b.name,a.treasure_type,a.treasure_value,UNIX_TIMESTAMP(a.time) time,a.is_active from sczd_income_deatails_log a 
		left join player_info b on a.player_id = b.id
		where a.parent_id='%s' order by time desc limit %d
		]],player_id,DATA.income_details_max_num)
	)
	if not ret then
		return 
	end

  dump(ret , "----->>> load_income_details:")

	basefunc.reverse(ret)
	_d.my_income_details = ret
end

--{
--     id                 -- 玩家id
--     name               -- 玩家昵称
--     treasure_type      -- 财富产生类型原因
--     treasure_value     -- 产生的财富值
--     time               -- 产生的时间
--     is_active          -- 是否激活
function PUBLIC.add_income_details(player_id,data)
  if player_id and data then
    if not DATA.player_details[player_id] or not DATA.player_details[player_id].base_info then
      PUBLIC.load_base_info(player_id)
    end
    if not DATA.player_details[player_id].my_income_details then
        PUBLIC.load_income_details(player_id)
    end
    DATA.player_details[player_id].my_income_details[#DATA.player_details[player_id].my_income_details+1]=data

    PUBLIC.check_and_clear_log_data( DATA.player_details[player_id].my_income_details , DATA.income_details_max_num , DATA.income_details_clear_num )

    return 0
  end
  return 1
end

---- 给 金猪礼包任务用的增加收入记录接口
function CMD.add_income_details_goldpig_task(player_id , player_name , contribute_value )
    local data = {
      player_id = player_id,
      name = player_name ,
      treasure_type = 110 ,
      treasure_value = contribute_value,
      time = os.time(),
      is_active = 1 ,
    }

    PUBLIC.add_income_details(player_id , data)

   db_exec(string.format( [[insert into sczd_income_deatails_log(player_id,parent_id,treasure_type,treasure_value,is_active)
  values('%s','%s',%s,%s,%s);]], data.player_id , data.player_id , data.treasure_type , data.treasure_value , data.is_active ) )
   
end

-- my_spending_details={  --我的支出明细
--     spending_value       --- 提现的值
--     spending_time        --- 提现的时间
--   } 
function PUBLIC.load_spending_details(player_id)

	if not player_id then
    return 
  end

  if DATA.player_details[player_id] and DATA.player_details[player_id].my_spending_details then
    return 
  end

  if not DATA.player_details[player_id] or not DATA.player_details[player_id].base_info then
      PUBLIC.load_base_info(player_id)
  end

  local _d = DATA.player_details[player_id] or {}
  DATA.player_details[player_id] = _d

  --local ret = query_data(string.format("select change_value spending_value,UNIX_TIMESTAMP(date) spending_time from player_asset_log where id='%s' and asset_type='cash' and change_value < 0 order by date desc limit %d;",
  --  player_id,DATA.spending_details_max_num))

  local ret1 = query_data(string.format("select money spending_value,UNIX_TIMESTAMP(complete_time) spending_time from player_withdraw where player_id='%s' and asset_type='cash' and src_type = 'game' order by complete_time desc limit %d;",
    player_id,DATA.spending_details_max_num))

  if not ret1 then
    ret1 = {}
  end

  local ret2 = {}
  if #ret1 >= 0 and #ret1 ~= DATA.spending_details_max_num then
    ret2 = query_data(string.format("select money spending_value,UNIX_TIMESTAMP(complete_time) spending_time from player_withdraw_log where player_id='%s' and asset_type='cash' and src_type = 'game' order by complete_time desc limit %d;",
      player_id,DATA.spending_details_max_num - #ret1 ))
  end

--[[  if not ret1 and not ret2 then
    return 
  end--]]
  
  if not ret2 then
    ret2 = {}
  end

  local ret = {}
  for k,v in ipairs(ret1) do
    ret[#ret+1] = v
  end
  for k,v in ipairs(ret2) do
    ret[#ret+1] = v
  end
  

  dump(ret1 , "----->>> load_spending_details1:")
  dump(ret2 , "----->>> load_spending_details1:")
  dump(ret , "----->>> load_spending_details1:")


  -- 返回值按倒序排列 最新的在最后
  basefunc.reverse(ret)

  ---- 提现的值变成负的
  for key,data in ipairs(ret) do
    if data.spending_value then
      data.spending_value = - math.abs(data.spending_value)
    end
  end

  _d.my_spending_details = ret

end

function PUBLIC.add_spending_details(player_id,data)
  if player_id and data then
    if not DATA.player_details[player_id] or not DATA.player_details[player_id].base_info then
       PUBLIC.load_base_info(player_id)
    end
    if not DATA.player_details[player_id].my_spending_details then
        PUBLIC.load_spending_details(player_id)
    end
    DATA.player_details[player_id].my_spending_details[#DATA.player_details[player_id].my_spending_details+1]=data

    PUBLIC.check_and_clear_log_data( DATA.player_details[player_id].my_spending_details , DATA.spending_details_max_num , DATA.spending_details_clear_num )

    return 0
  end
  return 1
end

--[[function PUBLIC.load_base_info(player_id)
  if player_id then
    -- ###_test
    local data=nil   --call
    if data and not DATA.player_details[player_id] then
        DATA.player_details[player_id] = DATA.player_details[player_id] or {}
        DATA.player_details[player_id].base_info =data.base_info or {}
        DATA.player_details[player_id].my_main_info_for_parent =data.my_main_info_for_parent or {}

        DATA.player_details[player_id].online_num = 0
        DATA.player_details[player_id].is_online = false

        DATA.cache_data_player_num = DATA.cache_data_player_num + 1


        PUBLIC.check_is_clear_palyer_cache()
        return 0
    end
  end
  --加载失败
  return 1

end--]]

function PUBLIC.load_my_deatails_info_for_parent(player_id)

	if not player_id then
		return 
	end

	if DATA.player_details[player_id] and DATA.player_details[player_id].my_deatails_info_for_parent then
		return 
	end

	local _d = DATA.player_details[player_id] or {}
	DATA.player_details[player_id] = _d

	local ret = query_data(string.format([[
		select ifnull(a.tglb_contribution_for_parent,0) my_tgli_gx,
		ifnull(a.bbsc_contribution_for_parent,0) my_bbsc_gx,
    ifnull(a.vip_contribution_for_parent,0) my_vip_lb_gx,
    ifnull(b.now_big_step,0) my_bbsc_progress 
		from sczd_activity_info a left join player_stepstep_money b on a.player_id = b.player_id
		where a.player_id = '%s']],player_id))

  dump(ret , "------------->>> load_my_deatails_info_for_parent:")

	if not ret then
		return 
	end

	_d.my_deatails_info_for_parent = ret[1] or
	{
		my_tgli_gx = 0,
		my_bbsc_gx = 0,
    my_vip_lb_gx = 0,
		my_bbsc_progress = 0,
	}
end

function PUBLIC.load_my_contribute_details_for_parent(player_id)

	if not player_id then
		return 
	end

	if DATA.player_details[player_id] and DATA.player_details[player_id].my_contribute_details_for_parent then
		return 
	end

	local _d = DATA.player_details[player_id] or {}
	DATA.player_details[player_id] = _d

	local ret = query_data(string.format([[
		select player_id,treasure_type,treasure_value,UNIX_TIMESTAMP(time) time,is_active from sczd_income_deatails_log
		where player_id='%s' and parent_id = '%s' order by time desc limit %d]],player_id
                                  ,DATA.player_relation[player_id] and DATA.player_relation[player_id].parent_id or ""
                                  ,DATA.income_details_max_num))

	if not ret then
		return 
	end

	-- 返回值按倒序排列 最新的在最后
	basefunc.reverse(ret)
	_d.my_contribute_details_for_parent = _d.my_contribute_details_for_parent or ret

end

function PUBLIC.add_my_contribute_details_for_parent(player_id,data)
    if not DATA.player_details[player_id] or not DATA.player_details[player_id].base_info then
       PUBLIC.load_base_info(player_id)
    end

    local player_data = DATA.player_details[player_id]

    if not player_data.my_contribute_details_for_parent then
      PUBLIC.load_my_contribute_details_for_parent(player_id)
    end
    if player_data.my_contribute_details_for_parent then
      player_data.my_contribute_details_for_parent[#player_data.my_contribute_details_for_parent + 1] = data

      PUBLIC.check_and_clear_log_data( player_data.my_contribute_details_for_parent , DATA.my_contribute_details_for_parent_max_num , DATA.my_contribute_details_for_parent_clear_num )
      
    end
end
--[[--添加团队业绩
function PUBLIC.add_group_achievements(player_id,num)
    if not DATA.player_relation[player_id] then
      return 
    end
    if DATA.player_relation[player_id].is_gjhhr==1 then
        if not DATA.player_details[player_id] then
            PUBLIC.load_base_info(player_id)
        end
        local data=DATA.player_details[player_id]
        if data then
            data.base_info.my_group_achievements=data.base_info.my_group_achievements+num
            --写入数据库   ###_test

        else
            print("error!!!!  add_group_achievements data not exits!!!!!!!! ") 
        end
    end
    if DATA.player_relation[player_id].parent then
        return PUBLIC.add_group_achievements(DATA.player_relation[player_id].parent,num)
    end

end

--添加团队业绩
function PUBLIC.add_group_tuikuan(player_id,num)
    if not DATA.player_relation[player_id] then
      return 
    end
    if DATA.player_relation[player_id].is_gjhhr==1 then
        if not DATA.player_details[player_id] then
            PUBLIC.load_base_info(player_id)
        end
        local data=DATA.player_details[player_id]
        if data then
            data.base_info.my_group_tuikuan=data.base_info.my_group_tuikuan+num
            --写入数据库   ###_test
            
        else
            print("error!!!!  add_group_tuikuan data not exits!!!!!!!! ") 
        end
    end
    if DATA.player_relation[player_id].parent then
        return PUBLIC.add_group_tuikuan(DATA.player_relation[player_id].parent,num)
    end
end
--]]


function PUBLIC.init_cfg()
  --收入明细最大数量
  DATA.income_details_max_num=500
  --收入明细清除数量  当达到这个数量时清除尾部数据 将量级变为income_details_max_num
  DATA.income_details_clear_num=DATA.income_details_max_num*2

  --支出明细最大数量
  DATA.spending_details_max_num=100
  --支出明细清除数量  当达到这个数量时清除尾部数据 spending_details_max_num
  DATA.spending_details_clear_num=DATA.spending_details_max_num*2

  --我对parent的贡献上午明细请求数量
  DATA.my_contribute_details_for_parent_max_num=100
  --我对parent的贡献上午明细请求数量  当达到这个数量时清除尾部数据 my_contribute_details_for_parent_max_num
  DATA.my_contribute_details_for_parent_clear_num=DATA.my_contribute_details_for_parent_max_num*2

end


function PUBLIC.load_player_all_son_data(player_id)
  if DATA.player_all_son_data[player_id] then
    return
  end

  DATA.player_all_son_data[player_id] = {}
  local data_ref = DATA.player_all_son_data[player_id]
  -- @need_code

  local sql_str = string.format( [[
                                  call get_sczd_all_son_main_info('%s');
                                  ]] , player_id )

  local children = query_data( sql_str )
  if not children then
    return
  else
    children = children[1]
  end

  dump(children , "--=-=-=-=--->>> load_player_all_son_data:")

  for key , data in pairs(children) do
    if not DATA.player_details[data.id] or not DATA.player_details[data.id].base_info then
      PUBLIC.load_base_info(data.id , true)
      DATA.player_details[data.id].my_main_info_for_parent = DATA.player_details[data.id].my_main_info_for_parent or {}   -- {}
    else
      if not DATA.player_details[data.id].my_main_info_for_parent then
        DATA.player_details[data.id].my_main_info_for_parent = DATA.player_details[data.id].my_main_info_for_parent or {}  -- {}
      end
     
    end

    local my_main_info_for_parent = DATA.player_details[data.id].my_main_info_for_parent

    my_main_info_for_parent.id = data.id
    my_main_info_for_parent.name = data.name
    my_main_info_for_parent.logined = data.logined
    my_main_info_for_parent.my_all_gx = data.my_all_gx
    my_main_info_for_parent.register_time = data.register_time
    my_main_info_for_parent.last_login_time = data.last_login_time
    --- 最新的贡献时间
    my_main_info_for_parent.last_gx_time = data.last_gx_time


    data_ref[#data_ref + 1] = my_main_info_for_parent

  end
  

end


---- 某个人增加贡献
function PUBLIC.add_palyer_contribute( player_id , change_type , contribut_type , contribute_value )
  print("call PUBLIC.add_palyer_contribute!!",player_id, change_type , contribut_type , contribute_value)
  local now_time = os.time()

  local player_data = DATA.player_details[player_id]
  if not player_data or not player_data.my_main_info_for_parent then
    PUBLIC.load_base_info(player_id)
    player_data = DATA.player_details[player_id]
  end
  
  local parent_id = DATA.player_relation[player_id] and DATA.player_relation[player_id].parent_id or nil

  if parent_id then
    --[[--- 我对上级的总贡献
    player_data.my_main_info_for_parent.my_all_gx = player_data.my_main_info_for_parent.my_all_gx + contribute_value
    player_data.my_main_info_for_parent.last_gx_time = now_time
    --- 我对上级的bbsc贡献
    if not player_data.my_deatails_info_for_parent then
      PUBLIC.load_my_deatails_info_for_parent(player_id)
    end
    if change_type == "bbsc" then
      player_data.my_deatails_info_for_parent.my_bbsc_gx = player_data.my_deatails_info_for_parent.my_bbsc_gx + contribute_value
    elseif change_type == "tglb1" or change_type == "tglb2" then
      player_data.my_deatails_info_for_parent.my_tgli_gx = player_data.my_deatails_info_for_parent.my_tgli_gx + contribute_value
    end--]]
  end
  ------------------- 玩家上级的改变
  print("call PUBLIC.add_palyer_contribute222!!",player_id,parent_id)
  if parent_id then
    if not DATA.player_details[parent_id] or not DATA.player_details[parent_id].base_info then
      PUBLIC.load_base_info(parent_id)
    end 
    local parent_data = DATA.player_details[parent_id]

    dump(DATA.player_details[parent_id] , string.format("-------------- DATA.player_details[%s]",parent_id) )
    
    --- 金猪缓存是否激活
    local is_activate_tglb_cache = 0
    ---- 父亲是否激活相应收益
    local is_active_profit = 0
    if change_type == "bbsc" then
      is_active_profit = parent_data.base_info.is_activate_bbsc_profit 
    elseif change_type == "qys_bisai" then
      is_active_profit = parent_data.base_info.is_activate_bisai_profit 
    elseif change_type == "vip_lb" then
      is_active_profit = parent_data.base_info.is_activate_tglb_profit
    elseif change_type == "tglb1" or change_type == "tglb2" then
      is_active_profit = parent_data.base_info.is_activate_tglb_profit 

      --- 如果激活礼包缓存收益
      is_activate_tglb_cache = parent_data.base_info.is_activate_tglb_cache 
      if is_activate_tglb_cache == 1 then
        parent_data.base_info.goldpig_profit_cache = parent_data.base_info.goldpig_profit_cache + contribute_value

        --- 通知父亲节点，金猪缓存改变
        nodefunc.send(parent_id , "goldpig_profit_cache_change" , parent_data.base_info.goldpig_profit_cache )
      end
    end

    ------------------------- 如果这个下级是bbsc反玩家奖， ---------------------
    if not player_data.my_deatails_info_for_parent then
      PUBLIC.load_my_deatails_info_for_parent(player_id)
    end
    --- 如果玩家奖已经反了，就不返了(这个是处理之前第一天是有效玩家，现在是第二天是有效玩家，避免重复返利)
    if change_type == "bbsc" and contribut_type == DATA.xj_award_bbsc_big_step and player_data.my_deatails_info_for_parent.my_bbsc_gx > 0 then
      is_active_profit = 0
    end
    -------------------------------------------------------------------------------

    ------ 上级权益激活才会有 下级增加数据
    if is_active_profit == 1 then
      --- 我对上级的总贡献
      player_data.my_main_info_for_parent.my_all_gx = player_data.my_main_info_for_parent.my_all_gx + contribute_value
      player_data.my_main_info_for_parent.last_gx_time = now_time
      --- 我对上级的bbsc贡献
      
      if change_type == "bbsc" then
        player_data.my_deatails_info_for_parent.my_bbsc_gx = player_data.my_deatails_info_for_parent.my_bbsc_gx + contribute_value
      elseif change_type == "tglb1" or change_type == "tglb2" then
        player_data.my_deatails_info_for_parent.my_tgli_gx = player_data.my_deatails_info_for_parent.my_tgli_gx + contribute_value
      elseif change_type == "vip_lb" then
        player_data.my_deatails_info_for_parent.my_vip_lb_gx = player_data.my_deatails_info_for_parent.my_vip_lb_gx + contribute_value
      end
    end

    print("call PUBLIC.add_palyer_contribute333!!",player_id,parent_id)

    ----- 只有开启了贡献功能，才能加入日志列表
    if is_active_profit == 1 then
       --- 我对上级的贡献明细
      PUBLIC.add_my_contribute_details_for_parent(player_id,{
          player_id = player_id,
          treasure_type = contribut_type,
          treasure_value = contribute_value,
          time = now_time,
          is_active = is_active_profit,
      })

      PUBLIC.add_income_details(parent_id,{
        player_id = player_id,
        name = player_data.my_main_info_for_parent.name,
        treasure_type = contribut_type,
        treasure_value = contribute_value,
        time = now_time,
        is_active = is_active_profit ,
      })
    end

    print("call PUBLIC.add_palyer_contribute444!!",player_id,parent_id)
    --- 给父亲 加钱并通知父亲
    if is_active_profit == 1 then
      skynet.send(DATA.service_config.data_service,"lua","change_asset_and_sendMsg",
                    parent_id, PLAYER_ASSET_TYPES.CASH ,
                    contribute_value, change_type .. "_rebate" , contribut_type )

      
    end

    query_data(string.format("call add_sczd_palyer_contribute('%s','%s',%s,%s,'%s',%s,%s);",
      player_id,parent_id, is_active_profit , is_activate_tglb_cache ,change_type, contribut_type , contribute_value 
    ))

    print("call PUBLIC.add_palyer_contribute555!!",player_id,parent_id)
  end
  

end

---- 减玩家的在线权重
function PUBLIC.reduce_player_online_num()
  for palyer_id , data in pairs(DATA.player_details) do
    data.online_num = data.online_num - 1
    data.online_num_clear = data.online_num_clear + 1
  end
end

---- 检查是否需要清理玩家数据缓存
function PUBLIC.check_is_clear_palyer_cache()
  if DATA.cache_data_player_num > DATA.max_cache_data_player_num then
    CMD.clear_player_cache()
  end
end

---- 清理玩家数据缓存,target_num 如果有，必须清理到指定数量
function CMD.clear_player_cache( )
  print("-----------------------  clear_player_cache")
  local delete_vec = {}
  local tag = {}

  for player_id , data in pairs(DATA.player_details) do
    if data.online_num < 0 and not data.is_online and data.online_num_clear > 1 then
        delete_vec[#delete_vec + 1] = player_id
        tag[player_id] = true
    end
  end
  
  ---- 如果清了，数据还多，就直接清掉不在线的
  if DATA.cache_data_player_num - #delete_vec > DATA.clear_cache_data_player_num then
    local other_clear_num = DATA.cache_data_player_num - #delete_vec - DATA.clear_cache_data_player_num

    local other_num = 0
    for player_id , data in pairs(DATA.player_details) do
      if not tag[player_id] and not data.is_online and data.online_num_clear > 1 then
        delete_vec[#delete_vec + 1] = player_id

        other_num = other_num + 1
        if other_num > other_clear_num then
          break
        end

        tag[player_id] = true
      end
    end
  end

  --- 删除
  for key,player_id in ipairs(delete_vec) do
    ---- 删掉 父节点，所有子数据中，自己的引用
    local parent_id = DATA.player_relation[player_id] and DATA.player_relation[player_id].parent_id or nil
    local is_parent_data_ptr = false
    if parent_id and DATA.player_all_son_data[parent_id] then
      for k,data in pairs(DATA.player_all_son_data[parent_id]) do
        if data.id == player_id then
          --table.remove(DATA.player_all_son_data[parent_id] , k)
          is_parent_data_ptr = true
          break
        end
      end
    end

    --- 如果有父亲节点 引用 自己的数据，则 my_main_info_for_parent 不清，其他的全清掉
    if is_parent_data_ptr then
      DATA.player_details[player_id].my_income_details = nil
      DATA.player_details[player_id].my_spending_details = nil
      DATA.player_details[player_id].base_info = nil
      DATA.player_details[player_id].my_deatails_info_for_parent = nil
      DATA.player_details[player_id].my_contribute_details_for_parent = nil
    else
      --- 再删自己
      DATA.player_details[player_id] = nil
    end
    
  end

  DATA.cache_data_player_num = DATA.cache_data_player_num - #delete_vec

end

function PROTECT.on_load()
    if DATA.reduce_online_timer then
      DATA.reduce_online_timer:stop()
      DATA.reduce_online_timer = nil
    end

    ---- 每个一定时间 减少在线权重
    DATA.reduce_online_timer = skynet.timer(DATA.online_num_clear_delay , function()
      PUBLIC.reduce_player_online_num()
    end)

end


---- 检查日志型数据是否超出最大缓存值，如果是，清理到指定值
function PUBLIC.check_and_clear_log_data( data_ref , max_num , clear_num )
  local data_length = #data_ref
  if data_length > clear_num then
    local need_clear_num = data_length - max_num

    for i = 1,need_clear_num do
      table.remove(data_ref , 1)
    end
  end
end




---- add by wss
------- 重置修复 生财之道 基础信息的的下级数量
function CMD.reset_sczd_base_info_son_count()
  
  query_data(string.format([[update sczd_player_base_info A set all_son_count = (select count(*) from sczd_relation_data where parent_id = A.player_id ) where A.player_id in (select distinct parent_id from sczd_relation_data where parent_id != '');]]))

end


return PROTECT


