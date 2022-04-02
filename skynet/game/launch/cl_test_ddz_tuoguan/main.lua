--require "ddz_tuoguan.test.test_pai_data"
 
local skynet = require "skynet_plus"
skynet.getcfg = skynet.getenv
 require "ddz_tuoguan.test.test_chupai"
 --require "ddz_tuoguan.test.test_chupai_special"

 os.exit(1)
