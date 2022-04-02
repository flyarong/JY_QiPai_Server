--- 生财之道 ,高级合伙人， 数据文件
--[[
        业绩概念：
  总团队：自己及以下所有人的业绩（充值）
  自己团队：自己的子孙中，不跨越任何高级合伙人
  xxx团队：高级合伙人，且是自己的直接孩子
  其它团队：高级合伙人，不是自己的直接孩子，不跨越其它高级合伙人
--]]

local skynet = require "skynet_plus"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "normal_enum"
require "printfunc"
local data_func = require "data_func"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

--************
--nil表示没有 空表表示 数据为空
--************

--数据结构
--[[
  key=player_id
  value={
    parent_gjhhr   --上级高级合伙人 （不管是否是自己的邀请人）
    son_gjhhr={
      key=player_id --子孙高级合伙人(包括不在我这一级的，即其它团队 )
    }
    parent  --父亲
        
    status
    son_gjhhr_count

  }
--]]
DATA.gjhhr_data={
  
}

    -- 供 web 查询的数据86197
    -- query_data_create_time  --查询数据产生的时间

    -- query_data { 

    -- }
DATA.gjhhr_query_data={

}

--[[
    all_achievements  --我周期内的总业绩
    tuikuan --我的团队退款

    yesterday_all_achievements --截止昨天周期内的总业绩
    yesterday_tuikuan --我的团队退款
--]]
DATA.player_achievements={
  
}
-- 查询数据，返回结果集，出错则返回 nil
local function query_data(_sql)

	local ret = skynet.call(DATA.service_config.data_service,"lua","db_query",_sql)
	if( ret.errno ) then
		print(string.format("query_data sql error: sql=%s\nerr=%s\n",_sql,basefunc.tostring( ret )))
		return nil
	end
	
	return ret
end
function PUBLIC.load_player_achievements(player_id)
    if player_id  and not DATA.player_achievements[player_id] then

    --将player的业绩数据load进来  
    --如果没有数据这插入一条   sczd_player_all_achievements
    local data = skynet.call(DATA.service_config.data_service,"lua","sczd_load_player_achievements",player_id)
    if not DATA.player_achievements[player_id] then
        DATA.player_achievements[player_id] = data
    end
  end
end
--添加团队业绩
function PUBLIC.add_player_achievements(player_id,num,_parents)

    if not player_id then 
      return 
    end
    
    --获得他所有的上级节点
    local parents=_parents or skynet.call(DATA.service_config.sczd_center_service,"lua","query_all_parents" , player_id)
    --
    local add_achievements=function (_player_id)
          PUBLIC.load_player_achievements(_player_id)
        
          local p_achievements=DATA.player_achievements[_player_id]
          if p_achievements then
              p_achievements.all_achievements=p_achievements.all_achievements+num
          else
              print("error <<add_player_achievements>> p_achievements is not exits!!!!!")
          end
    end

    local data={} 
    --加自己的
    add_achievements(player_id)
    data[player_id]=DATA.player_achievements[player_id].all_achievements
    if parents then
      for _,id in ipairs(parents) do
        add_achievements(id)
        data[id]=DATA.player_achievements[id].all_achievements
      end
    end


    --写入数据库     sczd_player_all_achievements
    skynet.send(DATA.service_config.data_service,"lua","sczd_add_player_achievements",data)

end

--添加退款  order_create_time--订单完成时间  根据此时间来确定是否算入高级合伙人的退款
function PUBLIC.add_player_refund(player_id,num,_parents)
    --获得他所有的上级节点
    local parents=_parents or skynet.call(DATA.service_config.sczd_center_service,"lua","query_all_parents" , player_id)

    local add_tuikuan=function (player_id)
              PUBLIC.load_player_achievements(player_id)
          local p_achievements=DATA.player_achievements[player_id]
          if p_achievements then
            p_achievements.tuikuan=p_achievements.tuikuan+num
          else
            print("error <<add_player_refund>> p_achievements is not exits!!!!!")
          end
    end

    local data={} 
    --加自己
    add_tuikuan(player_id)
    data[player_id]=DATA.player_achievements[player_id].tuikuan
    if parents then
      for _,id in ipairs(parents) do
        add_tuikuan(id)
        data[id]=DATA.player_achievements[id].tuikuan
      end
    end
    --写入数据库      sczd_player_all_achievements
    skynet.send(DATA.service_config.data_service,"lua","sczd_add_gjhhr_refund",data)
end

--只包含直属儿子
function PUBLIC.add_son_gjhhr(parent_gjhhr,son_gjhhr)
    
    --print("xxxxxxxxxxxxxxxxxxxx aa add_son_gjhhr:",parent_gjhhr,son_gjhhr,basefunc.tostring(DATA.gjhhr_data[parent_gjhhr]))
    
    if not DATA.gjhhr_data[parent_gjhhr].son_gjhhr or not DATA.gjhhr_data[parent_gjhhr].son_gjhhr[son_gjhhr] then
        DATA.gjhhr_data[parent_gjhhr].son_gjhhr=DATA.gjhhr_data[parent_gjhhr].son_gjhhr or {}
        DATA.gjhhr_data[parent_gjhhr].son_gjhhr[son_gjhhr]=true
        if DATA.gjhhr_data[son_gjhhr].parent==parent_gjhhr then
            DATA.gjhhr_data[parent_gjhhr].son_gjhhr_count=DATA.gjhhr_data[parent_gjhhr].son_gjhhr_count+1
        end
    end
end
function PUBLIC.remove_son_gjhhr(parent_gjhhr,son_gjhhr)
    
    if DATA.gjhhr_data[parent_gjhhr].son_gjhhr and DATA.gjhhr_data[parent_gjhhr].son_gjhhr[son_gjhhr] then
        DATA.gjhhr_data[parent_gjhhr].son_gjhhr[son_gjhhr]=nil
        if DATA.gjhhr_data[son_gjhhr].parent==parent_gjhhr then
          DATA.gjhhr_data[parent_gjhhr].son_gjhhr_count=DATA.gjhhr_data[parent_gjhhr].son_gjhhr_count-1
        end
    end
end
-- 设置高级合伙人的上下级关系
-- DATA.gjhhr_data 的 ： parent_gjhhr , parent , son_gjhhr
function PUBLIC.set_gjhhr_parent_and_superior_gjhhr(data_map)
  if data_map then
    local gjhhr_map={}
    for k,v in pairs(data_map) do
        gjhhr_map[k]=true
    end
    local data=skynet.call(DATA.service_config.sczd_center_service,"lua","query_frist_gjhhr_and_parent_by_group",gjhhr_map)
    if data and type(data)=="table" then
        for id,v in pairs(data) do
            DATA.gjhhr_data[id].parent_gjhhr=v.parent_gjhhr
            DATA.gjhhr_data[id].parent=v.parent

            if v.parent_gjhhr then 
                PUBLIC.add_son_gjhhr(v.parent_gjhhr,id)
            end
            
        end
    end
  end
end
--获得没有上级高gjhhr的gjhhr
function PUBLIC.get_no_superior_gjhhr()
    local data={}
    for id,v in pairs(DATA.gjhhr_data) do
      if not v.parent_gjhhr then
        data[id]=true
      end
    end
    return data
end

--每天向数据库写入今天的业绩log
function PUBLIC.record_today_achievements()
  if DATA.player_achievements then
      for k,v in pairs(DATA.player_achievements) do
          v.yesterday_all_achievements=v.all_achievements
          v.yesterday_tuikuan=v.tuikuan
      end
  end
  --调用服务器存储过程
  skynet.send(DATA.service_config.data_service,"lua","db_exec","call sczd_gjhhr_record_today_achievements();")

end

--根据配置获得我的返利比例
function PUBLIC.get_fanlibili(achievements)
  for _,v in ipairs(DATA.ticheng_config) do
    if v.achievements>=achievements then
      return v.proportion
    end
  end
  return DATA.ticheng_config[#DATA.ticheng_config].proportion
end
function PUBLIC.get_fanli(achievements)
  return math.floor(achievements * PUBLIC.get_fanlibili(achievements) + 0.5)
end
--按周期结账
function CMD.period_settle()
  local all_hhr=skynet.call(DATA.service_config.sczd_center_service,"lua","get_all_relation_data")
  --上级高级合伙人
  local superior_gjhhr={}
  local settle_data={}

  local calculate_income=function (p_id)
      --如果没有结算过  则结算
      if not settle_data[p_id] then
          settle_data[p_id]={}

          PUBLIC.load_player_achievements(p_id)
          
          local v=DATA.player_achievements[p_id]
          --先减去 退款
          local achievements=v.all_achievements
          local tuikuan=v.tuikuan
          if achievements>=tuikuan then
            achievements=achievements-tuikuan
            tuikuan=0
          else
            tuikuan=tuikuan-achievements
            achievements=0
          end
          settle_data[p_id].income=PUBLIC.get_fanli(achievements)
          settle_data[p_id].all_achievements=v.all_achievements
          settle_data[p_id].tuikuan=v.tuikuan
          settle_data[p_id].percentage=PUBLIC.get_fanlibili(achievements)
          settle_data[p_id].my_income=settle_data[p_id].income
          --清空本月业绩
          v.all_achievements=0
          v.tuikuan=tuikuan
      end
  end

  for p_id,v in pairs(DATA.gjhhr_data) do 
      calculate_income(p_id)  
  end

  --向上扣除
  local kouchu_flag={}
  for id,v in pairs(settle_data) do
    if not kouchu_flag[id] then
        local ps={}
        local k_id=id
        while k_id do
          ps[#ps+1]=k_id
          k_id=DATA.gjhhr_data[k_id].parent_gjhhr
        end
        local len=#ps
        for i=len,1,-1 do 
            if not kouchu_flag[ps[i]] then
                k_id=ps[i]
                kouchu_flag[k_id]=true
                local p_id=DATA.gjhhr_data[k_id].parent_gjhhr 
                if p_id then
                  settle_data[p_id].my_income=settle_data[p_id].my_income-settle_data[k_id].my_income
                end
            end
        end
    end
  end

  --清空所有人的数据 此处会大量增加内存  后期优化  ###_test  !!!!!!!!!!!!
  for p_id,_ in pairs(all_hhr) do
      PUBLIC.load_player_achievements(p_id)
      local v=DATA.player_achievements[p_id]
      if v.all_achievements>=v.tuikuan then
        v.tuikuan=0
      else
        v.tuikuan=v.tuikuan-v.all_achievements
      end
      v.all_achievements=0
      v.yesterday_all_achievements=0
      v.yesterday_tuikuan=v.tuikuan
  end

  ----发钱   写入数据库  sczd_gjhhr_settle_log   
  skynet.send(DATA.service_config.data_service,"lua","sczd_period_settle",settle_data)
  return 0

end

function PUBLIC.day_record()

    local wait_time=basefunc.get_diff_target_time(DATA.day_settle_time)
    skynet.sleep(wait_time*100)
    while DATA.day_record_run do
        PUBLIC.record_today_achievements()
        local day=os.date("%d")
        --暂时不开启下个月确定无问题后 改为自动
        if day=='01' and skynet.getcfg("gjhhr_auto_period_settle") then
          CMD.period_settle()
        end
        skynet.sleep(24*3600*100)
    end
    
end

function PUBLIC.create_gjhhr_query_data(player_id)
  PUBLIC.load_player_achievements(player_id)
  DATA.gjhhr_query_data[player_id]={}

  local g_data=DATA.gjhhr_data[player_id]

  local query_data=DATA.gjhhr_query_data[player_id]

    query_data.query_data_create_time=os.time()

    query_data.query_data={

      gjhhr_status=g_data.status,

      -- 可提现金额
      jicha_cash=skynet.call(DATA.service_config.data_service,"lua","query_asset",player_id,"prop_jicha_cash"),

      -- 周期内的总业绩 和 收入
      all_achievements=DATA.player_achievements[player_id].all_achievements,  
      all_income=PUBLIC.get_fanli(DATA.player_achievements[player_id].all_achievements),

      -- 总的提成比例
      all_percentage=PUBLIC.get_fanlibili(DATA.player_achievements[player_id].all_achievements),
      
      -- 今天的总业绩
      today_achievements=DATA.player_achievements[player_id].all_achievements-DATA.player_achievements[player_id].yesterday_all_achievements,

      -- 直接孩子 高级合伙人数据： xxx 团队
      son_data={}, 

      -- 直接孩子 高级合伙人 id 列表： xxx 团队
      children_gjhhr_ids = {}, 

      -- 其它下级 高级合伙人 id 列表： 直接孩子以下
      other_xj_gjhhr_ids={}, 

      -- 其它下级 高级合伙人 业绩 和 收入： 直接孩子以下
      other_achievements=0,
      other_income=0,
      other_today_achievements=0,

      -- 我的团队业绩： = all_achievements - sum(son_data.all_achievements) - other_achievements
      my_achievements = 0,

      my_today_achievements=0,
      -- 我的提成比例 和 返利
      my_percentage = 0,
      my_income = 0,

      son_tgy_count=0,

      my_real_income=0,
    }
    local data=query_data.query_data

    local all_need_query_map
    if g_data.son_gjhhr then
      all_need_query_map=basefunc.deepcopy(g_data.son_gjhhr)
    else
      all_need_query_map={}
    end
    all_need_query_map[player_id]=true

    local my_tgy_map=skynet.call(DATA.service_config.sczd_center_service,"lua","query_tgy_son_count",all_need_query_map)
    dump(my_tgy_map)
    data.son_tgy_count=my_tgy_map[player_id]

    local _sum_son_achievements = 0
    local _sum_son_today_achievements = 0

    if g_data.son_gjhhr then

      --dump(g_data,"xxxxxxxxxxxxxxx create_gjhhr_query_data:")

      for s_id,_ in pairs(g_data.son_gjhhr) do
          PUBLIC.load_player_achievements(s_id)

          _sum_son_achievements = _sum_son_achievements + DATA.player_achievements[s_id].all_achievements
          _sum_son_today_achievements=_sum_son_today_achievements+DATA.player_achievements[s_id].all_achievements-DATA.player_achievements[s_id].yesterday_all_achievements

          --print("xxxxxxxxxxxxxxxxxx DATA.gjhhr_data[s_id].parent: ",DATA.gjhhr_data[s_id].parent)
          if DATA.gjhhr_data[s_id].parent==player_id then
            data.son_data[#data.son_data +1 ]={ id=s_id,
                                                name=DATA.gjhhr_data[s_id].name,
                                                all_achievements=DATA.player_achievements[s_id].all_achievements,
                                                today_achievements=DATA.player_achievements[s_id].all_achievements-DATA.player_achievements[s_id].yesterday_all_achievements,
                                                percentage=PUBLIC.get_fanlibili(DATA.player_achievements[s_id].all_achievements),
                                                income=PUBLIC.get_fanli(DATA.player_achievements[s_id].all_achievements),
                                              }
                                              
            data.children_gjhhr_ids[#data.children_gjhhr_ids + 1] = s_id                                  
          else
            data.other_xj_gjhhr_ids[#data.other_xj_gjhhr_ids + 1] = s_id

            data.other_achievements=data.other_achievements+DATA.player_achievements[s_id].all_achievements
            data.other_income=data.other_income+PUBLIC.get_fanli(DATA.player_achievements[s_id].all_achievements)

            data.other_today_achievements=data.other_today_achievements+(DATA.player_achievements[s_id].all_achievements-DATA.player_achievements[s_id].yesterday_all_achievements)
          end
          data.son_tgy_count=data.son_tgy_count-my_tgy_map[s_id]
      end

    end

    data.my_achievements = data.all_achievements - _sum_son_achievements
    data.my_percentage = PUBLIC.get_fanlibili(data.my_achievements)
    data.my_income = PUBLIC.get_fanli(data.my_achievements)
    data.my_today_achievements =data.today_achievements-_sum_son_today_achievements
    ---测试
    data.my_real_income=data.all_income-data.other_income
    if data.son_data then
      for k,v in pairs(data.son_data) do
        data.my_real_income=data.my_real_income-v.income
      end
    end
end

function PUBLIC.get_gjhhr_query_data(player_id)
  if DATA.gjhhr_data[player_id]  then
    local v=DATA.gjhhr_query_data[player_id]
    if skynet.getcfg("debug") or not v or not v.query_data_create_time or os.time()-v.query_data_create_time>DATA.refresh_query_data_time then
      PUBLIC.create_gjhhr_query_data(player_id)
    end
    return DATA.gjhhr_query_data[player_id].query_data
  end
  dump(DATA.gjhhr_data,"get_gjhhr_query_data player_id is not  id:",player_id)
  return nil
end


local function load_config_from_db()

  local ret = query_data("select * from sczd_gjhhr_ticheng_cfg")
  if not ret or not ret[1] then
     return nil 
  end

  local data = {}
  for _,_d in ipairs(ret) do
    data[_d.id] = {achievements = _d.achievements,proportion = _d.proportion}
  end

  return data
end
function PUBLIC.init_ticheng_config()

  --从数据库读入  sczd_gjhhr_ticheng_cfg
  local data =   load_config_from_db()
  if data then
    DATA.ticheng_config=data
  else
      --读取默认的值
      DATA.ticheng_config=base.import("game/services/sczd_gjhhr_service/sczd_gjhhr_config.lua")
      --写入数据库
      PUBLIC.record_ticheng_config()
  end
end
function PUBLIC.record_ticheng_config()

    --将 DATA.ticheng_config 写入数据库表  sczd_gjhhr_ticheng_cfg
    local _sqls = {"delete from sczd_gjhhr_ticheng_cfg;"}
    for _id,_d in ipairs(DATA.ticheng_config) do
      _sqls[#_sqls + 1] = string.format("insert into sczd_gjhhr_ticheng_cfg(id,achievements,proportion) values(%d,%d,%f);",
          _id,_d.achievements,_d.proportion)
    end
    
    skynet.send(DATA.service_config.data_service,"lua","db_exec",table.concat(_sqls,"\n"))
end

function PUBLIC.init_gjhhr_data()
  --从  sczd_gjhhr_info  查询出suo有数据
  local data=skynet.call(DATA.service_config.data_service,"lua","sczd_load_sczd_gjhhr_info")  
  DATA.gjhhr_data=data or {}
  
  for k,v in pairs(DATA.gjhhr_data) do
    v.son_gjhhr_count=0
  end
  
  PUBLIC.set_gjhhr_parent_and_superior_gjhhr(DATA.gjhhr_data)
end

--初始化gjhhr_data
function PUBLIC.init_data()
  PUBLIC.init_ticheng_config()

  DATA.day_settle_time =3
  DATA.day_record_run=true
  --刷新查询数据时间  10分钟
  DATA.refresh_query_data_time=10*60

  PUBLIC.init_gjhhr_data()
  -- 每天记录
  skynet.fork(PUBLIC.day_record)
end



























