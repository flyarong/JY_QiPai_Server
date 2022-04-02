--
-- Created by lyx.
-- User: hare
-- Date: 2018/6/4
-- Time: 1:47
-- sczd 过滤器
--

local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local hlib = require "websever_service.handle_lib"

-----------------------------------------------------------
-- 处理器函数映射： ret=返回值处理函数, svr=调用的服务, param=参数名数组

local cmd_defines = 
{
    debug_pay                   ={ret=hlib.encode_data_code  ,svr="data_service"         ,param={"player_id","goods_id","money"}},

    wechat_create_player        ={ret=hlib.encode_data_code  ,svr="sczd_center_service"  ,param={"weixinUnionId"}},
    --wechat_create_player        ={ret=hlib.encode_data_code  ,svr="sczd_center_service",method="post"  ,param={"weixinUnionId","testjson"}},
    init_bind_parent            ={ret=hlib.encode_code       ,svr="sczd_center_service"  ,param={"player_id","parent_id"}},

    change_gjhhr_info           ={ret=hlib.encode_code       ,svr="sczd_center_service"  ,param={"player_id","create_or_delete","gjhhr_status","real_name","phone","weixin","shengfen","chengshi","qu","op_player",}},
                                               
    get_gjhhr_achievements_data ={ret=hlib.encode_data_code  ,svr="sczd_gjhhr_service"   ,param={"player_id"}},

    verify_gjhhr_info           ={ret=hlib.encode_data_code  ,svr="sczd_gjhhr_service"   ,param={"player_id","weixinUnionId"}},
    
    change_player_relation      ={ret=hlib.encode_code       ,svr="sczd_center_service"  ,param={"player_id","new_parent","op_player"}},

    get_player_openid           ={ret=hlib.encode_data_code  ,svr="data_service"         ,param={"player_id","app_id"}},
    add_player_openid           ={ret=hlib.encode_code       ,svr="data_service"         ,param={"player_id","app_id","open_id"}},
    add_alipay_account          ={ret=hlib.encode_code       ,svr="data_service"         ,param={"player_id","name","account"}},
    get_alipay_account          ={ret=hlib.encode_data_code  ,svr="data_service"         ,param={"player_id"}},

    get_all_gjhhr_base_data     ={ret=hlib.encode_data_code  ,svr="sczd_gjhhr_service"   ,param={}},

    withdraw_gjhhr              ={ret=hlib.encode_data_code  ,svr="sczd_gjhhr_service"   ,param={"player_id","channel_type","channel_receiver_id","money"}},

    player_refund_msg           ={ret=hlib.encode_code  ,svr="sczd_gjhhr_service"   ,param={"player_id","num"}},

    change_ticheng_config       ={ret=hlib.encode_code  ,svr="sczd_gjhhr_service"   ,method="post"  , param={"cfg"}},

    query_jicha_cash            ={ret=hlib.encode_data_code  ,svr="sczd_gjhhr_service"   , param={"player_id"}},

    -- period_settle                ={ret=hlib.encode_code  ,svr="sczd_gjhhr_service"   , param={}},

    query_user_game_count       ={ret=hlib.encode_data_code  ,svr="collect_service"   , param={"user_id","gametype","start_time","end_time"}},


    --  sczd的各种开关
    set_activate_sczd_profit   = {ret=hlib.encode_code  ,svr="sczd_center_service"   , param={"user_id","tgy_tx_profit" , "xj_profit" , "tglb_profit" , "basai_profit" }},


    -- web 查询游戏完成情况 
    query_user_specific_game_count       ={ret=hlib.encode_data_code  ,svr="collect_service"   , param={"user_id","gametype","game_id","start_time","end_time"}},

    -- web 查询游戏完成情况
    query_user_specific_games_count       ={ret=hlib.encode_data_code  ,svr="collect_service" ,method="post"  , param={"data"}},
    

    -- web 增加兑换码
    add_redeem_code_data       ={ret=hlib.encode_data_code  ,svr="redeem_code_center_service" ,method="post"  , param={"data"}},
    
    -- web 删除兑换码
    delete_redeem_code_data       ={ret=hlib.encode_data_code  ,svr="redeem_code_center_service" ,method="post"  , param={"data"}},
    
}

-----------------------------------------------------------

return hlib.handler(cmd_defines)