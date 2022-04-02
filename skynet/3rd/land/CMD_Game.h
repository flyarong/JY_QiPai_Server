#ifndef CMD_GAME_HEAD_FILE
#define CMD_GAME_HEAD_FILE

#include <assert.h>

#pragma pack(1)


//////////////////////////////////////////////////////////////////////////
// {{{ 增加定义 （by lyx 2018-9-29）

// #define LYX_DEBUG

typedef unsigned char BYTE;
typedef int SCORE;
typedef void VOID;
typedef unsigned short WORD;
typedef unsigned int DWORD;
typedef unsigned int UINT;
typedef unsigned long LONG;
typedef char TCHAR;
typedef const char * LPCSTR;
typedef const char * LPCTSTR;

#define INVALID_CHAIR 0xFF

const int LEN_NICKNAME = 50;
const int LEN_SERVER = 50;

#define ZeroMemory(d,l) memset((void *)(d),0,(l))
#define CopyMemory(dest,src,len) memcpy((void *)(dest),(const void *)(src),len)

#ifdef	NDEBUG
	#define ASSERT(a) ((void)0)
	#define VERIFY(f) ((void)(f))
#else
	#define ASSERT(a) assert((a))
	#define VERIFY(f) assert((f))
#endif

#define TRACE printf

#define TEXT(a) a

#define CountArray(a) (sizeof(a)/sizeof((a)[0]))
#define SafeDelete(a) do {if (a) delete (a);} while(0)

#ifdef LYX_DEBUG

	#define CHECK_MEMCPY(dest_len,src_len) ASSERT(dest_len>=src_len)

	#define CHECK_CHAIR(a)	ASSERT((a) >= 0 && (a) < 3)
	#define CHECK_CHAIR2(a)	ASSERT((a) >= 0 && (a) < 3 || (a) == INVALID_CHAIR)

	#define VALID_CARD(a) (((a) & 0x0F) >= 0x01 && ((a) & 0x0F) <= 0x0D && \
				(((a) & 0xF0) >= 0x00 && ((a) & 0xF0) <= 0x30 || \
				(a)==0x41 || (a) == 0x42))		

	#define CHECK_CARD(a) ASSERT(VALID_CARD(a))	
	#define CHECK_CARD2(a) ASSERT(VALID_CARD(a) || 0xff == (a))	

	#define THROW_ERROR(a) do {printf("throw error:%d!\n",a); ASSERT(0);} while(0)
	#define THROW ASSERT(0)

	#define TRY 
	#define CATCH(a)  if (0)
#else
	#define CHECK_MEMCPY(dest_len,src_len) ((void)0)

	#define CHECK_CHAIR(a)	((void)0)
	#define CHECK_CHAIR2(a)	((void)0)

	#define VALID_CARD(a) true

	#define CHECK_CARD(a) ((void)0)
	#define CHECK_CARD2(a) ((void)0)

	#define THROW_ERROR(a) throw TempExcep(a)
	#define THROW throw

	#define TRY try
	#define CATCH catch
#endif


class TempExcep
{
public:

	int error;

	TempExcep(int _error)	
	{
		error = _error;
	}
};


//#define USE_FUNTRACE

///}}}///////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////
//服务定义

//游戏属性
#define KIND_ID						35									//游戏 I D
#define GAME_NAME					TEXT("斗地主")					//游戏名字

//组件属性
#define GAME_PLAYER					3									//游戏人数
#define VERSION_SERVER				PROCESS_VERSION(1,0,11)				//程序版本
#define VERSION_CLIENT				PROCESS_VERSION(1,0,9)				//程序版本

//////////////////////////////////////////////////////////////////////////////////

//数目定义
#define MAX_COUNT					20									//最大数目
#define FULL_COUNT					54									//全牌数目

//逻辑数目
#define NORMAL_COUNT				17									//常规数目
#define DISPATCH_COUNT				51									//派发数目

#define MAX_GOOD_RATE               10000								//概率为万分比

//数值掩码
#define	MASK_COLOR					0xF0								//花色掩码
#define	MASK_VALUE					0x0F								//数值掩码

//逻辑类型
#define CT_ERROR					0									//错误类型
#define CT_SINGLE					1									//单牌类型
#define CT_DOUBLE					2									//对牌类型
#define CT_THREE					3									//三条类型（lyx: 不带）
#define CT_SINGLE_LINE				4									//单连类型
#define CT_DOUBLE_LINE				5									//对连类型
#define CT_THREE_LINE				6									//三连类型
#define CT_THREE_TAKE_ONE			7									//三带一单
#define CT_THREE_TAKE_TWO			8									//三带一对
#define CT_FOUR_TAKE_ONE			9									//四带两单
#define CT_FOUR_TAKE_TWO			10									//四带两对
#define CT_BOMB_CARD				11									//炸弹类型
#define CT_MISSILE_CARD				12									//火箭类型

//底牌类型
//#define BCT_GENERAL					0									//普通类型
//#define BCT_FULSH					1									//顺子类型
//#define BCT_STRAIGHT				2									//同花类型
//#define BCT_STRAIGHT_FULSH			3									//同花顺类型
//#define BCT_SINGLE_MISSILE			4									//单王类型
//#define BCT_DOUBLE_MISSILE			5									//对王类型
//#define BCT_THREE					6									//三条类型

//////////////////////////////////////////////////////////////////////////////////
//日志等级定义

#define LOG_LEVEL_DEBUG				0x00								//debug等级
#define LOG_LEVEL_ERROR				0x01								//error等级
#define LOG_LEVEL_WARN				0x02								//warn等级
#define LOG_LEVEL_INFO				0x03								//info等级

//////////////////////////////////////////////////////////////////////////////////
//状态定义

#define GAME_SCENE_FREE				GAME_STATUS_FREE					//等待开始
#define GAME_SCENE_CALL				GAME_STATUS_PLAY					//叫地主状态
#define GAME_SCENE_ADD				GAME_STATUS_PLAY+1					//加倍状态
#define GAME_SCENE_PLAY				GAME_STATUS_PLAY+2					//游戏进行

//叫地主
#define CB_NOT_CALL					0									//没叫地主
#define CB_MEN_BENKER				1									//闷抓
#define CB_CALL_BENKER				2									//抓主
#define CB_NO_CALL_BENKER			3									//不叫地主

//加倍信息
#define CB_NOT_ADD_DOUBLE			0									//没加倍
#define CB_ADD_DOUBLE				1									//加倍标志
#define CB_NO_ADD_DOUBLE			2									//不加倍

//玩家结算分数类型
#define ScoreType_Max				1								//封顶
#define ScoreType_bankruptcy		2								//破产
//自建房规则
#define RULE_3_0					0x01					//可以三不带
#define RULE_4_1					0x02					//只能四带二（lyx： 允许四带 两 单？）
#define RULE_No_La					0x04					//没有拉踩
#define RULE_ShuangWang				0x08					//双王必抓
#define RULE_3Zhua					0x10					//三个主必抓
#define RULE_Max_Time8				0x20					//8倍封顶
#define RULE_Max_Time16				0x40					//16倍封顶
#define RULE_Max_Time32				0x80					//32倍封顶
#define RULE_Max_Time				0x0200					//不封顶
#define RULE_Off					0x0100					//全程使用三不带和四带二的开关
#define RULE_3_2					0x0400					//可以三带对
#define RULE_4_2					0x0800					//可以四带对
//空闲状态
struct CMD_S_StatusFree
{
	//游戏属性
	SCORE							lCellScore;							//基础积分

	//时间信息
	BYTE							cbTimeCallBanker;					//叫地主时间
	BYTE							cbTimeAddDouble;					//加倍时间
	BYTE							cbTimeOutCard;						//出牌时间
	BYTE							cbTimeStartGame;					//开始时间
	BYTE							cbTimeHeadOutCard;					//首出时间

	//历史积分
	SCORE							lTurnScore[GAME_PLAYER];			//积分信息
	SCORE							lCollectScore[GAME_PLAYER];			//积分信息
	//元宝房进出分
	SCORE							lMinEnterScore;
	SCORE							lMinExitScore;
	DWORD							dwPPRule;
	SCORE							lServiceCharge;						//服务费
};

//叫分状态
struct CMD_S_StatusCall
{
	//时间信息
	BYTE							cbTimeOutCard;						//出牌时间
	BYTE							cbTimeCallBanker;					//叫地主时间
	BYTE							cbTimeAddDouble;					//加倍时间
	BYTE							cbTimeStartGame;					//开始时间
	BYTE							cbTimeHeadOutCard;					//首出时间

	//游戏信息
	SCORE							lCellScore;							//单元积分
	WORD							wCurrentUser;						//当前玩家
	WORD							wFirstUser;							//首叫用户
	BYTE							cbCallBankerInfo[GAME_PLAYER];		//叫地主信息
	BYTE							cbLookCard;							//看牌标识
	BYTE							cbHandCardData[NORMAL_COUNT];		//手上扑克
	WORD							wUserTime[GAME_PLAYER];				//用户倍数

	//历史积分
	SCORE							lTurnScore[GAME_PLAYER];			//积分信息
	SCORE							lCollectScore[GAME_PLAYER];			//积分信息
	//元宝房进出分
	SCORE							lMinEnterScore;
	SCORE							lMinExitScore;
	DWORD							dwPPRule;
	BYTE							cbTimeLeave;						//剩余时间
};

//加倍状态
struct CMD_S_StatusDouble
{
	//时间信息
	BYTE							cbTimeCallBanker;					//叫地主时间
	BYTE							cbTimeAddDouble;					//加倍时间
	BYTE							cbTimeStartGame;					//开始时间
	BYTE							cbTimeHeadOutCard;					//首出时间
	BYTE							cbTimeOutCard;						//出牌时间

	//游戏信息
	SCORE							lCellScore;							//单元积分
	WORD							wBankerUser;						//庄家用户
	WORD							wCurrentUser;						//当前用户

	BYTE							cbCallBankerInfo[GAME_PLAYER];		//叫地主信息	
	BYTE							cbAddDoubleInfo1[GAME_PLAYER];		//加倍信息
	BYTE							cbAddDoubleInfo2[GAME_PLAYER];		//加倍信息
	BYTE							cbLookCard;							//看牌标识
	BYTE							cbCurrStatus;						//当前状态:0:第一轮,1:第二轮

	//扑克信息
	BYTE							cbBankerCard[3];					//游戏底牌
	BYTE							cbHandCardCount[GAME_PLAYER];		//扑克数目
	BYTE							cbHandCardData[MAX_COUNT];			//手上扑克
	WORD							wUserTime[GAME_PLAYER];				//用户倍数

	//历史积分
	SCORE							lTurnScore[GAME_PLAYER];			//积分信息
	SCORE							lCollectScore[GAME_PLAYER];			//积分信息
	//元宝房进出分
	SCORE							lMinEnterScore;
	SCORE							lMinExitScore;
	DWORD							dwPPRule;
	BYTE							cbTimeLeave;						//剩余时间
};

//游戏状态
struct CMD_S_StatusPlay
{
	//时间信息
	BYTE							cbTimeOutCard;						//出牌时间
	BYTE							cbTimeCallBanker;					//叫地主时间
	BYTE							cbTimeAddDouble;					//加倍时间
	BYTE							cbTimeStartGame;					//开始时间
	BYTE							cbTimeHeadOutCard;					//首出时间

	//游戏变量
	LONG							lCellScore;							//单元积分
	BYTE							cbBombCount;						//炸弹次数
	WORD							wBankerUser;						//庄家用户
	WORD							wCurrentUser;						//当前玩家

	WORD							wBombTime;							//炸弹倍数
	BYTE							cbCallBankerInfo[GAME_PLAYER];		//叫地主信息	
	BYTE							cbAddDoubleInfo1[GAME_PLAYER];		//加倍信息
	BYTE							cbAddDoubleInfo2[GAME_PLAYER];		//加倍信息

	//出牌信息
	WORD							wTurnWiner;							//胜利玩家
	BYTE							cbTurnCardCount;					//出牌数目
	BYTE							cbTurnCardData[MAX_COUNT];			//出牌数据
	WORD							wUserTime[GAME_PLAYER];				//用户倍数

	//扑克信息
	BYTE							cbBankerCard[3];					//游戏底牌
	BYTE							cbHandCardCount[GAME_PLAYER];		//扑克数目
	BYTE							cbHandCardData[MAX_COUNT];			//手上扑克

	//历史积分
	SCORE							lTurnScore[GAME_PLAYER];			//积分信息
	SCORE							lCollectScore[GAME_PLAYER];			//积分信息
	BYTE							cbCardCountInfo[15];				//记牌器数据
	//元宝房进出分
	SCORE							lMinEnterScore;
	SCORE							lMinExitScore;
	DWORD							dwPPRule;
	BYTE							cbTimeLeave;						//剩余时间
	bool							bTrustee[GAME_PLAYER];				//玩家托管状态
};

//////////////////////////////////////////////////////////////////////////////////
//命令定义

#define SUB_S_SNED_CARD				99									//发送扑克
#define SUB_S_GAME_START			100									//游戏开始
#define SUB_S_CALL_BANKER			101									//叫地主
#define SUB_S_BANKER_INFO			102									//庄家信息
#define SUB_S_LOOK_CARD				103									//用户看牌
#define SUB_S_DOUBLE				104									//加倍信息
#define SUB_S_OUT_CARD				106									//用户出牌
#define SUB_S_PASS_CARD				107									//用户放弃
#define SUB_S_GAME_CONCLUDE			109									//游戏结束
#define SUB_S_SET_BASESCORE			110									//设置基数
#define SUB_S_CHEAT_CARD			111									//作弊扑克
#define SUB_S_USER_TRUSTEE			112									//用户托管
#define SUB_S_MATCH_INFO			113									//比赛信息
#define SUB_S_TIME_INFO				114									//倍数信息
#define SUB_S_ERROR					115									//异常消息

//发送扑克
struct CMD_S_SendCard
{
	WORD							wStartUser;							//开始玩家
	WORD				 			wCurrentUser;						//当前玩家
	BYTE							cbCardData[NORMAL_COUNT];			//扑克列表
	SCORE							wServiceCharge;						//服务费
};

//机器人扑克
struct CMD_S_AndroidCard
{
	BYTE							cbHandCard[GAME_PLAYER][NORMAL_COUNT];//手上扑克
	WORD							wCurrentUser ;						//当前玩家

	BYTE							cbBankerCard[GAME_PLAYER];			//庄家扑克
	BYTE							cbCardCount[GAME_PLAYER];			//手牌数量
	bool							bGameSenceMsg;						//是否是跟随场景消息
};

//用户叫地主
struct CMD_S_CallBanker
{
	WORD				 			wCurrentUser;						//当前玩家
	WORD							wCallUser;							//叫地主玩家
	BYTE							cbCallInfo;							//叫地主
	WORD							wUserTime[GAME_PLAYER];				//倍数
};

//用户抢地主
struct CMD_S_RodBanker
{
	WORD							wRodBankerTime;						//抢地主倍数

	WORD				 			wBankerUser;						//庄家玩家
	WORD				 			wCurrentUser;						//当前玩家	
	WORD							wLastUser;							//抢地主玩家
	BYTE							cbRodlInfo;							//抢地主
};

//庄家信息
struct CMD_S_BankerInfo
{
	WORD				 			wBankerUser;						//庄家玩家
	WORD				 			wCurrentUser;						//当前玩家
	BYTE							cbBankerCard[3];					//庄家扑克
	BYTE							cbDoubleInfo[GAME_PLAYER];			//能否加倍
};

//加倍信息
struct CMD_S_Double
{
	WORD							wCurrentUser;						//当前用户
	WORD				 			wBankerUser;						//庄家玩家
	WORD							wLastUser;							//上一个加倍用户
	BYTE							cbDouble;							//是否加倍
	BYTE							cbCurrStatus;						//当前状态:0:第一轮,1:第二轮
	WORD							wUserTime[GAME_PLAYER];				//倍数
};

//开始信息
struct CMD_S_GameStart
{
	WORD				 			wBankerUser;						//庄家玩家
	WORD				 			wCurrentUser;						//当前玩家
	BYTE							cbCardData[MAX_COUNT];				//扑克数据
	BYTE							cbBankerCard[3];					//庄家扑克
	WORD							wUserTime[GAME_PLAYER];				//倍数
	SCORE							lFeeScore[GAME_PLAYER];				//服务费
};

//用户出牌
struct CMD_S_OutCard
{
	BYTE							cbCardCount;						//出牌数目
	WORD				 			wCurrentUser;						//当前玩家
	WORD							wOutCardUser;						//出牌玩家
	BYTE							cbCardType;							//牌型
	BYTE							cbCardData[MAX_COUNT];				//扑克列表
};

//用户托管
struct CMD_S_Trustee
{
	WORD				 			wChairID;							//当前玩家
	bool							bTrustee;							//托管或取消
};

//放弃出牌
struct CMD_S_PassCard
{
	BYTE							cbTurnOver;							//一轮结束
	WORD				 			wCurrentUser;						//当前玩家
	WORD				 			wPassCardUser;						//放弃玩家
};

//用户看牌
struct CMD_S_LookCard
{
	WORD				 			wChairID;							//当前玩家
};

//游戏结束
struct CMD_S_GameConclude
{
	//积分变量
	SCORE							lCellScore;							//单元积分
	SCORE							lGameScore[GAME_PLAYER];			//游戏积分
	SCORE							lFeeScore[GAME_PLAYER];				//服务费

	//春天标志
	BYTE							bChunTian;							//春天标志
	BYTE							bFanChunTian;						//春天标志

	//炸弹信息
	BYTE							cbBombCount;						//炸弹个数
	BYTE							cbEachBombCount[GAME_PLAYER];		//炸弹个数

	//游戏信息
	BYTE							cbCardCount[GAME_PLAYER];			//扑克数目
	BYTE							cbHandCardData[FULL_COUNT];			//扑克列表

	//结束原因
	BYTE							cbReason;							//结束原因

	//补充结算信息
	BYTE							cbScoreType[GAME_PLAYER];			//积分结束类型(1:封顶 2:破产)
	WORD				 			wRobTime[GAME_PLAYER];				//抢地主倍数
	BYTE							cbCardInit[MAX_COUNT];				//初始牌数据
	WORD							wKindWinStreak[GAME_PLAYER];		//连赢局数
	//UserMadel						tagUserMadel[GAME_PLAYER];			//勋章信息
	WORD							wUserTime[GAME_PLAYER];				//玩家倍数
};

//比赛信息
struct CMD_S_MatchInfo
{
	BYTE							cbRoundCount[GAME_PLAYER];			//当前轮数
	BYTE							cbPlayGameCount;					//当前局数
	WORD							wChairID;							//当前用户
	SCORE							lMatchScore[GAME_PLAYER];			//比赛金币
	SCORE							lMinEnterScore;						//最少积分
};
struct CMD_S_TIME_INFO
{
	WORD				 			wRobTime;							//抢地主倍数
	WORD							wBoomTime;							//炸弹倍数
	WORD							wCurTime;							//当前倍数
};
//////////////////////////////////////////////////////////////////////////////////
//命令定义

#define SUB_C_CALL_BANKER			1									//用户叫地主
#define SUB_C_DOUBLE				2									//用户加倍
#define SUB_C_LOOK_CARD				4									//用户看牌
#define SUB_C_OUT_CARD				5									//用户出牌
#define SUB_C_PASS_CARD				6									//用户放弃
#define SUB_C_USER_TRUSTEE			7									//用户托管
#define SUB_C_TIME_INFO				8									//用户倍数

//用户地主
struct CMD_C_CallBanker
{				
	BYTE							cbCallInfo;							//叫地主
};

//用户加倍
struct CMD_C_Double
{				
	BYTE							cbDoubleInfo;						//加倍信息
};

//用户托管
struct CMD_C_Trustee
{
	bool							bTrustee;							//托管标识
};

//用户出牌
struct CMD_C_OutCard
{
	BYTE							cbCardCount;						//出牌数目
	BYTE							cbCardData[MAX_COUNT];				//扑克数据
};

//////////////////////////////////////////////////////////////////////////////////

#pragma pack()

#endif