
local skynet = require "skynet_plus"
local sprotoloader = require "sprotoloader"
local sprotoparser = require "sprotoparser"

local proto = require "game.protocol.proto"

local basefunc = require "basefunc"

skynet.start(function()

	print("load sproto c2s !!!")
	sprotoloader.save(proto.c2s, 1)
	print("load sproto s2c !!!")
	sprotoloader.save(proto.s2c, 2)

	-- don't call skynet.exit() , because sproto.core may unload and the global slot become invalid
end)
