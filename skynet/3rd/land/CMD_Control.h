#pragma once

#define 	CTRL_VERSION			747845

//�û���Ϣ
struct tagUserDataInfo
{
	DWORD					dwUserID;					//UserID
	DWORD					dwGameID;					//GameID
	SCORE					lUserScore;					//�û����
	SCORE					lInsure;					//�û�����
	WORD					wTableID;					//����
	TCHAR					szNickName[LEN_NICKNAME];	//�û��ǳ�
	BYTE					cbRoundCount;				//��ǰ����

	//��Ӯ
	SCORE                   lTotalLostScore;            //������Ӯ
	SCORE                   lDailyLostScore;            //������Ӯ

	//���г�ֵ
	SCORE					lChargeScore;				//�ۼƳ�ֵ
	SCORE					lDailyChargeScore;			//���ճ�ֵ
	SCORE					lTransferIn;				//���ת��
	SCORE					lTransferOut;				//���ת��
	SCORE					lBuyScore;					//���
	SCORE					lSellScore;					//����
	SCORE					lDistrScore;				//��Ӯ����
	LONG					lDiffiucult;				//�����Ѷ�
	TCHAR					szUserAttribute[32];		//������
	TCHAR					szSpreaderName[LEN_NICKNAME];	//�ƹ�Ա
};

//////////////////////////////////////////////////////////////////////////

#define MDM_CF_CONTROL              2800

#define SUB_C_QUERY_ROOM_NAME        99
#define SUB_C_QUERY_INFO            100
#define SUB_C_QUERY_USER_LIST       101
#define SUB_C_MODIFY_CONFIG			106
#define SUB_C_MODIFY_LUCK			107
#define SUB_C_RESET_STOCK			108

//ϵͳ����
struct CMD_C_ModifyConfig
{
	BYTE							cbPlayGameCount;					//ÿ�־���
	BYTE							cbAwardCount;						//��������
	SCORE							lFirMatchScore;						//��������
	SCORE							lSecMatchScore;						//��������
	SCORE							lThiMatchScore;						//��������

	SCORE							lFirFeeScore;						//��1��ÿ�ַ����
	SCORE							lSecFeeScore;						//��2��ÿ�ַ����
	SCORE							lThiFeeScore;						//��3��ÿ�ַ����
};

//��������
struct CMD_C_ModifyLuck
{
	WORD							wAndroidInitChance;					//�����˳�ʼ����
	WORD							wAndroidStepChance;					//�����˲�������

	WORD							wUserInitChance;					//�û���ʼ����
	WORD							wUserStepChance;					//�û���������

	WORD							wMasterInitChance;					//����Ա��ʼ����
	WORD							wMasterStepChance;					//����Ա��������
};
//�������
struct CMD_C_ModifyStock
{
	SCORE							dwStockScore;						//��ǰ���
	SCORE							dwLoseLimit;						//��������
};

#define SUB_S_QUERY_REQUEST         101						//��ѯ����
#define SUB_S_USER_LIST				103						//�û��б�
#define SUB_S_USER_LIST_BEGIN		104						//�б�ʼ
#define SUB_S_USER_LIST_END			105						//�б����	
#define SUB_S_ROOM_INFO				106						//������Ϣ

struct CMD_S_RoomInfo
{
	TCHAR							szRoomName[LEN_SERVER];
	WORD							wServerID;
	WORD							wServerType;
};

struct CMD_S_QueryInfo
{
	BYTE							cbPlayGameCount;					//ÿ�־���
	BYTE							cbAwardCount;						//��������
	SCORE							lFirMatchScore;						//��������
	SCORE							lSecMatchScore;						//��������
	SCORE							lThiMatchScore;						//��������

	SCORE							lFirFeeScore;						//��1��ÿ�ַ����
	SCORE							lSecFeeScore;						//��2��ÿ�ַ����
	SCORE							lThiFeeScore;						//��3��ÿ�ַ����

	DWORD							dwTotalGameCount;					//�ܵ���Ϸ����
	DWORD							dwTotalAwardCount;					//�ܵĻ񽱴���
	DWORD							dwDailyGameCount;					//ÿ����Ϸ����
	DWORD							dwDailyAwardCount;					//ÿ�ջ񽱴���
	SCORE							lRevenueScore;						//˰��

	WORD							wAndroidInitChance;					//�����˳�ʼ����
	WORD							wAndroidStepChance;					//�����˲�������

	WORD							wUserInitChance;					//�û���ʼ����
	WORD							wUserStepChance;					//�û���������

	WORD							wMasterInitChance;					//����Ա��ʼ����
	WORD							wMasterStepChance;					//����Ա��������

	SCORE							dwStoreScore;						//��ǰ���
	SCORE							dwLoseLimit;						//��������
};
