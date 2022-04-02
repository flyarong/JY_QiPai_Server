--
-- 作者: lyx
-- Date: 2018/3/10
-- Time: 14:48
-- 多节点之间服务调用测试
--

--------------------------------------------------
-- 全局参数配置，分发到每个节点
local configs = 
{
	-- 创建测试服务的数量
	service_count = 2000,

	-- 统计数据间隔时间
	stat_time_interval = 5,

	-- 需要测试删除、创建 的 服务 id
	test_service = 
	{
		["node_1.300"] = true,
		["node_2.500"] = true,
		["node_2.600"] = true,
		["node_3.700"] = true,
		["node_3.800"] = true,
	},
}

--------------------------------------------------
-- 节点参数配置，可覆盖全局配置
-- 系统参数说明：
--	resource 可分配的资源数量
--	resource_types 可分配的资源类型集合
--		格式： {"ddz_test_agent","player_agent/player_agent"}
--		默认：不填则允许所有类型
--	reject_resource_types 拒绝的资源类型集合（暂未实现）
--

local nodes = 
{
	node_1 = 
	{
		-- 管理控制台端口：管理服务状态、关机
		admin_console_port = 7101,

		-- skynet 调试控制台端口
		debug_console_port = 8101,

	},

	node_2 = 
	{
		-- 管理控制台端口：管理服务状态、关机
		admin_console_port = 7102,

		-- skynet 调试控制台端口
		debug_console_port = 8102,
	},

	-- 网关
	node_3 = 
	{
		-- 管理控制台端口：管理服务状态、关机
		admin_console_port = 7103,

		-- skynet 调试控制台端口
		debug_console_port = 8103,
	},
}

--------------------------------------------------
-- 服务配置
-- 说明：
--	launch 启动文件，给出启动的 lua 文件位置
--	deploy 部署配置，指定要部署到哪些节点，并给出名字：
--		1、全局服务，在每个节点均有唯一名字，例如：
--			{test_name1=node_1,test_name2=node_2,...}
--		2、私有服务，在不同节点名字均相同，例如：
--			{test_name={node_1,node_2,...}}
--		
--			特别的，部署到所有节点：{test_name="*"}
--

local services = 
{
	{	
		launch = "node_test_service/node_test_main_service",
		deploy = {main_service="node_1"},
	},
	{	-- 服务管理
		launch = "admin_console_service/admin_console_service",
		deploy = {service_console="*"},
	},
}


return {
	
	configs = configs,
	nodes = nodes,
	services = services,
}