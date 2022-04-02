--
-- Created by lyx.
-- User: hare
-- Date: 2018/7/5
-- Time: 15:06
-- 说明：
--

local skynet = require "skynet_plus"
local base = require "base"
local nodefunc = require "nodefunc"
local cluster = require "skynet.cluster"
local basefunc = require "basefunc"

require "printfunc"

local my_node_name = skynet.getenv("my_node_name")
local service_count = skynet.getenv("service_count")

local DATA = base.DATA
local PUBLIC = base.PUBLIC
local CMD = base.CMD

DATA.nodes = {}
DATA.node_map = {}

function PUBLIC.get_srv_id(_index,_node)

	return (_node or my_node_name) .. "." .. _index
end

function PUBLIC.query_node()

	-- 查询节点
	for _node,_ in pairs(skynet.get_nodes()) do
		if _node == my_node_name then
			DATA.nodes[#DATA.nodes + 1] = {addr="node_service",name=_node}
		else 
			DATA.nodes[#DATA.nodes + 1] = {addr=cluster.proxy(_node,cluster.query(_node,"node_service")),name=_node}
		end

		DATA.node_map[_node] = DATA.nodes[#DATA.nodes]
	end

end
