#pragma once

#define 	CTRL_VERSION			747845

//用户信息
struct tagUserDataInfo
{
	DWORD					dwUserID;					//UserID
	DWORD					dwGameID;					//GameID
	SCORE					lUserScore;					//用户金币
	SCORE					lInsure;					//用户银行
	WORD					wTableID;					//桌号
	TCHAR					szNickName[LEN_NICKNAME];	//用户昵称
	BYTE					cbRoundCount;				//当前轮数

	//输赢
	SCORE                   lTotalLostScore;            //当日输赢
	SCORE                   lDailyLostScore;            //当日输赢

	//银行充值
	SCORE					lChargeScore;				//累计充值
	SCORE					lDailyChargeScore;			//当日充值
	SCORE					lTransferIn;				//最近转入
	SCORE					lTransferOut;				//最近转出
	SCORE					lBuyScore;					//买分
	SCORE					lSellScore;					//卖分
	SCORE					lDistrScore;				//可赢积分
	LONG					lDiffiucult;				//个人难度
	TCHAR					szUserAttribute[32];		//归属地
	TCHAR					szSpreaderName[LEN_NICKNAME];	//推广员
};

//////////////////////////////////////////////////////////////////////////

#define MDM_CF_CONTROL              2800

#define SUB_C_QUERY_ROOM_NAME        99
#define SUB_C_QUERY_INFO            100
#define SUB_C_QUERY_USER_LIST       101
#define SUB_C_MODIFY_CONFIG			106
#define SUB_C_MODIFY_LUCK			107
#define SUB_C_RESET_STOCK			108

//系统配置
struct CMD_C_ModifyConfig
{
	BYTE							cbPlayGameCount;					//每轮局数
	BYTE							cbAwardCount;						//奖牌数量
	SCORE							lFirMatchScore;						//初赛积分
	SCORE							lSecMatchScore;						//复赛积分
	SCORE							lThiMatchScore;						//决赛积分

	SCORE							lFirFeeScore;						//第1轮每局服务费
	SCORE							lSecFeeScore;						//第2轮每局服务费
	SCORE							lThiFeeScore;						//第3轮每局服务费
};

//好牌配置
struct CMD_C_ModifyLuck
{
	WORD							wAndroidInitChance;					//机器人初始概率
	WORD							wAndroidStepChance;					//机器人步长概率

	WORD							wUserInitChance;					//用户初始概率
	WORD							wUserStepChance;					//用户步长概率

	WORD							wMasterInitChance;					//管理员初始概率
	WORD							wMasterStepChance;					//管理员步长概率
};
//库存设置
struct CMD_C_ModifyStock
{
	SCORE							dwStockScore;						//当前库存
	SCORE							dwLoseLimit;						//做牌限制
};

#define SUB_S_QUERY_REQUEST         101						//查询请求
#define SUB_S_USER_LIST				103						//用户列表
#define SUB_S_USER_LIST_BEGIN		104						//列表开始
#define SUB_S_USER_LIST_END			105						//列表结束	
#define SUB_S_ROOM_INFO				106						//房间信息

struct CMD_S_RoomInfo
{
	TCHAR							szRoomName[LEN_SERVER];
	WORD							wServerID;
	WORD							wServerType;
};

struct CMD_S_QueryInfo
{
	BYTE							cbPlayGameCount;					//每轮局数
	BYTE							cbAwardCount;						//奖牌数量
	SCORE							lFirMatchScore;						//初赛积分
	SCORE							lSecMatchScore;						//复赛积分
	SCORE							lThiMatchScore;						//决赛积分

	SCORE							lFirFeeScore;						//第1轮每局服务费
	SCORE							lSecFeeScore;						//第2轮每局服务费
	SCORE							lThiFeeScore;						//第3轮每局服务费

	DWORD							dwTotalGameCount;					//总的游戏局数
	DWORD							dwTotalAwardCount;					//总的获奖次数
	DWORD							dwDailyGameCount;					//每日游戏局数
	DWORD							dwDailyAwardCount;					//每日获奖次数
	SCORE							lRevenueScore;						//税收

	WORD							wAndroidInitChance;					//机器人初始概率
	WORD							wAndroidStepChance;					//机器人步长概率

	WORD							wUserInitChance;					//用户初始概率
	WORD							wUserStepChance;					//用户步长概率

	WORD							wMasterInitChance;					//管理员初始概率
	WORD							wMasterStepChance;					//管理员步长概率

	SCORE							dwStoreScore;						//当前库存
	SCORE							dwLoseLimit;						//做牌限制
};
