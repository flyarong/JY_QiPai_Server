--
-- Author: lyx
-- Date: 2018/4/13
-- Time: 14:03
-- 说明：斗地主比赛相关的枚举
--

-- 时间调度类型定义：配置表 match_schedule_config.type
DDZM_SCHEDULE_TYPES =
{
	OVERLAP = 1, -- 不停开
	ONE_BY_ONE = 2, -- 依次开
}

-- 调度结束类型定义：配置表 match_schedule_config.end_type
DDZM_END_TYPES =
{
	COUNT = 1, -- 场数量
	TIME = 2, -- 时间
	TIME_DIFF = 3, -- 时段：相对开始报名的时刻
}

-- 开始条件类型定义：配置表 match_begin_config.begin_type
DDZM_BEGIN_TYPES =
{
	PLAYER_COUNT = 1, -- 人数
	TIME = 2, -- 时间
	TIME_DIFF = 3, -- 时段：相对开始报名的时刻
}

-- 比赛状态定义
DDZM_STATUS =
{
	DISABLE = -1, -- 禁用（已经被 管理员配置为禁用，不允许再报名）
	ENABLE = 0, -- 启用（比赛还没有进入显示状态）
	READY = 1, -- 就绪（比赛刚刚进入显示状态）
	SIGNUP = 2, -- 报名中
	SIGNUP_END = 3, -- 报名结束
	MATCH= 4, -- 正在比赛
	SETTLE = 5, -- 正在结算
	FINISHED = 6, -- 结束
	STOP = 7, -- 服务停止
}
-- 比赛状态定义
MATCH_STATUS =
{
	DISABLE = -1, -- 禁用（已经被 管理员配置为禁用，不允许再报名）
	WAIT_BEGIN = 0, -- 等待报名开始
	SIGNUP = 1, -- 报名中
	SIGNUP_END = 2, -- 报名结束
	MATCHING= 3, -- 正在比赛
	OVER = 4, -- 比赛结束
	W_DISPATCH=5,
}



