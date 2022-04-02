--
-- Author: HEWEI
-- Date: 2018/4/12
-- Time: 
-- 说明：behavior_mgr
local skynet = require "skynet_plus"
local basefunc=require"basefunc"
require"printfunc"
local base = require "base"
local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST
local PROTECT={}

--排他锁
DATA.game_lock=nil
DATA.location=nil

function PUBLIC.lock(_type,_loc,_game_id)
	if not DATA.game_lock then
		DATA.game_lock=_type
		DATA.location=_loc
		DATA.game_id=_game_id
		return true
	end
	return false
end
function PUBLIC.unlock(_type)
	if  DATA.game_lock==_type then
		DATA.game_lock=nil
		DATA.location=nil
		DATA.game_id=nil
		return true
	end
	return false
end
function REQUEST.get_location()
	if DATA.location then
		return {result=0,location = DATA.location,game_id = DATA.game_id}
	else
		return {result=0,location = "dating"}
	end
end


return PROTECT



