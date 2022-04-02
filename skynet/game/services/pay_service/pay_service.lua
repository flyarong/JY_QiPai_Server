--
-- Author: yy
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：邮件服务
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
local cjson = require "cjson"

local payment_config = require "payment_config"

require "pay_service.pay_agent_manager"

require "pay_service.pay_gift_bag"

require "normal_enum"

local loadstring = rawget(_G, "loadstring") or load

require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC


--玩家锁 一个玩家同时只能进行一笔appstore订单
local player_lock={}


local function init_data()
	PUBLIC.init_gift_bag()
end


DATA.service_config = nil

DATA.pay_switch_config = require("payment_switch")


-- 设置 支付开关
function CMD.set_payment_switch(_payment_switch)

	for _channel_type,_enable in pairs(_payment_switch) do

		if _enable then
			DATA.pay_switch_config[_channel_type] = nil
		else
			DATA.pay_switch_config[_channel_type] = false
		end

	end

	return 0
end

-- 设置 支付开关(单个)
function CMD.set_payment_switch(_channel,_enable)

	if tostring(_enable) == "true" then
		DATA.pay_switch_config[_channel] = nil
	else
		DATA.pay_switch_config[_channel] = false
	end

	return 0
end

function CMD.get_payment_switch()
	local ret = {}
	for _channel,_ in pairs(payment_config.channel_types) do
		if DATA.pay_switch_config[_channel] == false then
			ret[_channel] = false
		else
			ret[_channel] = true
		end
	end

	return ret
end

local function get_appStore_verify_url( _is_sandbox )
	if( _is_sandbox ) then
		return "https://sandbox.itunes.apple.com/verifyReceipt"
	else 
		return "https://buy.itunes.apple.com/verifyReceipt"
	end
end


function CMD.verify_appstore_pay(_user_id,_product_id,_receipt,_transaction_id,_is_sandbox,_convert,_definition_id)

	if DATA.pay_switch_config.appstore == false then
		return 2403
	end

	print("verify_appstore_pay",_user_id,_product_id,_receipt,_transaction_id,_is_sandbox,_convert,_definition_id)

	if player_lock[_user_id] then
		return 1008
	end
	player_lock[_user_id] = true

	if not skynet.getcfg("is_pay_test") and _is_sandbox > 0 then
		print(" error pay test is not open ")
	end

	local order = skynet.call( DATA.service_config.data_service, "lua", "query_appstore_order", _transaction_id )
	if order then

		if order.order_status == "complete" then
			print("交易已经完成了")
			player_lock[_user_id] = nil
			nodefunc.send(order.player_id,"notify_pay_order_status",
						0,nil,order.order_id,order.product_id,nil,_transaction_id,_definition_id)
			return 0
		end

		if order.order_status == "error"
			or order.order_status == "fail" then
			print("交易异常"..order.order_status)
			dump(order)
			player_lock[_user_id] = nil
			nodefunc.send(order.player_id,"notify_pay_order_status",
						2503,order.error_desc,order.order_id,order.product_id,nil,_transaction_id,_definition_id)
			return 2503
		end

		order = order.order_id

	else
		local error_msg
		order,error_msg = skynet.call( DATA.service_config.data_service, "lua", "create_appstore_order",
							 _user_id,
							 _product_id,
							 _transaction_id,
							 _is_sandbox,
							 _convert,
							 _definition_id)
		if not order then
			print("create_appstore_order error : ".. error_msg)
			player_lock[_user_id] = nil
			return error_msg
		end
	end

	local post_data = string.format('{"receipt-data":"%s"}',_receipt)

	local url_to = get_appStore_verify_url(_is_sandbox > 0)
	
	local ok,content = skynet.call(base.DATA.service_config.webclient_service,"lua",
									"request_post_json", url_to,post_data)

	if ok then

		local status, retArgs = pcall( cjson.decode, content )
		if not status then
			dump(retArgs)
			player_lock[_user_id] = nil
			return 1003,"cjson.decode error "
		end
		
		if retArgs.status ~= 0  then

			print("app store 验证收据返回的状态码：" .. retArgs.status)
			skynet.send( DATA.service_config.data_service, "lua", "modify_appstore_order",
							 order,
							 _transaction_id,
							 "error",
							 retArgs.status)
			player_lock[_user_id] = nil
			return 2502
		end

		--验证收据
		if not retArgs.receipt
			or not payment_config.appstore_bundleid[retArgs.receipt.bid] 
			or retArgs.receipt.transaction_id ~= _transaction_id
			or retArgs.receipt.product_id ~= _product_id
			then
			dump(retArgs)
			local error_data = {}
			if retArgs.receipt then
				error_data.bid = retArgs.receipt.bid
				error_data.transaction_id = retArgs.receipt.transaction_id
				error_data.product_id = retArgs.receipt.product_id
			end
			skynet.send( DATA.service_config.data_service, "lua", "modify_appstore_order",
							 order,
							 _transaction_id,
							 "fail",
							 cjson.encode(error_data))
			player_lock[_user_id] = nil
			return 2502
		end

		local ret,error_code = skynet.call( DATA.service_config.data_service, "lua", "modify_appstore_order",
							 order,
							 _transaction_id,
							 "complete")
		if ret then

			--ok
			print("验证收据 成功")
			player_lock[_user_id] = nil
			return 0
		else
			
			--error
			print("验证收据 失败",error_code)

			player_lock[_user_id] = nil
			return error_code
		end

	else
		dump(content)
		player_lock[_user_id] = nil
		return 2501,content
	end

end



function CMD.start(_service_config)
	DATA.service_config = _service_config
	init_data()

	-- 刷新配置
	skynet.timer(5,function()
		payment_config = base.require("game/config/","payment_config")
		DATA.pay_switch_config = base.require("game/config/","payment_switch")
	end)

	--CMD.test()
end

-- 启动服务
base.start_service()




function CMD.test()

	-- local _receipt = 'ewoJInNpZ25hdHVyZSIgPSAiQXdIdWhsenNaZ3VWcUpqWEttRGxHN1prYWh6NFMxMFg3Q05jWFpPYkFvSXp1c1JIZFRKazlJajViZU85RVFERGdDa05rcDU0REEzOWo4NGxQUmRoeWE0cWxGZzlEcEZGK0JGYzZFT01PR0ZQdEVsbVlZbkFNQm84WDBEYUorTGdqUHpKeXRUQ2hBT0t5cTJnZUViRGc3bnFjaU1jVVM4cFNVdmc3bWg5TWIxMDlCY2w0dEUvbGMvWkc2cWFpcTUzU3ZXRVNoMTViMUVQTjZRSHdnZ1Bac2JMaXNlKzd0elRPWDJEdjZKU1Z5UGxVV0VPVnliUFpwWjNiQzJRUXpkNDRIVzZEQWdNSWlZRk9FaDRYajNaQXVHd2xzNys2NGZUa0h6NGNOR25uaENQUmpJZ1BjWFNTbXEvZk5Sb01EcW0xUTFObmFoK08wUG5kWDFQZnZtM2hSVUFBQVdBTUlJRmZEQ0NCR1NnQXdJQkFnSUlEdXRYaCtlZUNZMHdEUVlKS29aSWh2Y05BUUVGQlFBd2daWXhDekFKQmdOVkJBWVRBbFZUTVJNd0VRWURWUVFLREFwQmNIQnNaU0JKYm1NdU1Td3dLZ1lEVlFRTERDTkJjSEJzWlNCWGIzSnNaSGRwWkdVZ1JHVjJaV3h2Y0dWeUlGSmxiR0YwYVc5dWN6RkVNRUlHQTFVRUF3dzdRWEJ3YkdVZ1YyOXliR1IzYVdSbElFUmxkbVZzYjNCbGNpQlNaV3hoZEdsdmJuTWdRMlZ5ZEdsbWFXTmhkR2x2YmlCQmRYUm9iM0pwZEhrd0hoY05NVFV4TVRFek1ESXhOVEE1V2hjTk1qTXdNakEzTWpFME9EUTNXakNCaVRFM01EVUdBMVVFQXd3dVRXRmpJRUZ3Y0NCVGRHOXlaU0JoYm1RZ2FWUjFibVZ6SUZOMGIzSmxJRkpsWTJWcGNIUWdVMmxuYm1sdVp6RXNNQ29HQTFVRUN3d2pRWEJ3YkdVZ1YyOXliR1IzYVdSbElFUmxkbVZzYjNCbGNpQlNaV3hoZEdsdmJuTXhFekFSQmdOVkJBb01Da0Z3Y0d4bElFbHVZeTR4Q3pBSkJnTlZCQVlUQWxWVE1JSUJJakFOQmdrcWhraUc5dzBCQVFFRkFBT0NBUThBTUlJQkNnS0NBUUVBcGMrQi9TV2lnVnZXaCswajJqTWNqdUlqd0tYRUpzczl4cC9zU2cxVmh2K2tBdGVYeWpsVWJYMS9zbFFZbmNRc1VuR09aSHVDem9tNlNkWUk1YlNJY2M4L1cwWXV4c1FkdUFPcFdLSUVQaUY0MWR1MzBJNFNqWU5NV3lwb041UEM4cjBleE5LaERFcFlVcXNTNCszZEg1Z1ZrRFV0d3N3U3lvMUlnZmRZZUZScjZJd3hOaDlLQmd4SFZQTTNrTGl5a29sOVg2U0ZTdUhBbk9DNnBMdUNsMlAwSzVQQi9UNXZ5c0gxUEttUFVockFKUXAyRHQ3K21mNy93bXYxVzE2c2MxRkpDRmFKekVPUXpJNkJBdENnbDdaY3NhRnBhWWVRRUdnbUpqbTRIUkJ6c0FwZHhYUFEzM1k3MkMzWmlCN2o3QWZQNG83UTAvb21WWUh2NGdOSkl3SURBUUFCbzRJQjF6Q0NBZE13UHdZSUt3WUJCUVVIQVFFRU16QXhNQzhHQ0NzR0FRVUZCekFCaGlOb2RIUndPaTh2YjJOemNDNWhjSEJzWlM1amIyMHZiMk56Y0RBekxYZDNaSEl3TkRBZEJnTlZIUTRFRmdRVWthU2MvTVIydDUrZ2l2Uk45WTgyWGUwckJJVXdEQVlEVlIwVEFRSC9CQUl3QURBZkJnTlZIU01FR0RBV2dCU0lKeGNKcWJZWVlJdnM2N3IyUjFuRlVsU2p0ekNDQVI0R0ExVWRJQVNDQVJVd2dnRVJNSUlCRFFZS0tvWklodmRqWkFVR0FUQ0IvakNCd3dZSUt3WUJCUVVIQWdJd2diWU1nYk5TWld4cFlXNWpaU0J2YmlCMGFHbHpJR05sY25ScFptbGpZWFJsSUdKNUlHRnVlU0J3WVhKMGVTQmhjM04xYldWeklHRmpZMlZ3ZEdGdVkyVWdiMllnZEdobElIUm9aVzRnWVhCd2JHbGpZV0pzWlNCemRHRnVaR0Z5WkNCMFpYSnRjeUJoYm1RZ1kyOXVaR2wwYVc5dWN5QnZaaUIxYzJVc0lHTmxjblJwWm1sallYUmxJSEJ2YkdsamVTQmhibVFnWTJWeWRHbG1hV05oZEdsdmJpQndjbUZqZEdsalpTQnpkR0YwWlcxbGJuUnpMakEyQmdnckJnRUZCUWNDQVJZcWFIUjBjRG92TDNkM2R5NWhjSEJzWlM1amIyMHZZMlZ5ZEdsbWFXTmhkR1ZoZFhSb2IzSnBkSGt2TUE0R0ExVWREd0VCL3dRRUF3SUhnREFRQmdvcWhraUc5Mk5rQmdzQkJBSUZBREFOQmdrcWhraUc5dzBCQVFVRkFBT0NBUUVBRGFZYjB5NDk0MXNyQjI1Q2xtelQ2SXhETUlKZjRGelJqYjY5RDcwYS9DV1MyNHlGdzRCWjMrUGkxeTRGRkt3TjI3YTQvdncxTG56THJSZHJqbjhmNUhlNXNXZVZ0Qk5lcGhtR2R2aGFJSlhuWTR3UGMvem83Y1lmcnBuNFpVaGNvT0FvT3NBUU55MjVvQVE1SDNPNXlBWDk4dDUvR2lvcWJpc0IvS0FnWE5ucmZTZW1NL2oxbU9DK1JOdXhUR2Y4YmdwUHllSUdxTktYODZlT2ExR2lXb1IxWmRFV0JHTGp3Vi8xQ0tuUGFObVNBTW5CakxQNGpRQmt1bGhnd0h5dmozWEthYmxiS3RZZGFHNllRdlZNcHpjWm04dzdISG9aUS9PamJiOUlZQVlNTnBJcjdONFl0UkhhTFNQUWp2eWdhWndYRzU2QWV6bEhSVEJoTDhjVHFBPT0iOwoJInB1cmNoYXNlLWluZm8iID0gImV3b0pJbTl5YVdkcGJtRnNMWEIxY21Ob1lYTmxMV1JoZEdVdGNITjBJaUE5SUNJeU1ERTRMVEEzTFRFeElESXhPakEwT2pNNElFRnRaWEpwWTJFdlRHOXpYMEZ1WjJWc1pYTWlPd29KSW5WdWFYRjFaUzFwWkdWdWRHbG1hV1Z5SWlBOUlDSmhaVE14TXpkaU4yWm1NVEJoWXpNM01XRmxNMkppTlRrelpEUmpOV0UyWW1NNVpUaGlNVEJrSWpzS0NTSnZjbWxuYVc1aGJDMTBjbUZ1YzJGamRHbHZiaTFwWkNJZ1BTQWlNVEF3TURBd01EUXhOamMxTlRZM015STdDZ2tpWW5aeWN5SWdQU0FpTVNJN0Nna2lkSEpoYm5OaFkzUnBiMjR0YVdRaUlEMGdJakV3TURBd01EQTBNVFkzTlRVMk56TWlPd29KSW5GMVlXNTBhWFI1SWlBOUlDSXhJanNLQ1NKdmNtbG5hVzVoYkMxd2RYSmphR0Z6WlMxa1lYUmxMVzF6SWlBOUlDSXhOVE14TXpZNE1qYzRNREF3SWpzS0NTSjFibWx4ZFdVdGRtVnVaRzl5TFdsa1pXNTBhV1pwWlhJaUlEMGdJa1EzUlRVM09VWkVMVEV3TUVVdE5ETTBSUzFCTlVVNUxUUTJNRGRHUXpjNFJqazBSU0k3Q2draWNISnZaSFZqZEMxcFpDSWdQU0FpWTI5dExtcHFaR1I2TG5wekxtUnBZVzF2Ym1RMklqc0tDU0pwZEdWdExXbGtJaUE5SUNJeE5EQTVOalU0TWpFM0lqc0tDU0ppYVdRaUlEMGdJbU52YlM1elkycDVhR1F1YW5scWFtUmtlaUk3Q2draWFYTXRhVzR0YVc1MGNtOHRiMlptWlhJdGNHVnlhVzlrSWlBOUlDSm1ZV3h6WlNJN0Nna2ljSFZ5WTJoaGMyVXRaR0YwWlMxdGN5SWdQU0FpTVRVek1UTTJPREkzT0RBd01DSTdDZ2tpY0hWeVkyaGhjMlV0WkdGMFpTSWdQU0FpTWpBeE9DMHdOeTB4TWlBd05Eb3dORG96T0NCRmRHTXZSMDFVSWpzS0NTSnBjeTEwY21saGJDMXdaWEpwYjJRaUlEMGdJbVpoYkhObElqc0tDU0p3ZFhKamFHRnpaUzFrWVhSbExYQnpkQ0lnUFNBaU1qQXhPQzB3TnkweE1TQXlNVG93TkRvek9DQkJiV1Z5YVdOaEwweHZjMTlCYm1kbGJHVnpJanNLQ1NKdmNtbG5hVzVoYkMxd2RYSmphR0Z6WlMxa1lYUmxJaUE5SUNJeU1ERTRMVEEzTFRFeUlEQTBPakEwT2pNNElFVjBZeTlIVFZRaU93cDkiOwoJImVudmlyb25tZW50IiA9ICJTYW5kYm94IjsKCSJwb2QiID0gIjEwMCI7Cgkic2lnbmluZy1zdGF0dXMiID0gIjAiOwp9'
	-- local _user_id = "110"
	-- local _product_id = "com.jjddz.zs.diamond6"
	-- local _transaction_id = "1000000416755673"
	-- local _is_sandbox = 1

	-- skynet.timeout(200,function ( ... )
	-- 	CMD.verify_appstore_pay(_user_id,_product_id,_receipt,_transaction_id,_is_sandbox)
	-- end)

	

end