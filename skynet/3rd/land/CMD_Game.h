#ifndef CMD_GAME_HEAD_FILE
#define CMD_GAME_HEAD_FILE

#include <assert.h>

#pragma pack(1)


//////////////////////////////////////////////////////////////////////////
// {{{ ���Ӷ��� ��by lyx 2018-9-29��

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
//������

//��Ϸ����
#define KIND_ID						35									//��Ϸ I D
#define GAME_NAME					TEXT("������")					//��Ϸ����

//�������
#define GAME_PLAYER					3									//��Ϸ����
#define VERSION_SERVER				PROCESS_VERSION(1,0,11)				//����汾
#define VERSION_CLIENT				PROCESS_VERSION(1,0,9)				//����汾

//////////////////////////////////////////////////////////////////////////////////

//��Ŀ����
#define MAX_COUNT					20									//�����Ŀ
#define FULL_COUNT					54									//ȫ����Ŀ

//�߼���Ŀ
#define NORMAL_COUNT				17									//������Ŀ
#define DISPATCH_COUNT				51									//�ɷ���Ŀ

#define MAX_GOOD_RATE               10000								//����Ϊ��ֱ�

//��ֵ����
#define	MASK_COLOR					0xF0								//��ɫ����
#define	MASK_VALUE					0x0F								//��ֵ����

//�߼�����
#define CT_ERROR					0									//��������
#define CT_SINGLE					1									//��������
#define CT_DOUBLE					2									//��������
#define CT_THREE					3									//�������ͣ�lyx: ������
#define CT_SINGLE_LINE				4									//��������
#define CT_DOUBLE_LINE				5									//��������
#define CT_THREE_LINE				6									//��������
#define CT_THREE_TAKE_ONE			7									//����һ��
#define CT_THREE_TAKE_TWO			8									//����һ��
#define CT_FOUR_TAKE_ONE			9									//�Ĵ�����
#define CT_FOUR_TAKE_TWO			10									//�Ĵ�����
#define CT_BOMB_CARD				11									//ը������
#define CT_MISSILE_CARD				12									//�������

//��������
//#define BCT_GENERAL					0									//��ͨ����
//#define BCT_FULSH					1									//˳������
//#define BCT_STRAIGHT				2									//ͬ������
//#define BCT_STRAIGHT_FULSH			3									//ͬ��˳����
//#define BCT_SINGLE_MISSILE			4									//��������
//#define BCT_DOUBLE_MISSILE			5									//��������
//#define BCT_THREE					6									//��������

//////////////////////////////////////////////////////////////////////////////////
//��־�ȼ�����

#define LOG_LEVEL_DEBUG				0x00								//debug�ȼ�
#define LOG_LEVEL_ERROR				0x01								//error�ȼ�
#define LOG_LEVEL_WARN				0x02								//warn�ȼ�
#define LOG_LEVEL_INFO				0x03								//info�ȼ�

//////////////////////////////////////////////////////////////////////////////////
//״̬����

#define GAME_SCENE_FREE				GAME_STATUS_FREE					//�ȴ���ʼ
#define GAME_SCENE_CALL				GAME_STATUS_PLAY					//�е���״̬
#define GAME_SCENE_ADD				GAME_STATUS_PLAY+1					//�ӱ�״̬
#define GAME_SCENE_PLAY				GAME_STATUS_PLAY+2					//��Ϸ����

//�е���
#define CB_NOT_CALL					0									//û�е���
#define CB_MEN_BENKER				1									//��ץ
#define CB_CALL_BENKER				2									//ץ��
#define CB_NO_CALL_BENKER			3									//���е���

//�ӱ���Ϣ
#define CB_NOT_ADD_DOUBLE			0									//û�ӱ�
#define CB_ADD_DOUBLE				1									//�ӱ���־
#define CB_NO_ADD_DOUBLE			2									//���ӱ�

//��ҽ����������
#define ScoreType_Max				1								//�ⶥ
#define ScoreType_bankruptcy		2								//�Ʋ�
//�Խ�������
#define RULE_3_0					0x01					//����������
#define RULE_4_1					0x02					//ֻ���Ĵ�����lyx�� �����Ĵ� �� ������
#define RULE_No_La					0x04					//û������
#define RULE_ShuangWang				0x08					//˫����ץ
#define RULE_3Zhua					0x10					//��������ץ
#define RULE_Max_Time8				0x20					//8���ⶥ
#define RULE_Max_Time16				0x40					//16���ⶥ
#define RULE_Max_Time32				0x80					//32���ⶥ
#define RULE_Max_Time				0x0200					//���ⶥ
#define RULE_Off					0x0100					//ȫ��ʹ�����������Ĵ����Ŀ���
#define RULE_3_2					0x0400					//����������
#define RULE_4_2					0x0800					//�����Ĵ���
//����״̬
struct CMD_S_StatusFree
{
	//��Ϸ����
	SCORE							lCellScore;							//��������

	//ʱ����Ϣ
	BYTE							cbTimeCallBanker;					//�е���ʱ��
	BYTE							cbTimeAddDouble;					//�ӱ�ʱ��
	BYTE							cbTimeOutCard;						//����ʱ��
	BYTE							cbTimeStartGame;					//��ʼʱ��
	BYTE							cbTimeHeadOutCard;					//�׳�ʱ��

	//��ʷ����
	SCORE							lTurnScore[GAME_PLAYER];			//������Ϣ
	SCORE							lCollectScore[GAME_PLAYER];			//������Ϣ
	//Ԫ����������
	SCORE							lMinEnterScore;
	SCORE							lMinExitScore;
	DWORD							dwPPRule;
	SCORE							lServiceCharge;						//�����
};

//�з�״̬
struct CMD_S_StatusCall
{
	//ʱ����Ϣ
	BYTE							cbTimeOutCard;						//����ʱ��
	BYTE							cbTimeCallBanker;					//�е���ʱ��
	BYTE							cbTimeAddDouble;					//�ӱ�ʱ��
	BYTE							cbTimeStartGame;					//��ʼʱ��
	BYTE							cbTimeHeadOutCard;					//�׳�ʱ��

	//��Ϸ��Ϣ
	SCORE							lCellScore;							//��Ԫ����
	WORD							wCurrentUser;						//��ǰ���
	WORD							wFirstUser;							//�׽��û�
	BYTE							cbCallBankerInfo[GAME_PLAYER];		//�е�����Ϣ
	BYTE							cbLookCard;							//���Ʊ�ʶ
	BYTE							cbHandCardData[NORMAL_COUNT];		//�����˿�
	WORD							wUserTime[GAME_PLAYER];				//�û�����

	//��ʷ����
	SCORE							lTurnScore[GAME_PLAYER];			//������Ϣ
	SCORE							lCollectScore[GAME_PLAYER];			//������Ϣ
	//Ԫ����������
	SCORE							lMinEnterScore;
	SCORE							lMinExitScore;
	DWORD							dwPPRule;
	BYTE							cbTimeLeave;						//ʣ��ʱ��
};

//�ӱ�״̬
struct CMD_S_StatusDouble
{
	//ʱ����Ϣ
	BYTE							cbTimeCallBanker;					//�е���ʱ��
	BYTE							cbTimeAddDouble;					//�ӱ�ʱ��
	BYTE							cbTimeStartGame;					//��ʼʱ��
	BYTE							cbTimeHeadOutCard;					//�׳�ʱ��
	BYTE							cbTimeOutCard;						//����ʱ��

	//��Ϸ��Ϣ
	SCORE							lCellScore;							//��Ԫ����
	WORD							wBankerUser;						//ׯ���û�
	WORD							wCurrentUser;						//��ǰ�û�

	BYTE							cbCallBankerInfo[GAME_PLAYER];		//�е�����Ϣ	
	BYTE							cbAddDoubleInfo1[GAME_PLAYER];		//�ӱ���Ϣ
	BYTE							cbAddDoubleInfo2[GAME_PLAYER];		//�ӱ���Ϣ
	BYTE							cbLookCard;							//���Ʊ�ʶ
	BYTE							cbCurrStatus;						//��ǰ״̬:0:��һ��,1:�ڶ���

	//�˿���Ϣ
	BYTE							cbBankerCard[3];					//��Ϸ����
	BYTE							cbHandCardCount[GAME_PLAYER];		//�˿���Ŀ
	BYTE							cbHandCardData[MAX_COUNT];			//�����˿�
	WORD							wUserTime[GAME_PLAYER];				//�û�����

	//��ʷ����
	SCORE							lTurnScore[GAME_PLAYER];			//������Ϣ
	SCORE							lCollectScore[GAME_PLAYER];			//������Ϣ
	//Ԫ����������
	SCORE							lMinEnterScore;
	SCORE							lMinExitScore;
	DWORD							dwPPRule;
	BYTE							cbTimeLeave;						//ʣ��ʱ��
};

//��Ϸ״̬
struct CMD_S_StatusPlay
{
	//ʱ����Ϣ
	BYTE							cbTimeOutCard;						//����ʱ��
	BYTE							cbTimeCallBanker;					//�е���ʱ��
	BYTE							cbTimeAddDouble;					//�ӱ�ʱ��
	BYTE							cbTimeStartGame;					//��ʼʱ��
	BYTE							cbTimeHeadOutCard;					//�׳�ʱ��

	//��Ϸ����
	LONG							lCellScore;							//��Ԫ����
	BYTE							cbBombCount;						//ը������
	WORD							wBankerUser;						//ׯ���û�
	WORD							wCurrentUser;						//��ǰ���

	WORD							wBombTime;							//ը������
	BYTE							cbCallBankerInfo[GAME_PLAYER];		//�е�����Ϣ	
	BYTE							cbAddDoubleInfo1[GAME_PLAYER];		//�ӱ���Ϣ
	BYTE							cbAddDoubleInfo2[GAME_PLAYER];		//�ӱ���Ϣ

	//������Ϣ
	WORD							wTurnWiner;							//ʤ�����
	BYTE							cbTurnCardCount;					//������Ŀ
	BYTE							cbTurnCardData[MAX_COUNT];			//��������
	WORD							wUserTime[GAME_PLAYER];				//�û�����

	//�˿���Ϣ
	BYTE							cbBankerCard[3];					//��Ϸ����
	BYTE							cbHandCardCount[GAME_PLAYER];		//�˿���Ŀ
	BYTE							cbHandCardData[MAX_COUNT];			//�����˿�

	//��ʷ����
	SCORE							lTurnScore[GAME_PLAYER];			//������Ϣ
	SCORE							lCollectScore[GAME_PLAYER];			//������Ϣ
	BYTE							cbCardCountInfo[15];				//����������
	//Ԫ����������
	SCORE							lMinEnterScore;
	SCORE							lMinExitScore;
	DWORD							dwPPRule;
	BYTE							cbTimeLeave;						//ʣ��ʱ��
	bool							bTrustee[GAME_PLAYER];				//����й�״̬
};

//////////////////////////////////////////////////////////////////////////////////
//�����

#define SUB_S_SNED_CARD				99									//�����˿�
#define SUB_S_GAME_START			100									//��Ϸ��ʼ
#define SUB_S_CALL_BANKER			101									//�е���
#define SUB_S_BANKER_INFO			102									//ׯ����Ϣ
#define SUB_S_LOOK_CARD				103									//�û�����
#define SUB_S_DOUBLE				104									//�ӱ���Ϣ
#define SUB_S_OUT_CARD				106									//�û�����
#define SUB_S_PASS_CARD				107									//�û�����
#define SUB_S_GAME_CONCLUDE			109									//��Ϸ����
#define SUB_S_SET_BASESCORE			110									//���û���
#define SUB_S_CHEAT_CARD			111									//�����˿�
#define SUB_S_USER_TRUSTEE			112									//�û��й�
#define SUB_S_MATCH_INFO			113									//������Ϣ
#define SUB_S_TIME_INFO				114									//������Ϣ
#define SUB_S_ERROR					115									//�쳣��Ϣ

//�����˿�
struct CMD_S_SendCard
{
	WORD							wStartUser;							//��ʼ���
	WORD				 			wCurrentUser;						//��ǰ���
	BYTE							cbCardData[NORMAL_COUNT];			//�˿��б�
	SCORE							wServiceCharge;						//�����
};

//�������˿�
struct CMD_S_AndroidCard
{
	BYTE							cbHandCard[GAME_PLAYER][NORMAL_COUNT];//�����˿�
	WORD							wCurrentUser ;						//��ǰ���

	BYTE							cbBankerCard[GAME_PLAYER];			//ׯ���˿�
	BYTE							cbCardCount[GAME_PLAYER];			//��������
	bool							bGameSenceMsg;						//�Ƿ��Ǹ��泡����Ϣ
};

//�û��е���
struct CMD_S_CallBanker
{
	WORD				 			wCurrentUser;						//��ǰ���
	WORD							wCallUser;							//�е������
	BYTE							cbCallInfo;							//�е���
	WORD							wUserTime[GAME_PLAYER];				//����
};

//�û�������
struct CMD_S_RodBanker
{
	WORD							wRodBankerTime;						//����������

	WORD				 			wBankerUser;						//ׯ�����
	WORD				 			wCurrentUser;						//��ǰ���	
	WORD							wLastUser;							//���������
	BYTE							cbRodlInfo;							//������
};

//ׯ����Ϣ
struct CMD_S_BankerInfo
{
	WORD				 			wBankerUser;						//ׯ�����
	WORD				 			wCurrentUser;						//��ǰ���
	BYTE							cbBankerCard[3];					//ׯ���˿�
	BYTE							cbDoubleInfo[GAME_PLAYER];			//�ܷ�ӱ�
};

//�ӱ���Ϣ
struct CMD_S_Double
{
	WORD							wCurrentUser;						//��ǰ�û�
	WORD				 			wBankerUser;						//ׯ�����
	WORD							wLastUser;							//��һ���ӱ��û�
	BYTE							cbDouble;							//�Ƿ�ӱ�
	BYTE							cbCurrStatus;						//��ǰ״̬:0:��һ��,1:�ڶ���
	WORD							wUserTime[GAME_PLAYER];				//����
};

//��ʼ��Ϣ
struct CMD_S_GameStart
{
	WORD				 			wBankerUser;						//ׯ�����
	WORD				 			wCurrentUser;						//��ǰ���
	BYTE							cbCardData[MAX_COUNT];				//�˿�����
	BYTE							cbBankerCard[3];					//ׯ���˿�
	WORD							wUserTime[GAME_PLAYER];				//����
	SCORE							lFeeScore[GAME_PLAYER];				//�����
};

//�û�����
struct CMD_S_OutCard
{
	BYTE							cbCardCount;						//������Ŀ
	WORD				 			wCurrentUser;						//��ǰ���
	WORD							wOutCardUser;						//�������
	BYTE							cbCardType;							//����
	BYTE							cbCardData[MAX_COUNT];				//�˿��б�
};

//�û��й�
struct CMD_S_Trustee
{
	WORD				 			wChairID;							//��ǰ���
	bool							bTrustee;							//�йܻ�ȡ��
};

//��������
struct CMD_S_PassCard
{
	BYTE							cbTurnOver;							//һ�ֽ���
	WORD				 			wCurrentUser;						//��ǰ���
	WORD				 			wPassCardUser;						//�������
};

//�û�����
struct CMD_S_LookCard
{
	WORD				 			wChairID;							//��ǰ���
};

//��Ϸ����
struct CMD_S_GameConclude
{
	//���ֱ���
	SCORE							lCellScore;							//��Ԫ����
	SCORE							lGameScore[GAME_PLAYER];			//��Ϸ����
	SCORE							lFeeScore[GAME_PLAYER];				//�����

	//�����־
	BYTE							bChunTian;							//�����־
	BYTE							bFanChunTian;						//�����־

	//ը����Ϣ
	BYTE							cbBombCount;						//ը������
	BYTE							cbEachBombCount[GAME_PLAYER];		//ը������

	//��Ϸ��Ϣ
	BYTE							cbCardCount[GAME_PLAYER];			//�˿���Ŀ
	BYTE							cbHandCardData[FULL_COUNT];			//�˿��б�

	//����ԭ��
	BYTE							cbReason;							//����ԭ��

	//���������Ϣ
	BYTE							cbScoreType[GAME_PLAYER];			//���ֽ�������(1:�ⶥ 2:�Ʋ�)
	WORD				 			wRobTime[GAME_PLAYER];				//����������
	BYTE							cbCardInit[MAX_COUNT];				//��ʼ������
	WORD							wKindWinStreak[GAME_PLAYER];		//��Ӯ����
	//UserMadel						tagUserMadel[GAME_PLAYER];			//ѫ����Ϣ
	WORD							wUserTime[GAME_PLAYER];				//��ұ���
};

//������Ϣ
struct CMD_S_MatchInfo
{
	BYTE							cbRoundCount[GAME_PLAYER];			//��ǰ����
	BYTE							cbPlayGameCount;					//��ǰ����
	WORD							wChairID;							//��ǰ�û�
	SCORE							lMatchScore[GAME_PLAYER];			//�������
	SCORE							lMinEnterScore;						//���ٻ���
};
struct CMD_S_TIME_INFO
{
	WORD				 			wRobTime;							//����������
	WORD							wBoomTime;							//ը������
	WORD							wCurTime;							//��ǰ����
};
//////////////////////////////////////////////////////////////////////////////////
//�����

#define SUB_C_CALL_BANKER			1									//�û��е���
#define SUB_C_DOUBLE				2									//�û��ӱ�
#define SUB_C_LOOK_CARD				4									//�û�����
#define SUB_C_OUT_CARD				5									//�û�����
#define SUB_C_PASS_CARD				6									//�û�����
#define SUB_C_USER_TRUSTEE			7									//�û��й�
#define SUB_C_TIME_INFO				8									//�û�����

//�û�����
struct CMD_C_CallBanker
{				
	BYTE							cbCallInfo;							//�е���
};

//�û��ӱ�
struct CMD_C_Double
{				
	BYTE							cbDoubleInfo;						//�ӱ���Ϣ
};

//�û��й�
struct CMD_C_Trustee
{
	bool							bTrustee;							//�йܱ�ʶ
};

//�û�����
struct CMD_C_OutCard
{
	BYTE							cbCardCount;						//������Ŀ
	BYTE							cbCardData[MAX_COUNT];				//�˿�����
};

//////////////////////////////////////////////////////////////////////////////////

#pragma pack()

#endif