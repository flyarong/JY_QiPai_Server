--
-- Author: lyx
-- Date: 2018/10/9
-- Time: 15:14
-- 说明：托管 调度器
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
require"printfunc"
local nodefunc = require "nodefunc"
require "normal_enum"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC

local PROTECTED = {}


local function default_Data()
    return 
    {
        --[[ 
            托管的池，数组：  {config=,tg_data_pool=准备好的托管agent池,user_data_pool=用户数据池}
        --]]
       grades_tuoguan_pool = {},
    
        -- 游戏场次所在的池序号： game hash => 序号
       game2pool = {},
    
        -- 用户 login id 所在 池序号
       login_id2pool = {},
    
       config_time = 0,
    
       game_id_maps = {},
    }
end

DATA.tg_schedule_data = DATA.tg_schedule_data or default_Data()
local D = DATA.tg_schedule_data


function PUBLIC.get_model_game_hash(_name,_id)
	local g = D.game_id_maps[_name] or {}
	D.game_id_maps[_name] = g

	local _hash = g[_id] or _name .. "_" .. _id
	g[_id] = _hash

	return _hash
end


local function load_config(_tg_user_pool)
    local configs = nodefunc.get_global_config("tuoguan_config")

    if not configs.tuoguan_games[1] then
        return
    end

    D.grades_tuoguan_pool = {}

    local _count_per = math.floor(#_tg_user_pool/#configs.tuoguan_games)

     for i,_config in ipairs(configs.tuoguan_games) do

        local _pool = {tg_data_pool={},user_data_pool={}}
        D.grades_tuoguan_pool[i] = _pool

        -- 建立场次映射
        for _,_game in ipairs(_config.games) do
            D.game2pool[PUBLIC.get_model_game_hash(_game.model,_game.game_id)] = i
        end

        _pool.config = _config
        
        -- 分配 托管池
        local _i_begin = _count_per*(i-1)+1
        for _i2=_i_begin, _i_begin + _count_per-1 do
            _pool.user_data_pool[#_pool.user_data_pool + 1] = _tg_user_pool[_i2]

            -- login id 映射
            D.login_id2pool[_tg_user_pool[_i2].id] = i
        end
    end
end


-- 刷新配置
local function refresh_config()
    local configs,_time = nodefunc.get_global_config("tuoguan_config")
    if _time == D.config_time then
        return
    end
    D.config_time = _time

    -- 清除映射表
    D.game2pool = {}

    for i,_config in ipairs(configs.tuoguan_games) do

        local _pool = D.grades_tuoguan_pool[i]
  
        for _,_game in ipairs(_config.games) do
            D.game2pool[PUBLIC.get_model_game_hash(_game.model,_game.game_id)] = i
        end

        _pool.config = _config
        
    end

end

-- 确保托管的 钱在给定的范围
local function adjust_money(_player_id,_money1,_money2)

    local _jing_bi = nodefunc.call(_player_id,"query_asset_by_type",PLAYER_ASSET_TYPES.JING_BI)

    print("tuoguan achedule adjust money(player,cur money ,money1,money2):",_player_id,_jing_bi,_money1,_money2)

    if _jing_bi < _money1 or _jing_bi > _money2 then
        local _inc_value = math.random(_money1,_money2)-_jing_bi
        print("tuoguan achedule adjust money(money,player ,change):",_jing_bi+_inc_value,_player_id,_inc_value)
        nodefunc.call(_player_id,"change_asset_multi",{{asset_type=PLAYER_ASSET_TYPES.JING_BI,value=_inc_value}},
            ASSET_CHANGE_TYPE.TUOGUAN_ADJUST,"0")
    end
end

local function create_tuoguan_agent(_pool)
    local _ud = basefunc.random_pop(_pool.user_data_pool)
    if not _ud then 
        print("schedule create_tuoguan_agent ,pool data use out!")
        return nil
    end

    local _tg = PUBLIC.create_tuoguan_agent(_ud)
    if not _tg then
        print("schedule create_tuoguan_agent,create tuoguan agent failed!")
        return nil -- 失败，放弃此次检查
    end
 
    -- 确保鲸币 在范围内
    adjust_money(_tg.player_id,
        _pool.config.money[1],_pool.config.money[2])

    return _tg
end

local check_tuoguan_pool_start = false

-- 检查 托管池
local function check_tuoguan_pool()

	if skynet.getcfg("forbid_tuoguan_manager") then
		return
	end

    if not check_tuoguan_pool_start then
        check_tuoguan_pool_start = true
        print("check_tuoguan_pool start...")
    end

    refresh_config()

    -- 检查 池中的数量，不足则创建

    local _min_psize = skynet.getcfg("tuoguan_pool_size") or 10
    for _,_pool in pairs(D.grades_tuoguan_pool) do

        -- 确保缓存 充足
        local _diff = _min_psize - #_pool.tg_data_pool
        for i=1,_diff do
            local _tg = create_tuoguan_agent(_pool)
            if _tg then
                _pool.tg_data_pool[#_pool.tg_data_pool + 1] = _tg
            else
                print("check_tuoguan_pool error:",i)
            end
        end
        
    end

end

function PROTECTED.recycle_user_data(_user_data)
    local _pool_i = D.login_id2pool[_user_data.id]
    if _pool_i then

        local _pool = D.grades_tuoguan_pool[_pool_i]
        _pool.user_data_pool[#_pool.user_data_pool + 1] = _user_data

        print("recycle_user_data schedule :",_user_data.id)

        return true
    else
        return false
    end
end

-- 从池中弹出一个 托管 agent，如果没有，则新创建
function PROTECTED.pop_tuoguan_agent(_model,_game_id)
    local _pool_i = D.game2pool[PUBLIC.get_model_game_hash(_model,_game_id)]
    if _pool_i then
        local _pool = D.grades_tuoguan_pool[_pool_i]
        if not _pool then
            print("schedule pop_tuoguan_agent ,pool is nil :",_model,_game_id,_pool_i)
            return nil
        end

        -- 从池中取
        local _tg = basefunc.random_pop(_pool.tg_data_pool)
        if _tg then
    		print("schedule pop_tuoguan_agent ,from pool :",_model,_game_id,_pool_i)
            return _tg
        end

        -- 没有则创建
        _tg = create_tuoguan_agent(_pool)
        if _tg then
            print("schedule pop_tuoguan_agent ,create :",_model,_game_id,_pool_i)
            return _tg
        else
            print("schedule pop_tuoguan_agent error:",_model,_game_id,_pool_i)
            return nil
        end
    end

    print("schedule pop_tuoguan_agent error,not found pool:",_model,_game_id,_game_id)
    return nil
end

function PROTECTED.init(_tg_user_pool,_reload)

    if _reload then
        -- 初始化数据
        D = default_Data()
        DATA.tg_schedule_data = D
    end

    load_config(_tg_user_pool)

    if not _reload then
        skynet.timer(10,check_tuoguan_pool)     
    end
    
end



return PROTECTED