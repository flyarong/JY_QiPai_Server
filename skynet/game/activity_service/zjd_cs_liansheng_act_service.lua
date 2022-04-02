--zjd_cs_liansheng_act_service
--砸金蛋连出财神活动
--- 生财之道 高级合伙人 中心服务

local skynet = require "skynet_plus"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


-- zjd_cs_lisnsheng_round   第几期活动
-- zjd_cs_lisnsheng_start	开始时间
-- zjd_cs_lisnsheng_end		结束时间

--DATA.player_game_data[player_id] or {liansheng=0,huojiang_time={}}
function PUBLIC.check_data_is_safe(player_id,level)
	if not DATA.player_game_data[player_id] or not DATA.player_game_data[player_id][level] then
		DATA.player_game_data[player_id]= DATA.player_game_data[player_id] or {}
		DATA.player_game_data[player_id][level]={cur_ls=0}
		local round=skynet.getcfg_2number("zjd_cs_lisnsheng_round")
		--写数据库
		local sql=string.format("INSERT INTO zjd_cs_liansheng_info(player_id,round,level,cur_ls)VALUES('%s',%d,%d,%d);",player_id,round,level,0)
		skynet.send(DATA.service_config.data_service,"lua","db_exec",sql)
	end
end

function PUBLIC.check_fajiang(player_id,level)
	local p_data=DATA.player_game_data[player_id][level]
	local cur_ls=p_data.cur_ls
	local ls="ls"..cur_ls
	if DATA.game_config[level] and DATA.game_config[level][cur_ls] then

		p_data[ls]=p_data[ls] or 0

		if DATA.game_config[level][cur_ls].times>p_data[ls] then
			p_data[ls]=p_data[ls]+1
			--发邮件
			--[[发送邮件
					type
						"sys_welcome" -- 系统欢迎邮件
						"native" -- 原生邮件 邮件内容在data中的content中
					type
					title
					sender
					receiver
					state -- 选填(默认"normal")
					valid_time -- 选填(默认0)大于0才有效
					data -- 选填(默认{})
				]]
			skynet.send(DATA.service_config.email_service,"lua","send_email",{type="native",
																					title="砸金蛋财神模式连胜中奖",
																					sender="系统",
																					receiver=player_id,
																					valid_time=os.time()+10*24*3600,
																					data={content=DATA.game_config[level][cur_ls].email_content}
																					})

			local round=skynet.getcfg_2number("zjd_cs_lisnsheng_round")
			--写数据库
			local sql=string.format("update zjd_cs_liansheng_info set %s=%d where player_id='%s' and round=%d and level=%d;",ls,p_data[ls],player_id,round,level)
			skynet.send(DATA.service_config.data_service,"lua","db_exec",sql)

		end
	end

end
--开奖通知  res --结果
function CMD.zjd_cs_kaijiang_res(player_id,level,res_rate)
	if not skynet.getcfg("zjd_cs_lisnsheng_level_"..level) then
		return 
	end
	PUBLIC.check_data_is_safe(player_id,level)
	local p_data=DATA.player_game_data[player_id][level]
	if res_rate==38 then
		p_data.cur_ls=p_data.cur_ls +1
		--检查发奖
		PUBLIC.check_fajiang(player_id,level)
	--连胜中断
	else
		DATA.player_game_data[player_id][level].cur_ls=0
	end

	local round=skynet.getcfg_2number("zjd_cs_lisnsheng_round")
	--写入数据库
	local sql=string.format("update zjd_cs_liansheng_info set cur_ls=%d where player_id='%s' and round=%d and level=%d;",p_data.cur_ls,player_id,round,level)
	skynet.send(DATA.service_config.data_service,"lua","db_exec",sql)

end
function CMD.get_cur_ls(player_id,level)
	if not skynet.getcfg("zjd_cs_lisnsheng_level_"..level) then
		return 0
	end
	PUBLIC.check_data_is_safe(player_id,level)
	return DATA.player_game_data[player_id][level].cur_ls
end
function PUBLIC.init_data_form_db()
	DATA.player_game_data={}
	local s_time=skynet.getcfg_2number("zjd_cs_lisnsheng_start")
	local e_time=skynet.getcfg_2number("zjd_cs_lisnsheng_end")
	if s_time and e_time then
		local cur_time=os.time()
		if cur_time>s_time and cur_time<e_time then
			--从数控库读入数据
			local round=skynet.getcfg_2number("zjd_cs_lisnsheng_round")
			local sql="select * from  zjd_cs_liansheng_info where round="..round..";"
			local ret = skynet.call(DATA.service_config.data_service,"lua","db_query",sql)
			if ret.errno then
				print("init_data_form_db error!!!")
				return 
			end
			for i,_row in ipairs(ret) do
				DATA.player_game_data[_row.player_id]=DATA.player_game_data[_row.player_id] or {}
				DATA.player_game_data[_row.player_id][_row.level]=_row
			end
		end
	end

end

function CMD.start(_service_config)
	DATA.service_config = _service_config
	CMD.set_game_cfg()
	PUBLIC.init_data_form_db()
end
--[[
	--levle  等级
	game_config[levle]={
		key={times, email_content   }    key表示 连胜次数   times 表示发奖次数   email_content 表示邮件内容 
	}
--]]
function CMD.set_game_cfg(_cfg)
	DATA.game_config=_cfg or {
		[3]={
			[4]={times=1, email_content="恭喜您在砸金蛋财神模式中使用小银锤连续敲出4次财神，请联系微信客服JYDDZ01领取奖励。"},
			[6]={times=1, email_content="恭喜您在砸金蛋财神模式中使用小银锤连续敲出6次财神，请联系微信客服JYDDZ01领取奖励。"},
			[8]={times=1, email_content="恭喜您在砸金蛋财神模式中使用小银锤连续敲出8次财神，请联系微信客服JYDDZ01领取奖励。"},
		},
		[4]={
			[4]={times=1, email_content="恭喜您在砸金蛋财神模式中使用小金锤连续敲出4次财神，请联系微信客服JYDDZ01领取奖励。"},
			[6]={times=1, email_content="恭喜您在砸金蛋财神模式中使用小金锤连续敲出6次财神，请联系微信客服JYDDZ01领取奖励。"},
			[8]={times=1, email_content="恭喜您在砸金蛋财神模式中使用小金锤连续敲出8次财神，请联系微信客服JYDDZ01领取奖励。"},
		}
	}
end
function CMD.clear_game_data(_cfg)
	DATA.player_game_data={}
end


-- 启动服务
base.start_service()




