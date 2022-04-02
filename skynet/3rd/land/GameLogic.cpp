#include <string.h>
#include <stdio.h>
#include <memory.h>

#include <algorithm>
#include "CMD_Game.h"
#include "CMD_Control.h"
#include "GameLogic.h"

#include "GameUserItemSink.h"

using namespace std;
//////////////////////////////////////////////////////////////////////////
const size_t nBadSearch=99999999; //搜索错误

//索引变量
const BYTE cbIndexCount=5;

static	size_t m_nTimeLimit=2000;
static	size_t m_nDepthLimit=54;
//搜索次数
size_t m_nSearchCount=0;
size_t m_nDepthCount=0;

#ifdef USE_LOG_TRACE
CFunTrace g_FunTrace;
#endif

//扑克数据
const BYTE	CGameLogic::m_cbCardData[FULL_COUNT]=
{
	0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,	//方块 A - K
	0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,	//梅花 A - K
	0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D,	//红桃 A - K
	0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x3B,0x3C,0x3D,	//黑桃 A - K
	0x41,0x42,
};

void CHECK_CARD_ARRAY(const BYTE cbCardData[],BYTE cbCardCount,BYTE maxCount /*= -1*/)
{
	ASSERT(maxCount == -1 || cbCardCount <= maxCount);

	for (BYTE i=0;i < cbCardCount; ++ i)
	{
		CHECK_CARD(cbCardData[i]);
	}
}

//用于连排序
bool less_linkcount(const tagLinkCard &st1,const tagLinkCard & st2)
{
	// 牌数目小
	if (st1.cbCardCount < st2.cbCardCount)
		return true;
	
	// 牌数目大
	if (st1.cbCardCount > st2.cbCardCount)
		return false;

	// 牌数目一致，比较牌逻辑值
	return (st1.cbLogicValue < st2.cbLogicValue);
}


//用与牌型牌型
bool less_value(const tagOutCard &st1,const tagOutCard &st2)
{
	return (st1.cbLogicValue<st2.cbLogicValue);
}

//打印扑克
// del by lyx 2018-9-29
// void PrintCardData(const BYTE cbCardData[],BYTE cbCardCount,CString &str)
// {
// 	for (int i=0;i<cbCardCount;i++)
// 		str.AppendFormat(TEXT("%02X,"),cbCardData[i]);
// 	return;
// }

std::string cardDataToString(const BYTE * data,BYTE len)
{
	std::string ret;

	for (int i=0;i<len;++i)
	{
		char buf[10] = {0};
		sprintf(buf,"%02X",data[i]);

		if (0 != i)
			ret.append(",");

		ret.append(buf);
	}

	return ret;
}

bool equalCardData(const BYTE data1[],BYTE len1,const BYTE data2[],BYTE len2)
{
	if (len1 != len2)
		return false;

	for (BYTE i=0;i<len1;++i)
		if (data1[i] != data2[i])
			return false;

	return true;
}

void CheckGameLogicData(CGameLogic * pLogic,CGameUserItemSink *userSink)
{
	// 比较手上的牌
	ASSERT(equalCardData(pLogic->m_cbAllCardData[userSink->m_wMeChairID],
				pLogic->m_cbAllCount[userSink->m_wMeChairID],
				userSink->m_cbHandCardData,userSink->m_cbHandCardCount[userSink->m_wMeChairID]));

	ASSERT(pLogic->m_cbAllCount[0] == userSink->m_cbHandCardCount[0]);
	ASSERT(pLogic->m_cbAllCount[1] == userSink->m_cbHandCardCount[1]);
	ASSERT(pLogic->m_cbAllCount[2] == userSink->m_cbHandCardCount[2]);

	// 上次出牌
	ASSERT(pLogic->m_LastOutCard.wOutUser == userSink->m_wOutChairID);
	ASSERT(pLogic->m_cbOutCount[0] == userSink->m_cbOutCount[0]);
	ASSERT(pLogic->m_cbOutCount[1] == userSink->m_cbOutCount[1]);
	ASSERT(pLogic->m_cbOutCount[2] == userSink->m_cbOutCount[2]);
}

//////////////////////////////////////////////////////////////////////////

//构造函数
CGameLogic::CGameLogic()
{
	m_userSink = nullptr;

	ZeroMemory(m_cbLandScoreCardData, sizeof(m_cbLandScoreCardData));
	ZeroMemory(m_cbAllCount, sizeof(m_cbAllCount));

	ZeroMemory(m_cbAllCardData, sizeof(m_cbAllCardData));
	m_wBankerUser = INVALID_CHAIR;
	m_bMayChunTian = false;

	ZeroMemory(m_cbOutCount, sizeof(m_cbOutCount));
	ZeroMemory(&m_LastOutCard, sizeof(tagLastOutCard));

	_wNextUser = INVALID_CHAIR;
	_wFrontUser = INVALID_CHAIR;
	_wAllyID = INVALID_CHAIR;
	_wAfterBanker = INVALID_CHAIR;
	_wFrontBanker = INVALID_CHAIR;

	_bCanBomb = false;
	_bTrySearch = false;

	ZeroMemory(_cb2Card, sizeof(_cb2Card));

	_cb2CardCount = 0;
	m_ppRule = 0;

	ZeroMemory(&_stTurnCard, sizeof(tagOutCard));

	ZeroMemory(&_stAnalyseResult, sizeof(tagAnalyseResult));
}

//析构函数
CGameLogic::~CGameLogic()
{
	// by lyx 2018-9-29

	while(!m_SearchItemPool.empty())
	{
		SafeDelete(m_SearchItemPool.back());
		m_SearchItemPool.pop_back();
	}
}

void CGameLogic::SetppRule(DWORD rule)
{ 
	printf("\n\n------------- SetppRule ------------\n");
	if (rule & RULE_3_0) printf("\t RULE_3_0 \n");
	if (rule & RULE_4_1) printf("\t RULE_4_1 \n");
	if (rule & RULE_No_La) printf("\t RULE_No_La \n");
	if (rule & RULE_ShuangWang) printf("\t RULE_ShuangWang \n");
	if (rule & RULE_3Zhua) printf("\t RULE_3Zhua \n");
	if (rule & RULE_Max_Time8) printf("\t RULE_Max_Time8 \n");
	if (rule & RULE_Max_Time16) printf("\t RULE_Max_Time16 \n");
	if (rule & RULE_Max_Time32) printf("\t RULE_Max_Time32 \n");
	if (rule & RULE_Max_Time) printf("\t RULE_Max_Time \n");
	if (rule & RULE_Off) printf("\t RULE_Off \n");
	if (rule & RULE_3_2) printf("\t RULE_3_2 \n");
	if (rule & RULE_4_2) printf("\t RULE_4_2 \n");
	printf("---------------------------------------\n\n");

	m_ppRule = rule; 
}

//获取类型
BYTE CGameLogic::GetCardType(const BYTE cbCardData[], BYTE cbCardCount)
{
	tagAnalyseResult stAnalyseResult;
	return AnalyseOutCard(cbCardData,cbCardCount,stAnalyseResult);
}

//分析出牌
BYTE CGameLogic::AnalyseOutCard(const BYTE cbTurnCardData[],BYTE cbTurnCardCount,tagOutCard &stOutCard)
{
	tagAnalyseResult stARlt;
	AnalyseOutCard(cbTurnCardData,cbTurnCardCount,stARlt);
	CHECK_MEMCPY(MAX_COUNT,cbTurnCardCount);
	CopyMemory(stOutCard.cbCardData,cbTurnCardData,cbTurnCardCount);
	stOutCard.cbCardCount=cbTurnCardCount;
	stOutCard.cbCardType=stARlt.cbCardType;
	stOutCard.cbLogicValue=stARlt.cbLogicValue;

	return stOutCard.cbCardType;
}

//分析出牌
BYTE CGameLogic::AnalyseOutCard(const BYTE cbTurnCardData[],BYTE cbTurnCardCount,tagAnalyseResult &stAnalyseResult)
{
	CFunItem tt(__FUNCTION__, TEXT("tc=%d"), cbTurnCardCount);
	//分析手牌
	BYTE cbCardData[MAX_COUNT]={0};
	BYTE cbCardCount=cbTurnCardCount;
	CHECK_MEMCPY(MAX_COUNT,cbCardCount);
	CopyMemory(cbCardData,cbTurnCardData,cbCardCount*sizeof(BYTE));
	SortCardList(cbCardData,cbCardCount,ST_ORDER);
	AnalysebCardData(cbCardData,cbCardCount,stAnalyseResult);

	for (BYTE cbTypeIndex=0;cbTypeIndex<=12;cbTypeIndex++)
	{
		switch (cbTypeIndex)
		{
		case 0://错误类型
			{
				//无牌
				if (cbCardCount==0) return CT_ERROR;
				//火箭不带牌
				if (cbCardCount>2&&cbCardData[0]==0x42&&cbCardData[1]==0x41) return CT_ERROR;

				//错误扑克
				for(int i=0;i<cbCardCount;i++)
				{
					BYTE cbCardValue=GetCardValue(cbCardData[i]);
					BYTE cbCardColor=GetCardColor(cbCardData[i]);

					if (cbCardValue==0||cbCardColor>0x40) return CT_ERROR;
					//if (cbCardColor==0x40&&cbCardValue<0x0E) return CT_ERROR;
					if (cbCardColor<0x40&&cbCardValue>0x0D) return CT_ERROR;
				}
				break;
			}
		case 1://单牌类型
			{
				if (cbCardCount==1)
				{
					stAnalyseResult.cbLogicValue=GetCardLogicValue(cbCardData[0]);
					stAnalyseResult.cbCardType=CT_SINGLE;
					return CT_SINGLE;
				}
				break;
			}
		case 2://对牌类型
			{
				if (cbCardCount==2)
				{
					if(GetCardLogicValue(cbCardData[0])==GetCardLogicValue(cbCardData[1]))
					{
						stAnalyseResult.cbLogicValue=GetCardLogicValue(cbCardData[0]);
						stAnalyseResult.cbCardType=CT_DOUBLE;
						return CT_DOUBLE;
					}
					break;
				}
			}
		case 3://三条类型
			{
				   if (cbCardCount == 3 && stAnalyseResult.cbBlockCount[2] == 1 && IsValidType(CT_THREE, cbCardCount))
				{
					stAnalyseResult.cbCardType=CT_THREE;
					stAnalyseResult.cbLogicValue=GetCardLogicValue(cbCardData[0]);
					return CT_THREE;
				}
				break;
			}
		case 4://单连类型
		case 5://对连类型
		case 6://三连类型
			{
				//单连
				BYTE cbSameCount=1; // 相同牌的数量
				BYTE cbMinLink=5;	// 连续张数
				BYTE cbCardType=CT_SINGLE_LINE;
				//对连
				if (cbTypeIndex==5)
				{
					cbSameCount=2;
					cbMinLink=3;
					cbCardType=CT_DOUBLE_LINE;
				}
				//三连
				else if (cbTypeIndex==6 )
				{
					//if (!IsValidType(CT_THREE, cbCardCount)) break;
					cbSameCount=3;
					cbMinLink=2;
					cbCardType=CT_THREE_LINE;
				}

				//张数不对
				if (stAnalyseResult.cbBlockCount[cbSameCount-1]*cbSameCount!=cbCardCount) break;
				BYTE cbTypeValue=GetCardLogicValue(cbCardData[0]);
				//首牌过大
				if (cbTypeValue>=0x0F) break;
				BYTE cbLinkCount=0;
				for (int i=0;i<stAnalyseResult.cbBlockCount[cbSameCount-1];i++)
				{//连续判断
					BYTE cbCardValue=GetCardLogicValue(stAnalyseResult.cbCardData[cbSameCount-1][i*cbSameCount]);
					if (cbTypeValue-cbCardValue==i) cbLinkCount++;//连的起
					else break;
				}
				if (cbLinkCount<cbMinLink) break;	//连数太小
				if (cbLinkCount*cbSameCount!=cbCardCount) break;//不是连
				stAnalyseResult.cbCardType=cbCardType;
				stAnalyseResult.cbLogicValue=cbTypeValue;

				return cbCardType;
			}
		case 7://三带一单
		case 8://三带一对
			{
				//排除判断
				if (stAnalyseResult.cbBlockCount[3]>0) break; //不能出现炸弹

				//连续判断
				BYTE cbLinkCount=0;
				BYTE cbTypeValue=0xFF;
				for (int i=0;i<stAnalyseResult.cbBlockCount[2];i++)
				{
					if (cbTypeValue==0xFF)
					{//考虑2
						cbTypeValue=GetCardLogicValue(stAnalyseResult.cbCardData[2][3*i]);
						if (cbTypeValue==0x0F&&cbCardCount>5)
						{
							cbTypeValue=0xFF;
							continue;
						}
					}
					BYTE cbValue=GetCardLogicValue(stAnalyseResult.cbCardData[2][3*i]);
					if (cbTypeValue-cbValue==cbLinkCount) cbLinkCount++;
					else
					{
						if (cbLinkCount<2)
						{
							cbLinkCount=1;
							cbTypeValue=cbValue;
						}
						else break;
					}
				}

				if (cbLinkCount*4==cbCardCount )
				{//三带一
					stAnalyseResult.cbCardType=CT_THREE_TAKE_ONE;
					stAnalyseResult.cbLogicValue=cbTypeValue;
					return CT_THREE_TAKE_ONE;
				}

				if (cbLinkCount * 5 == cbCardCount&&stAnalyseResult.cbBlockCount[1] == cbLinkCount && IsValidType(CT_THREE_TAKE_TWO))
				{//三带二
					stAnalyseResult.cbCardType=CT_THREE_TAKE_TWO;
					stAnalyseResult.cbLogicValue=cbTypeValue;
					return CT_THREE_TAKE_TWO;
				}
				break;
			}	
		case 9://四带两单
			{
				   if (cbCardCount == 6 && stAnalyseResult.cbBlockCount[3] == 1 && IsValidType(CT_FOUR_TAKE_ONE, cbCardCount))
				{
					stAnalyseResult.cbCardType=CT_FOUR_TAKE_ONE;
					stAnalyseResult.cbLogicValue=GetCardLogicValue(stAnalyseResult.cbCardData[3][0]);
					return CT_FOUR_TAKE_ONE;
				}
				break;
			}
		case 10://四带两对
			{
				if (cbCardCount==8&&stAnalyseResult.cbBlockCount[3]==1&&stAnalyseResult.cbBlockCount[1]==2)
				{
					stAnalyseResult.cbCardType=CT_FOUR_TAKE_TWO;
					stAnalyseResult.cbLogicValue=GetCardLogicValue(stAnalyseResult.cbCardData[3][0]);
					return CT_FOUR_TAKE_TWO;
				}
				break;
			}
		case 11://炸弹类型
			{
				if (cbCardCount==4&&stAnalyseResult.cbBlockCount[3]==1)
				{
					stAnalyseResult.cbCardType=CT_BOMB_CARD;
					stAnalyseResult.cbLogicValue=GetCardLogicValue(GetCardLogicValue(stAnalyseResult.cbCardData[3][0]));
					return CT_BOMB_CARD;
				}
				break;
			}
		case 12://火箭类型
			{
				if (cbCardData[0]==0x42&&cbCardData[1]==0x41)
				{
					stAnalyseResult.cbLogicValue=0x11;
					stAnalyseResult.cbCardType=CT_MISSILE_CARD;
					return CT_MISSILE_CARD;
				}
				break;
			}
		}
	}

	return CT_ERROR;
}

//排列扑克
VOID CGameLogic::SortCardList(BYTE cbCardData[], BYTE cbCardCount, BYTE cbSortType)
{
	CFunItem tt(__FUNCTION__, TEXT("cc=%d"), cbCardCount);
	//数目过虑
	if (cbCardCount==0) return;
	if (cbSortType==ST_CUSTOM) return;

	// ASSERT(cbCardCount<=FULL_COUNT);
	// by lyx 
	if (cbCardCount>FULL_COUNT)
	{
		THROW_ERROR(-1001);
	}

	if (cbCardCount>FULL_COUNT) return;

	//转换数值
	BYTE cbSortValue[FULL_COUNT];
	for (BYTE i=0;i<cbCardCount;i++) cbSortValue[i]=GetCardLogicValue(cbCardData[i]);	

	//排序操作
	bool bSorted=true;
	BYTE cbSwitchData=0,cbLast=cbCardCount-1;
	do
	{
		bSorted=true;
		for (BYTE i=0;i<cbLast;i++)
		{
			if ((cbSortValue[i]<cbSortValue[i+1])||
				((cbSortValue[i]==cbSortValue[i+1])&&(cbCardData[i]<cbCardData[i+1])))
			{
				//设置标志
				bSorted=false;

				//扑克数据
				cbSwitchData=cbCardData[i];
				cbCardData[i]=cbCardData[i+1];
				cbCardData[i+1]=cbSwitchData;

				//排序权位
				cbSwitchData=cbSortValue[i];
				cbSortValue[i]=cbSortValue[i+1];
				cbSortValue[i+1]=cbSwitchData;
			}	
		}
		cbLast--;
	} while(bSorted==false);

	//数目排序
	if (cbSortType==ST_COUNT)
	{
		//变量定义
		BYTE cbCardIndex=0;

		//分析扑克
		tagAnalyseResult AnalyseResult;
		AnalysebCardData(&cbCardData[cbCardIndex],cbCardCount-cbCardIndex,AnalyseResult);

		//提取扑克
		for (BYTE i=0;i<CountArray(AnalyseResult.cbBlockCount);i++)
		{
			//拷贝扑克
			BYTE cbIndex=CountArray(AnalyseResult.cbBlockCount)-i-1;
			CHECK_MEMCPY(cbCardCount-cbCardIndex,AnalyseResult.cbBlockCount[cbIndex]*(cbIndex+1)*sizeof(BYTE));
			CHECK_MEMCPY(MAX_COUNT-cbCardIndex,AnalyseResult.cbBlockCount[cbIndex]*(cbIndex+1)*sizeof(BYTE));
			CHECK_MEMCPY(cbCardIndex,0);
			CopyMemory(&cbCardData[cbCardIndex],AnalyseResult.cbCardData[cbIndex],AnalyseResult.cbBlockCount[cbIndex]*(cbIndex+1)*sizeof(BYTE));

			//设置索引
			cbCardIndex+=AnalyseResult.cbBlockCount[cbIndex]*(cbIndex+1)*sizeof(BYTE);
		}
	}

	return;
}

//混乱扑克
VOID CGameLogic::RandCardList(BYTE cbCardBuffer[], BYTE cbBufferCount)
{
	//混乱准备
	BYTE cbCardData[CountArray(m_cbCardData)];
	CHECK_MEMCPY(FULL_COUNT,sizeof(m_cbCardData));
	CopyMemory(cbCardData,m_cbCardData,sizeof(m_cbCardData));

	//混乱扑克
	BYTE cbRandCount=0,cbPosition=0;
	do
	{
		cbPosition=rand()%(cbBufferCount-cbRandCount);
		cbCardBuffer[cbRandCount++]=cbCardData[cbPosition];
		cbCardData[cbPosition]=cbCardData[cbBufferCount-cbRandCount];
	} while (cbRandCount<cbBufferCount);

	return;
}
// 获取好牌
VOID CGameLogic::RandGoodCardList(BYTE cbCardBuffer[], BYTE cbBufferCount, WORD UserChairID, BYTE CardType[])
{
	RandCardList(cbCardBuffer, cbBufferCount);
	BYTE CardCount = CardType[0] * 3 + CardType[1] * 4;
	if (CardCount > NORMAL_COUNT || CardCount == 0 ) return;
	//选出需要设置成三/四张的牌点数
	BYTE GoodCard[NORMAL_COUNT];
	ZeroMemory(GoodCard, sizeof(GoodCard));
	//将A到K 打乱排序，数组前面几个值用来制作好牌
	BYTE CardTemp[11] = { 1, 2, 3, 4, 5, 6, 8, 9, 11, 12, 13 };
	BYTE CardValue[11];
	BYTE cbRandCount = 0, cbPosition = 0;
	do
	{
		cbPosition = rand() % (13 - cbRandCount);
		CardValue[cbRandCount++] = CardTemp[cbPosition];
		CardTemp[cbPosition] = CardTemp[13 - cbRandCount];
	} while (cbRandCount < 11);

	//将好牌放入GoodCard数组保存
	CardCount = 0;
	BYTE TempIndex = 0;
	BYTE TempCod[4];
	//先放入三张牌
	for (BYTE index = 0; index < CardType[0];++index)
	{
		ZeroMemory(TempCod, sizeof(TempCod));
		RandCardColor(TempCod, CardValue[TempIndex],3);
		memcpy(&GoodCard[CardCount], TempCod,sizeof(BYTE)*3);
		CardCount += 3;
		TempIndex++;
	}
	//放入炸弹牌
	for (BYTE index = 0; index < CardType[1]; ++index)
	{
		ZeroMemory(TempCod, sizeof(TempCod));
		RandCardColor(TempCod, CardValue[TempIndex], 4);
		memcpy(&GoodCard[CardCount], TempCod, sizeof(BYTE)* 4);
		CardCount += 4;
		TempIndex++;
	}
	//放入一张王牌
	//GoodCard[CardCount++] = rand() % 2 == 0 ? 0x41 : 0x42;
	//将好牌数据放入玩家对应的椅子号
	for (BYTE i = 0; i < CardCount;++i)
	{
		for (BYTE j = 0; j < cbBufferCount;++j)
		{
			if (GoodCard[i] == cbCardBuffer[j])
			{//将好牌放到椅子号对应的下标
				BYTE Temp = cbCardBuffer[i + UserChairID*NORMAL_COUNT];
				cbCardBuffer[i + UserChairID*NORMAL_COUNT] = GoodCard[i];
				cbCardBuffer[j] = Temp;
				break;
			}
		}
	}
	//对好牌玩家的牌重新排序
	ZeroMemory(GoodCard, sizeof(GoodCard));
	cbRandCount = 0;
	BYTE CurIndex = NORMAL_COUNT*UserChairID;
	do
	{
		cbPosition = CurIndex + rand() % (NORMAL_COUNT - cbRandCount);
		GoodCard[cbRandCount++] = cbCardBuffer[cbPosition];
		cbCardBuffer[cbPosition] = cbCardBuffer[CurIndex + NORMAL_COUNT - cbRandCount];
	} while (cbRandCount < NORMAL_COUNT);
	memcpy(&cbCardBuffer[CurIndex], GoodCard, sizeof(GoodCard));
}
//获取差牌
VOID CGameLogic::RandBadCardList(BYTE cbCardBuffer[], BYTE cbBufferCount, WORD UserChairID)
{
	RandCardList(cbCardBuffer, cbBufferCount);
	BYTE GoodChairID = (UserChairID + 1) % GAME_PLAYER;
	//将玩家的王/二 和好牌玩家对家的牌对调
	for (BYTE i = UserChairID*NORMAL_COUNT; i < (UserChairID+1)*NORMAL_COUNT; ++i)
	{
		if (GetCardLogicValue(cbCardBuffer[i]) > 13)
		{
			for (BYTE j = GoodChairID*NORMAL_COUNT; j < (GoodChairID+1)*NORMAL_COUNT; ++j)
			{
				if (GetCardLogicValue(cbCardBuffer[j]) < 13)
				{
					BYTE Temp = cbCardBuffer[i];
					cbCardBuffer[i] = cbCardBuffer[j];
					cbCardBuffer[j] = Temp;
					break;
				}
			}
		}
	}
	SortCardList(&cbCardBuffer[UserChairID*NORMAL_COUNT], NORMAL_COUNT, ST_ORDER);
	tagAnalyseResult AnalyseResult = {};
	AnalysebCardData(&cbCardBuffer[UserChairID*NORMAL_COUNT], NORMAL_COUNT, AnalyseResult);

	//移除炸弹
	for (BYTE i = 0; i < AnalyseResult.cbBlockCount[3]; i++)
	{
		for (BYTE j = UserChairID*NORMAL_COUNT; j < (UserChairID + 1)*NORMAL_COUNT; ++j)
		{
			if (cbCardBuffer[j] == AnalyseResult.cbCardData[3][i * 4])
			{
				for (BYTE k = GoodChairID*NORMAL_COUNT; k < (GoodChairID + 1)*NORMAL_COUNT; ++k)
				{
					if (GetCardLogicValue(cbCardBuffer[k]) < 13)
					{
						BYTE Temp = cbCardBuffer[j];
						cbCardBuffer[j] = cbCardBuffer[k];
						cbCardBuffer[k] = Temp;
						break;
					}
				}
				break;
			}
		}
	}
	//混乱扑克
	BYTE cbCardData[NORMAL_COUNT];
	memcpy(cbCardData, &cbCardBuffer[GoodChairID*NORMAL_COUNT], sizeof(cbCardData));
	BYTE cbRandCount = 0, cbPosition = 0;
	BYTE CurIndex = NORMAL_COUNT*GoodChairID;
	do
	{
		cbPosition = CurIndex + rand() % (NORMAL_COUNT - cbRandCount);
		cbCardData[cbRandCount++] = cbCardBuffer[cbPosition];
		cbCardBuffer[cbPosition] = cbCardBuffer[CurIndex + NORMAL_COUNT - cbRandCount];
	} while (cbRandCount < NORMAL_COUNT);
	memcpy(&cbCardBuffer[CurIndex], cbCardData, sizeof(cbCardData));
}

//获取牌的花色
VOID CGameLogic::RandCardColor(BYTE cbCardCode[], BYTE cbCardValue, BYTE cbCount)
{
	BYTE CardTemp[4];
	BYTE CardCode[4];
	for (BYTE index = 0; index < 4;++index)
	{
		CardTemp[index] = 16 * index + cbCardValue;
	}
	if (cbCount == 4)
	{
		memcpy(cbCardCode, CardTemp, sizeof(BYTE)*cbCount);
		return;
	}
	BYTE cbRandCount = 0, cbPosition = 0;
	do
	{
		cbPosition = rand() % (4 - cbRandCount);
		CardCode[cbRandCount++] = CardTemp[cbPosition];
		CardTemp[cbPosition] = CardTemp[4 - cbRandCount];
	} while (cbRandCount < 4);
	memcpy(cbCardCode, CardCode, sizeof(BYTE)*cbCount);
}
//删除扑克
bool CGameLogic::RemoveCard(const BYTE cbRemoveCard[], BYTE cbRemoveCount, BYTE cbCardData[], BYTE cbCardCount)
{
	//检验数据
	//ASSERT(cbRemoveCount<=cbCardCount);
	if (cbRemoveCount > cbCardCount) return true;

	//定义变量
	BYTE cbDeleteCount=0,cbTempCardData[FULL_COUNT];
	if (cbCardCount>CountArray(cbTempCardData)) return false;
	CHECK_MEMCPY(FULL_COUNT,cbCardCount*sizeof(cbCardData[0]));
	CopyMemory(cbTempCardData,cbCardData,cbCardCount*sizeof(cbCardData[0]));

	//置零扑克
	for (BYTE i=0;i<cbRemoveCount;i++)
	{
		for (BYTE j=0;j<cbCardCount;j++)
		{
			if (cbRemoveCard[i]==cbTempCardData[j])
			{
				cbDeleteCount++;
				cbTempCardData[j]=0;
				break;
			}
		}
	}
	if (cbDeleteCount!=cbRemoveCount) return false;
	ZeroMemory(cbCardData,cbCardCount*sizeof(cbCardData[0]));
	//清理扑克
	BYTE cbCardPos=0;
	for (BYTE i=0;i<cbCardCount;i++)
	{
		if (cbTempCardData[i]!=0) cbCardData[cbCardPos++]=cbTempCardData[i];
	}

	return true;
}

//有效判断
bool CGameLogic::IsValidCard(BYTE cbCardData)
{
	//获取属性
	BYTE cbCardColor=GetCardColor(cbCardData);
	BYTE cbCardValue=GetCardValue(cbCardData);

	//有效判断
	if ((cbCardData==0x41)||(cbCardData==0x42)) return true;
	if ((cbCardColor<=0x30)&&(cbCardValue>=0x01)&&(cbCardValue<=0x0D)) return true;

	return false;
}

//逻辑数值
BYTE CGameLogic::GetCardLogicValue(BYTE cbCardData)
{
	if(cbCardData == 0) return 0;
	//扑克属性
	BYTE cbCardColor=GetCardColor(cbCardData);
	BYTE cbCardValue=GetCardValue(cbCardData);

	//转换数值
	if (cbCardColor==0x40) return cbCardValue+15;
	return (cbCardValue<=2)?(cbCardValue+13):cbCardValue;
}

//对比扑克
bool CGameLogic::CompareCard(const BYTE cbFirstCard[], const BYTE cbNextCard[], BYTE cbFirstCount, BYTE cbNextCount)
{
	//获取类型
	tagAnalyseResult stNextResult;
	tagAnalyseResult stFirstResult;
	BYTE cbNextType=AnalyseOutCard(cbNextCard,cbNextCount,stNextResult);
	BYTE cbFirstType=AnalyseOutCard(cbFirstCard,cbFirstCount,stFirstResult);

	//类型判断
	if (cbNextType==CT_ERROR||cbFirstType==CT_ERROR) return false;
	if (cbFirstType==CT_MISSILE_CARD) return false;
	if (cbNextType==CT_MISSILE_CARD) return true;

	//炸弹判断
	if ((cbFirstType!=CT_BOMB_CARD)&&(cbNextType==CT_BOMB_CARD)) return true;
	if ((cbFirstType==CT_BOMB_CARD)&&(cbNextType!=CT_BOMB_CARD)) return false;

	//规则判断
	if ((cbFirstType!=cbNextType)||(cbFirstCount!=cbNextCount)) return false;

	//开始对比
	switch (cbNextType)
	{
	case CT_SINGLE:
	case CT_DOUBLE:
	case CT_THREE:
	case CT_SINGLE_LINE:
	case CT_DOUBLE_LINE:
	case CT_THREE_LINE:
	case CT_BOMB_CARD:
	case CT_THREE_TAKE_ONE:
	case CT_THREE_TAKE_TWO:
	case CT_FOUR_TAKE_ONE:
	case CT_FOUR_TAKE_TWO:
		{
			//对比扑克
			return stNextResult.cbLogicValue>stFirstResult.cbLogicValue;
		}
	}
	
	return false;
}

//同牌搜索
BYTE CGameLogic::SearchSameCard( const BYTE cbHandCardData[], BYTE cbHandCardCount, BYTE cbReferCard, BYTE cbSameCardCount,
								tagSearchCardResult *pSearchCardResult )
{
	CFunItem tt(__FUNCTION__, TEXT("hc=%d"), cbHandCardCount);
	//设置结果
	if( pSearchCardResult )
		ZeroMemory(pSearchCardResult,sizeof(tagSearchCardResult));
	BYTE cbResultCount = 0;

	//构造扑克
	BYTE cbCardData[MAX_COUNT];
	BYTE cbCardCount=cbHandCardCount;
	CHECK_MEMCPY(MAX_COUNT,sizeof(BYTE)*cbHandCardCount);
	CopyMemory(cbCardData,cbHandCardData,sizeof(BYTE)*cbHandCardCount);

	//排列扑克
	SortCardList(cbCardData,cbCardCount,ST_ORDER);

	//分析扑克
	tagAnalyseResult AnalyseResult = {};
	AnalysebCardData( cbCardData,cbCardCount,AnalyseResult );

	BYTE cbReferLogicValue = cbReferCard==0?0:GetCardLogicValue(cbReferCard);
	BYTE cbBlockIndex = cbSameCardCount-1;
	do
	{
		for( BYTE i = 0; i < AnalyseResult.cbBlockCount[cbBlockIndex]; i++ )
		{
			BYTE cbIndex = (AnalyseResult.cbBlockCount[cbBlockIndex]-i-1)*(cbBlockIndex+1);
			if( GetCardLogicValue(AnalyseResult.cbCardData[cbBlockIndex][cbIndex]) > cbReferLogicValue )
			{
				if( pSearchCardResult == NULL ) return 1;

				ASSERT( cbResultCount < CountArray(pSearchCardResult->cbCardCount) );

				//复制扑克
				CHECK_MEMCPY(MAX_COUNT,cbSameCardCount*sizeof(BYTE));
				CopyMemory( pSearchCardResult->cbResultCard[cbResultCount],&AnalyseResult.cbCardData[cbBlockIndex][cbIndex],
					cbSameCardCount*sizeof(BYTE) );
				pSearchCardResult->cbCardCount[cbResultCount] = cbSameCardCount;

				cbResultCount++;
				if (cbResultCount == MAX_COUNT)
				{//记录最多存放20条，如果超过这个数量 退出函数
					cbResultCount = MAX_COUNT - 1;
					cbBlockIndex = 5;
					break;
				}
			}
		}

		cbBlockIndex++;
	}while( cbBlockIndex < CountArray(AnalyseResult.cbBlockCount) );
	if (pSearchCardResult == NULL) return 1;
	if( pSearchCardResult )
		pSearchCardResult->cbSearchCount = cbResultCount;
	return cbResultCount;
}

//构造扑克
BYTE CGameLogic::MakeCardData(BYTE cbValueIndex, BYTE cbColorIndex)
{
	return (cbColorIndex<<4)|(cbValueIndex+1);
}

//分析扑克
VOID CGameLogic::AnalysebCardData(const BYTE cbCardData[], BYTE cbCardCount, tagAnalyseResult & AnalyseResult)
{
	CFunItem tt(__FUNCTION__, TEXT("cc=%d"), cbCardCount);
	//设置结果
	ZeroMemory(&AnalyseResult,sizeof(AnalyseResult));

	//扑克分析
	for (BYTE i=0;i<cbCardCount;i++)
	{
		//变量定义
		BYTE cbSameCount=1,cbCardValueTemp=0;
		BYTE cbLogicValue=GetCardLogicValue(cbCardData[i]);
		if (cbLogicValue == 0) break;

		//搜索同牌
		for (BYTE j=i+1;j<cbCardCount;j++)
		{
			//获取扑克
			if (GetCardLogicValue(cbCardData[j])!=cbLogicValue) break;

			//设置变量
			cbSameCount++;
			if (cbSameCount>CountArray(AnalyseResult.cbCardData))
			{
				cbSameCount=4;
				break;
			}
		}

		//设置结果
		BYTE cbIndex=AnalyseResult.cbBlockCount[cbSameCount-1]++;
		for (BYTE j=0;j<cbSameCount;j++) AnalyseResult.cbCardData[cbSameCount-1][cbIndex*cbSameCount+j]=cbCardData[i+j];

		//设置索引
		i+=cbSameCount-1;
	}

	return;
}

//分析分布
VOID CGameLogic::AnalysebDistributing(const BYTE cbCardData[], BYTE cbCardCount, tagDistributing & Distributing)
{
	CFunItem tt(__FUNCTION__, TEXT("cc=%d"), cbCardCount);
	//设置变量
	ZeroMemory(&Distributing,sizeof(Distributing));

	//设置变量
	for (BYTE i=0;i<cbCardCount;i++)
	{
		if (cbCardData[i]==0) continue;

		//获取属性
		BYTE cbCardColor=GetCardColor(cbCardData[i]);
		BYTE cbCardValue=GetCardValue(cbCardData[i]);

		//分布信息
		Distributing.cbCardCount++;
		Distributing.cbDistributing[cbCardValue-1][cbIndexCount]++;
		Distributing.cbDistributing[cbCardValue-1][cbCardColor>>4]++;
	}

	return;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////以下为AI函数

//设置扑克
VOID CGameLogic::SetUserCard(WORD wChairID, BYTE cbCardData[], BYTE cbCardCount)
{
#ifdef LYX_DEBUG	
	printf("0x%08x -> 0x%08x ============= CGameLogic::SetUserCard ========\n",m_userSink,this);
	printf("chairId:%d.\n",wChairID);
	printf("bank user:%d\n",m_wBankerUser);
	printf("_wAllyID user:%d\n",_wAllyID);
	printf("cbCardData:%s;\n",cardDataToString(cbCardData,cbCardCount).c_str());
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbAllCount:%d, %d !\n",i,m_cbAllCount[i]);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbOutCount:%d, %d !\n",i,m_cbOutCount[i]);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbAllCardData:%d, %s !\n",i,cardDataToString(m_cbAllCardData[i],MAX_COUNT).c_str());
#endif

	if (wChairID >= GAME_PLAYER) return;
	CHECK_MEMCPY(MAX_COUNT,cbCardCount*sizeof(BYTE));
	CopyMemory(m_cbAllCardData[wChairID], cbCardData, cbCardCount*sizeof(BYTE)) ;
	m_cbAllCount[wChairID] = cbCardCount ;

	//排列扑克
	SortCardList(m_cbAllCardData[wChairID], cbCardCount, ST_ORDER) ;

#ifdef LYX_DEBUG
	printf("0x%08x -> 0x%08x ============= CGameLogic::SetUserCard --end-- ========\n",m_userSink,this);
	printf("chairId:%d.\n",wChairID);
	printf("bank user:%d\n",m_wBankerUser);
	printf("_wAllyID user:%d\n",_wAllyID);
	printf("cbCardData:%s;\n",cardDataToString(cbCardData,cbCardCount).c_str());
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbAllCount:%d, %d !\n",i,m_cbAllCount[i]);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbOutCount:%d, %d !\n",i,m_cbOutCount[i]);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbAllCardData:%d, %s !\n",i,cardDataToString(m_cbAllCardData[i],MAX_COUNT).c_str());
#endif	
}

//设置底牌
VOID CGameLogic::SetBackCard(WORD wChairID, BYTE cbBackCardData[], BYTE cbCardCount)
{
	CHECK_CHAIR(wChairID);
	CHECK_CARD_ARRAY(cbBackCardData,cbCardCount);

	if (wChairID >= GAME_PLAYER) return;
	BYTE cbTmpCount = m_cbAllCount[wChairID];
	CHECK_MEMCPY(MAX_COUNT-wChairID,cbCardCount*sizeof(BYTE));
	CopyMemory(m_cbAllCardData[wChairID]+cbTmpCount, cbBackCardData, cbCardCount*sizeof(BYTE)) ;
	m_cbAllCount[wChairID] += cbCardCount ;

	//排列扑克
	SortCardList(m_cbAllCardData[wChairID], m_cbAllCount[wChairID], ST_ORDER) ;
}

//设置庄家
VOID CGameLogic::SetBanker(WORD wBanker) 
{
	CHECK_CHAIR2(wBanker);

	m_wBankerUser = wBanker ;
}
//叫牌扑克
VOID CGameLogic::SetLandScoreCardData(BYTE cbCardData[], BYTE cbCardCount) 
{
	CHECK_CARD_ARRAY(cbCardData,cbCardCount);

	ASSERT(cbCardCount==MAX_COUNT) ;
	if(cbCardCount!=MAX_COUNT) return ;
    CHECK_MEMCPY(MAX_COUNT,cbCardCount*sizeof(BYTE));
	CopyMemory(m_cbLandScoreCardData, cbCardData, cbCardCount*sizeof(BYTE)) ;
	//排列扑克
	SortCardList(m_cbLandScoreCardData, cbCardCount, ST_ORDER) ;
}
//删除扑克
VOID CGameLogic::RemoveUserCardData(WORD wChairID, BYTE cbRemoveCardData[], BYTE cbRemoveCardCount) 
{
#ifdef LYX_DEBUG	
	printf("0x%08x -> 0x%08x ============= CGameLogic::RemoveUserCardData =======\n",m_userSink,this);
	printf("cbRemoveCardData:%s;\n",cardDataToString(cbRemoveCardData,cbRemoveCardCount).c_str());
	printf("out chairId:%d.\n",wChairID);
	printf("bank user:%d\n",m_wBankerUser);
	printf("_wAllyID user:%d\n",_wAllyID);
	printf("m_cbLandScoreCardData:%s;\n",cardDataToString(m_cbLandScoreCardData,MAX_COUNT).c_str());
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbAllCount:%d, %d !\n",i,m_cbAllCount[i]);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbOutCount:%d, %d !\n",i,m_cbOutCount[i]);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbAllCardData:%d, %s !\n",i,cardDataToString(m_cbAllCardData[i],MAX_COUNT).c_str());
#endif	

	CHECK_CHAIR(wChairID);
	CHECK_CARD_ARRAY(cbRemoveCardData,cbRemoveCardCount);

	ASSERT(wChairID<GAME_PLAYER&&cbRemoveCardCount<=MAX_COUNT);
	if (wChairID>=GAME_PLAYER||cbRemoveCardCount>MAX_COUNT)
	{
		ASSERT(false);
		return;
	}
	bool bSuccess = RemoveCard(cbRemoveCardData, cbRemoveCardCount, m_cbAllCardData[wChairID], m_cbAllCount[wChairID]) ;
	//ASSERT(bSuccess) ;
	if (bSuccess == false)
	{
		ASSERT(false);
	 	return;
	}

	ASSERT(m_cbAllCount[wChairID] >= cbRemoveCardCount);
	if (m_cbAllCount[wChairID] >= cbRemoveCardCount) 
		m_cbAllCount[wChairID] -= cbRemoveCardCount;

#ifdef LYX_DEBUG
	printf("0x%08x -> 0x%08x ============= CGameLogic::RemoveUserCardData --end--  =======\n",m_userSink,this);
	printf("cbRemoveCardData:%s;\n",cardDataToString(cbRemoveCardData,cbRemoveCardCount).c_str());
	printf("out chairId:%d.\n",wChairID);
	printf("bank user:%d\n",m_wBankerUser);
	printf("_wAllyID user:%d\n",_wAllyID);
	printf("m_cbLandScoreCardData:%s;\n",cardDataToString(m_cbLandScoreCardData,MAX_COUNT).c_str());
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbAllCount:%d, %d !\n",i,m_cbAllCount[i]);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbOutCount:%d, %d !\n",i,m_cbOutCount[i]);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbAllCardData:%d, %s !\n",i,cardDataToString(m_cbAllCardData[i],MAX_COUNT).c_str());
#endif	
}

//设置出牌
VOID CGameLogic::SetLastOutCard(WORD wOutUser,BYTE cbCardData[],BYTE cbCardCount)
{
	CHECK_CHAIR2(wOutUser);
	CHECK_CARD_ARRAY(cbCardData,cbCardCount);

	if (cbCardData!=NULL&&wOutUser<GAME_PLAYER && cbCardCount > 0)
	{
		m_LastOutCard.wOutUser=wOutUser;
		AnalyseOutCard(cbCardData,cbCardCount,m_LastOutCard.stLastCard);
	}
	else ZeroMemory(&m_LastOutCard,sizeof(tagLastOutCard));

	return;
}

//出牌次数
VOID CGameLogic::SetOutCount(const BYTE cbOutCount[])
{
    CHECK_MEMCPY(GAME_PLAYER,sizeof(m_cbOutCount));

	CopyMemory(m_cbOutCount,cbOutCount,sizeof(m_cbOutCount));
}

//叫分判断
BYTE CGameLogic::LandScore(WORD wMeChairID, BYTE cbCurrentLandScore)
{
	CHECK_CHAIR(wMeChairID);

	if (wMeChairID >= GAME_PLAYER) return 255;
	//地主手牌
	BYTE cbCardData[MAX_COUNT]={0};
    CHECK_MEMCPY(MAX_COUNT,sizeof(m_cbLandScoreCardData));
	CopyMemory(cbCardData,m_cbLandScoreCardData,sizeof(m_cbLandScoreCardData));
	SortCardList(cbCardData,MAX_COUNT,ST_ORDER);
	//A以上牌价值
	double fWorth=0.0;
	BYTE cbLargeCardCount=0;
	BYTE cbRemoveCard[MAX_COUNT]={0};
	BYTE cbRemoveCount=0;
	while(cbLargeCardCount<MAX_COUNT)
	{
		BYTE cbValue=GetCardLogicValue(cbCardData[cbLargeCardCount]);
		if (cbValue>=0x0F) cbRemoveCard[cbRemoveCount++]=cbCardData[cbLargeCardCount];
		cbLargeCardCount++;
		if (cbValue==0x11) fWorth+=3.5;
		else if (cbValue==0x10) fWorth+=2.5;
		else if (cbValue==0x0f) fWorth+=1.5;
		else if (cbValue==0x0e) fWorth+=1;
		else break;
	};

	//移除2和王
	VERIFY(RemoveCard(cbRemoveCard,cbRemoveCount,cbCardData,MAX_COUNT));
	BYTE cbCardCount=MAX_COUNT-cbRemoveCount;

	//快速出牌
	vector<tagOutCard> vecFastCard;
	FastestOutCard(cbCardData,cbCardCount,vecFastCard);
	
	BYTE cbLittleCount=0;
	for (int i=0;i<(int)vecFastCard.size();i++)
	{
		tagOutCard &stOutCard=vecFastCard.at(i);
		if (stOutCard.cbCardType==CT_SINGLE&&stOutCard.cbLogicValue<=0x0C) cbLittleCount++;//Q以下单
		if (stOutCard.cbCardCount==CT_DOUBLE&&stOutCard.cbLogicValue<=0x0A) cbLittleCount++;//10以下对
	}
	
	if (fWorth>=8.5) return cbCurrentLandScore<3?3:255;
	if (fWorth>=6.5) return cbCurrentLandScore<2?2:255;
	if (fWorth>=5&&cbLittleCount<4) return cbCurrentLandScore<3?3:255;
	if (fWorth>=5&&cbLittleCount<5) return cbCurrentLandScore<2?2:255;
	if (fWorth>=5&&cbLittleCount<7) return cbCurrentLandScore<1?1:255;
					
	//放弃叫分
	return 255;
}
//////////////////////////////////////////////////////////////////////////

//送牌搜索
bool CGameLogic::SearchSamllerResult(const BYTE cbCardData[],BYTE cbCardCount,tagOutCard stOutCard, tagOutCard &stSearchResult)
{
	CFunItem tt(__FUNCTION__, TEXT("cc=%d"), cbCardCount);
	//寻找小于stOutCard的结果
	//最小优先
	tagAnalyseResult stAnalyseResult;
	AnalyseOutCard(cbCardData,cbCardCount,stAnalyseResult);
	
	switch(stOutCard.cbCardType)
	{
	case CT_SINGLE: //单
		{
			for(int i=cbCardCount-1;i>=0;i--)
			{
				BYTE cbValue=GetCardLogicValue(cbCardData[i]);
				if (cbValue<stOutCard.cbLogicValue)
				{
					stSearchResult.cbCardType=CT_SINGLE;
					stSearchResult.cbCardData[0]=cbCardData[i];
					stSearchResult.cbCardCount=1;
					stSearchResult.cbLogicValue=cbValue;
					return true;
				}
				else break;
			}
			break;
		}
	case CT_DOUBLE: //对
	case CT_THREE: //同三
		{
			BYTE cbSameCount=2;
			if (stOutCard.cbCardType==CT_THREE) cbSameCount=3;
			for (int i=cbSameCount-1;i<4;i++)
			{
				for (int j=stAnalyseResult.cbBlockCount[i]-1;j>=0;j--)
				{
					BYTE cbValue=GetCardLogicValue(stAnalyseResult.cbCardData[i][j*(i+1)]);
					if (cbValue<stOutCard.cbLogicValue)
					{
						stSearchResult.cbCardType=stOutCard.cbCardType;
                        CHECK_MEMCPY(MAX_COUNT,cbSameCount*sizeof(BYTE));
						CopyMemory(stSearchResult.cbCardData,&stAnalyseResult.cbCardData[i][j*(i+1)],cbSameCount*sizeof(BYTE));
						stSearchResult.cbCardCount=cbSameCount;
						stSearchResult.cbLogicValue=cbValue;
						return true;
					}
					else break;
				}
			}
			break;
		}
		
	case CT_THREE_TAKE_ONE: //三带一
		{
			if (stOutCard.cbCardCount==4 && IsValidType(CT_THREE_TAKE_ONE))
			{//不考虑飞机
				for (int i=2;i<4;i++)
				{//找同三
					for (int j=stAnalyseResult.cbBlockCount[i]-1;j>=0;j--)
					{
						BYTE cbValue=GetCardLogicValue(stAnalyseResult.cbCardData[i][(i+1)*j]);
						if (cbValue<stOutCard.cbLogicValue)
						{
							for (BYTE k=cbCardCount-1;k>=0;k--)
							{//找单牌
								if (GetCardLogicValue(cbCardData[k])!=cbValue)
								{
									stSearchResult.cbLogicValue=cbValue;
									stSearchResult.cbCardType=CT_THREE_TAKE_ONE;
									stSearchResult.cbCardCount=4;
                                    CHECK_MEMCPY(MAX_COUNT,3*sizeof(BYTE));
									CopyMemory(stSearchResult.cbCardData,&stAnalyseResult.cbCardData[i][j*(i+1)],3*sizeof(BYTE));
									stSearchResult.cbCardData[3]=cbCardData[k];
									return true;
								}
							}
						}
						else break;
					}
				}	
			}
			break;
		}
	case CT_THREE_TAKE_TWO: //三带二
		{
			if (stOutCard.cbCardCount == 5 && IsValidType(CT_THREE_TAKE_TWO))
			{//不考虑飞机
				for (int i=2;i<4;i++)
				{//找同三
					for (int j=stAnalyseResult.cbBlockCount[i]-1;j>=0;j--)
					{
						BYTE cbValue=GetCardLogicValue(stAnalyseResult.cbCardData[i][(i+1)*j]);
						if (cbValue<stOutCard.cbLogicValue)
						{
							for (BYTE k=cbCardCount-1;k>0;k--)
							{//找对
								if (GetCardLogicValue(cbCardData[k])!=cbValue&&GetCardLogicValue(cbCardData[k])==GetCardLogicValue(cbCardData[k-1]))
								{
									stSearchResult.cbLogicValue=cbValue;
									stSearchResult.cbCardType=CT_THREE_TAKE_TWO;
									stSearchResult.cbCardCount=5;
									CopyMemory(stSearchResult.cbCardData,&stAnalyseResult.cbCardData[i][j*(i+1)],3*sizeof(BYTE));
									CopyMemory(&stSearchResult.cbCardData[3],&cbCardData[k-1],2*sizeof(BYTE));
									return true;
								}
							}
						}
						else break;
					}
				}	
			}

			break;
		}
	case CT_SINGLE_LINE:	//单连
	case CT_DOUBLE_LINE:	//对连
	case CT_THREE_LINE:		//三连
		{
			BYTE cbSameCount=1;
			if (stOutCard.cbCardType==CT_DOUBLE_LINE) cbSameCount=2;
			else if (stOutCard.cbCardType==CT_THREE_LINE) cbSameCount=3;
			vector<tagLinkCard> vecLinkCard;
			SearchAllLink(cbCardData,cbCardCount,cbSameCount,vecLinkCard);
			for(int i=0;i<(int)vecLinkCard.size();i++)
			{
				tagLinkCard &stLinkCard=vecLinkCard.at(i);
				if (stLinkCard.cbCardCount==stOutCard.cbCardCount&&stLinkCard.cbLogicValue<stOutCard.cbLogicValue)
				{
					stSearchResult.cbLogicValue=stLinkCard.cbLogicValue;
					stSearchResult.cbCardCount=stLinkCard.cbCardCount;
                    CHECK_MEMCPY(MAX_COUNT,stLinkCard.cbCardCount*sizeof(BYTE));
					CopyMemory(stSearchResult.cbCardData,stLinkCard.cbCardData,stLinkCard.cbCardCount*sizeof(BYTE));
					stSearchResult.cbCardType=stOutCard.cbCardType;
					return true;
				}
			}
			break;
		}
	}

	return false;
}

//最快出牌(无人管牌)
size_t  CGameLogic::FastestOutCard(const BYTE cbCardData[],BYTE cbCardCount,vector<tagOutCard> &vecOutCard)
{
	CFunItem tt(__FUNCTION__, TEXT("cc=%d"), cbCardCount);
	m_nSearchCount=0;	//初始化
	vecOutCard.clear();
	
	//无牌直接返回
	if (cbCardCount==0) return 0;

	vector<tagOutCard> vecCurrentResult;
	TRY
	{
		FindFastest(cbCardData,cbCardCount,vecOutCard,vecCurrentResult);
	}
	CATCH (...)
	{
		THROW;
// 		ASSERT(false);
// #ifdef USE_LOG_TRACE		
// 		CTraceService::TraceString(TEXT("AndroidServer:FastestOutCard ERROR"),TraceLevel_Exception);
// #endif		
	}
#ifdef _DEBUG
	//BYTE cbCardBuf[MAX_COUNT]={0};
	//CopyMemory(cbCardBuf,cbCardData,cbCardCount*sizeof(BYTE));
	//BYTE cbBufCount=cbCardCount;
	//for	(size_t i=0;i<vecOutCard.size();i++)
	//{
	//	tagOutCard &stOutCard=vecOutCard.at(i);

	//	ASSERT(GetCardType(stOutCard.cbCardData,stOutCard.cbCardCount)==stOutCard.cbCardType);
	//	ASSERT(stOutCard.cbCardType!=CT_ERROR);
	//	
	//	VERIFY(RemoveCard(stOutCard.cbCardData,stOutCard.cbCardCount,cbCardBuf,cbBufCount));
	//	cbBufCount-=stOutCard.cbCardCount;
	//}
	//ASSERT(vecOutCard.size()>0);
	//ASSERT(cbBufCount==0);
#endif

	return vecOutCard.size();
}

//寻找最快出牌(辅助函数)
void  CGameLogic::FindFastest(const BYTE cbCardData[],BYTE cbCardCount,vector<tagOutCard> &vecFastestResult,vector<tagOutCard> &vecCurrentResult)
{
	CFunItem tt(__FUNCTION__, TEXT("cc=%d"), cbCardCount);
	//变量定义
	BYTE cbCardTempCount=0;
	BYTE cbCardTemp[MAX_COUNT]={0};

	vector<tagOutCard> vecAllPossibleResult;

	size_t nResultCount=SimplySearchFastest(cbCardData,cbCardCount,vecAllPossibleResult);
	
	m_nSearchCount++;

	if (m_nSearchCount>10000) 
	{
		#ifdef LYX_DEBUG	
			printf("0x%08x -> 0x%08x ============= CGameLogic::FindFastest ========\n",m_userSink,this);
			printf("bank user:%d\n",m_wBankerUser);
			printf("cbCardData:%s;\n",cardDataToString(cbCardData,cbCardCount).c_str());
			for (int i=0;i<GAME_PLAYER;++i)
				printf("player m_cbAllCount:%d, %d !\n",i,m_cbAllCount[i]);
			for (int i=0;i<GAME_PLAYER;++i)
				printf("player m_cbOutCount:%d, %d !\n",i,m_cbOutCount[i]);
			for (int i=0;i<GAME_PLAYER;++i)
				printf("player m_cbAllCardData:%d, %s !\n",i,cardDataToString(m_cbAllCardData[i],MAX_COUNT).c_str());
		#endif
		
		//THROW_ERROR(-1004);
		return;
	}
	
	// if (m_nSearchCount > m_nTimeLimit) return;
	if (m_nSearchCount > 8000) return;

	for(size_t i=0;i<nResultCount;i++)
	{
		//保存结果
		tagOutCard &stSearchResult=vecAllPossibleResult.at(i);
		vecCurrentResult.push_back(stSearchResult);
	
		if (stSearchResult.cbCardCount==cbCardCount)
		{//牌出完
			if (vecFastestResult.size()==0||vecFastestResult.size()>vecCurrentResult.size())
			{//保存最快结果
				vecFastestResult=vecCurrentResult;
				vecCurrentResult.pop_back();
				return;
			}
		}

		//无需继续
		if (vecFastestResult.size()>0&&vecCurrentResult.size()>=vecFastestResult.size()-1)
			{
				vecCurrentResult.pop_back();
				return;
			}
		
		//继续搜索
		CHECK_MEMCPY(MAX_COUNT,cbCardCount*sizeof(BYTE));
		CopyMemory(cbCardTemp,cbCardData,cbCardCount*sizeof(BYTE));
		cbCardTempCount=cbCardCount;
		VERIFY(RemoveCard(stSearchResult.cbCardData,stSearchResult.cbCardCount,cbCardTemp,cbCardCount));
		cbCardTempCount-=stSearchResult.cbCardCount;

		//最后剩余单牌或对牌
		if (stSearchResult.cbCardType==CT_SINGLE||stSearchResult.cbCardType==CT_DOUBLE)
		{
			tagAnalyseResult stAnalyseResult;
			AnalysebCardData(cbCardTemp,cbCardTempCount,stAnalyseResult);
			
			//有其它牌型没计算
			if (cbCardTempCount!=stAnalyseResult.cbBlockCount[0]+2*stAnalyseResult.cbBlockCount[1])
			{
				vecCurrentResult.pop_back();
				return;
			}

			//不是最快
			if (vecFastestResult.size()>0&&vecCurrentResult.size()+stAnalyseResult.cbBlockCount[0]+stAnalyseResult.cbBlockCount[1]>=vecFastestResult.size())
			{
				vecCurrentResult.pop_back();
				return;
			}
			
			vecFastestResult=vecCurrentResult;
			//对牌
			for (int k=0;k<stAnalyseResult.cbBlockCount[1];k++)
			{	
				tagOutCard stTemp;
				stTemp.cbCardCount=2;
				stTemp.cbCardType=CT_DOUBLE;
				stTemp.cbLogicValue=GetCardLogicValue(stAnalyseResult.cbCardData[1][2*k]);
				stTemp.cbCardData[0]=stAnalyseResult.cbCardData[1][2*k];
				stTemp.cbCardData[1]=stAnalyseResult.cbCardData[1][2*k+1];
				vecFastestResult.push_back(stTemp);
			}
			//单牌
			for (int k=0;k<stAnalyseResult.cbBlockCount[0];k++)
			{	
				tagOutCard stTemp;
				stTemp.cbCardCount=1;
				stTemp.cbCardType=CT_SINGLE;
				stTemp.cbLogicValue=GetCardLogicValue(stAnalyseResult.cbCardData[0][k]);
				stTemp.cbCardData[0]=stAnalyseResult.cbCardData[0][k];
				vecFastestResult.push_back(stTemp);
			}
			vecCurrentResult.pop_back();
			return;
		}

		//三带一的牌型
		if (stSearchResult.cbCardType == CT_THREE_TAKE_ONE )
		{
			tagAnalyseResult stAnalyseResult;
			AnalysebCardData(cbCardTemp, cbCardTempCount, stAnalyseResult);

			vecFastestResult = vecCurrentResult;
			//三张
			for (int k = 0; k < stAnalyseResult.cbBlockCount[2]; k++)
			{
				tagOutCard stTemp;
				stTemp.cbCardCount = 4;
				stTemp.cbCardType = CT_THREE_TAKE_ONE;
				stTemp.cbLogicValue = GetCardLogicValue(stAnalyseResult.cbCardData[2][3 * k]);
				stTemp.cbCardData[0] = stAnalyseResult.cbCardData[2][3 * k];
				stTemp.cbCardData[1] = stAnalyseResult.cbCardData[2][3 * k + 1];
				stTemp.cbCardData[2] = stAnalyseResult.cbCardData[2][3 * k + 2];
				stTemp.cbCardData[3] = vecFastestResult[0].cbCardData[3];
				vecFastestResult.push_back(stTemp);
			}

			vecCurrentResult.pop_back();
			return;
		}
		FindFastest(cbCardTemp,cbCardTempCount,vecFastestResult,vecCurrentResult);
		vecCurrentResult.pop_back();
	}
	
	return;
}
//寻找炸弹
BYTE CGameLogic::SearchBombCard(tagAnalyseResult stAnalyseResult,std::vector<tagOutCardResult> &vecBombCardResult)
{
	CFunItem tt(__FUNCTION__);
	//张数过少
	tagOutCardResult stOutCardResult;

	//火箭
	if(stAnalyseResult.cbBlockCount[0]>=2)
	{
		if(stAnalyseResult.cbCardData[0][0]==0x42&&stAnalyseResult.cbCardData[0][1]==0x41)
		{
			stOutCardResult.cbCardCount=2;
			stOutCardResult.cbResultCard[0]=0x42;
			stOutCardResult.cbResultCard[1]=0x41;
			vecBombCardResult.push_back(stOutCardResult);
		}
		
	}

	//炸弹
	for (int i=0;i<stAnalyseResult.cbBlockCount[3];i++)
	{
		stOutCardResult.cbCardCount=4;
		CHECK_MEMCPY(MAX_COUNT,4*sizeof(BYTE));
		CopyMemory(stOutCardResult.cbResultCard,&stAnalyseResult.cbCardData[3][4*i],4*sizeof(BYTE));
		vecBombCardResult.push_back(stOutCardResult);
	}
	
	
	return (BYTE) vecBombCardResult.size();
}

//连续最大尝试
bool CGameLogic::TryAllBiggestCard(const BYTE cbAllUserCard[GAME_PLAYER][MAX_COUNT],BYTE cbAllCount[GAME_PLAYER],WORD wMeChairID,const tagOutCard &stTurnCard,std::vector<tagOutCard> &vecOutCard)
{
	CFunItem tt(__FUNCTION__);
	//变量定义
	vector<tagOutCard> vecPossibleResult;						//可能结果
	TRY
	{
		//拷贝扑克
		BYTE	cbAllUserCardTemp[GAME_PLAYER][MAX_COUNT]={0};
		BYTE	cbAllCountTemp[GAME_PLAYER]={0};

		//搜索可能
		size_t nResultCount=SimplySearchResult(cbAllUserCard[wMeChairID],cbAllCount[wMeChairID],stTurnCard,vecPossibleResult);
		
		//循环查找
		for (UINT i=0;i<nResultCount;i++)
		{	
			//未出牌
			if (vecPossibleResult[i].cbCardCount==0) continue;

			m_nSearchCount++;

			if (m_nSearchCount>m_nTimeLimit)
			{
				m_nSearchCount=nBadSearch;
				return false;
			}

			//保存结果
			vecOutCard.push_back(vecPossibleResult.at(i));

			CopyMemory(cbAllUserCardTemp,cbAllUserCard,sizeof(cbAllUserCardTemp));
			CopyMemory(cbAllCountTemp,cbAllCount,sizeof(cbAllCountTemp));

			VERIFY(RemoveCard(vecPossibleResult[i].cbCardData,vecPossibleResult[i].cbCardCount,cbAllUserCardTemp[wMeChairID],cbAllCountTemp[wMeChairID]));
			cbAllCountTemp[wMeChairID]-=vecPossibleResult[i].cbCardCount;
			
			//牌已出完
			if (cbAllCountTemp[wMeChairID]==0) return true;

			//模拟下家出牌
			WORD	wNextUser=(wMeChairID+1)%GAME_PLAYER;
			//搜索出牌
			WORD wID=0;
			vector<tagOutCard> vecSearchTemp;
			for (wID=1;wID<GAME_PLAYER;wID++)
			{
				WORD wOutUser=(wMeChairID+wID)%GAME_PLAYER;
				if(SimplySearchResult(cbAllUserCard[wOutUser],cbAllCount[wOutUser],vecPossibleResult.at(i),vecSearchTemp))
				{
					//有人管
					if (vecSearchTemp.size()>1) break;
				}
			}
			
			//牌未出完并且无人能管
			if (cbAllCountTemp[wMeChairID]!=0&&wID==GAME_PLAYER)
			{
				tagOutCard stTemp = {0};
				if(TryAllBiggestCard(cbAllUserCardTemp,cbAllCountTemp,wMeChairID,stTemp,vecOutCard))
				{//可以胜
					return true;
				}
			}
			
			//弹出
			vecOutCard.pop_back();		
		}
	}
	CATCH (...)
	{
		THROW;
// 		ASSERT(false);
// #ifdef USE_LOG_TRACE		
// 		CTraceService::TraceString(TEXT("AndroidServer:TryAllBiggestCard ERROR"),TraceLevel_Exception);
// #endif
	}
	
	return false;
}
//出牌搜索
bool CGameLogic::SearchOutCard(const BYTE cbHandCardData[], BYTE cbHandCardCount, const BYTE cbTurnCardData[], BYTE cbTurnCardCount, WORD wOutCardUser, WORD wMeChairID, tagOutCard &stOutCard)
{	
#ifdef LYX_DEBUG	
	printf("0x%08x -> 0x%08x ============= CGameLogic::SearchOutCard  =======\n",m_userSink,this);
	printf("bank user:%d\n",m_wBankerUser);
	printf("_wAllyID user:%d\n",_wAllyID);
	printf("m_cbLandScoreCardData:%s;\n",cardDataToString(m_cbLandScoreCardData,MAX_COUNT).c_str());
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbAllCount:%d, %d !\n",i,m_cbAllCount[i]);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbOutCount:%d, %d !\n",i,m_cbOutCount[i]);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbAllCardData:%d, %s !\n",i,cardDataToString(m_cbAllCardData[i],MAX_COUNT).c_str());
#endif

	if (m_wBankerUser >= GAME_PLAYER || cbHandCardCount > MAX_COUNT) return true;
	CFunItem tt(__FUNCTION__, TEXT("tc=%d"), cbTurnCardCount);
	TRY
	{
		//初始化
		ZeroMemory(&stOutCard,sizeof(tagOutCard));
		
		//管不起直接过
		vector<tagOutCard> vecSearchResult;			//搜索结果
		int nCount=0;								//结果个数

		//stTurnCard构造
		ZeroMemory(&_stTurnCard,sizeof(tagOutCard));
		tagAnalyseResult TurnAlalyseResult;
		AnalyseOutCard(cbTurnCardData,cbTurnCardCount,TurnAlalyseResult);
		_stTurnCard.cbCardCount = cbTurnCardCount;
		_stTurnCard.cbCardType=TurnAlalyseResult.cbCardType;
		_stTurnCard.cbLogicValue=TurnAlalyseResult.cbLogicValue;
		CHECK_MEMCPY(MAX_COUNT,cbTurnCardCount*sizeof(BYTE));
		CopyMemory(_stTurnCard.cbCardData,cbTurnCardData,cbTurnCardCount*sizeof(BYTE));
		if (cbTurnCardCount>0)
		{//管不起就返回
			nCount=SimplySearchResult(cbHandCardData,cbHandCardCount,_stTurnCard,vecSearchResult);
			if (nCount==1) return true;
		}

		//玩家判断
		_wAfterBanker = (m_wBankerUser+1)%GAME_PLAYER ;	//地主下家
		_wFrontBanker = (_wAfterBanker+1)%GAME_PLAYER ;	//地主上家
		_wNextUser    = (wMeChairID+1)%GAME_PLAYER;		//自己下家
		_wFrontUser   = (wMeChairID+2)%GAME_PLAYER;		//自己上家
		_wAllyID      = INVALID_CHAIR;
		if (wMeChairID!=m_wBankerUser)
			_wAllyID=wMeChairID==_wFrontBanker?_wAfterBanker:_wFrontBanker;

		_bCanBomb=false;		//能否出炸
		_bTrySearch=false;		//是否尝试

		//分析手牌
		ZeroMemory(_stAnalyseResult,sizeof(_stAnalyseResult));
		for (WORD i=0;i<GAME_PLAYER;i++)
			AnalyseOutCard(m_cbAllCardData[i],m_cbAllCount[i],_stAnalyseResult[i]);		

		//搜寻炸弹
		for (WORD i=0;i<GAME_PLAYER;i++)
		{
			_vecBombCardResult[i].clear();
			SearchBombCard(_stAnalyseResult[i],_vecBombCardResult[i]);
		}

		//组合玩家扑克
		_cb2CardCount=0;
		ZeroMemory(_cb2Card, sizeof(_cb2Card));
		for (WORD i=0;i<GAME_PLAYER;i++)
		{
			if (i==wMeChairID) continue;
			CHECK_MEMCPY(MAX_COUNT*2,m_cbAllCount[i]*sizeof(BYTE));
			CopyMemory(&_cb2Card[_cb2CardCount],m_cbAllCardData[i],m_cbAllCount[i]*sizeof(BYTE));
			_cb2CardCount+=m_cbAllCount[i];
		}
		SortCardList(_cb2Card,_cb2CardCount,ST_ORDER);

		//春天判断
		m_bMayChunTian=false;
		if (wMeChairID==m_wBankerUser&&_cb2CardCount==2*NORMAL_COUNT) m_bMayChunTian=true;
		if (wMeChairID!=m_wBankerUser&&m_cbOutCount[m_wBankerUser]==1) m_bMayChunTian=true;

		//变量定义
		vector<tagOutCard> vecOutCard;
		BYTE cbAllCardData[GAME_PLAYER][MAX_COUNT];
		BYTE cbAllCount[GAME_PLAYER];
		CopyMemory(cbAllCardData,m_cbAllCardData,sizeof(cbAllCardData));
		CopyMemory(cbAllCount,m_cbAllCount,sizeof(cbAllCount));


		//考虑等盟友炸弹
		if (cbTurnCardCount==0&&wMeChairID==_wFrontBanker&&m_cbAllCount[m_wBankerUser]==1)
		{
			if (_vecBombCardResult[_wAllyID].size()>0&&cbAllCount[wMeChairID]>1)
			{
				if (_stAnalyseResult[wMeChairID].cbCardType==CT_DOUBLE)
				{
					if (_stAnalyseResult[wMeChairID].cbLogicValue>=GetCardLogicValue(_cb2Card[0]))
					{
						AnalyseOutCard(cbAllCardData[wMeChairID],1,stOutCard);
						return true;
					}
				}
			}
		}
	
		/////尝试打春天////////
		if ( TryChunTian(cbTurnCardData,cbTurnCardCount,wOutCardUser,wMeChairID,stOutCard))	return true;

		/////尝试连续出完/////
		if (TryOutAllCard(cbTurnCardData,cbTurnCardCount,wOutCardUser,wMeChairID,stOutCard)) return true;

		//考虑送牌
		if (_stAnalyseResult[_wFrontBanker].cbCardType!=CT_ERROR&&wMeChairID==_wAfterBanker&&cbTurnCardCount==0)
		{
			//只考虑无炸弹情况
			if (_vecBombCardResult[wMeChairID].size()==0)
			{
				tagOutCard stOutTemp;
				stOutTemp.cbLogicValue=_stAnalyseResult[_wFrontBanker].cbLogicValue;
				stOutTemp.cbCardCount=cbAllCount[_wFrontBanker];
				stOutTemp.cbCardType=_stAnalyseResult[_wFrontBanker].cbCardType;
				if(SearchSamllerResult(cbAllCardData[wMeChairID],cbAllCount[wMeChairID],stOutTemp,stOutCard))
				{
					return true;
				}
			}
		}

		//考虑炸弹送盟友
		if (wMeChairID==_wAfterBanker&&cbAllCount[_wAllyID]==1&&_vecBombCardResult[wMeChairID].size()>0)
		{
			tagOutCard stOutTemp = {0};

			BYTE cbCardBuf[GAME_PLAYER][MAX_COUNT]={0};
			BYTE cbBufCount[GAME_PLAYER]={0};

			for (int i=(int)_vecBombCardResult[wMeChairID].size()-1;i>=0;i--)
			{//尝试出炸弹
				//构造手牌
				CopyMemory(cbCardBuf,cbAllCardData,sizeof(cbCardBuf));
				CopyMemory(cbBufCount,cbAllCount,sizeof(cbAllCount));

				//去除炸弹
				tagOutCardResult &stBombTemp=_vecBombCardResult[wMeChairID].at(i);
				VERIFY(RemoveCard(stBombTemp.cbResultCard,stBombTemp.cbCardCount,cbCardBuf[wMeChairID],cbBufCount[wMeChairID]));
				cbBufCount[wMeChairID]-=stBombTemp.cbCardCount;

				//管的起判断
				if (cbTurnCardCount>0&&!CompareCard(cbTurnCardData,stBombTemp.cbResultCard,cbTurnCardCount,stBombTemp.cbCardCount))
					continue;

				//构造结构
				stOutCard.cbCardCount=stBombTemp.cbCardCount;
				stOutCard.cbLogicValue=GetCardLogicValue(stBombTemp.cbResultCard[0]);
				stOutCard.cbCardType=stBombTemp.cbCardCount==2?CT_MISSILE_CARD:CT_BOMB_CARD;
				CHECK_MEMCPY(MAX_COUNT,stOutCard.cbCardCount*sizeof(BYTE));
				CopyMemory(stOutCard.cbCardData,stBombTemp.cbResultCard,stOutCard.cbCardCount*sizeof(BYTE));

				m_nSearchCount=0;
				m_nDepthCount=0;
				tagOutCard stOutTemp;
				if (!SimplySearchTheBest(cbCardBuf,cbBufCount,stOutCard,m_wBankerUser,wMeChairID,stOutTemp,true))
				{//庄家走不了
					//构造结构
					stOutTemp.cbLogicValue=_stAnalyseResult[_wAllyID].cbLogicValue;
					stOutTemp.cbCardCount=cbAllCount[_wAllyID];
					stOutTemp.cbCardType=_stAnalyseResult[_wAllyID].cbCardType;

					tagOutCard stOutTemp2;

					if(SearchSamllerResult(cbCardBuf[wMeChairID],cbBufCount[wMeChairID],stOutTemp,stOutTemp2))
					{//能够送走	
						return true;
					}
				}
			}
		}

		//考虑不管牌
		if (_vecBombCardResult[wMeChairID].size()==0&&cbTurnCardCount>0)
		{//只考虑无炸情况
			bool bTry=false;	//尝试
			if (_wNextUser==m_wBankerUser&&wOutCardUser==_wAfterBanker)
			{
				if (_stTurnCard.cbCardCount>1||_stTurnCard.cbCardCount!=cbAllCount[_wNextUser]||_stTurnCard.cbLogicValue>0x0D)
				{
					SimplySearchResult(cbAllCardData[_wNextUser],cbAllCount[_wNextUser],_stTurnCard,vecOutCard);
					if (vecOutCard.size()<=1) bTry=true; //地主管不起
				}
			}

			// 地主已不管
			if (wMeChairID==_wAfterBanker&&wOutCardUser==_wFrontBanker) bTry=true;

			//盟友尝试连续出牌
			if (bTry)
			{
				tagOutCard stOutTemp = {0};
				BYTE cbCountTemp[GAME_PLAYER]={0};
				CopyMemory(cbCountTemp,cbAllCount,sizeof(cbAllCount));
				cbCountTemp[wMeChairID]=0;
				vector<tagOutCard> vecTemp;
				m_nSearchCount=0;
				if (TryAllBiggestCard(cbAllCardData,cbCountTemp,_wAllyID,stOutTemp,vecTemp))
				{//盟友可连续出完
					ZeroMemory(&stOutCard,sizeof(stOutCard));
					return true;
				}
			}	
		}

		//不考虑盟友
		if (_bTrySearch&&TrySingleOutAll(cbTurnCardData,cbTurnCardCount,wOutCardUser,wMeChairID,stOutCard))	return true;

		/////尝试单挑搜索/////
		if (TrySingleLoopSearch(cbTurnCardData,cbTurnCardCount,wOutCardUser,wMeChairID,stOutCard))	return true;
		
		/////尝试循环搜索/////
		if (TryLoopSearch(cbTurnCardData,cbTurnCardCount,wOutCardUser,wMeChairID,stOutCard))	return true;
		
		/////经验出牌////////
		bool bRet = NormalOutCard(cbTurnCardData, cbTurnCardCount, wOutCardUser, wMeChairID, stOutCard);
		return bRet;
	}
	CATCH (...)
	{
		THROW;

// 		ASSERT(false);
// #ifdef USE_LOG_TRACE		
// 		CTraceService::TraceString(TEXT("AndroidServer:SearchOutCard ERROR"),TraceLevel_Exception);
// #endif
	}
	ZeroMemory(&stOutCard,sizeof(tagOutCard));
	return true;
}

//简化搜索
size_t CGameLogic::SimplySearchResult(const BYTE cbHandCardData[],BYTE cbHandCardCount,tagOutCard TurnCardResult,std::vector<tagOutCard> &vecPossibleResult,bool bFourTake,bool bFixedBomb)
{
	CFunItem tt(__FUNCTION__, TEXT("hc=%d"), cbHandCardCount);
	//简单修改best函数
	vecPossibleResult.clear();

	if (cbHandCardCount==0) return 0;
	
	TRY
	{
		//变量定义
		tagSearchCardResult tmpSearchCardResult = {};

		//构造扑克
		BYTE cbCardData[MAX_COUNT];
		BYTE cbCardCount=cbHandCardCount;
		CHECK_MEMCPY(MAX_COUNT,sizeof(BYTE)*cbHandCardCount);
		CopyMemory(cbCardData,cbHandCardData,sizeof(BYTE)*cbHandCardCount);

		//排列扑克
		SortCardList(cbCardData,cbCardCount,ST_ORDER);

		//分析手牌
		tagAnalyseResult stHandCardResult;
		AnalysebCardData(cbCardData,cbCardCount,stHandCardResult);

		tagOutCard stOutCard = {0};

		//出牌分析
		switch (TurnCardResult.cbCardType)
		{
		case CT_ERROR://错误类型
			{
				vector<tagLinkCard> vecLinkCard;
				int nSortBegin=0;
				//火箭
				if (cbHandCardCount>=2)
				{
					if (cbHandCardData[0]==0x42&&cbHandCardData[1]==0x41)
					{
						stOutCard.cbCardType=CT_MISSILE_CARD;
						stOutCard.cbCardCount=2;
						stOutCard.cbCardData[0]=0x42;
						stOutCard.cbCardData[1]=0x41;
						vecPossibleResult.push_back(stOutCard);
					}
				}

				//炸弹
				if (cbHandCardCount>=4)
				{
					for(BYTE i=0;i<stHandCardResult.cbBlockCount[3];i++)
					{
						stOutCard.cbCardType=CT_BOMB_CARD;
						stOutCard.cbCardCount=4;
						stOutCard.cbLogicValue=GetCardLogicValue(stHandCardResult.cbCardData[3][i*4]);
						CopyMemory(stOutCard.cbCardData,&stHandCardResult.cbCardData[3][i*4],4*sizeof(BYTE));
						
						vecPossibleResult.push_back(stOutCard);
					}
				}

				//考虑一手出完
				tagAnalyseResult AnalyseResult = {0};
				//分析扑克
				if(CT_ERROR!=AnalyseOutCard(cbCardData,cbCardCount,AnalyseResult)&&AnalyseResult.cbCardType!=CT_FOUR_TAKE_ONE&&
					AnalyseResult.cbCardType!=CT_FOUR_TAKE_TWO)
				{
					stOutCard.cbCardType=AnalyseResult.cbCardType;
					stOutCard.cbCardCount=cbCardCount;
					stOutCard.cbLogicValue=AnalyseResult.cbLogicValue;
					CHECK_MEMCPY(MAX_COUNT,cbCardCount*sizeof(cbCardCount));
					CopyMemory(stOutCard.cbCardData,cbCardData,cbCardCount*sizeof(cbCardCount));
					
					vecPossibleResult.push_back(stOutCard);
				}

				//考虑连对
				if (cbCardCount>=6)
				{
					SearchAllLink(cbCardData,cbCardCount,2,vecLinkCard);

					for(int i=(int)vecLinkCard.size()-1;i>=0;i--)
					{
						stOutCard.cbCardCount=vecLinkCard[i].cbCardCount;
						stOutCard.cbCardType=CT_DOUBLE_LINE;
						stOutCard.cbLogicValue=vecLinkCard[i].cbLogicValue;
						CopyMemory(stOutCard.cbCardData,vecLinkCard[i].cbCardData,stOutCard.cbCardCount*sizeof(BYTE));
						
						vecPossibleResult.push_back(stOutCard);
					}
				}

				//考虑单连
				if (cbCardCount>=5)
				{
					SearchAllLink(cbCardData,cbCardCount,1,vecLinkCard);

					for(int i=(int)vecLinkCard.size()-1;i>=0;i--)
					{
						stOutCard.cbCardCount=vecLinkCard[i].cbCardCount;
						stOutCard.cbCardType=CT_SINGLE_LINE;
						stOutCard.cbLogicValue=vecLinkCard[i].cbLogicValue;
						CHECK_MEMCPY(MAX_COUNT,stOutCard.cbCardCount*sizeof(BYTE));
						CopyMemory(stOutCard.cbCardData,vecLinkCard[i].cbCardData,stOutCard.cbCardCount*sizeof(BYTE));
						
						vecPossibleResult.push_back(stOutCard);
					}
				}

				//考虑四带单
				if (bFourTake&&cbHandCardCount >= 6 && stHandCardResult.cbBlockCount[0] >= 2 && IsValidType(CT_FOUR_TAKE_ONE, cbCardCount))
				{
					for(BYTE i=0;i<stHandCardResult.cbBlockCount[3];i++)
					{
						stOutCard.cbCardType=CT_FOUR_TAKE_ONE;
						stOutCard.cbCardCount=6;
						stOutCard.cbLogicValue=GetCardLogicValue(stHandCardResult.cbCardData[3][i*4]);
						CopyMemory(stOutCard.cbCardData,&stHandCardResult.cbCardData[3][i*4],4*sizeof(BYTE));
												
						BYTE cbCount=stHandCardResult.cbBlockCount[0];
						CopyMemory(&stOutCard.cbCardData[4],&stHandCardResult.cbCardData[0][cbCount-2],2);
						if (GetCardType(stOutCard.cbCardData,stOutCard.cbCardCount)==stOutCard.cbCardType)
							vecPossibleResult.push_back(stOutCard);//防止四带王
					}
				}

				//考虑四带对
				if (bFourTake&&cbHandCardCount >= 6 && stHandCardResult.cbBlockCount[1] >= 2 && IsValidType(CT_FOUR_TAKE_TWO, cbCardCount))
				{
					for(BYTE i=0;i<stHandCardResult.cbBlockCount[3];i++)
					{
						stOutCard.cbCardType=CT_FOUR_TAKE_TWO;
						stOutCard.cbCardCount=8;
						stOutCard.cbLogicValue=GetCardLogicValue(stHandCardResult.cbCardData[3][i*4]);
						CopyMemory(stOutCard.cbCardData,&stHandCardResult.cbCardData[3][i*4],4*sizeof(BYTE));

						BYTE cbCount=stHandCardResult.cbBlockCount[1];
						CopyMemory(&stOutCard.cbCardData[4],&stHandCardResult.cbCardData[1][2*(cbCount-2)],4);
						vecPossibleResult.push_back(stOutCard);
					}
				}
			
				//考虑飞机
				if (cbCardCount>=6)
				{
					//搜索所有
					SearchAllLink(cbCardData,cbCardCount,3,vecLinkCard);

					for(int i=(int)vecLinkCard.size()-1;i>=0;i--)
					{
						BYTE cbTackCard[MAX_COUNT]={0};					//带牌
						BYTE cbLinkCount=vecLinkCard[i].cbCardCount/3;	//连牌长度
						BYTE cbLinkCardCount=vecLinkCard[i].cbCardCount;//连牌张数
						stOutCard.cbLogicValue=GetCardLogicValue(vecLinkCard[i].cbCardData[0]);

						//考虑飞机带对
						if (cbCardCount >= cbLinkCount * 5 && IsValidType(CT_THREE_TAKE_ONE, cbCardCount))
						{
							BYTE cbDoubleCard[MAX_COUNT]={0};		//所有可用对牌
							BYTE cbDoubleCount=0;						//对个数

							//找出所有的对
							for(int k=1;k>=1;k--)
							{
								for (int m=0;m<stHandCardResult.cbBlockCount[k];m++)
								{
									BYTE cbCard=stHandCardResult.cbCardData[k][m*(k+1)];
									if (GetCardLogicValue(cbCard)<=vecLinkCard[i].cbLogicValue && GetCardLogicValue(cbCard)>vecLinkCard[i].cbLogicValue-cbLinkCount)
										continue;

									CHECK_MEMCPY(MAX_COUNT-2*cbDoubleCount,2*sizeof(BYTE));
									CopyMemory(&cbDoubleCard[2*cbDoubleCount],&stHandCardResult.cbCardData[k][m*(k+1)],2*sizeof(BYTE));
									cbDoubleCount++;
								}
							}

							if (cbDoubleCount>=cbLinkCount)
							{
								stOutCard.cbCardType=CT_THREE_TAKE_TWO;
								stOutCard.cbCardCount=cbLinkCount*5;
								CopyMemory(stOutCard.cbCardData,vecLinkCard[i].cbCardData,vecLinkCard[i].cbCardCount*sizeof(BYTE));
								CopyMemory(&stOutCard.cbCardData[cbLinkCount*3],&cbDoubleCard[2*cbDoubleCount-2*cbLinkCount],cbLinkCount*2*sizeof(BYTE));
								SortCardList(stOutCard.cbCardData,stOutCard.cbCardCount,ST_ORDER);
								vecPossibleResult.push_back(stOutCard);
							}		
						}

						//考虑飞机带单
						if (cbCardCount>=cbLinkCount*4)
						{
							BYTE cbSingleCard[MAX_COUNT]={0};				//所有可用单牌
							BYTE cbSingleCount=0;							//可用张数

							//找出所有的单牌
							for(int k=0;k>=0;k--)
							{
								for (int m=stHandCardResult.cbBlockCount[k]-1;m>=0;m--)
								{
									BYTE cbCardValue=GetCardLogicValue(stHandCardResult.cbCardData[k][(k+1)*m]);
									//排除连内值
									if (cbCardValue<=vecLinkCard[i].cbLogicValue && cbCardValue>vecLinkCard[i].cbLogicValue-cbLinkCount)
										continue;
								
									for (int n=0;n<=(k==3?2:k);n++)
									{
										if (n>=2&&cbCardValue<0x0F&&
											((cbCardValue==vecLinkCard[i].cbLogicValue+1)||(cbCardValue==vecLinkCard[i].cbLogicValue-cbLinkCount)))
											continue;	//排除连在一起的同三张 

										cbSingleCard[cbSingleCount++]=stHandCardResult.cbCardData[k][(k+1)*m+n];
									}
								}				
							}
							
							if (cbSingleCount >= cbLinkCount)
							{
								SortCardList(cbSingleCard,cbSingleCount,ST_ORDER);

								stOutCard.cbCardType=CT_THREE_TAKE_ONE;
								stOutCard.cbCardCount=cbLinkCount*4;
								CHECK_MEMCPY(MAX_COUNT,vecLinkCard[i].cbCardCount*sizeof(BYTE));
								CopyMemory(stOutCard.cbCardData,vecLinkCard[i].cbCardData,vecLinkCard[i].cbCardCount*sizeof(BYTE));
								CHECK_MEMCPY(MAX_COUNT-cbLinkCount*3,cbLinkCount*sizeof(BYTE));
								CopyMemory(&stOutCard.cbCardData[cbLinkCount*3],&cbSingleCard[cbSingleCount-cbLinkCount],cbLinkCount*sizeof(BYTE));
								SortCardList(stOutCard.cbCardData,stOutCard.cbCardCount,ST_ORDER);
								//排除火箭
								if (stOutCard.cbCardData[0]==0x42&&stOutCard.cbCardData[1]==0x41) continue;
								vecPossibleResult.push_back(stOutCard);
							}
						}
						if (cbCardCount >= cbLinkCount * 3 && IsValidType(CT_THREE, cbCardCount))
						{
							//飞机不带翅膀
							stOutCard.cbCardCount = cbLinkCount * 3;
							stOutCard.cbCardType = CT_THREE_LINE;
							stOutCard.cbLogicValue = vecLinkCard[i].cbLogicValue;
							CHECK_MEMCPY(MAX_COUNT,cbLinkCount * 3 * sizeof(BYTE));
							CopyMemory(stOutCard.cbCardData, vecLinkCard[i].cbCardData, cbLinkCount * 3 * sizeof(BYTE));
							//保存

							vecPossibleResult.push_back(stOutCard);
						}
						
					}//for(size_t i=0;i<vecLinkCard.size();i++)
				}
				
				nSortBegin=(int)vecPossibleResult.size();

				//考虑三带
				if (cbCardCount>=3)
				{	
					for(int i=2;i<3;i++)
					{//找出同三张
						for (int j=stHandCardResult.cbBlockCount[i]-1;j>=0;j--)
						{
							BYTE cbCardTemp[3]={0};
							CopyMemory(cbCardTemp,&stHandCardResult.cbCardData[i][(i+1)*j],3*sizeof(BYTE));
							stOutCard.cbLogicValue = GetCardLogicValue(cbCardTemp[0]);
							//三带一
							if (IsValidType(CT_THREE_TAKE_ONE))
							{
								stOutCard.cbCardCount = 4;
								stOutCard.cbCardType = CT_THREE_TAKE_ONE;
								for (int k = 0; k <= 0; k++)
								{//找单牌
									for (int m = stHandCardResult.cbBlockCount[k] - 1; m >= 0; m--)
									{
										if (m == j&&k == i) continue;  //排除同三
										BYTE cbCard = stHandCardResult.cbCardData[k][(k + 1)*m];

										CopyMemory(stOutCard.cbCardData, cbCardTemp, 3 * sizeof(BYTE));
										stOutCard.cbCardData[3] = cbCard;
										SortCardList(stOutCard.cbCardData, 4, ST_ORDER);

										vecPossibleResult.push_back(stOutCard);
									}
								}//找单牌
							}
							

							//三带二
							if (IsValidType(CT_THREE_TAKE_TWO))
							{
								stOutCard.cbCardCount = 5;
								stOutCard.cbCardType = CT_THREE_TAKE_TWO;
								for (int k = 1; k <= 1; k++)
								{//找对
									for (int m = stHandCardResult.cbBlockCount[k] - 1; m >= 0; m--)
									{
										if (m == j&&k == i) continue;  //排除同三

										CopyMemory(stOutCard.cbCardData, cbCardTemp, 3 * sizeof(BYTE));
										CopyMemory(&stOutCard.cbCardData[3], &stHandCardResult.cbCardData[k][(k + 1)*m], 2 * sizeof(BYTE));
										SortCardList(stOutCard.cbCardData, 5, ST_ORDER);

										vecPossibleResult.push_back(stOutCard);
									}
								}//找对
							}
							
							if (IsValidType(CT_THREE, cbCardCount))
							{
								//三不带
								stOutCard.cbCardCount = 3;
								stOutCard.cbCardType = CT_THREE;
								CopyMemory(stOutCard.cbCardData, cbCardTemp, 3 * sizeof(BYTE));

								vecPossibleResult.push_back(stOutCard);
							}
							
						}
					}//找出同三张

				}////考虑三带
				
				//考虑对牌
				if (cbCardCount>=2)
				{
					stOutCard.cbCardCount=2;
					stOutCard.cbCardType=CT_DOUBLE;
					for (int i=1;i<2;i++)
					{
						for(int j=stHandCardResult.cbBlockCount[i]-1;j>=0;j--)
						{
							stOutCard.cbLogicValue=GetCardLogicValue(stHandCardResult.cbCardData[i][(i+1)*j]);
							CopyMemory(stOutCard.cbCardData,&stHandCardResult.cbCardData[i][(i+1)*j],2*sizeof(BYTE));
							
							vecPossibleResult.push_back(stOutCard);
						}
					}
				}//考虑对牌
				
				//考虑单牌
				stOutCard.cbCardCount=1;
				stOutCard.cbCardType=CT_SINGLE;
				for (int i=0;i<1;i++)
				{
					for(int j=stHandCardResult.cbBlockCount[i]-1;j>=0;j--)
					{
						BYTE cbCard=stHandCardResult.cbCardData[i][(i+1)*j];

						stOutCard.cbLogicValue=GetCardLogicValue(cbCard);
						stOutCard.cbCardData[0]=cbCard;

						vecPossibleResult.push_back(stOutCard);	
					}
				}
				//排序//防止深度搜索先出大牌
				if (vecPossibleResult.size()>nSortBegin)
				{
					std::sort(vecPossibleResult.begin() + nSortBegin, vecPossibleResult.end(), less_value);
				}
					
				//考虑对牌
				if (cbCardCount>=2)
				{
					stOutCard.cbCardCount=2;
					stOutCard.cbCardType=CT_DOUBLE;
					for (int i=2;i<3;i++)
					{
						for(int j=stHandCardResult.cbBlockCount[i]-1;j>=0;j--)
						{
							stOutCard.cbLogicValue=GetCardLogicValue(stHandCardResult.cbCardData[i][(i+1)*j]);
							CopyMemory(stOutCard.cbCardData,&stHandCardResult.cbCardData[i][(i+1)*j],2*sizeof(BYTE));

							vecPossibleResult.push_back(stOutCard);
						}
					}
				}//考虑对牌

				//考虑单牌
				stOutCard.cbCardCount=1;
				stOutCard.cbCardType=CT_SINGLE;
				for (int i=1;i<3;i++)
				{
					for(int j=stHandCardResult.cbBlockCount[i]-1;j>=0;j--)
					{
						BYTE cbCard=stHandCardResult.cbCardData[i][(i+1)*j];

						stOutCard.cbLogicValue=GetCardLogicValue(cbCard);
						stOutCard.cbCardData[0]=cbCard;

						vecPossibleResult.push_back(stOutCard);	
					}
				}
				if (vecPossibleResult.size() == 0) return NULL;
				//考虑不拆炸弹
				if (bFixedBomb&&vecPossibleResult[0].cbCardType>=CT_BOMB_CARD)
				{
					vector<tagOutCardResult> vecBomb;
					SearchBombCard(stHandCardResult,vecBomb);
					for (int k=0;k<(int)vecPossibleResult.size();)
					{
						if (vecPossibleResult[k].cbCardType<CT_BOMB_CARD)
						{
							tagOutCard &stOutTemp=vecPossibleResult.at(k);
							SortCardList(stOutTemp.cbCardData,stOutTemp.cbCardCount,ST_ORDER);
							BYTE cbCardBuf[MAX_COUNT]={0};
							BYTE cbBufCount=cbCardCount;
							CHECK_MEMCPY(MAX_COUNT,cbCardCount*sizeof(BYTE));
							CopyMemory(cbCardBuf,cbCardData,cbCardCount*sizeof(BYTE));
							VERIFY(RemoveCard(stOutTemp.cbCardData,stOutTemp.cbCardCount,cbCardBuf,cbBufCount));
							cbBufCount-=stOutTemp.cbCardCount;

							tagAnalyseResult stAnalyseTemp;
							AnalyseOutCard(cbCardBuf,cbBufCount,stAnalyseTemp);
							vector<tagOutCardResult> vecBomb2;
							SearchBombCard(stAnalyseTemp,vecBomb2);
							if (vecBomb2.size()<vecBomb.size())
							{//擦掉拆炸弹的项
								vecPossibleResult.erase(vecPossibleResult.begin()+k);
								continue;
							}
						}
						k++;
					}
				}

#ifdef _DEBUG
				for (size_t i=0;i<vecPossibleResult.size();i++)
				{
					tagOutCard &stTemp=vecPossibleResult.at(i);
					
					ASSERT(stTemp.cbCardType!=CT_ERROR);
					ASSERT(GetCardType(stTemp.cbCardData,stTemp.cbCardCount)==stTemp.cbCardType);
					if (stTemp.cbCardType<CT_MISSILE_CARD)
					{
						ASSERT(stTemp.cbLogicValue!=0);
					}						
				}
#endif
				return vecPossibleResult.size();
			}//case CT_ERROR:
		case CT_SINGLE://单牌类型
		case CT_DOUBLE://对牌类型
		case CT_THREE://三条类型
			{
				//变量定义
				BYTE cbReferCard=TurnCardResult.cbCardData[0];
				BYTE cbSameCount = 1;
				if( TurnCardResult.cbCardType == CT_DOUBLE ) cbSameCount = 2;
				else if( TurnCardResult.cbCardType == CT_THREE ) cbSameCount = 3;

				//搜索相同牌
				tagSearchCardResult SearchCardResult = {0};
				BYTE cbResultCount = SearchSameCard( cbCardData,cbCardCount,cbReferCard,cbSameCount,&SearchCardResult );

				stOutCard.cbCardCount=cbSameCount;
				stOutCard.cbCardType=TurnCardResult.cbCardType;

				for (int i=0;i<SearchCardResult.cbSearchCount;i++)
				{
					stOutCard.cbLogicValue=GetCardLogicValue(SearchCardResult.cbResultCard[i][0]);
					CHECK_MEMCPY(MAX_COUNT,cbSameCount*sizeof(BYTE));
					CopyMemory(stOutCard.cbCardData,SearchCardResult.cbResultCard[i],cbSameCount*sizeof(BYTE));
					
					vecPossibleResult.push_back(stOutCard);
				}

				break;
			}
		case CT_SINGLE_LINE://单连类型
		case CT_DOUBLE_LINE://对连类型
		case CT_THREE_LINE://三连类型
			{
				if (cbCardCount<TurnCardResult.cbCardCount) break;

				BYTE cbSameCount=1;
				if (CT_DOUBLE_LINE==TurnCardResult.cbCardType) cbSameCount=2;
				else if (CT_THREE_LINE==TurnCardResult.cbCardType) cbSameCount=3;

				//找出可能连
				vector<tagLinkCard> vecLinkCard;
				SearchAllLink(cbCardData,cbCardCount,cbSameCount,vecLinkCard);

				stOutCard.cbCardCount=TurnCardResult.cbCardCount;
				stOutCard.cbCardType=TurnCardResult.cbCardType;

				for (size_t i=0;i<vecLinkCard.size();i++)
				{
					if (vecLinkCard[i].cbLogicValue>TurnCardResult.cbLogicValue&&vecLinkCard[i].cbCardCount==TurnCardResult.cbCardCount)
					{//符合
						stOutCard.cbLogicValue=vecLinkCard[i].cbLogicValue;
						CHECK_MEMCPY(MAX_COUNT,vecLinkCard[i].cbCardCount*sizeof(BYTE));
						CopyMemory(stOutCard.cbCardData,vecLinkCard[i].cbCardData,vecLinkCard[i].cbCardCount*sizeof(BYTE));
						
						vecPossibleResult.push_back(stOutCard);
						break;
					}
				}

				break;
			}
		case CT_THREE_TAKE_ONE://三带一单
			{	
				if (cbCardCount<TurnCardResult.cbCardCount) break;
				
				if (TurnCardResult.cbCardCount == 4 && IsValidType(CT_THREE_TAKE_ONE))
				{
					for(int i=2;i<(bFourTake?4:3);i++)
					{//找出同三张
						for (int j=stHandCardResult.cbBlockCount[i]-1;j>=0;j--)
						{
							BYTE cbCardTemp[3]={0};
							CopyMemory(cbCardTemp,&stHandCardResult.cbCardData[i][(i+1)*j],3*sizeof(BYTE));

							//排除小牌
							if (GetCardLogicValue(cbCardTemp[0])<=TurnCardResult.cbLogicValue) continue;

							//三带一
							stOutCard.cbCardCount=4;
							stOutCard.cbCardType=CT_THREE_TAKE_ONE;
							stOutCard.cbLogicValue=GetCardLogicValue(cbCardTemp[0]);
							for(int k=0;k<3;k++)
							{//找单牌
								for(int m=stHandCardResult.cbBlockCount[k]-1;m>=0;m--)
								{
									if (m==j&&k==i) continue;  //排除同三
									BYTE cbCard=stHandCardResult.cbCardData[k][(k+1)*m];
								
									CopyMemory(stOutCard.cbCardData,cbCardTemp,3*sizeof(BYTE));
									stOutCard.cbCardData[3]=cbCard;
									SortCardList(stOutCard.cbCardData,4,ST_ORDER);

									vecPossibleResult.push_back(stOutCard);
									break;
								}
							}//找单牌
						}
					}//找出同三张
				}
				
				//考虑飞机
				if (TurnCardResult.cbCardCount>4)
				{
					vector<tagLinkCard> vecLinkCard;
					//搜索所有
					SearchAllLink(cbCardData,cbCardCount,3,vecLinkCard);

					for(UINT i=0;i<vecLinkCard.size();i++)
					{
						if (vecLinkCard[i].cbCardCount!=TurnCardResult.cbCardCount/4*3) continue;
						if (vecLinkCard[i].cbLogicValue<=TurnCardResult.cbLogicValue) continue;

						BYTE cbTackCard[MAX_COUNT]={0};					//带牌
						BYTE cbLinkCount=vecLinkCard[i].cbCardCount/3;	//连牌长度
						BYTE cbLinkCardCount=vecLinkCard[i].cbCardCount;//连牌张数

						stOutCard.cbLogicValue=GetCardLogicValue(vecLinkCard[i].cbCardData[0]);

						//考虑飞机带单
						if (cbCardCount>=cbLinkCount*4)
						{
							BYTE cbSingleCard[MAX_COUNT]={0};				//所有可用单牌
							BYTE cbSingleCount=0;								//可用张数

							//找出所有的单牌
							for(int k=0;k<=2;k++)
							{
								for (int m=stHandCardResult.cbBlockCount[k]-1;m>=0;m--)
								{
									BYTE cbCardValue=GetCardLogicValue(stHandCardResult.cbCardData[k][(k+1)*m]);
									//排除连内值
									if (cbCardValue<=vecLinkCard[i].cbLogicValue && cbCardValue>vecLinkCard[i].cbLogicValue-cbLinkCount)
										continue;
									if (cbCardValue==0) continue; //排除百打牌
									for (int n=0;n<=k;n++)
									{
										if (n>=2&&cbCardValue<0x0F&&
											((cbCardValue==vecLinkCard[i].cbLogicValue+1)||(cbCardValue==vecLinkCard[i].cbLogicValue-cbLinkCount)))
											continue;	//排除连在一起的同三张
										cbSingleCard[cbSingleCount++]=stHandCardResult.cbCardData[k][(k+1)*m+n];
									}
								}				
							}				

							if (cbSingleCount >= cbLinkCount && IsValidType(CT_THREE_TAKE_ONE))
							{
								SortCardList(cbSingleCard,cbSingleCount,ST_ORDER);

								stOutCard.cbCardType=CT_THREE_TAKE_ONE;
								stOutCard.cbCardCount=cbLinkCount*4;
								CHECK_MEMCPY(MAX_COUNT,vecLinkCard[i].cbCardCount*sizeof(BYTE));
								CopyMemory(stOutCard.cbCardData,vecLinkCard[i].cbCardData,vecLinkCard[i].cbCardCount*sizeof(BYTE));
								CHECK_MEMCPY(MAX_COUNT-cbLinkCount*3,cbLinkCount*sizeof(BYTE));
								CopyMemory(&stOutCard.cbCardData[cbLinkCount*3],&cbSingleCard[cbSingleCount-cbLinkCount],cbLinkCount*sizeof(BYTE));
								SortCardList(stOutCard.cbCardData,stOutCard.cbCardCount,ST_ORDER);
								if (GetCardType(stOutCard.cbCardData,stOutCard.cbCardCount)!=CT_THREE_TAKE_ONE) continue;//排除带火箭
								vecPossibleResult.push_back(stOutCard);
								break;
							}

						}
					}//for(int i=0;i<vecLinkCard.size();i++)
				}

				break;
			}
		case CT_THREE_TAKE_TWO://三带一对
			{
				if (cbCardCount<TurnCardResult.cbCardCount) break;
				
				if (TurnCardResult.cbCardCount==5)
				{
					for(int i=2;i<(bFourTake?4:3);i++)
					{//找出同三张
						for (int j=stHandCardResult.cbBlockCount[i]-1;j>=0;j--)
						{
							BYTE cbCardTemp[3]={0};
							CopyMemory(cbCardTemp,&stHandCardResult.cbCardData[i][(i+1)*j],3*sizeof(BYTE));
							//排除小牌
							if (GetCardLogicValue(cbCardTemp[0])<=TurnCardResult.cbLogicValue) continue;

							//三带二
							stOutCard.cbCardCount=5;
							stOutCard.cbCardType=CT_THREE_TAKE_TWO;
							stOutCard.cbLogicValue=GetCardLogicValue(cbCardTemp[0]);
							for (int k=1;k<3;k++)
							{//找对
								for(int m=stHandCardResult.cbBlockCount[k]-1;m>=0;m--)
								{
									if (m==j&&k==i) continue;  //排除同三

									CopyMemory(stOutCard.cbCardData,cbCardTemp,3*sizeof(BYTE));
									CopyMemory(&stOutCard.cbCardData[3],&stHandCardResult.cbCardData[k][(k+1)*m],2*sizeof(BYTE));
									SortCardList(stOutCard.cbCardData,5,ST_ORDER);

									vecPossibleResult.push_back(stOutCard);
									break;
								}
							}//找对
						}
					}//找出同三张
				}
				
				//考虑飞机
				if (TurnCardResult.cbCardCount>5)
				{
					//搜索所有
					vector<tagLinkCard> vecLinkCard;
					SearchAllLink(cbCardData,cbCardCount,3,vecLinkCard);

					for(size_t i=0;i<vecLinkCard.size();i++)
					{
						if (vecLinkCard[i].cbCardCount!=TurnCardResult.cbCardCount/5*3) continue;
						if (vecLinkCard[i].cbLogicValue<=TurnCardResult.cbLogicValue) continue;

						BYTE cbTackCard[MAX_COUNT]={0};					//带牌
						BYTE cbLinkCount=vecLinkCard[i].cbCardCount/3;	//连牌长度
						BYTE cbLinkCardCount=vecLinkCard[i].cbCardCount;//连牌张数

						stOutCard.cbLogicValue=GetCardLogicValue(vecLinkCard[i].cbCardData[0]);

						//考虑飞机带对
						if (cbCardCount>=cbLinkCount*5)
						{
							BYTE cbDoubleCard[MAX_COUNT]={0};		//所有可用对牌
							BYTE cbDoubleCount=0;					//对个数

							//找出所有的对
							for(int k=3;k>=1;k--)
							{
								for (int m=0;m<stHandCardResult.cbBlockCount[k];m++)
								{
									BYTE cbCard=stHandCardResult.cbCardData[k][m*(k+1)];
									if (GetCardLogicValue(cbCard)<=vecLinkCard[i].cbLogicValue && GetCardLogicValue(cbCard)>vecLinkCard[i].cbLogicValue-cbLinkCount)
										continue;

									CopyMemory(&cbDoubleCard[2*cbDoubleCount],&stHandCardResult.cbCardData[k][m*(k+1)],2*sizeof(BYTE));
									cbDoubleCount++;		
								}				
							}
							if (cbDoubleCount>=cbLinkCount)
							{
								stOutCard.cbCardType=CT_THREE_TAKE_TWO;
								stOutCard.cbCardCount=cbLinkCount*5;
								CopyMemory(stOutCard.cbCardData,vecLinkCard[i].cbCardData,vecLinkCard[i].cbCardCount*sizeof(BYTE));
								CopyMemory(&stOutCard.cbCardData[cbLinkCount*3],&cbDoubleCard[2*cbDoubleCount-2*cbLinkCount],cbLinkCount*2*sizeof(BYTE));
								SortCardList(stOutCard.cbCardData,stOutCard.cbCardCount,ST_ORDER);
								vecPossibleResult.push_back(stOutCard);
								break;
							}		
						}////考虑飞机带对

					}//for(int i=0;i<vecLinkCard.size();i++)
				}

				break;
			}
		case CT_FOUR_TAKE_ONE:
		case CT_FOUR_TAKE_TWO:
		case CT_BOMB_CARD:
		case CT_MISSILE_CARD:
			break;
		//default:
			//ASSERT(false);
		}//switch (TurnCardResult.cbCardType)

		vector<tagOutCard> vecBomb;
		//搜索炸弹
		if ((cbCardCount>=4)&&(TurnCardResult.cbCardType!=CT_MISSILE_CARD))
		{
			stOutCard.cbCardCount=4;
			stOutCard.cbCardType=CT_BOMB_CARD;
		
			//搜索炸弹
			for( BYTE i = 0; i < stHandCardResult.cbBlockCount[3]; i++ )
			{
				stOutCard.cbLogicValue=GetCardLogicValue(stHandCardResult.cbCardData[3][4*i]);
				if (TurnCardResult.cbCardType==CT_BOMB_CARD&&stOutCard.cbLogicValue<=TurnCardResult.cbLogicValue) continue;
				CopyMemory(stOutCard.cbCardData,&stHandCardResult.cbCardData[3][4*i],4*sizeof(BYTE));
		
				vecBomb.push_back(stOutCard);
			}
		}

		//搜索火箭
		if (TurnCardResult.cbCardType!=CT_MISSILE_CARD&&cbCardCount>=2)
		{
			if (cbHandCardData[0]==0x42&&cbHandCardData[1]==0x41)
			{
				stOutCard.cbCardType=CT_MISSILE_CARD;
				stOutCard.cbCardCount=2;
				stOutCard.cbCardData[0]=0x42;
				stOutCard.cbCardData[1]=0x41;
				stOutCard.cbLogicValue=0x11;
				vecBomb.push_back(stOutCard);
			}
		}

		if (vecBomb.size()>0)
		{		
			bool bBombFirst=false;
			//防止先拆炸弹
			int k=0;
			for (k=0;k<(int)vecPossibleResult.size();)
			{
				if (vecPossibleResult[k].cbCardType<CT_BOMB_CARD)
				{
					tagOutCard &stOutTemp=vecPossibleResult.at(k);
					SortCardList(stOutTemp.cbCardData,stOutTemp.cbCardCount,ST_ORDER);
					BYTE cbCardBuf[MAX_COUNT]={0};
					BYTE cbBufCount=cbCardCount;
					CHECK_MEMCPY(MAX_COUNT,cbCardCount*sizeof(BYTE));
					CopyMemory(cbCardBuf,cbCardData,cbCardCount*sizeof(BYTE));
					VERIFY(RemoveCard(stOutTemp.cbCardData,stOutTemp.cbCardCount,cbCardBuf,cbBufCount));
					cbBufCount-=stOutTemp.cbCardCount;

					tagAnalyseResult stAnalyseTemp;
					AnalyseOutCard(cbCardBuf,cbBufCount,stAnalyseTemp);
					vector<tagOutCardResult> vecBomb2;
					SearchBombCard(stAnalyseTemp,vecBomb2);
					if (vecBomb2.size()<vecBomb.size())
					{
						if (bFixedBomb)
						{//不拆
							vecPossibleResult.erase(vecPossibleResult.begin()+k);
							continue;
						}
						else
						{
							bBombFirst=true;	
							break;
						}	
					}
				}
				k++;
			}

			//先出炸弹
			if (bBombFirst)
			{
				for (int i=(int)vecBomb.size()-1;i>=0;i--)
				{
					vecPossibleResult.insert(vecPossibleResult.begin()+k,i+1,vecBomb.at(i));
				}		
			}		

			//后出炸弹
			if (!bBombFirst)
			{
				for (int i=0;i<(int)vecBomb.size();i++)
				{
					vecPossibleResult.push_back(vecBomb.at(i));
				}		
			}			
		}
//#ifdef _DEBUG
//		for (size_t i=0;i<vecPossibleResult.size();i++)
//		{
//			tagOutCard &stTemp=vecPossibleResult.at(i);
//
//			ASSERT(stTemp.cbCardType!=CT_ERROR);
//			ASSERT(GetCardType(stTemp.cbCardData,stTemp.cbCardCount)==stTemp.cbCardType);
//			
//			ASSERT(stTemp.cbLogicValue!=0);					
//		}
//#endif
		//不出
		ZeroMemory(&stOutCard,sizeof(stOutCard));
		vecPossibleResult.push_back(stOutCard);
	}
	CATCH (...)
	{
		THROW;
// 		ASSERT(false);
// #ifdef USE_LOG_TRACE		
// 		CTraceService::TraceString(TEXT("AndroidServer:SimplySearchResult ERROR"),TraceLevel_Exception);
// #endif
	}
	
	return vecPossibleResult.size();
}

//循环实现
bool CGameLogic::SimplySearchTheBest(const BYTE cbAllUserCard[GAME_PLAYER][MAX_COUNT], BYTE cbAllCount[GAME_PLAYER],const tagOutCard stTurnCard,WORD wMeChairID, WORD wOutUser,tagOutCard &stOutCard,bool bFourTake,bool bFixedBankerBomb)
{
#ifdef LYX_DEBUG	
	printf("0x%08x -> 0x%08x ============= CGameLogic::SimplySearchTheBest  =======\n",m_userSink,this);
	printf("wMeChairID:%d.\n",wMeChairID);
	printf("wOutUser:%d.\n",wOutUser);
	printf("bank user:%d\n",m_wBankerUser);
	printf("_wAllyID user:%d\n",_wAllyID);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player cbAllUserCard:%d, %s !\n",i,cardDataToString(cbAllUserCard[i],MAX_COUNT).c_str());
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player cbAllCount:%d, %d !\n",i,cbAllCount[i]);
#endif	

	CFunItem tt(__FUNCTION__);
	//初始化
	ZeroMemory(&stOutCard,sizeof(stOutCard));
#ifdef LYX_DEBUG
	TRACE("In Best\n");
#endif
	bool bReturn=false;

	TRY
	{
#define END_WIN			2
#define END_LOSE		1

		//构造子项
		tagSearchItem* pSearchItem=NULL;
		if (bFixedBankerBomb&&wMeChairID==m_wBankerUser)
		{
			pSearchItem=ConstructItem(cbAllUserCard,cbAllCount,stTurnCard,wMeChairID,wOutUser,false,true);
		}
		else pSearchItem=ConstructItem(cbAllUserCard,cbAllCount,stTurnCard,wMeChairID,wOutUser,bFourTake);	

		vector<tagSearchItem*> vecpSearchItem;

		//构造失败
		if (pSearchItem==NULL)	
		{
			ASSERT(false);
			m_nDepthCount=nBadSearch; 
			return false;
		}		

		//压栈处理
		vecpSearchItem.push_back(pSearchItem);

		while(vecpSearchItem.size()>0)
		{
			//深度限制
			if (m_nDepthCount>m_nDepthLimit)
			{
				bReturn=false;
				break;
			}

			//次数限制
			if (m_nSearchCount>=m_nTimeLimit)
			{
				bReturn=false;
				break;
			}

			if (!DealWithSearchItem(vecpSearchItem,bFourTake,bFixedBankerBomb)) {bReturn=false; break;}

			if (vecpSearchItem.size()>m_nDepthCount) m_nDepthCount=vecpSearchItem.size();

			tagSearchItem *pCurItem=vecpSearchItem.back();

			//最终无果
			if (pCurItem->nIndex>=(int)pCurItem->vecSearchReslut.size())
			{
				pCurItem->cbWin=END_LOSE;
				break;
			}
			else
			{
				if (pCurItem->cbAllCount[pCurItem->wChairID]==pCurItem->vecSearchReslut[pCurItem->nIndex].cbCardCount)
				{//牌已出完
					pCurItem->cbWin=END_WIN;
					break;
				}
				else
				{//继续搜索
					continue;
				}
			}

			//校验数据
			ASSERT(pCurItem->cbWin==END_LOSE||pCurItem->cbWin==END_WIN);
			if (pCurItem->cbWin!=END_LOSE&&pCurItem->cbWin!=END_WIN) { bReturn=false; break;}

			int nSize=(int)vecpSearchItem.size();

			//找到结果
			if (nSize==1)
			{
				if (pCurItem->cbWin==END_WIN)
				{
					CopyMemory(&stOutCard,&pCurItem->vecSearchReslut[pCurItem->nIndex],sizeof(tagOutCard));
					bReturn=true;
					break;
				}
				else if (pCurItem->cbWin==END_LOSE)
				{
					bReturn=false;
					break;
				}
				ASSERT(false);
			}

			//处理子项
			while(vecpSearchItem.size()>1)
			{
				nSize=(int)vecpSearchItem.size();

				tagSearchItem* pItem1=vecpSearchItem.at(nSize-2);
				tagSearchItem* pItem2=vecpSearchItem.at(nSize-1);

				if (END_WIN==pItem2->cbWin)
				{//赢
					if (IsAlly(pItem1->wChairID,pItem2->wChairID))
					{//盟友
						pItem1->cbWin=END_WIN;
						FreeSearchItem(pItem2);
						vecpSearchItem.pop_back();
						continue;
					}
					else
					{//敌对
						pItem1->nIndex++;
						FreeSearchItem(pItem2);
						vecpSearchItem.pop_back();
						break;
					}
				}
				else if (END_LOSE==pItem2->cbWin)
				{//输
					if (IsAlly(pItem1->wChairID,pItem2->wChairID))
					{//盟友
						pItem1->nIndex++;
						FreeSearchItem(pItem2);
						vecpSearchItem.pop_back();
						break;
					}
					else
					{//敌对
						pItem1->cbWin=END_WIN;
						FreeSearchItem(pItem2);
						vecpSearchItem.pop_back();
						continue;
					}
				}
				ASSERT(false);
				break;
			}//处理子项
			
			//结束搜索
			if (vecpSearchItem.size()==1&&vecpSearchItem[0]->cbWin!=0)
			{
				stOutCard=vecpSearchItem[0]->vecSearchReslut[vecpSearchItem[0]->nIndex];
				
				if (vecpSearchItem[0]->cbWin==END_WIN) bReturn=true;
				else bReturn=false;
				break;
			}

		}//循环处理

		//释放资源
		for (size_t i=0;i<vecpSearchItem.size();i++)
		{
			tagSearchItem* p=vecpSearchItem.at(i);
			FreeSearchItem(p);
		}
		vecpSearchItem.clear();
	}
	CATCH (...)
	{
		THROW;
// 		ASSERT(false);
// #ifdef USE_LOG_TRACE		
// 		CTraceService::TraceString(TEXT("AndroidServer:SimplySearchBest ERROR"),TraceLevel_Exception);
// #endif
	}
#ifdef LYX_DEBUG
	TRACE("User:%d Search Depth:%d Count:%d Return:%d\n",wMeChairID,m_nDepthCount,m_nSearchCount,bReturn);
	TRACE("Out Best\n");
#endif
	return bReturn;
}

//分配内存
tagSearchItem* CGameLogic::AllocSearchItem()
{
	// tagSearchItem* pItem = NULL;
	// if(m_SearchItemPool.IsEmpty())
	// {
	// 	pItem = new tagSearchItem;
	// 	ASSERT(pItem);
	// 	if(pItem)
	// 		m_SearchItemUsed.AddTail(pItem);
	// }
	// else
	// {
	// 	// begin modified by lizhongqiang 2015-04-28 09:00
	// 	// 可能会出现越界访问
	// 	pItem = m_SearchItemPool.RemoveHead();
	// 	if (pItem)
	// 	{
	// 		m_SearchItemUsed.AddTail(pItem);
	// 		pItem->reset();
	// 	}
	// 	// end modified by lizhongqiang 2015-04-28 09:00
	// }
	// return pItem;

	// by lyx 2018-9-29
	if (m_SearchItemPool.empty())
	{
		return new tagSearchItem;
	}
	else
	{
		tagSearchItem * ret = m_SearchItemPool.back();
		ret->reset();
		m_SearchItemPool.pop_back();
		return ret;
	}

}

//释放内存
void CGameLogic::FreeSearchItem(tagSearchItem* pItem)
{
	// POSITION pos = m_SearchItemUsed.GetHeadPosition(), temppos = pos;
	// for(temppos = pos;pos;temppos = pos)
	// {
	// 	if(m_SearchItemUsed.GetNext(pos) == pItem)
	// 	{
	// 		m_SearchItemUsed.RemoveAt(temppos);
	// 		m_SearchItemPool.AddTail(pItem);
	// 		return;
	// 	}
	// }
	// ASSERT(false);

	// by lyx 2018-9-29
	m_SearchItemPool.push_back(pItem);
}

//构造条目
tagSearchItem* CGameLogic::ConstructItem(const BYTE cbAllUserCard[GAME_PLAYER][MAX_COUNT], BYTE cbAllCount[GAME_PLAYER],const tagOutCard stTurnCard,WORD wMeChairID, WORD wOutUser,bool bFourTake,bool bFixedBomb)
{
	tagSearchItem *pCurItem = (tagSearchItem *)AllocSearchItem();
	if (pCurItem==NULL) return NULL;

	CopyMemory(pCurItem->cbAllCount,cbAllCount,sizeof(pCurItem->cbAllCount));
	CopyMemory(pCurItem->cbAllCard,cbAllUserCard,sizeof(pCurItem->cbAllCard));
	CopyMemory(&pCurItem->stTurnCard,&stTurnCard,sizeof(tagOutCard));
	pCurItem->wChairID=wMeChairID;
	pCurItem->wOutUser=wOutUser;
	ASSERT(wMeChairID<GAME_PLAYER);
	SimplySearchResult(cbAllUserCard[wMeChairID],cbAllCount[wMeChairID],stTurnCard,pCurItem->vecSearchReslut,bFourTake,bFixedBomb);

	return pCurItem;
}

//循环处理
bool CGameLogic::DealWithSearchItem(std::vector<tagSearchItem*> &vecpSearchItem,bool bFourTake,bool bFixedBankerBomb)
{
	if (vecpSearchItem.size()==0) return false;

	//次数统计
	m_nSearchCount++;

	tagSearchItem* pSearchItem=vecpSearchItem.back();
	
	for (int i=pSearchItem->nIndex;i<(int)pSearchItem->vecSearchReslut.size();i++)
	{
		//拷贝扑克
		BYTE	cbAllCardTemp[GAME_PLAYER][MAX_COUNT]={0};
		BYTE	cbAllCountTemp[GAME_PLAYER];
		CopyMemory(cbAllCardTemp,pSearchItem->cbAllCard,sizeof(cbAllCardTemp));
		CopyMemory(cbAllCountTemp,pSearchItem->cbAllCount,sizeof(cbAllCountTemp));
		ReSetCardCount(cbAllCardTemp, cbAllCountTemp);
		WORD wChairID=pSearchItem->wChairID;
		WORD wOutUser=pSearchItem->wOutUser;
		tagOutCard stTurnCard;
		tagOutCard stOutCard;
		CopyMemory(&stTurnCard,&pSearchItem->stTurnCard,sizeof(tagOutCard));
		CopyMemory(&stOutCard,&pSearchItem->vecSearchReslut.at(i),sizeof(tagOutCard));

		VERIFY(RemoveCard(stOutCard.cbCardData,stOutCard.cbCardCount,cbAllCardTemp[wChairID],cbAllCountTemp[wChairID]));
		cbAllCountTemp[wChairID]-=stOutCard.cbCardCount;

		//牌已出完
		if (cbAllCountTemp[wChairID]==0) return true;

		//模拟下家出牌
		WORD	wNextUser=INVALID_CHAIR;

		//注意单挑模式
		for(WORD j=1;j<GAME_PLAYER;j++)
		{
			wNextUser=(wChairID+j)%GAME_PLAYER;
			if (cbAllCountTemp[wNextUser]!=0)
				break;
		}

		//校验
		ASSERT(wNextUser<GAME_PLAYER);
		
		if (wNextUser==INVALID_CHAIR)
		{
			m_nDepthCount=nBadSearch;
			return false;
		}

		//搜索出牌
		tagSearchItem* pNewSearch=NULL;
		//如果管牌
		if (stOutCard.cbCardCount!=0)
		{
			if (bFixedBankerBomb&&wNextUser==m_wBankerUser)
				pNewSearch=ConstructItem(cbAllCardTemp,cbAllCountTemp,stOutCard,wNextUser,wChairID,false,true);

			else pNewSearch=ConstructItem(cbAllCardTemp,cbAllCountTemp,stOutCard,wNextUser,wChairID,bFourTake);
		}
		else
		{//pass
			//单挑模式
			if (stTurnCard.cbCardCount>0&&cbAllCountTemp[wOutUser]==0)	return false;
			
			if (wNextUser==wOutUser)
			{
				if (bFixedBankerBomb&&wNextUser==m_wBankerUser)
					pNewSearch=ConstructItem(cbAllCardTemp,cbAllCountTemp,stOutCard,wNextUser,INVALID_CHAIR,false,true);

				else pNewSearch=ConstructItem(cbAllCardTemp,cbAllCountTemp,stOutCard,wNextUser,INVALID_CHAIR,bFourTake);
			}
			else
			{
				if (bFixedBankerBomb&&wNextUser==m_wBankerUser)
					pNewSearch=ConstructItem(cbAllCardTemp,cbAllCountTemp,stTurnCard,wNextUser,wOutUser,false,true);

				else pNewSearch=ConstructItem(cbAllCardTemp,cbAllCountTemp,stTurnCard,wNextUser,wOutUser,bFourTake);
			}
		}
		//搜索错误
		if (pNewSearch==NULL)	return false;
		else vecpSearchItem.push_back(pNewSearch);
		return true;
	 }

	return true;
}

//递归穷举搜索最佳出牌 暂停不用
bool CGameLogic::SimplySearchTheBest(const BYTE cbAllUserCard[GAME_PLAYER][MAX_COUNT], BYTE cbAllCount[GAME_PLAYER],const tagOutCard stTurnCard,WORD wMeChairID, WORD wOutUser,tagOutCard &stOutCard,size_t &nTime/*初始值必须是0*/,bool bFourTake)
{
	CFunItem tt(__FUNCTION__);
	ZeroMemory(&stOutCard,sizeof(stOutCard));

	m_nDepthCount++;

	if (m_nDepthCount>m_nDepthLimit)
	{
#ifdef USE_LOG_TRACE		
		CTraceService::TraceString(TEXT("AndroidServer:SimplySearchTheBest FUN exceed DepthLimit"),TraceLevel_Exception);
#endif
	}
	
	//变量定义
	vector<tagOutCard> vecPossibleResult;						//可能结果
	bool	bWin=false;
	UINT	i=0;												//循环索引
	//胜利标志
	TRY
	{
		//拷贝扑克
		BYTE	cbAllUserCardTemp[GAME_PLAYER][MAX_COUNT]={0};
		BYTE	cbAllCountTemp[GAME_PLAYER]={0};

		//搜索可能
		size_t nResultCount=SimplySearchResult(cbAllUserCard[wMeChairID],cbAllCount[wMeChairID],stTurnCard,vecPossibleResult,bFourTake);
	
		//循环查找
		for (;i<nResultCount;i++)
		{	
			nTime++;

			if (cbAllCount[wMeChairID]==vecPossibleResult[i].cbCardCount)
			{//出牌结束
				bWin=true;
				break;
			}

			//深度限制
			if (nTime>m_nTimeLimit)
			{
				nTime=nBadSearch;
				return false;
			}

			CopyMemory(cbAllUserCardTemp,cbAllUserCard,sizeof(cbAllUserCardTemp));
			CopyMemory(cbAllCountTemp,cbAllCount,sizeof(cbAllCountTemp));

			VERIFY(RemoveCard(vecPossibleResult[i].cbCardData,vecPossibleResult[i].cbCardCount,cbAllUserCardTemp[wMeChairID],cbAllCountTemp[wMeChairID]));
			cbAllCountTemp[wMeChairID]-=vecPossibleResult[i].cbCardCount;

			//模拟下家出牌
			WORD	wNextUser=INVALID_CHAIR;

			//注意单挑模式
			for(WORD j=1;j<GAME_PLAYER;j++)
			{
				wNextUser=(wMeChairID+j)%GAME_PLAYER;
				if (cbAllCountTemp[wNextUser]!=0)
					break;
			}
			
			//校验
			ASSERT(wNextUser<GAME_PLAYER);
			ASSERT(wNextUser!=wMeChairID);
			if (wNextUser>=GAME_PLAYER||wNextUser==wMeChairID)
			{
				nTime=nBadSearch;
				return false;
			}
			
			//搜索出牌
			tagOutCard stNextOutCard;
			bool bResult=false;
			//如果管牌
			if (vecPossibleResult[i].cbCardCount!=0)
			{

				bResult=SimplySearchTheBest(cbAllUserCardTemp,cbAllCountTemp,vecPossibleResult.at(i),wNextUser,wMeChairID,stNextOutCard,nTime,bFourTake);
			}
			else
			{//pass
				if (wNextUser==wOutUser)
				{
					if (stTurnCard.cbCardCount>0&&cbAllCountTemp[wOutUser]==0)
					{//考虑单挑模式
						nTime=nBadSearch;
						return false;
					}
					bResult=SimplySearchTheBest(cbAllUserCardTemp,cbAllCountTemp,vecPossibleResult.at(i),wNextUser,wOutUser,stNextOutCard,nTime,bFourTake);
				}
				else
				{
					bResult=SimplySearchTheBest(cbAllUserCardTemp,cbAllCountTemp,stTurnCard,wNextUser,wOutUser,stNextOutCard,nTime,bFourTake);
				}
			}
			
			//未得到结果
			if (nTime==nBadSearch) return false;

			//都是农民
			if (wMeChairID!=m_wBankerUser&&wNextUser!=m_wBankerUser) bWin=bResult;
			//反方
			else bWin=!bResult;

			if (bWin)   break;	//胜利
		}
	}
	CATCH (...)
	{
		THROW;
// 		ASSERT(false);
// #ifdef USE_LOG_TRACE		
// 		CTraceService::TraceString(TEXT("AndroidServer:SimplySearchTheBest ERROR"),TraceLevel_Exception);
// #endif
	}
	
	//保存结果
	if (bWin) stOutCard=vecPossibleResult[i];
	
	m_nDepthCount--;

	return bWin;
}
//简化搜索
size_t CGameLogic::SearchAllLink(const BYTE cbCardData[],BYTE cbCardCount,BYTE cbSameCount,std::vector<tagLinkCard> &vecLinkCard)
{
	CFunItem tt(__FUNCTION__, TEXT("cc=%d"), cbCardCount);
	TRY
	{
		//校验
		ASSERT(cbSameCount>0&&cbSameCount<4);
		if(cbSameCount==0||cbSameCount>3) return 0;

		//初始化
		vecLinkCard.clear();

		//最小连数
		BYTE cbMinLinkCount=5;
		BYTE cbCardType=CT_SINGLE_LINE;
		if (cbSameCount==2)
		{
			cbMinLinkCount=3;
			cbCardType=CT_DOUBLE_LINE;
		}
		else if (cbSameCount==3)
		{
			cbMinLinkCount=2;
			cbCardType=CT_THREE_LINE;
		}

		//变量定义
		tagAnalyseResult stAnalyseResult;
		AnalysebCardData(cbCardData,cbCardCount,stAnalyseResult);
		
		//变量定义
		BYTE cbLinkCount=0;
		BYTE cbTypeValue=0;
		bool bExist[15]={0};
		
		for (int i=cbSameCount-1;i<4;i++)
		{
			for (int j=0;j<stAnalyseResult.cbBlockCount[i];j++)
			{
				BYTE cbValue=GetCardLogicValue(stAnalyseResult.cbCardData[i][j*(i+1)]);
				if (cbValue<15) bExist[cbValue]=true;
			}	
		}
		
		//最长连
		for(int i=14;i>=0;i--)
		{
			if (bExist[i])
			{
				if (cbLinkCount==0) cbTypeValue=i;
				cbLinkCount++;
			}
			else
			{
				if (cbLinkCount>=cbMinLinkCount)
				{
					tagLinkCard stLinkCard = {0};
					stLinkCard.cbCardCount=cbLinkCount*cbSameCount;
					stLinkCard.cbLogicValue=cbTypeValue;
					stLinkCard.cbCardType=cbCardType;
					stLinkCard.cbLinkCount=cbLinkCount;
					vecLinkCard.push_back(stLinkCard);
				}

				//初始化
				cbLinkCount=0;
			}
		}

		//合适连
		for (int i=(int)vecLinkCard.size()-1;i>=0;i--)
		{
			tagLinkCard stLinkCard;
			stLinkCard=vecLinkCard[i];
			
			for (int j=stLinkCard.cbLinkCount-1;j>=cbMinLinkCount;j--)
			{//合适连长
				for (int k=stLinkCard.cbLogicValue;k>=stLinkCard.cbLogicValue-stLinkCard.cbLinkCount+j;k--)
				{//合适大小
					tagLinkCard stLinkTemp = {0};
					stLinkTemp.cbLogicValue=k;
					stLinkTemp.cbLinkCount=j;
					stLinkTemp.cbCardType=cbCardType;
					stLinkTemp.cbCardCount=cbSameCount*j;
					vecLinkCard.push_back(stLinkTemp);
				}
			}
		}
		
		//从小到大排序
		std::sort(vecLinkCard.begin(),vecLinkCard.end(),less_linkcount);

		//填充牌值
		for (int i=0;i<(int)vecLinkCard.size();i++)
		{
			tagLinkCard &stLinkCard=vecLinkCard.at(i);
			BYTE cbFillCount=0;
			for (int j=stLinkCard.cbLogicValue;j>stLinkCard.cbLogicValue-stLinkCard.cbLinkCount;j--)
			{
				for (int k=0;k<cbCardCount;k++)
				{
					if (GetCardLogicValue(cbCardData[k])==j)
					{
						CHECK_MEMCPY(MAX_COUNT-cbFillCount,cbSameCount*sizeof(BYTE));
						CopyMemory(&stLinkCard.cbCardData[cbFillCount],&cbCardData[k],cbSameCount*sizeof(BYTE));
						k+=cbSameCount;
						cbFillCount+=cbSameCount;
						break;
					}
				}
			}
			ASSERT(cbFillCount==stLinkCard.cbCardCount);
		}
	}
	CATCH(...)
	{
		THROW;
// 		ASSERT(false);
// #ifdef USE_LOG_TRACE
// 		CTraceService::TraceString(TEXT("AndroidServer:SearchAllLink ERROR"),TraceLevel_Exception);
// #endif
	}

	return vecLinkCard.size();
}
//简化搜索
size_t CGameLogic::SimplySearchFastest(const BYTE cbHandCardData[],BYTE cbHandCardCount,std::vector<tagOutCard> &vecPossibleResult)
{
	CFunItem tt(__FUNCTION__, TEXT("hc=%d"), cbHandCardCount);
	//遵循从大到小排列
	vecPossibleResult.clear();
	
	TRY
	{
		//变量定义
		tagSearchCardResult tmpSearchCardResult = {};

		//构造扑克
		BYTE cbCardData[MAX_COUNT];
		BYTE cbCardCount=cbHandCardCount;
		CHECK_MEMCPY(MAX_COUNT,cbHandCardCount*sizeof(BYTE));
		CopyMemory(cbCardData,cbHandCardData,sizeof(BYTE)*cbHandCardCount);

		//排列扑克
		SortCardList(cbCardData,cbCardCount,ST_ORDER);

		//分析手牌
		tagAnalyseResult stHandCardResult;
		AnalysebCardData(cbCardData,cbCardCount,stHandCardResult);

		tagOutCard stOutCard = {0};

		//出牌分析
		vector<tagLinkCard> vecLinkCard;
		//火箭
		if (cbHandCardCount>=2)
		{
			if (cbHandCardData[0]==0x42&&cbHandCardData[1]==0x41)
			{
				stOutCard.cbCardType=CT_MISSILE_CARD;
				stOutCard.cbCardCount=2;
				stOutCard.cbCardData[0]=0x42;
				stOutCard.cbCardData[1]=0x41;
				vecPossibleResult.push_back(stOutCard);
			}
		}

		//炸弹
		if (cbHandCardCount>=4)
		{
			for(BYTE i=0;i<stHandCardResult.cbBlockCount[3];i++)
			{
				stOutCard.cbCardType=CT_BOMB_CARD;
				stOutCard.cbCardCount=4;
				stOutCard.cbLogicValue=GetCardLogicValue(stHandCardResult.cbCardData[3][i*4]);
				CopyMemory(stOutCard.cbCardData,&stHandCardResult.cbCardData[3][i*4],4*sizeof(BYTE));
				vecPossibleResult.push_back(stOutCard);
			}
		}

		//考虑一手出完
		tagAnalyseResult AnalyseResult = {0};
		//分析扑克
		if(CT_ERROR!=AnalyseOutCard(cbCardData,cbCardCount,AnalyseResult)
			&&AnalyseResult.cbCardType!=CT_FOUR_TAKE_ONE&&AnalyseResult.cbCardType!=CT_FOUR_TAKE_TWO)
		{
			stOutCard.cbCardType=AnalyseResult.cbCardType;
			stOutCard.cbCardCount=cbCardCount;
			stOutCard.cbLogicValue=AnalyseResult.cbLogicValue;
			CHECK_MEMCPY(MAX_COUNT,cbCardCount*sizeof(cbCardCount));
			CopyMemory(stOutCard.cbCardData,cbCardData,cbCardCount*sizeof(cbCardCount));
			vecPossibleResult.push_back(stOutCard);
		}

		//考虑连对
		if (cbCardCount>=6)
		{
			SearchAllLink(cbCardData,cbCardCount,2,vecLinkCard);

			for(int i=(int)vecLinkCard.size()-1;i>=0;i--)
			{
				stOutCard.cbCardCount=vecLinkCard[i].cbCardCount;
				stOutCard.cbCardType=CT_DOUBLE_LINE;
				stOutCard.cbLogicValue=vecLinkCard[i].cbLogicValue;
				CHECK_MEMCPY(MAX_COUNT,stOutCard.cbCardCount*sizeof(BYTE));
				CopyMemory(stOutCard.cbCardData,vecLinkCard[i].cbCardData,stOutCard.cbCardCount*sizeof(BYTE));
				
				vecPossibleResult.push_back(stOutCard);
			}
		}

		if (cbHandCardCount>=6)
		{
			for(BYTE i=0;i<stHandCardResult.cbBlockCount[3];i++)
			{
				stOutCard.cbCardType=CT_BOMB_CARD;
				stOutCard.cbCardCount=4;
				stOutCard.cbLogicValue=GetCardLogicValue(stHandCardResult.cbCardData[3][i*4]);
				CopyMemory(stOutCard.cbCardData,&stHandCardResult.cbCardData[3][i*4],4*sizeof(BYTE));
				vecPossibleResult.push_back(stOutCard);
			}
		}

		//考虑单连
		if (cbCardCount>=5)
		{
			SearchAllLink(cbCardData,cbCardCount,1,vecLinkCard);

			for(int i=(int)vecLinkCard.size()-1;i>=0;i--)
			{
				stOutCard.cbCardCount=vecLinkCard[i].cbCardCount;
				stOutCard.cbCardType=CT_SINGLE_LINE;
				stOutCard.cbLogicValue=vecLinkCard[i].cbLogicValue;
				CopyMemory(stOutCard.cbCardData,vecLinkCard[i].cbCardData,stOutCard.cbCardCount*sizeof(BYTE));
				
				vecPossibleResult.push_back(stOutCard);
			}
		}
		
		//考虑飞机
		if (cbCardCount>=6)
		{
			//搜索所有
			SearchAllLink(cbCardData,cbCardCount,3,vecLinkCard);

			for(int i=(int)vecLinkCard.size()-1;i>=0;i--)
			{
				BYTE cbTackCard[MAX_COUNT]={0};					//带牌
				BYTE cbLinkCount=vecLinkCard[i].cbCardCount/3;	//连牌长度
				BYTE cbLinkCardCount=vecLinkCard[i].cbCardCount;//连牌张数
				stOutCard.cbLogicValue=GetCardLogicValue(vecLinkCard[i].cbCardData[0]);

				//考虑飞机带单
				if (cbCardCount>=cbLinkCount*4)
				{
					BYTE cbSingleCard[MAX_COUNT]={0};				//所有可用单牌
					BYTE cbSingleCount=0;							//可用张数

					//找出所有的单牌
					for(int k=0;k>=0;k--)
					{
						for (int m=0;m<stHandCardResult.cbBlockCount[k];m++)
						{
							BYTE cbCardValue=GetCardLogicValue(stHandCardResult.cbCardData[k][(k+1)*m]);
							//排除连内值
							if (cbCardValue<=vecLinkCard[i].cbLogicValue && cbCardValue>vecLinkCard[i].cbLogicValue-cbLinkCount)
								continue;
				
							for (int n=0;n<=(k==3?2:k);n++)
							{
								if (n>=2&&cbCardValue<0x0F&&
									((cbCardValue==vecLinkCard[i].cbLogicValue+1)||(cbCardValue==vecLinkCard[i].cbLogicValue-cbLinkCount)))
									continue;	//排除连在一起的同三张
								cbSingleCard[cbSingleCount++]=stHandCardResult.cbCardData[k][(k+1)*m+n];
							}
						}				
					}

					if (cbSingleCount >= cbLinkCount && IsValidType(CT_THREE_TAKE_ONE, cbCardCount))
					{
						SortCardList(cbSingleCard,cbSingleCount,ST_ORDER);

						stOutCard.cbCardType=CT_THREE_TAKE_ONE;
						stOutCard.cbCardCount=cbLinkCount*4;
						CHECK_MEMCPY(MAX_COUNT,vecLinkCard[i].cbCardCount*sizeof(BYTE));
						CopyMemory(stOutCard.cbCardData,vecLinkCard[i].cbCardData,vecLinkCard[i].cbCardCount*sizeof(BYTE));
						CHECK_MEMCPY(MAX_COUNT-cbLinkCount*3,cbLinkCount*sizeof(BYTE));
						CopyMemory(&stOutCard.cbCardData[cbLinkCount*3],&cbSingleCard[cbSingleCount-cbLinkCount],cbLinkCount*sizeof(BYTE));
						SortCardList(stOutCard.cbCardData,stOutCard.cbCardCount,ST_ORDER);
						//排除火箭
						if (stOutCard.cbCardData[0]==0x42&&stOutCard.cbCardData[1]==0x41) continue;
						vecPossibleResult.push_back(stOutCard);
					}
				}
			}//for(size_t i=0;i<vecLinkCard.size();i++)

			for(int i=(int)vecLinkCard.size()-1;i>=0;i--)
			{
				BYTE cbTackCard[MAX_COUNT]={0};					//带牌
				BYTE cbLinkCount=vecLinkCard[i].cbCardCount/3;	//连牌长度
				BYTE cbLinkCardCount=vecLinkCard[i].cbCardCount;//连牌张数
				stOutCard.cbLogicValue=GetCardLogicValue(vecLinkCard[i].cbCardData[0]);


				//考虑飞机带对
				//if (cbCardCount>=cbLinkCount*5)
				//{
				//	BYTE cbDoubleCard[MAX_COUNT]={0};		//所有可用对牌
				//	BYTE cbDoubleCount=0;						//对个数

				//	//找出所有的对
				//	for(int k=1;k>=1;k--)
				//	{
				//		for (int m=0;m<stHandCardResult.cbBlockCount[k];m++)
				//		{
				//			BYTE cbCard=stHandCardResult.cbCardData[k][m*(k+1)];
				//			if (GetCardLogicValue(cbCard)<=vecLinkCard[i].cbLogicValue && GetCardLogicValue(cbCard)>vecLinkCard[i].cbLogicValue-cbLinkCount)
				//				continue;

				//			CopyMemory(&cbDoubleCard[2*cbDoubleCount],&stHandCardResult.cbCardData[k][m*(k+1)],2*sizeof(BYTE));
				//			cbDoubleCount++;		
				//		}				
				//	}			

				//	if (cbDoubleCount>=cbLinkCount)
				//	{
				//		stOutCard.cbCardType=CT_THREE_TAKE_TWO;
				//		stOutCard.cbCardCount=cbLinkCount*5;
				//		CopyMemory(stOutCard.cbCardData,vecLinkCard[i].cbCardData,vecLinkCard[i].cbCardCount*sizeof(BYTE));
				//		CopyMemory(&stOutCard.cbCardData[cbLinkCount*3],&cbDoubleCard[2*cbDoubleCount-2*cbLinkCount],cbLinkCount*2*sizeof(BYTE));
				//		SortCardList(stOutCard.cbCardData,stOutCard.cbCardCount,ST_ORDER);
				//		vecPossibleResult.push_back(stOutCard);
				//	}		
				//}
			}//for(size_t i=0;i<vecLinkCard.size();i++)

			for(int i=(int)vecLinkCard.size()-1;i>=0;i--)
			{
				BYTE cbTackCard[MAX_COUNT]={0};					//带牌
				BYTE cbLinkCount=vecLinkCard[i].cbCardCount/3;	//连牌长度
				BYTE cbLinkCardCount=vecLinkCard[i].cbCardCount;//连牌张数
				stOutCard.cbLogicValue=GetCardLogicValue(vecLinkCard[i].cbCardData[0]);

				//飞机不带翅膀
				stOutCard.cbCardCount=cbLinkCount*3;
				stOutCard.cbCardType=CT_THREE_LINE;
				stOutCard.cbLogicValue=vecLinkCard[i].cbLogicValue;
				CHECK_MEMCPY(MAX_COUNT,cbLinkCount*3*sizeof(BYTE));
				CopyMemory(stOutCard.cbCardData,vecLinkCard[i].cbCardData,cbLinkCount*3*sizeof(BYTE));
				//保存
				vecPossibleResult.push_back(stOutCard);
			}//for(size_t i=0;i<vecLinkCard.size();i++)
		}

		//考虑三带
		if (cbCardCount>=3)
		{	
			for(int i=2;i<=2;i++)
			{//找出同三张
				for (int j=0;j<stHandCardResult.cbBlockCount[i];j++)
				{
					BYTE cbCardTemp[3]={0};
					CopyMemory(cbCardTemp,&stHandCardResult.cbCardData[i][(i+1)*j],3*sizeof(BYTE));
					
					//三带一
					if (IsValidType(CT_THREE_TAKE_ONE))
					{
						stOutCard.cbCardCount = 4;
						stOutCard.cbCardType = CT_THREE_TAKE_ONE;
						stOutCard.cbLogicValue = GetCardLogicValue(cbCardTemp[0]);
						bool bFind = false;
						for (int k = 0; k <= 0; k++)
						{//找单牌
							for (int m = stHandCardResult.cbBlockCount[k] - 1; m >= 0; m--)
							{
								if (m == j&&k == i) continue;  //排除同三
								BYTE cbCard = stHandCardResult.cbCardData[k][(k + 1)*m];

								CopyMemory(stOutCard.cbCardData, cbCardTemp, 3 * sizeof(BYTE));
								stOutCard.cbCardData[3] = cbCard;
								SortCardList(stOutCard.cbCardData, 4, ST_ORDER);

								vecPossibleResult.push_back(stOutCard);
								bFind = true;
								break;
							}
						}//找单牌
						if (bFind) break;
					}
					
				}

				//for (int j=0;j<stHandCardResult.cbBlockCount[i];j++)
				//{
				//	BYTE cbCardTemp[3]={0};
				//	CopyMemory(cbCardTemp,&stHandCardResult.cbCardData[i][(i+1)*j],3*sizeof(BYTE));

				//	stOutCard.cbLogicValue=GetCardLogicValue(cbCardTemp[0]);

				//	//三带二
				//	stOutCard.cbCardCount=5;
				//	stOutCard.cbCardType=CT_THREE_TAKE_TWO;
				//	bool bFind=false;
				//	for (int k=1;k<=1;k++)
				//	{//找对
				//		for(int m=stHandCardResult.cbBlockCount[k]-1;m>=0;m--)
				//		{
				//			if (m==j&&k==i) continue;  //排除同三

				//			CopyMemory(stOutCard.cbCardData,cbCardTemp,3*sizeof(BYTE));
				//			CopyMemory(&stOutCard.cbCardData[3],&stHandCardResult.cbCardData[k][(k+1)*m],2*sizeof(BYTE));
				//			SortCardList(stOutCard.cbCardData,5,ST_ORDER);
				//			
				//			vecPossibleResult.push_back(stOutCard);
				//			bFind=true;
				//			break;
				//		}
				//	}//找对	
				//	if (bFind) break;
				//}
				if (IsValidType(CT_THREE, cbCardCount))
				{
					for (int j = 0; j < stHandCardResult.cbBlockCount[i]; j++)
					{
						BYTE cbCardTemp[3] = { 0 };
						CopyMemory(cbCardTemp, &stHandCardResult.cbCardData[i][(i + 1)*j], 3 * sizeof(BYTE));

						stOutCard.cbLogicValue = GetCardLogicValue(cbCardTemp[0]);

						//三不带
						if (stHandCardResult.cbBlockCount[1] == 0 && stHandCardResult.cbBlockCount[0] == 0)
						{
							stOutCard.cbCardCount = 3;
							stOutCard.cbCardType = CT_THREE;
							CopyMemory(stOutCard.cbCardData, cbCardTemp, 3 * sizeof(BYTE));

							vecPossibleResult.push_back(stOutCard);
							break;
						}
					}
				}
				
			}
		}//考虑三带
			
		//////////////////单\对放最后(fastestoutcard用)///////
		//考虑对牌
		if (cbCardCount>=2)
		{
			stOutCard.cbCardCount=2;
			stOutCard.cbCardType=CT_DOUBLE;
			for (int i=1;i<=1;i++)
			{
				for(int j=0;j<stHandCardResult.cbBlockCount[i];j++)
				{
					stOutCard.cbLogicValue=GetCardLogicValue(stHandCardResult.cbCardData[i][(i+1)*j]);
					CopyMemory(stOutCard.cbCardData,&stHandCardResult.cbCardData[i][(i+1)*j],2*sizeof(BYTE));
					
					vecPossibleResult.push_back(stOutCard);
					break;
				}
			}
		}//考虑对牌
		
		//考虑单牌
		stOutCard.cbCardCount=1;
		stOutCard.cbCardType=CT_SINGLE;
		for (int i=0;i<=0;i++)
		{
			for(int j=0;j<stHandCardResult.cbBlockCount[i];j++)
			{
				BYTE cbCard=stHandCardResult.cbCardData[i][(i+1)*j];
				if (cbCard==0x40) continue;
				stOutCard.cbLogicValue=GetCardLogicValue(cbCard);
				stOutCard.cbCardData[0]=cbCard;
				
				vecPossibleResult.push_back(stOutCard);	
				break;
			}
		}

#ifdef _DEBUG
		for (size_t i=0;i<vecPossibleResult.size();i++)
		{
			tagOutCard &stTemp=vecPossibleResult.at(i);

			ASSERT(stTemp.cbCardType!=CT_ERROR);
			ASSERT(GetCardType(stTemp.cbCardData,stTemp.cbCardCount)==stTemp.cbCardType);
			if (stTemp.cbCardType<CT_MISSILE_CARD)
			{
				ASSERT(stTemp.cbLogicValue!=0);
			}						
		}
#endif
	}
	CATCH (...)
	{
		THROW;
// 		ASSERT(false);
// #ifdef USE_LOG_TRACE		
// 		CTraceService::TraceString(TEXT("AndroidServer:SimplySearchFast ERROR"),TraceLevel_Exception);
// #endif
	}
	
	return vecPossibleResult.size();
}
//提出单牌
BYTE CGameLogic::DrawSingleCard(const std::vector<tagOutCard> &vecOutCard,BYTE cbSingleCard[MAX_COUNT])
{
	BYTE cbCount=0;
	for (int i=0;i<(int)vecOutCard.size();i++)
	{
		tagAnalyseResult stAnalyseResult;
		AnalysebCardData(vecOutCard[i].cbCardData,vecOutCard[i].cbCardCount,stAnalyseResult);
		if (vecOutCard[i].cbCardType==CT_SINGLE) cbSingleCard[cbCount++]=vecOutCard[i].cbCardData[0];
		if (vecOutCard[i].cbCardType==CT_THREE_TAKE_ONE)
		{
			if (stAnalyseResult.cbBlockCount[0]>0)
			{
				BYTE cbTemp=stAnalyseResult.cbBlockCount[0];
				cbSingleCard[cbCount++]=stAnalyseResult.cbCardData[0][0];
			}
		}
	}

	return cbCount;
}
//盟友判断
bool CGameLogic::IsAlly(WORD wMeChairID,WORD wID)
{
	ASSERT(wMeChairID!=wID);
	if (wMeChairID==m_wBankerUser) return false;
	if (wID==m_wBankerUser) return false;
	else return true;
}

//春天尝试
bool CGameLogic::TryChunTian(const BYTE cbTurnCardData[], BYTE cbTurnCardCount, WORD wOutCardUser, WORD wMeChairID, tagOutCard &stOutCard)
{
	CFunItem tt(__FUNCTION__, TEXT("tc=%d"), cbTurnCardCount);
	if (m_bMayChunTian)
	{
		m_nSearchCount=0;
		vector<tagOutCard> vecOutCard;
		BYTE cbAllCardData[GAME_PLAYER][MAX_COUNT];
		BYTE cbAllCount[GAME_PLAYER];
		CopyMemory(cbAllCardData,m_cbAllCardData,sizeof(cbAllCardData));
		CopyMemory(cbAllCount,m_cbAllCount,sizeof(cbAllCount));

		ZeroMemory(&stOutCard,sizeof(stOutCard));


		for (WORD i=0;i<GAME_PLAYER;i++)
		{//春天不考虑炸弹
			if (i==wMeChairID) continue;

			for (int nIndex=0;nIndex<(int)_vecBombCardResult[i].size();nIndex++)
			{//删除炸弹
				tagOutCardResult stBombCard=_vecBombCardResult[i][nIndex];
				VERIFY(RemoveCard(&stBombCard.cbResultCard[0],1,cbAllCardData[i],cbAllCount[i]));
				cbAllCount[i]-=1;
			}
		}

		//提取连牌
		BYTE cbTemp[MAX_COUNT]={0};
		BYTE cbTempCount=0;
		BYTE cbCurrentValue=0;
		for (int j=0;j<_cb2CardCount;j++)
		{
			BYTE cbLogicValue=GetCardLogicValue(_cb2Card[j]);
			if (cbLogicValue!=cbCurrentValue)
			{
				cbTemp[cbTempCount++]=_cb2Card[j];
				cbCurrentValue=cbLogicValue;
			}
		}
		ASSERT(cbTempCount<MAX_COUNT);
		SortCardList(cbTemp,cbTempCount,ST_ORDER);

		BYTE cb2TempCount=_cb2CardCount>MAX_COUNT?MAX_COUNT:_cb2CardCount;
		BYTE cb2Card[MAX_COUNT*2]={0};
		CopyMemory(cb2Card,_cb2Card,sizeof(cb2Card));
		tagAnalyseResult st2AResult;
		AnalysebCardData(cb2Card,cb2TempCount,st2AResult);
		vector<tagOutCardResult> vec2Bomb;
		SearchBombCard(st2AResult,vec2Bomb);

		for (int nIndex=0;nIndex<(int)vec2Bomb.size();nIndex++)
		{//删除炸弹
			tagOutCardResult stBomb = vec2Bomb[nIndex];
			
			VERIFY(RemoveCard(&stBomb.cbResultCard[0],1,cb2Card,cb2TempCount));
			cb2TempCount-=1;
		}

		vecOutCard.clear();
		m_nSearchCount=0;
		if (TryAllBiggestCard(cbAllCardData,cbAllCount,wMeChairID,_stTurnCard,vecOutCard))
		{
			size_t nVecSize=vecOutCard.size();
			bool bContinue=false;//是否继续

			if (nVecSize>0)
			{
				bContinue=true;
				for (int i=0;i<(int)nVecSize-1;i++)
				{
					vector<tagOutCard> vecTemp;
					if (vecOutCard[i].cbCardCount>=6&&vecOutCard[i].cbCardType!=CT_SINGLE_LINE) continue;
					if(SimplySearchResult(cb2Card,cb2TempCount,vecOutCard[i],vecTemp)>0)
					{//牌可能被管 不打春天牌
						if (vecTemp[0].cbCardCount!=0) {bContinue=false;break;}
					}

					if (vecOutCard[i].cbCardType==CT_SINGLE_LINE)
					{//单连可能被管 不打春天牌
						BYTE cbLinkCount=vecOutCard[i].cbCardCount;
						BYTE cbValue=vecOutCard[i].cbLogicValue;

						if (cbValue==0x0E) continue;

						if(SimplySearchResult(cbTemp,cbTempCount,vecOutCard[i],vecTemp)>0)
						{
							if (vecTemp[0].cbCardCount!=0) {bContinue=false;break;}
						}
					}
				}

			}
			if (bContinue)
			{
				if (cbTurnCardCount==0)
				{//首出
					for (int i=0;i<(int)nVecSize;i++)
					{
						if (vecOutCard[i].cbCardType>=CT_BOMB_CARD)
							continue;//炸弹后出

						WORD j=0;
						if (i==nVecSize-1)
						{
							for (;j<GAME_PLAYER;j++)
							{//如果最后一手不是最大就排除
								if (j==wMeChairID) continue;
								vector<tagOutCard> vecTemp;
								if(SimplySearchResult(cbAllCardData[j],cbAllCount[j],vecOutCard[i],vecTemp)>0)
								{
									if (vecTemp[0].cbCardCount!=0) break;
								}
							}
							if (j!=GAME_PLAYER) continue;
						}

						stOutCard=vecOutCard[i];
						return true;	
					}
				}

				stOutCard=vecOutCard[0];
				return true;
			}	
		}			
	}

	return false;
}

//连续出牌
bool CGameLogic::TryOutAllCard(const BYTE cbTurnCardData[], BYTE cbTurnCardCount, WORD wOutCardUser, WORD wMeChairID, tagOutCard &stOutCard)
{
	CFunItem tt(__FUNCTION__, TEXT("tc=%d"), cbTurnCardCount);
	vector<tagOutCard> vecOutCard;
	BYTE cbAllCardData[GAME_PLAYER][MAX_COUNT];
	BYTE cbAllCount[GAME_PLAYER];
	CopyMemory(cbAllCardData,m_cbAllCardData,sizeof(cbAllCardData));
	CopyMemory(cbAllCount,m_cbAllCount,sizeof(cbAllCount));

	ZeroMemory(&stOutCard,sizeof(stOutCard));

	//初始化搜索次数限制
	m_nSearchCount=0;
	_bTrySearch=false;
	if (_stAnalyseResult[wMeChairID].cbCardType!=CT_ERROR
		&&_stAnalyseResult[wMeChairID].cbCardType!=CT_FOUR_TAKE_ONE&&_stAnalyseResult[wMeChairID].cbCardType!=CT_FOUR_TAKE_TWO) _bTrySearch=true;
	if (wMeChairID==m_wBankerUser&&cbAllCount[_wAfterBanker]+cbAllCount[_wFrontBanker]<=8) _bTrySearch=true;
	if (wMeChairID!=m_wBankerUser&&cbAllCount[m_wBankerUser]<=3) _bTrySearch=true;
	if (m_bMayChunTian) _bTrySearch=false;	//春天已特殊处理

	if(TryAllBiggestCard(cbAllCardData,cbAllCount,wMeChairID,_stTurnCard,vecOutCard))
	{
		size_t nVecSize=vecOutCard.size();

		//两手出完
		if (vecOutCard.size()==2&&!_bTrySearch)
		{
			bool bOut=false;
			if (CompareCard(vecOutCard[1].cbCardData,vecOutCard[0].cbCardData,vecOutCard[1].cbCardCount,vecOutCard[0].cbCardCount))
			{//先出了大牌
				vector<tagOutCard> vecTemp;
				if(SimplySearchResult(_cb2Card,_cb2CardCount>MAX_COUNT?MAX_COUNT:_cb2CardCount,vecOutCard[0],vecTemp)>0)
				{//如果大牌确定无人能管
					if (vecTemp[0].cbCardCount==0)
					{
						bOut=true;
						if (_cb2CardCount>MAX_COUNT)
						{//可能被管
							tagAnalyseResult st2ARlt;
							AnalysebCardData(_cb2Card,_cb2CardCount,st2ARlt);
							vector<tagOutCardResult> vec2Bomb;
							if (SearchBombCard(st2ARlt,vec2Bomb)>0)
							{
								if (CompareCard(vecOutCard[0].cbCardData,vec2Bomb[0].cbResultCard,vecOutCard[0].cbCardCount,vec2Bomb[0].cbCardCount))
									bOut=false;
							}
						}
					}

					if (!bOut&&(cbTurnCardCount==0||CompareCard(cbTurnCardData,vecOutCard[1].cbCardData,cbTurnCardCount,vecOutCard[1].cbCardCount)))
					{//如果第二手也能出 考虑颠倒顺序
						bool bReversal=false;
						if (vecTemp[0].cbCardType>=CT_BOMB_CARD||vecTemp[0].cbCardCount==0)
						{//如果第一手牌是牌型中最大的
							if (wMeChairID!=m_wBankerUser&&vecOutCard[1].cbCardCount!=cbAllCount[m_wBankerUser]) bReversal=true;
							if (wMeChairID==m_wBankerUser&&vecOutCard[1].cbCardCount!=cbAllCount[_wFrontBanker]&&vecOutCard[1].cbCardCount!=cbAllCount[_wAfterBanker])
								bReversal=true;
							if (bReversal)
							{
								if (!(stOutCard.cbCardCount<=5&&(stOutCard.cbCardType==CT_THREE_TAKE_ONE/*||stOutCard.cbCardType==CT_THREE_TAKE_TWO*/)))
								{//非三带牌型
									stOutCard=vecOutCard.at(1);
									return true;
								}
								
								//三带牌型 防止先带大牌
								vecOutCard.clear();
								SimplySearchResult(cbAllCardData[wMeChairID],cbAllCount[wMeChairID],_stTurnCard,vecOutCard);
								stOutCard=vecOutCard.at(0);
								return true;
							}
						}	
					}
				}
			}

			//第二手没法出
			if (!bOut&&cbTurnCardCount>0&&(_stTurnCard.cbCardType!=vecOutCard[1].cbCardType||_stTurnCard.cbLogicValue>=vecOutCard[1].cbLogicValue)) bOut=true;
			//尾牌比较大
			if (vecOutCard.back().cbLogicValue>=0x0F||vecOutCard.back().cbLogicValue>=GetCardLogicValue(_cb2Card[0])) bOut=true;
			if (bOut)
			{//可以出
				stOutCard=vecOutCard.at(0);
				return true;
			}
		}

		//如果能保证地主管不起
		if (wMeChairID!=m_wBankerUser)
		{//农民
			int i=0;
			for (;i<(int)vecOutCard.size()-1;i++)
			{
				if (vecOutCard[i].cbCardCount<=m_cbAllCount[m_wBankerUser])
				{
					vector<tagOutCard> vecTemp;
					if(SimplySearchResult(_cb2Card,_cb2CardCount>MAX_COUNT?MAX_COUNT:_cb2CardCount,vecOutCard[i],vecTemp)>0)
					{//如果大牌确定无人能管
						if (vecTemp[0].cbCardCount>0) break;
					}
				}
			}
			if (i==vecOutCard.size()-1) _bTrySearch=true;
		}

		if (wMeChairID==m_wBankerUser)
		{//地主
			int i=0;
			for (;i<(int)vecOutCard.size()-1;i++)
			{
				vector<tagOutCard> vecTemp;
				if(SimplySearchResult(_cb2Card,_cb2CardCount>MAX_COUNT?MAX_COUNT:_cb2CardCount,vecOutCard[i],vecTemp)>0)
				{//如果大牌确定无人能管
					if (vecTemp[0].cbCardCount>0) break;
				}	
			}
			if (i==vecOutCard.size()-1) _bTrySearch=true;
		}
		
		if (vecOutCard.size()==1) _bTrySearch=true;

		if (cbTurnCardCount>0&&!IsAlly(wMeChairID,wOutCardUser)&&vecOutCard[0].cbCardType<CT_BOMB_CARD) _bTrySearch=true;

		if (nVecSize>0&&_bTrySearch)
		{
			if (cbTurnCardCount==0)
			{//首出
				for (int i=0;i<(int)nVecSize;i++)
				{
					if (vecOutCard[i].cbCardType>=CT_BOMB_CARD)
						continue;//炸弹后出

					if (i==nVecSize-1)
					{
						WORD j=0;

						for (;j<GAME_PLAYER;j++)
						{//如果最后一手不是最大就排除
							if (j==wMeChairID) continue;
							vector<tagOutCard> vecTemp;
							if(SimplySearchResult(cbAllCardData[j],cbAllCount[j],vecOutCard[i],vecTemp)>0)
							{
								if (vecTemp[0].cbCardCount!=0) break;
							}
						}
						if (j!=GAME_PLAYER) break;
					}

					stOutCard=vecOutCard[i];
					return true;	
				}
			}

			stOutCard=vecOutCard[0];
			return true;
		}
	}

	return false;
}

//单人连续
bool CGameLogic::TrySingleOutAll(const BYTE cbTurnCardData[], BYTE cbTurnCardCount, WORD wOutCardUser, WORD wMeChairID, tagOutCard &stOutCard)
{
	CFunItem tt(__FUNCTION__, TEXT("tc=%d"), cbTurnCardCount);
	//连续大牌尝试
	vector<tagOutCard> vecOutCard;
	BYTE cbAllCardData[GAME_PLAYER][MAX_COUNT];
	BYTE cbAllCount[GAME_PLAYER];
	CopyMemory(cbAllCardData,m_cbAllCardData,sizeof(cbAllCardData));
	CopyMemory(cbAllCount,m_cbAllCount,sizeof(cbAllCount));

	ZeroMemory(&stOutCard,sizeof(stOutCard));

	//不考虑盟友管牌尝试连续出完
	if (m_wBankerUser!=wMeChairID)
	{
		vecOutCard.clear();
		BYTE cbAllCardData2[GAME_PLAYER][MAX_COUNT]={0};
		BYTE cbAllCount2[GAME_PLAYER]={0};
		CopyMemory(cbAllCardData2,m_cbAllCardData,sizeof(cbAllCardData));
		CopyMemory(cbAllCount2,m_cbAllCount,sizeof(cbAllCount));

		cbAllCount2[_wAllyID]=0;
		//初始化搜索次数限制
		m_nSearchCount=0;
		if(TryAllBiggestCard(cbAllCardData2,cbAllCount2,wMeChairID,_stTurnCard,vecOutCard))
		{
			size_t nVecSize=vecOutCard.size();

			if (nVecSize>0)
			{
				bool bContinue=true;
				for (int i=0;i<(int)nVecSize-1;i++)
				{
					vector<tagOutCard> vecTemp;
					if (vecOutCard[i].cbCardCount>=6) continue;
					if (vecOutCard[i].cbCardCount>cbAllCount[m_wBankerUser]) continue;

					if(SimplySearchResult(_cb2Card,_cb2CardCount>MAX_COUNT?MAX_COUNT:_cb2CardCount,vecOutCard[i],vecTemp)>0)
					{//牌可能被管
						if (vecTemp[0].cbCardCount>0)
						{
							for (int j=0;j<(int)vecTemp.size();j++)
							{
								if (vecTemp[j].cbCardCount>0&&vecTemp[j].cbCardCount<=cbAllCount[m_wBankerUser])
								{//庄家可能管
									bContinue=false;
									break;
								}
							}
						}
						if (bContinue==false) break;
					}
				}

				if (bContinue)
				{
					if (cbTurnCardCount==0)
					{//首出
						for (int i=0;i<(int)nVecSize;i++)
						{//防止先出炸弹
							if (vecOutCard[i].cbCardType>=CT_BOMB_CARD) continue;
							if (i==nVecSize-1)
							{
								WORD j=0;
								for (;j<GAME_PLAYER;j++)
								{
									if (j==wMeChairID) continue;
									vector<tagOutCard> vecTemp;
									if(SimplySearchResult(cbAllCardData2[j],cbAllCount2[j],vecOutCard[i],vecTemp)>0)
									{
										if (vecTemp[0].cbCardCount!=0) break;
									}
									if (j!=GAME_PLAYER) break;
								}
							}
							stOutCard=vecOutCard[i];
							return true;	
						}
					}

					stOutCard=vecOutCard[0];
					return true;
				}
			}
		}
	}
	
	return false;
}

//循环搜索
bool CGameLogic::TrySingleLoopSearch(const BYTE cbTurnCardData[], BYTE cbTurnCardCount, WORD wOutCardUser, WORD wMeChairID, tagOutCard &stOutCard)
{
#ifdef LYX_DEBUG	
	printf("0x%08x -> 0x%08x ============= CGameLogic::TrySingleLoopSearch  =======\n",m_userSink,this);
	printf("wOutCardUser:%d\n",wOutCardUser);
	printf("wMeChairID user:%d\n",wMeChairID);
	printf("cbTurnCardData:%s;\n",cardDataToString(cbTurnCardData,cbTurnCardCount).c_str());
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbAllCount:%d, %d !\n",i,m_cbAllCount[i]);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbOutCount:%d, %d !\n",i,m_cbOutCount[i]);
	for (int i=0;i<GAME_PLAYER;++i)
		printf("player m_cbAllCardData:%d, %s !\n",i,cardDataToString(m_cbAllCardData[i],MAX_COUNT).c_str());
#endif	

	CFunItem tt(__FUNCTION__, TEXT("tc=%d"), cbTurnCardCount);
	vector<tagOutCard> vecOutCard;
	BYTE cbAllCardData[GAME_PLAYER][MAX_COUNT];
	BYTE cbAllCount[GAME_PLAYER];
	CopyMemory(cbAllCardData,m_cbAllCardData,sizeof(cbAllCardData));
	CopyMemory(cbAllCount,m_cbAllCount,sizeof(cbAllCount));

	ZeroMemory(&stOutCard,sizeof(stOutCard));

	//单挑模式
	m_nDepthCount=0;
	m_nSearchCount=0;

	if (wMeChairID!=m_wBankerUser)
	{
		BYTE cbAllCount2[GAME_PLAYER]={0};
		CopyMemory(cbAllCount2,cbAllCount,sizeof(cbAllCount));

		if (wMeChairID==_wAfterBanker) cbAllCount2[_wFrontBanker]=0;
		else cbAllCount2[_wAfterBanker]=0;

		if(SimplySearchTheBest(cbAllCardData,cbAllCount2,_stTurnCard,wMeChairID,wOutCardUser,stOutCard))
		{
			ASSERT(m_nDepthCount!=nBadSearch);
			
			BYTE cbCardTemp[MAX_COUNT];
			BYTE cbTempCount=cbAllCount[wMeChairID];
			//CopyMemory(cbCardTemp,cbAllCardData[wMeChairID],cbTempCount);
			CopyMemory(cbCardTemp,cbAllCardData[wMeChairID],MAX_COUNT * sizeof(BYTE));
			//VERIFY(RemoveCard(stOutCard.cbCardData,stOutCard.cbCardCount,cbCardTemp,cbTempCount));
			// ###_temp ： by lyx
			if (!RemoveCard(stOutCard.cbCardData,stOutCard.cbCardCount,cbCardTemp,cbTempCount))
			{
				THROW_ERROR(-1002);
			}
			cbTempCount-=stOutCard.cbCardCount;
			tagAnalyseResult stARlt;
			AnalyseOutCard(cbCardTemp,cbTempCount,stARlt);
			vector<tagOutCardResult> vecBombTemp;
			SearchBombCard(stARlt,vecBombTemp);

			//不挡盟友走
			if (wMeChairID==_wAfterBanker&&wOutCardUser==_wFrontBanker&&cbTurnCardCount>0)
			{
				if (_stAnalyseResult[_wFrontBanker].cbCardType!=CT_ERROR&&stOutCard.cbCardType<CT_BOMB_CARD)
				{//不是出炸弹就不出
					if (vecBombTemp.size()==0)
					{
						ZeroMemory(&stOutCard,sizeof(tagOutCard));
						return true;
					}	
				}
			}

			if (cbTurnCardCount>0&&wMeChairID==_wAfterBanker&&CompareCard(cbTurnCardData,cbAllCardData[_wFrontBanker],cbTurnCardCount,cbAllCount[_wFrontBanker]))
			{//盟友可大牌走人
				if (stOutCard.cbCardType<CT_BOMB_CARD)
				{//不管放人
					if (vecBombTemp.size()==0)
					{
						ZeroMemory(&stOutCard,sizeof(stOutCard));
						return true;
					}	
				}
			}

			bool bOut=true;
			//盟友出牌
			if (wOutCardUser==_wAllyID)
			{
				if (stOutCard.cbLogicValue>=0x0F) bOut=false;
				if (stOutCard.cbLogicValue>=0x0D&&stOutCard.cbCardCount>=2) bOut=false;
				if (stOutCard.cbCardType>=CT_BOMB_CARD) bOut=false;
			}

			//谨慎出炸弹
			if (stOutCard.cbCardType>=CT_BOMB_CARD)
			{
				m_nDepthCount=0;
				m_nSearchCount=0;
				tagOutCard stOutTemp;
				BYTE cbAllCardData2[GAME_PLAYER][MAX_COUNT]={0};
				CHECK_MEMCPY(MAX_COUNT,cbAllCount[wMeChairID]);
				CopyMemory(cbAllCardData2[wMeChairID],cbAllCardData[wMeChairID],cbAllCount[wMeChairID]);
				CHECK_MEMCPY(MAX_COUNT,cbAllCount[m_wBankerUser]);
				CopyMemory(cbAllCardData2[m_wBankerUser],_cb2Card,cbAllCount[m_wBankerUser]);
				if (!SimplySearchTheBest(cbAllCardData2,cbAllCount2,_stTurnCard,wMeChairID,wOutCardUser,stOutTemp))
					bOut=false;
			}

			//防止被认为作弊
			if (wMeChairID==_wFrontBanker&&cbAllCount[m_wBankerUser]==1)
			{
				if (stOutCard.cbCardCount==1&&stOutCard.cbLogicValue<GetCardLogicValue(_cb2Card[0]))
					bOut=false;
			}

			if(bOut&&!(cbTurnCardCount==0&&stOutCard.cbCardType>=CT_BOMB_CARD))//不首出炸弹
				return true;
		}		
	}

	return false;
}

//循环搜索
bool CGameLogic::TryLoopSearch(const BYTE cbTurnCardData[], BYTE cbTurnCardCount, WORD wOutCardUser, WORD wMeChairID, tagOutCard &stOutCard)
{
	CFunItem tt(__FUNCTION__, TEXT("tc=%d"), cbTurnCardCount);
	BYTE cbAllCardData[GAME_PLAYER][MAX_COUNT];
	BYTE cbAllCount[GAME_PLAYER];
	CopyMemory(cbAllCardData,m_cbAllCardData,sizeof(cbAllCardData));
	CopyMemory(cbAllCount,m_cbAllCount,sizeof(cbAllCount));

	ZeroMemory(&stOutCard,sizeof(stOutCard));

	//简易深度搜索
	m_nDepthCount=0;
	m_nSearchCount=0;
	if (true)
	{//m_nTimeLimit次深度搜索
		ZeroMemory(&stOutCard,sizeof(tagOutCard));
		bool bOp=false;
		if(SimplySearchTheBest(cbAllCardData,cbAllCount,_stTurnCard,wMeChairID,wOutCardUser,stOutCard)) bOp=true;
		if (!bOp&&_vecBombCardResult[wMeChairID].size()>0&&_vecBombCardResult[wMeChairID].back().cbCardCount==4)
		{//考虑四带二
			bool bTryFourTake=false;
			if (wMeChairID!=m_wBankerUser&&cbAllCount[m_wBankerUser]<=5) bTryFourTake=true;
			if (wMeChairID==m_wBankerUser&&(cbAllCount[_wFrontBanker]<=3||cbAllCount[_wAfterBanker]<=3)) bTryFourTake=true;
			
			if (bTryFourTake)
			{
				m_nDepthCount=0;
				m_nSearchCount=0;
				ZeroMemory(&stOutCard,sizeof(tagOutCard));
				if (SimplySearchTheBest(cbAllCardData,cbAllCount,_stTurnCard,wMeChairID,wOutCardUser,stOutCard,true))
					bOp=true;		
			}
		}
		if (bOp)
		{
			ASSERT(m_nDepthCount!=nBadSearch);
			//bCanBomb=true;
			bool bContinue=true;
			//如果是不出 
			if (stOutCard.cbCardCount==0) return true;

			if (wMeChairID!=m_wBankerUser&&stOutCard.cbCardType<CT_BOMB_CARD)
			{//不是地主
				if (cbTurnCardCount==0)
				{//首出 如果盟友无法接牌
					vector<tagOutCard> vecTemp;
					if(cbAllCount[wMeChairID]-stOutCard.cbCardCount>2&&SimplySearchResult(cbAllCardData[_wAllyID],cbAllCount[_wAllyID],stOutCard,vecTemp)>0)
					{
						if (vecTemp[0].cbCardCount==0) bContinue=false;
					}
				}

				//盟友出牌
				if (wOutCardUser!=m_wBankerUser&&bContinue)
				{ 
					if (wMeChairID==_wFrontBanker)
					{
						if (cbTurnCardCount>cbAllCount[m_wBankerUser]&&_stAnalyseResult[_wAllyID].cbCardType!=CT_ERROR)
						{//盟友能走
							ZeroMemory(&stOutCard,sizeof(stOutCard));
							return true;
						}
					}

					bool bCare=false;
					if (stOutCard.cbCardCount>=2&&stOutCard.cbLogicValue>0x0C) bCare=true;			//出对K以上
					if (wOutCardUser==_wAfterBanker&&stOutCard.cbCardCount>=3) bCare=true;			//三张以上
					if (wOutCardUser==_wAfterBanker&&stOutCard.cbLogicValue>0x0F) bCare=true;		//王以上

					if (bCare)
					{//注意出牌	
						tagOutCard stTurnTemp;
						tagOutCard stOutTemp;
						if (wMeChairID==_wAfterBanker)
						{//地主下家
							m_nDepthCount=0;
							m_nSearchCount=0;
							ZeroMemory(&stTurnTemp,sizeof(stTurnTemp));
							if (SimplySearchTheBest(cbAllCardData,cbAllCount,stTurnTemp,_wAllyID,INVALID_CHAIR,stOutTemp))
							{
								bContinue=false;
							}
						}
						else
						{//地主上家
							m_nDepthCount=0;
							m_nSearchCount=0;
							if (!SimplySearchTheBest(cbAllCardData,cbAllCount,_stTurnCard,m_wBankerUser,wOutCardUser,stOutTemp))
							{
								bContinue=false;
							}
						}
					}
				}

				if (bContinue)
				{
					//不挡盟友走
					if (wMeChairID==_wAfterBanker&&wOutCardUser==_wFrontBanker&&cbTurnCardCount>0)
					{
						if (_stAnalyseResult[_wAllyID].cbCardType!=CT_ERROR&&stOutCard.cbCardType<CT_BOMB_CARD)
						{//不是出炸弹就不出
							ZeroMemory(&stOutCard,sizeof(tagOutCard));
							return true;
						}
					}

					if (cbTurnCardCount>0&&wOutCardUser==_wAfterBanker&&_stAnalyseResult[_wAfterBanker].cbCardType!=CT_ERROR&&stOutCard.cbCardType<CT_BOMB_CARD)
					{//盟友出牌
						bool bOut=true;
						if (!CompareCard(cbTurnCardData,cbAllCardData[m_wBankerUser],cbTurnCardCount,cbAllCount[m_wBankerUser]))
						{
							//出牌大于2
							if (_stTurnCard.cbLogicValue>=0x0F) bOut=false;
							//对子大于QQ
							if (_stTurnCard.cbLogicValue>=0x0C&&cbTurnCardCount>=2) bOut=false;
							//张数大于4
							if (cbTurnCardCount>=4) bOut=false;

							if (!bOut)
							{
								ZeroMemory(&stOutCard,sizeof(tagOutCard));
								return true;
							}
						}
					}

					if (cbTurnCardCount>0&&wMeChairID==_wAfterBanker&&CompareCard(cbTurnCardData,cbAllCardData[_wFrontBanker],cbTurnCardCount,cbAllCount[_wFrontBanker]))
					{//盟友可大牌走人
						if (stOutCard.cbCardType<CT_BOMB_CARD)
						{//不管放人
							ZeroMemory(&stOutCard,sizeof(stOutCard));
							return true;
						}
					}

					//防止被认为作弊
					if (cbAllCount[m_wBankerUser]==1&&wMeChairID==_wFrontBanker&&stOutCard.cbCardCount==1)
					{
						if (cbTurnCardCount==0&&cbAllCount[_wAfterBanker]==1&&GetCardLogicValue(cbAllCardData[m_wBankerUser][0])<GetCardLogicValue(cbAllCardData[_wAfterBanker][0]))
						{//隔地主送盟友一张牌
							if (stOutCard.cbLogicValue<GetCardLogicValue(cbAllCardData[_wAfterBanker][0]))
							{//从最大单牌送起
								stOutCard.cbCardData[0]=cbAllCardData[wMeChairID][0];
								stOutCard.cbLogicValue=GetCardLogicValue(stOutCard.cbCardData[0]);
								return true;
							}
						}

						//地主剩一张
						if (stOutCard.cbCardCount==1&&stOutCard.cbLogicValue<GetCardLogicValue(_cb2Card[0])) bContinue=false;
					}
				}
			}

			//谨慎出炸弹
			if (stOutCard.cbCardType>=CT_BOMB_CARD)
			{//假想对手牌
				_bCanBomb=true;

				m_nDepthCount=0;
				m_nSearchCount=0;
				tagOutCard stOutTemp;
				BYTE cbAllCardData2[GAME_PLAYER][MAX_COUNT]={0};
				BYTE cbAllCount2[GAME_PLAYER]={0};
				cbAllCount2[wMeChairID]=cbAllCount[wMeChairID];
				CHECK_MEMCPY(MAX_COUNT,cbAllCount[wMeChairID]);
				CopyMemory(cbAllCardData2[wMeChairID],cbAllCardData[wMeChairID],cbAllCount[wMeChairID]);
				if (wMeChairID!=m_wBankerUser)
				{
					CHECK_MEMCPY(MAX_COUNT,cbAllCount[m_wBankerUser]);
					CopyMemory(cbAllCardData2[m_wBankerUser],_cb2Card,cbAllCount[m_wBankerUser]);
					cbAllCount2[m_wBankerUser]=cbAllCount[m_wBankerUser];
					if (!SimplySearchTheBest(cbAllCardData2,cbAllCount2,_stTurnCard,wMeChairID,wOutCardUser,stOutTemp))
						bContinue=false;
				}
				else
				{
					cbAllCount2[_wNextUser]=cbAllCount[_wFrontUser]>cbAllCount[_wNextUser]?cbAllCount[_wNextUser]:cbAllCount[_wFrontUser];
					CHECK_MEMCPY(MAX_COUNT,cbAllCount2[_wNextUser]);
					CopyMemory(cbAllCardData2[_wNextUser],_cb2Card,cbAllCount2[_wNextUser]);
					if (!SimplySearchTheBest(cbAllCardData2,cbAllCount2,_stTurnCard,wMeChairID,_stTurnCard.cbCardCount>0?_wNextUser:INVALID_CHAIR,stOutTemp))
						bContinue=false;
				}
			}

			if (bContinue)
			{
				if(!(cbTurnCardCount==0&&stOutCard.cbCardType>=CT_BOMB_CARD))//不首出炸弹
					return true;
				else //首出炸弹
				{
					//尝试先出其它牌
					BYTE cbCardBuf[GAME_PLAYER][MAX_COUNT]={0};
					BYTE cbBufCount[GAME_PLAYER]={0};
					CopyMemory(cbCardBuf,cbAllCardData,sizeof(cbCardBuf));
					CopyMemory(cbBufCount,cbAllCount,sizeof(cbBufCount));
					VERIFY(RemoveCard(stOutCard.cbCardData,stOutCard.cbCardCount,cbCardBuf[wMeChairID],cbBufCount[wMeChairID]));
					cbBufCount[wMeChairID]-=stOutCard.cbCardCount;

					tagOutCard stOutTemp=stOutCard;

					while (cbBufCount[wMeChairID]>0)
					{
						BYTE cbType=GetCardType(cbCardBuf[wMeChairID],cbBufCount[wMeChairID]);
						if (cbType>=CT_BOMB_CARD) return true;//就剩炸弹了
						if (cbType==CT_ERROR||cbType==CT_FOUR_TAKE_ONE||cbType==CT_FOUR_TAKE_TWO)
						{//可以出其它牌
							m_nDepthCount=0;
							m_nSearchCount=0;
							if(SimplySearchTheBest(cbCardBuf,cbBufCount,_stTurnCard,wMeChairID,wOutCardUser,stOutTemp))
							{//能赢
								if (stOutTemp.cbCardType>=CT_BOMB_CARD)
								{//还有炸
									VERIFY(RemoveCard(stOutTemp.cbCardData,stOutTemp.cbCardCount,cbCardBuf[wMeChairID],cbBufCount[wMeChairID]));
									cbBufCount[wMeChairID]-=stOutTemp.cbCardCount;
									continue;
								}
								else
								{//不是炸
									stOutCard=stOutTemp;
									return true;
								}
							}
							else return true;	//不出炸就输
						}
						else
						{//一手
							if (wMeChairID==m_wBankerUser)
							{//地主
								if (cbBufCount[wMeChairID]!=cbBufCount[_wNextUser]&&cbBufCount[wMeChairID]!=cbBufCount[_wFrontUser])
								{//不会导致输
									AnalyseOutCard(cbCardBuf[wMeChairID],cbBufCount[wMeChairID],stOutCard);
									return true;
								}
								else return true;
							}
							else
							{//农民
								if (cbBufCount[wMeChairID]!=cbBufCount[m_wBankerUser])
								{//不会导致输
									AnalyseOutCard(cbCardBuf[wMeChairID],cbBufCount[wMeChairID],stOutCard);
									return true;
								}
								else return true;
							}
						}
						ASSERT(false);//防止死循环
						break;
					}	
				}
			}
			else
			{//考虑不管
				if (wMeChairID==_wFrontBanker&&wOutCardUser==_wAllyID)
				{//盟友出牌(地主下家)
					vector<tagOutCard> vecTemp;
					if (SimplySearchResult(cbAllCardData[m_wBankerUser],cbAllCount[m_wBankerUser],_stTurnCard,vecTemp)<=1)
					{//庄家管不起
						if (_stAnalyseResult[_wAllyID].cbCardType!=CT_ERROR)
						{//盟友就剩一手了
							if (cbTurnCardCount>1||_stTurnCard.cbLogicValue>=GetCardLogicValue(_cb2Card[0]))
							{//出牌多于一张或庄家不可能管
								ZeroMemory(&stOutCard,sizeof(stOutCard));
								return true;
							}
						}	
					}
				}
			}
		}
		else if (wMeChairID!=m_wBankerUser&&_vecBombCardResult[m_wBankerUser].size()>0)
		{//考虑逼地主拆炸弹
			m_nSearchCount=0;
			m_nDepthCount=0;
			if (SimplySearchTheBest(cbAllCardData,cbAllCount,_stTurnCard,wMeChairID,wOutCardUser,stOutCard,false,true))
			{
				if (stOutCard.cbCardType<CT_BOMB_CARD) return true;
			}
		}
	}

	return false;
}

//经验出牌
bool CGameLogic::NormalOutCard(const BYTE cbTurnCardData[], BYTE cbTurnCardCount, WORD wOutCardUser, WORD wMeChairID, tagOutCard &stOutCard)
{
	CFunItem tt(__FUNCTION__, TEXT("tc=%d"), cbTurnCardCount);
	vector<tagOutCard> vecOutCard;
	BYTE cbAllCardData[GAME_PLAYER][MAX_COUNT];
	BYTE cbAllCount[GAME_PLAYER];
	CopyMemory(cbAllCardData,m_cbAllCardData,sizeof(cbAllCardData));
	CopyMemory(cbAllCount,m_cbAllCount,sizeof(cbAllCount));

	ZeroMemory(&stOutCard,sizeof(stOutCard));

	//获得除炸弹外扑克
	vector<tagOutCard> vecFastestOutCard[GAME_PLAYER];

	BYTE cbCardTemp[GAME_PLAYER][MAX_COUNT]={0};	//删除王二炸弹的扑克
	BYTE cbTempCount[GAME_PLAYER]={0};
	BYTE cbSingleCount[GAME_PLAYER]={0};
	BYTE cbSingleCard[GAME_PLAYER][MAX_COUNT]={0};
	BYTE cbBigCard[GAME_PLAYER][8]={0};//大小王 二
	BYTE cbBigCount[GAME_PLAYER]={0};
	CopyMemory(cbCardTemp,cbAllCardData,sizeof(cbCardTemp));
	CopyMemory(cbTempCount,cbAllCount,sizeof(cbTempCount));
	for(WORD wID=0;wID<GAME_PLAYER;wID++)
	{
		for (size_t i=0;i<_vecBombCardResult[wID].size();i++)
		{//删除炸弹扑克
			tagOutCardResult &stTemp=_vecBombCardResult[wID].at(i);
			VERIFY(RemoveCard(_vecBombCardResult[wID][i].cbResultCard,_vecBombCardResult[wID][i].cbCardCount,cbCardTemp[wID],cbTempCount[wID]));
			cbTempCount[wID]-=_vecBombCardResult[wID][i].cbCardCount;
		}
		//删除大小王和2
		if (cbTempCount[wID]>0)
		{
			for (int i=0;i<cbTempCount[wID];i++)
			{
				if (cbCardTemp[wID][i]==0x42||cbCardTemp[wID][i]==0x41||GetCardValue(cbCardTemp[wID][i])==0x02)
					cbBigCard[wID][cbBigCount[wID]++]=cbCardTemp[wID][i];
				else break;//可跳出			
			}

			VERIFY(RemoveCard(cbBigCard[wID],cbBigCount[wID],cbCardTemp[wID],cbTempCount[wID]));
			cbTempCount[wID]-=cbBigCount[wID];
		}

		if (cbTempCount[wID]>0)
		{//提取快速出牌扑克
			FastestOutCard(cbCardTemp[wID],cbTempCount[wID],vecFastestOutCard[wID]);

			//提取单牌个数
			cbSingleCount[wID]=DrawSingleCard(vecFastestOutCard[wID],cbSingleCard[wID]);
			SortCardList(cbSingleCard[wID],cbSingleCount[wID],ST_ORDER);
		}
	}

	/////////////////////////////////////////////分析出牌  首出////////////////////////////////////////////////////////////////////
	//首出
	if(cbTurnCardCount==0)
	{	
		if (wMeChairID!=m_wBankerUser)
		{//农民
			if (vecFastestOutCard[wMeChairID].size() > 0 && wMeChairID==_wFrontBanker&&cbAllCount[m_wBankerUser]==1/*&&cbAllCount[_wAfterBanker]>=2*/)
			{
				// wxq(下家是地主 且只有一张牌出牌的时候从大出到小)
				/*for (int i=(int)vecFastestOutCard[wMeChairID].size()-1;i>=0;i--)
				{*/
					tagOutCard &stTemp=vecFastestOutCard[wMeChairID].at(0);
					//wxq begin
					//if (stTemp.cbCardType > CT_SINGLE )
					//{
						/*stOutCard.cbCardType = CT_DOUBLE;
						stOutCard.cbCardCount=2;
						CopyMemory(stOutCard.cbCardData,&stTemp.cbCardData[stTemp.cbCardCount-2],2);
						stOutCard.cbLogicValue=GetCardLogicValue(stOutCard.cbCardData[0]);
						if (SimplySearchResult(_cb2Card,_cb2CardCount>MAX_COUNT?MAX_COUNT:_cb2CardCount,stOutCard,vecOutCard)==1) break;
						else
						{
							if (m_LastOutCard.stLastCard.cbCardType!=CT_DOUBLE||m_LastOutCard.stLastCard.cbLogicValue>stOutCard.cbLogicValue)
								return true;	//之前没出过对
							else break;		//已经出过了
						}*/

						CopyMemory(&stOutCard, &stTemp, sizeof(tagOutCard));
						if (stOutCard.cbCardType == CT_SINGLE && stOutCard.cbCardData[0] != cbCardTemp[wMeChairID][0])
						{//如果当前的牌型是单牌，选择最大的单排开始出(此前统计算法的时候已经排除 王,2 vecFastestOutCard里面最大的单牌就没有 王,2)
							stOutCard.cbCardData[0] = cbCardTemp[wMeChairID][0];
							stOutCard.cbLogicValue = GetCardLogicValue(stOutCard.cbCardData[0]);
						}
						return true;
					//}
				//}
				//wxq end
			}

			//地主还剩一手牌 或盟友报牌
			if (_stAnalyseResult[m_wBankerUser].cbCardType!=CT_ERROR||(cbAllCount[_wAllyID]<=2&&_stAnalyseResult[_wAllyID].cbCardType!=CT_ERROR))
			{//配合			
				for (int i=(int)vecFastestOutCard[_wAllyID].size()-1;i>=0;i--)
				{//让盟友接牌
					for (int j=(int)vecFastestOutCard[wMeChairID].size()-1;j>=0;j--)
					{	
						//盟友管不起
						if (!CompareCard(vecFastestOutCard[wMeChairID][j].cbCardData,vecFastestOutCard[_wAllyID][i].cbCardData,
							vecFastestOutCard[wMeChairID][j].cbCardCount,vecFastestOutCard[_wAllyID][i].cbCardCount))
							continue;
						if (vecFastestOutCard[wMeChairID][j].cbCardType==_stAnalyseResult[m_wBankerUser].cbCardType&&
							vecFastestOutCard[wMeChairID][j].cbLogicValue<_stAnalyseResult[m_wBankerUser].cbLogicValue)
							continue;//不能导致输

						stOutCard=vecFastestOutCard[wMeChairID].at(j);
						ASSERT(stOutCard.cbCardType==GetCardType(stOutCard.cbCardData,stOutCard.cbCardCount));
						ASSERT(stOutCard.cbCardType!=CT_ERROR);

						//防止出牌太明显
						if (stOutCard.cbCardType==CT_SINGLE&&wMeChairID==_wFrontBanker&&cbAllCount[m_wBankerUser]==1)
						{//地主只有一张 先出大单牌
							for (int k=0;k<cbAllCount[wMeChairID];k++)
							{
								if (GetCardLogicValue(cbAllCardData[wMeChairID][k])<GetCardLogicValue(_cb2Card[0]))
								{
									stOutCard.cbCardData[0]=cbAllCardData[wMeChairID][k];
									stOutCard.cbLogicValue=GetCardLogicValue(cbAllCardData[wMeChairID][k]);
									return true;
								}
							}
						}
						return true;
					}
				}

				//庄家剩一对
				if (_stAnalyseResult[m_wBankerUser].cbCardType==CT_DOUBLE)
				{
					//出单牌
					if (cbSingleCount[wMeChairID]>0)
					{
						stOutCard.cbCardCount=1;
						stOutCard.cbCardData[0]=cbSingleCard[wMeChairID][cbSingleCount[wMeChairID]-1];
						stOutCard.cbCardType=CT_SINGLE;
						stOutCard.cbLogicValue=GetCardLogicValue(stOutCard.cbCardData[0]);
						return true;
					}
					for (int i=cbAllCount[wMeChairID]-1;i>=0;i--)
					{
						if (cbAllCardData[wMeChairID][i]!=0x40)
						{
							stOutCard.cbCardCount=1;
							stOutCard.cbCardData[0]=cbAllCardData[wMeChairID][i];
							stOutCard.cbCardType=CT_SINGLE;
							stOutCard.cbLogicValue=GetCardLogicValue(stOutCard.cbCardData[0]);
							return true;
						}
					}
				}

				//地主还剩一张
				if (wMeChairID==_wFrontBanker&&cbAllCount[m_wBankerUser]==1)
				{
					int cbLittle=0;//小单牌
					for (int i=0;i<(int)vecFastestOutCard[wMeChairID].size();i++)
					{
						tagOutCard &stOutTemp=vecFastestOutCard[wMeChairID][i];

						if (stOutTemp.cbCardType==CT_SINGLE&&stOutTemp.cbLogicValue<_stAnalyseResult[m_wBankerUser].cbLogicValue)
							cbLittle++;
					}
					if (cbLittle>=2)
					{
						//全牌搜索
						SimplySearchResult(cbAllCardData[wMeChairID],cbAllCount[wMeChairID],_stTurnCard,vecOutCard);
						for (int i=(int)vecOutCard.size()-1;i>=0;i--)
						{
							tagOutCard &stOutTemp=vecOutCard.at(i);
							if (CompareCard(stOutTemp.cbCardData,cbAllCardData[_wNextUser],stOutTemp.cbCardCount,cbAllCount[_wNextUser]))
								continue;
							if (stOutTemp.cbCardType>=CT_BOMB_CARD&&!_bCanBomb) continue;

							if (_wAllyID<GAME_PLAYER)
							{	vector<tagOutCard> vecTemp;
							SimplySearchResult(cbAllCardData[_wAllyID],cbAllCount[_wAllyID],stOutTemp,vecTemp);
							if (vecTemp.size()==0||vecTemp[0].cbCardCount==0)
								continue;//盟友管不起
							}

							CopyMemory(&stOutCard,&stOutTemp,sizeof(tagOutCard));
							return true;
						}
						
						// wxq begin
						//for (int k=0;k<cbAllCount[wMeChairID];k++)
						//{//没救了
						//	if (GetCardLogicValue(cbAllCardData[wMeChairID][k])<GetCardLogicValue(_cb2Card[0])&&
						//		GetCardLogicValue(cbAllCardData[wMeChairID][k])>=GetCardLogicValue(_cb2Card[_cb2CardCount-1]))
						//	{
						//		stOutCard.cbCardCount=1;
						//		stOutCard.cbCardData[0]=cbAllCardData[wMeChairID][k];
						//		stOutCard.cbCardType=CT_SINGLE;
						//		stOutCard.cbLogicValue=GetCardLogicValue(stOutCard.cbCardData[0]);

						//		return true;
						//	}
						//}

						//  从最大的单牌开始出
						stOutCard.cbCardCount = 1;
						stOutCard.cbCardData[0] = cbAllCardData[wMeChairID][0];
						stOutCard.cbCardType = CT_SINGLE;
						stOutCard.cbLogicValue = GetCardLogicValue(stOutCard.cbCardData[0]);
						// wxq end
						return true;
					}
					else
					{
						for (int i=0;i<(int)vecFastestOutCard[wMeChairID].size();i++)
						{
							tagOutCard &stOutTemp=vecFastestOutCard[wMeChairID][i];

							if (!CompareCard(stOutTemp.cbCardData,cbAllCardData[m_wBankerUser],stOutTemp.cbCardCount,cbAllCount[m_wBankerUser]))
							{
								CopyMemory(&stOutCard,&stOutTemp,sizeof(tagOutCard));
								return true;
							}
						}

						//全牌搜索
						SimplySearchResult(cbAllCardData[wMeChairID],cbAllCount[wMeChairID],_stTurnCard,vecOutCard);
						for (int i=(int)vecOutCard.size()-1;i>=0;i--)
						{
							tagOutCard &stOutTemp=vecOutCard.at(i);
							if (CompareCard(stOutTemp.cbCardData,cbAllCardData[_wNextUser],stOutTemp.cbCardCount,cbAllCount[_wNextUser]))
								continue;
							if (stOutTemp.cbCardType>=CT_BOMB_CARD&&!_bCanBomb) continue;

							CopyMemory(&stOutCard,&stOutTemp,sizeof(tagOutCard));
							return true;
						}
					}
				}
			}
		}

		//农民还剩一手
		if (m_wBankerUser==wMeChairID&&(_stAnalyseResult[_wNextUser].cbCardType!=CT_ERROR||_stAnalyseResult[_wFrontUser].cbCardType!=CT_ERROR))
		{
			WORD wUser=_wNextUser;	//对比玩家
			if (_stAnalyseResult[_wFrontUser].cbCardType!=CT_ERROR) wUser=_wFrontBanker;
			if (_stAnalyseResult[_wFrontUser].cbCardType!=CT_ERROR&&_stAnalyseResult[_wNextUser].cbCardType!=CT_ERROR)
				wUser=cbAllCount[_wNextUser]<cbAllCount[_wFrontUser]?_wNextUser:_wFrontUser;
			if (_stAnalyseResult[_wFrontUser].cbCardType==_stAnalyseResult[_wNextUser].cbCardType)
				wUser=(_stAnalyseResult[_wFrontUser].cbLogicValue>_stAnalyseResult[_wNextUser].cbLogicValue)?_wFrontUser:_wNextUser;
			BYTE cbLittleCount=0;
			for (int i=(int)vecFastestOutCard[wMeChairID].size()-1;i>=0;i--)
			{
				tagOutCard &stOutTemp=vecFastestOutCard[wMeChairID].at(i);
				if (CompareCard(stOutTemp.cbCardData,cbAllCardData[wUser],stOutTemp.cbCardCount,cbAllCount[wUser]))
				{
					cbLittleCount++; 
					continue;
				}
			}

			if (cbLittleCount>1&&cbAllCount[wUser]==1&&_vecBombCardResult[wMeChairID].size()>0)
			{//考虑四带2
				for (int j=(int)_vecBombCardResult[wMeChairID].size()-1;j>=0;j--)
				{
					if (_vecBombCardResult[wMeChairID][j].cbCardCount == 4 && cbSingleCount[wMeChairID] >= 2 && IsValidType(CT_FOUR_TAKE_ONE, cbAllCount[wMeChairID]))
					{
						CopyMemory(stOutCard.cbCardData,_vecBombCardResult[wMeChairID][j].cbResultCard,4);
						CopyMemory(&stOutCard.cbCardData[4],&cbSingleCard[wMeChairID][cbSingleCount[wMeChairID]-2],2);
						stOutCard.cbCardType=CT_FOUR_TAKE_ONE;
						stOutCard.cbCardCount=6;
						stOutCard.cbLogicValue=GetCardLogicValue(stOutCard.cbCardData[0]);
						return true;
					}
				}
			}
			//wxq begin 已经不可能胜利,先出牌型和下家不一致的牌型(假装再挣扎一手)
			for (int i = (int)vecFastestOutCard[wMeChairID].size() - 1; i >= 0; i--)
			{//查找牌型和下家不一致的牌型
				tagOutCard &stOutTemp = vecFastestOutCard[wMeChairID].at(i);
				if (stOutTemp.cbCardType != _stAnalyseResult[_wNextUser].cbCardType && stOutTemp.cbCardType < CT_BOMB_CARD)
				{
					CopyMemory(&stOutCard, &stOutTemp, sizeof(tagOutCard));
					return true;
				}
			}
			//wxq  end
			cbLittleCount=0;
			for (int i=(int)vecFastestOutCard[wMeChairID].size()-1;i>=0;i--)
			{
				tagOutCard &stOutTemp=vecFastestOutCard[wMeChairID].at(i);
				if (CompareCard(stOutTemp.cbCardData,cbAllCardData[wUser],stOutTemp.cbCardCount,cbAllCount[wUser]))
				{
					cbLittleCount++; 
					if (cbLittleCount==1) continue;
				}
				CopyMemory(&stOutCard,&stOutTemp,sizeof(tagOutCard));
				return true;
			}
		}

		//出连牌
		BYTE cbCountTemp=0;
		for(int i=(int)vecFastestOutCard[wMeChairID].size()-1;i>=0;i--)
		{
			tagOutCard &stOutTemp=vecFastestOutCard[wMeChairID].at(i);
			if (stOutTemp.cbCardType==CT_SINGLE_LINE||stOutTemp.cbCardType==CT_DOUBLE_LINE||stOutTemp.cbCardType==CT_THREE_LINE||
				(stOutTemp.cbCardCount>5&&(stOutTemp.cbCardType==CT_THREE_TAKE_ONE||stOutTemp.cbCardType==CT_THREE_TAKE_TWO)))
			{
				if (stOutTemp.cbLogicValue<0x0B||vecFastestOutCard[wMeChairID].size()<=3)
				{
					CopyMemory(&stOutCard,&stOutTemp,sizeof(tagOutCard));
					return true;
				}
			}
		}

		//考虑出对
		vector<tagOutCard> vecDouble[GAME_PLAYER];
		WORD wBigDoubleU=wMeChairID;
		BYTE cbBigDoubleV=0;				//最大对
		BYTE cbSingleTemp[GAME_PLAYER]={0};//单牌张数
		for (WORD i=0;i<GAME_PLAYER;i++)
		{
			for (WORD j=0;j<(int)vecFastestOutCard[i].size();j++)
			{
				if (vecFastestOutCard[i][j].cbCardType==CT_SINGLE) cbSingleTemp[i]++;
				if (vecFastestOutCard[i][j].cbCardType==CT_DOUBLE||vecFastestOutCard[i][j].cbCardType==CT_DOUBLE_LINE)
				{
					vecDouble[i].push_back(vecFastestOutCard[i][j]);
					if (vecFastestOutCard[i][j].cbLogicValue>cbBigDoubleV)
					{
						cbBigDoubleV=vecFastestOutCard[i][j].cbLogicValue;
						wBigDoubleU=i;
					}
				}
			}
		}

		//让盟友接对
		if (wMeChairID==_wFrontBanker&&cbSingleTemp[_wAllyID]<3)
		{
			for (int i=(int)vecFastestOutCard[_wAllyID].size()-1;i>=0;i--)
			{//让盟友接牌
				for (int j=(int)vecFastestOutCard[wMeChairID].size()-1;j>=0;j--)
				{	
					if (vecFastestOutCard[_wAllyID][i].cbCardType!=CT_DOUBLE) continue;
					if (vecFastestOutCard[wMeChairID][j].cbLogicValue>0x0A) continue;
					//盟友管不起
					if (!CompareCard(vecFastestOutCard[wMeChairID][j].cbCardData,vecFastestOutCard[_wAllyID][i].cbCardData,
						vecFastestOutCard[wMeChairID][j].cbCardCount,vecFastestOutCard[_wAllyID][i].cbCardCount))
						continue;

					stOutCard=vecFastestOutCard[wMeChairID].at(j);

					return true;
				}
			}

		}

		if (cbBigDoubleV>0&&(wBigDoubleU==wMeChairID||wBigDoubleU==_wAllyID)&&vecDouble[wMeChairID].size()>=2)
		{
			//出10以下的小对
			if (vecDouble[wMeChairID].back().cbLogicValue<=0x0A)
			{
				if ((wMeChairID==m_wBankerUser&&cbAllCount[_wFrontUser]>=6&&cbAllCount[_wNextUser]>=6)||
					(wMeChairID!=m_wBankerUser&&cbAllCount[m_wBankerUser]>=6))
				{
					stOutCard=vecDouble[wMeChairID].back();
					return true;
				}
			}
		}

		//三带从小到大
		BYTE cbIndex=0;
		BYTE cbLogicValue=0;		
		for(int i=(int)vecFastestOutCard[wMeChairID].size()-1;i>=0;i--)
		{
			tagOutCard &stOutTemp=vecFastestOutCard[wMeChairID].at(i);

			if ((stOutTemp.cbCardType==CT_THREE||stOutTemp.cbCardType==CT_THREE_TAKE_ONE/*||stOutTemp.cbCardType==CT_THREE_TAKE_TWO*/)&&stOutTemp.cbLogicValue<=0x0B)
			{	
				if (cbLogicValue==0||cbLogicValue>vecFastestOutCard[wMeChairID][i].cbLogicValue)
				{
					cbLogicValue=vecFastestOutCard[wMeChairID][i].cbLogicValue;
					cbIndex=(BYTE)i;
				}
			}
		}

		if (cbLogicValue>0&&(cbLogicValue<0x0B||vecFastestOutCard[wMeChairID].size()<=3))
		{
			stOutCard=vecFastestOutCard[wMeChairID].at(cbIndex);
			ASSERT(stOutCard.cbCardType!=CT_ERROR);
			ASSERT(GetCardType(stOutCard.cbCardData,stOutCard.cbCardCount)==stOutCard.cbCardType);
			return true;
		}

		//顶庄家
		if (wMeChairID==_wFrontBanker&&cbSingleCount[m_wBankerUser]>0&&vecFastestOutCard[wMeChairID].size()>3)
		{
			BYTE cbCard=cbSingleCard[m_wBankerUser][cbSingleCount[m_wBankerUser]-1];
			{
				if (cbSingleCount[wMeChairID]>0&&GetCardLogicValue(cbSingleCard[wMeChairID][0])>=GetCardLogicValue(cbCard))
				{
					for (int i=0;i<cbSingleCount[wMeChairID];i++)
					{
						if (GetCardLogicValue(cbSingleCard[wMeChairID][i])<0x0E)
						{
							stOutCard.cbCardCount=1;
							stOutCard.cbCardData[0]=cbSingleCard[wMeChairID][i];
							stOutCard.cbCardType=CT_SINGLE;
							stOutCard.cbLogicValue=GetCardLogicValue(cbSingleCard[wMeChairID][i]);
							return true;
						}
					}
				}
			}
		}

		//出小牌
		cbIndex=0;
		cbLogicValue=0;

		for(int i=(int)vecFastestOutCard[wMeChairID].size()-1;i>=0;i--)
		{
			if (cbLogicValue==0||cbLogicValue>vecFastestOutCard[wMeChairID][i].cbLogicValue)
			{
				cbLogicValue=vecFastestOutCard[wMeChairID][i].cbLogicValue;
				cbIndex=(BYTE)i;
			}
		}

		if (vecFastestOutCard[wMeChairID].size()>0)
		{
			stOutCard=vecFastestOutCard[wMeChairID].at(cbIndex);
			ASSERT(stOutCard.cbCardType!=CT_ERROR);
			ASSERT(GetCardType(stOutCard.cbCardData,stOutCard.cbCardCount)==stOutCard.cbCardType);
			return true;
		}

		//出大单牌
		FastestOutCard(cbBigCard[wMeChairID],cbBigCount[wMeChairID],vecOutCard);
		for (int i=(int)vecOutCard.size()-1;i>=0;i--)
		{
			if (vecOutCard[i].cbCardCount>0)
			{
				stOutCard=vecOutCard[i];
				return true;
			}
		}

		//炸弹
		if (_vecBombCardResult[wMeChairID].size()>0)
		{
			BYTE cbBombCount=(BYTE)_vecBombCardResult[wMeChairID].size();
			stOutCard.cbCardCount=_vecBombCardResult[wMeChairID][cbBombCount-1].cbCardCount;
			CHECK_MEMCPY(MAX_COUNT,stOutCard.cbCardCount*sizeof(BYTE));
			CopyMemory(stOutCard.cbCardData,_vecBombCardResult[wMeChairID][cbBombCount-1].cbResultCard,stOutCard.cbCardCount*sizeof(BYTE));
			stOutCard.cbCardType=GetCardColor(stOutCard.cbCardData[0])==0x40?CT_MISSILE_CARD:CT_BOMB_CARD;
			stOutCard.cbLogicValue=GetCardLogicValue(stOutCard.cbCardData[0]);
			ASSERT(stOutCard.cbCardType!=CT_ERROR);
			ASSERT(GetCardType(stOutCard.cbCardData,stOutCard.cbCardCount)==stOutCard.cbCardType);
			return true;
		}
		//ASSERT(false);
	}////首出

	/////////////////////////////////////////////分析出牌 非首出////////////////////////////////////////////////////////////////////
	//非首出
	if (cbTurnCardCount>0)
	{
		//不管即输
		if (true)
		{
			bool bLose=false; //不管即输
			bool bPress=false; //压牌走人
			if (!IsAlly(wMeChairID,wOutCardUser)&&_stAnalyseResult[wOutCardUser].cbCardType!=CT_ERROR) 
			{
				bLose=true;//出牌者就剩一手
				if (CompareCard(cbTurnCardData,cbAllCardData[wOutCardUser],cbTurnCardCount,cbAllCount[wOutCardUser]))
					bPress=true;//出牌者压牌走人
			}
			if (wOutCardUser!=m_wBankerUser&&wMeChairID!=m_wBankerUser&&_stAnalyseResult[m_wBankerUser].cbCardType!=CT_ERROR)
			{
				if (CompareCard(cbTurnCardData,cbAllCardData[m_wBankerUser],cbTurnCardCount,cbAllCount[m_wBankerUser]))
				{
					bLose=true;//地主管牌走人
					bPress=true; 
				}
			}
			if (wMeChairID==m_wBankerUser&&wOutCardUser==_wFrontBanker&&_stAnalyseResult[_wAfterBanker].cbCardType!=CT_ERROR)
			{
				if (CompareCard(cbTurnCardData,cbAllCardData[_wAfterBanker],cbTurnCardCount,cbAllCount[_wAfterBanker]))
				{
					bLose=true;//地主下家管牌走人
					bPress=true;
				}
			}
			if (bLose)
			{
				//先尝试顺
				for (int i=(int)vecFastestOutCard[wMeChairID].size()-1;i>=0;i--)
				{
					tagOutCard &stOutTemp=vecFastestOutCard[wMeChairID].at(i);
					if (stOutTemp.cbCardType!=_stTurnCard.cbCardType) continue;
					if (stOutTemp.cbLogicValue<=_stTurnCard.cbLogicValue) continue;
					if (stOutTemp.cbCardCount!=_stTurnCard.cbCardCount) continue;
					if (wMeChairID==m_wBankerUser)
					{
						if (bPress)
						{//敌方压牌走人
							bool bContinue=false;
							for (WORD i=1;i<GAME_PLAYER;i++)
							{
								WORD wID=(wMeChairID+i)%GAME_PLAYER;
								if (IsAlly(wMeChairID,wID)) continue;
								if (_stAnalyseResult[wID].cbCardType!=CT_ERROR)
								{
									if (CompareCard(stOutTemp.cbCardData,cbAllCardData[wID],stOutTemp.cbCardCount,cbAllCount[wID]))
										bContinue=true;//敌方能压
								}
							}
							if (bContinue) continue;	
						}

						CopyMemory(&stOutCard,&stOutTemp,sizeof(tagOutCard));
						return true;
					}
				}

				//搜索出牌
				SimplySearchResult(cbAllCardData[wMeChairID],cbAllCount[wMeChairID],_stTurnCard,vecOutCard);

				for(int i=0;i<(int)vecOutCard.size()-1;i++)
				{
					if (vecOutCard[i].cbCardCount==0) continue;
					bool bContinue=false;
					if (bPress)
					{
						for (WORD j=1;j<GAME_PLAYER;j++)
						{
							WORD wID=(wMeChairID+j)%GAME_PLAYER;
							if (IsAlly(wMeChairID,wID)) continue;
							if (_stAnalyseResult[wID].cbCardType!=CT_ERROR)
							{
								if (CompareCard(vecOutCard[i].cbCardData,cbAllCardData[wID],vecOutCard[i].cbCardCount,cbAllCount[wID]))
									bContinue=true;//敌方能压

							}
						}
					}
					if (bContinue) continue;
					if (vecOutCard[i].cbCardType>=CT_BOMB_CARD)
					{//防止被春天
						if (wMeChairID==m_wBankerUser&&m_cbOutCount[wMeChairID]>=2) continue;
						if (wMeChairID!=m_wBankerUser&&(m_cbOutCount[wMeChairID]>0||m_cbOutCount[_wAllyID]>0)) continue;
					}
					stOutCard=vecOutCard[i];
					return true;
				}

				//至此已不能赢
				//地主剩一张 
				if (wMeChairID==_wFrontBanker&&cbAllCount[m_wBankerUser]==1&&cbTurnCardCount==1)
				{
					//出2或王
					if (cbBigCount[wMeChairID]>0&&_stTurnCard.cbLogicValue<GetCardLogicValue(cbBigCard[wMeChairID][0]))
					{
						stOutCard.cbCardData[0]=cbBigCard[wMeChairID][0];
						stOutCard.cbCardCount=1;
						stOutCard.cbCardType=CT_SINGLE;
						stOutCard.cbLogicValue=GetCardLogicValue(stOutCard.cbCardData[0]);
						return true;
					}

					//出A以下大单
					if (cbSingleCount[wMeChairID]>0&&_stTurnCard.cbLogicValue<GetCardLogicValue(cbSingleCard[wMeChairID][0]))
					{
						stOutCard.cbCardData[0]=cbSingleCard[wMeChairID][0];
						stOutCard.cbCardCount=1;
						stOutCard.cbCardType=CT_SINGLE;
						stOutCard.cbLogicValue=GetCardLogicValue(stOutCard.cbCardData[0]);
						return true;
					}	
				}
			}
		}

		//还剩两手牌
		if (vecFastestOutCard[wMeChairID].size()<=2&&wMeChairID==_wFrontBanker&&wOutCardUser==_wAllyID)
		{
			if (stOutCard.cbLogicValue<=0x0E)
			{
				if (stOutCard.cbCardCount==cbAllCount[m_wBankerUser])
				{
					for (int i=0;i<(int)vecFastestOutCard[wMeChairID].size();i++)
					{//从大到小
						if (vecFastestOutCard[wMeChairID][i].cbCardType>=CT_BOMB_CARD) continue;
						tagOutCard &stOutTemp=vecFastestOutCard[wMeChairID].at(i);
						if (CompareCard(cbTurnCardData,stOutTemp.cbCardData,cbTurnCardCount,stOutTemp.cbCardCount))
						{	
							stOutCard=vecFastestOutCard[wMeChairID].at(i);
							return true;
						}
					}
				}
				else
				{
					for (int i=(int)vecFastestOutCard[wMeChairID].size()-1;i>=0;i--)
					{//从小到大
						if (vecFastestOutCard[wMeChairID][i].cbCardType>=CT_BOMB_CARD) continue;
						tagOutCard &stOutTemp=vecFastestOutCard[wMeChairID].at(i);
						if (CompareCard(cbTurnCardData,stOutTemp.cbCardData,cbTurnCardCount,stOutTemp.cbCardCount))
						{	
							stOutCard=vecFastestOutCard[wMeChairID].at(i);
							return true;
						}
					}
				}	
			}	
		}

		//单牌顶地主
		if (_stTurnCard.cbCardType==CT_SINGLE&&wMeChairID==_wFrontBanker&&vecFastestOutCard[wMeChairID].size()>3&&
			cbSingleCount[wMeChairID]>0&&GetCardLogicValue(cbSingleCard[wMeChairID][0])>_stTurnCard.cbLogicValue)
		{//先顶地主
			for (int j=0;j<cbSingleCount[m_wBankerUser];j++)
			{	
				for(int i=0;i<cbSingleCount[wMeChairID]-1;i++)
				{
					if (GetCardLogicValue(cbSingleCard[wMeChairID][i])<=_stTurnCard.cbLogicValue) break;

					if (GetCardLogicValue(cbSingleCard[wMeChairID][i])>=GetCardLogicValue(cbSingleCard[m_wBankerUser][j])&&
						GetCardLogicValue(cbSingleCard[wMeChairID][i+1])<GetCardLogicValue(cbSingleCard[m_wBankerUser][j]))
					{
						stOutCard.cbCardCount=1;
						stOutCard.cbCardData[0]=cbSingleCard[wMeChairID][i];
						stOutCard.cbCardType=CT_SINGLE;
						stOutCard.cbLogicValue=GetCardLogicValue(cbSingleCard[wMeChairID][i]);
						return true;
					}
				}
			}
		}//单牌顶

		if (wOutCardUser!=m_wBankerUser&&wMeChairID!=m_wBankerUser)
		{//盟友出牌
			bool bOutCard=true;
			ZeroMemory(&stOutCard,sizeof(stOutCard));
			if (_stTurnCard.cbLogicValue>=0x0F) bOutCard=false;
			if (_stTurnCard.cbCardType>CT_THREE_TAKE_TWO) bOutCard=false;
			if (cbTurnCardCount>=2&&cbAllCount[wOutCardUser]<6) bOutCard=false;
			if (cbTurnCardCount>3&&vecFastestOutCard[_wAllyID].size()<=4&&vecFastestOutCard[wMeChairID].size()>3) bOutCard=false;
			if (_stTurnCard.cbCardType>CT_SINGLE&&_stTurnCard.cbLogicValue>=0x0B) bOutCard=false;
			if (vecFastestOutCard[wOutCardUser].size()<=2) bOutCard=false;
			if (bOutCard) 
			{
				//尝试顺牌
				for (int i=(int)vecFastestOutCard[wMeChairID].size()-1;i>=0;i--)
				{
					tagOutCard &stOutTemp=vecFastestOutCard[wMeChairID].at(i);
					if (CompareCard(_stTurnCard.cbCardData,stOutTemp.cbCardData,_stTurnCard.cbCardCount,stOutTemp.cbCardCount))
					{	
						//不用大牌管盟友
						if (stOutTemp.cbCardCount>1&&stOutTemp.cbLogicValue>0x0C) continue;
						if (stOutTemp.cbLogicValue>=0x0F) continue; 
						CopyMemory(&stOutCard,&stOutTemp,sizeof(tagOutCard));
						return true;
					}
				}
				return true;
			}
			//不管
			else return true;
		}
		
		// wxq begin 考虑盟友是最后一手牌并且能一次出完(当前放弃出去让下家出)
		if (vecFastestOutCard[_wAllyID].size() == 1 && CompareCard(_stTurnCard.cbCardData, cbAllCardData[_wAllyID], _stTurnCard.cbCardCount, cbAllCount[_wAllyID]))
		{
			ZeroMemory(&stOutCard, sizeof(stOutCard));
			return true;
		}
		//wxq end

		BYTE cbIndex=0;
		BYTE cbLogicValue=0;
		for(int i=(int)vecFastestOutCard[wMeChairID].size()-1;i>=0;i--)
		{//顺着出最小的
			tagOutCard &stOutTemp=vecFastestOutCard[wMeChairID].at(i);
			if (CompareCard(cbTurnCardData,stOutTemp.cbCardData,cbTurnCardCount,stOutTemp.cbCardCount))
			{	
				if (cbLogicValue==0||cbLogicValue>vecFastestOutCard[wMeChairID][i].cbLogicValue)
				{
					cbLogicValue=stOutTemp.cbLogicValue;
					cbIndex=(BYTE)i;
				}						
			}
		}

		if (vecFastestOutCard[wMeChairID].size()>0&&cbLogicValue>0)
		{
			stOutCard=vecFastestOutCard[wMeChairID].at(cbIndex);
			
			return true;
		}

		//管单牌
		if (_stTurnCard.cbCardType==CT_SINGLE)
		{
			bool bOut=true;
			//考虑忍牌不出
			if (wMeChairID!=m_wBankerUser&&cbBigCount[wMeChairID]==1&&cbBigCount[m_wBankerUser]>0&&cbAllCount[m_wBankerUser]>3)
			{//如果等地主打过
				if (GetCardLogicValue(cbBigCard[m_wBankerUser][0])>GetCardLogicValue(cbBigCard[wMeChairID][0]))
				{
					m_nDepthCount=0;
					m_nSearchCount=0;
					BYTE cbAllCount2[GAME_PLAYER]={0};
					BYTE cbAllCardData2[GAME_PLAYER][MAX_COUNT]={0};
					CHECK_MEMCPY(MAX_COUNT,cbAllCount[wMeChairID]);
					CopyMemory(cbAllCardData2[wMeChairID],cbAllCardData[wMeChairID],cbAllCount[wMeChairID]);
					CHECK_MEMCPY(MAX_COUNT,cbAllCount[m_wBankerUser]-1);
					CopyMemory(cbAllCardData2[m_wBankerUser],&cbAllCardData[m_wBankerUser][1],cbAllCount[m_wBankerUser]-1);
					cbAllCount2[wMeChairID]=cbAllCount[wMeChairID];
					cbAllCount2[m_wBankerUser]=cbAllCount[m_wBankerUser]-1;
					if(SimplySearchTheBest(cbAllCardData2,cbAllCount2,_stTurnCard,wMeChairID,wOutCardUser,stOutCard))
						bOut=false;
				}
			}

			//挺二
			if (bOut&&_stTurnCard.cbLogicValue<0x0F&&cbBigCount[wMeChairID]>0)
			{
				bool	bOutTwo=false;		//需出二
				if (!IsAlly(wMeChairID,wOutCardUser)) bOutTwo=true;

				if(bOutTwo&&GetCardValue(cbBigCard[wMeChairID][cbBigCount[wMeChairID]-1])==0x02)
				{
					stOutCard.cbCardCount=1;
					stOutCard.cbCardData[0]=cbBigCard[wMeChairID][cbBigCount[wMeChairID]-1];
					stOutCard.cbLogicValue=0x0F;
					stOutCard.cbCardType=CT_SINGLE;
					return true;
				}
			}

			//用王管
			if (bOut&&cbBigCount[wMeChairID]>0&&GetCardColor(cbBigCard[wMeChairID][0])==0x40)
			{
				bool bNeedKing=false;
				if (!IsAlly(wMeChairID,wOutCardUser))
				{//非盟友出牌
					if (wOutCardUser!=_wFrontBanker&&_stTurnCard.cbLogicValue>=GetCardLogicValue(_cb2Card[0]))
						bNeedKing=true;//非盟友出最大单牌

					if (_stTurnCard.cbLogicValue==0x0F&&wOutCardUser!=_wFrontBanker) //非盟友出2
					{
						if (wMeChairID==m_wBankerUser) bNeedKing=true;
						//考虑等着管小王
						else if (!(GetCardValue(cbBigCard[wMeChairID][0])==0x0F&&GetCardValue(cbBigCard[m_wBankerUser][0])==0x0E)) 
							bNeedKing=true;
					}

					if (vecFastestOutCard[wOutCardUser].size()<2) bNeedKing=true; //对家快出完

					if (vecFastestOutCard[wMeChairID].size()<2) bNeedKing=true;	//自己快出完

					//地主
					if (wMeChairID==m_wBankerUser)
					{
						if (wOutCardUser==_wNextUser&&cbAllCount[_wFrontUser]==1) bNeedKing=true;//下家要放人
					}

					//地主上家
					if (wMeChairID==_wFrontBanker)	bNeedKing=true;
				}

				BYTE cbCard=cbBigCard[wMeChairID][0];
				if (bNeedKing&&GetCardLogicValue(cbCard)>_stTurnCard.cbLogicValue)
				{
					stOutCard.cbCardCount=1;
					stOutCard.cbCardData[0]=cbCard;
					stOutCard.cbLogicValue=GetCardLogicValue(cbCard);
					stOutCard.cbCardType=CT_SINGLE;
					return true;
				}

				//不管
				if (bNeedKing==false) return true;
			}
		}//单牌

		//打对2
		if (_stTurnCard.cbCardType==CT_DOUBLE&&_stTurnCard.cbLogicValue<0x0F&&cbBigCount[wMeChairID]>=2)
		{
			ZeroMemory(&stOutCard,sizeof(stOutCard));
			bool bNeedDouble2=false;
			if (wOutCardUser==m_wBankerUser&&_stTurnCard.cbLogicValue==0x0E) bNeedDouble2=true; //地主下对A
			if (wMeChairID==m_wBankerUser&&wOutCardUser==_wAfterBanker&&_stTurnCard.cbLogicValue==0x0E) bNeedDouble2=true; //地主下家下对A
			if (!IsAlly(wMeChairID,wOutCardUser)&&vecFastestOutCard[wOutCardUser].size()<3) bNeedDouble2=true;	//对家快出完
			if (wMeChairID==m_wBankerUser&&vecFastestOutCard[_wFrontBanker].size()<3) bNeedDouble2=true;//地主上家快出完
			if (!IsAlly(wMeChairID,wOutCardUser)&&vecFastestOutCard[wMeChairID].size()<=2) bNeedDouble2=true; //自己快出完

			if (bNeedDouble2)
			{
				if(GetCardLogicValue(cbBigCard[wMeChairID][cbBigCount[wMeChairID]-2])==0x0F)
				{//有对2
					stOutCard.cbCardCount=2;
					stOutCard.cbCardType=CT_DOUBLE;
					stOutCard.cbLogicValue=0x0f;
					stOutCard.cbCardData[0]=cbBigCard[wMeChairID][cbBigCount[wMeChairID]-2];
					stOutCard.cbCardData[1]=cbBigCard[wMeChairID][cbBigCount[wMeChairID]-1];
					return true;
				}
			}
			else return true;
		}

		//拆两王四个二
		if (_vecBombCardResult[wMeChairID].size()>0&&_stTurnCard.cbCardType<=CT_DOUBLE&&!IsAlly(wMeChairID,wOutCardUser))
		{
			int nLittleCount=0;
			for(int i=(int)vecFastestOutCard[wMeChairID].size()-1;i>=0;i--)
			{
				tagOutCard &stOutTemp=vecFastestOutCard[wMeChairID].at(i);
				if (stOutTemp.cbLogicValue<=0x0A) //10以下牌
					nLittleCount++;
			}
			for (int i=0;i<(int)_vecBombCardResult[wMeChairID].size();i++)
			{
				tagOutCardResult &stRsultTemp=_vecBombCardResult[wMeChairID].at(i);

				if (GetCardLogicValue(stRsultTemp.cbResultCard[0])==0x0F)
				{//有四个2
					if (nLittleCount==vecFastestOutCard[wMeChairID].size()&&nLittleCount>=2&&_stTurnCard.cbLogicValue<0x0F)
					{//剩的全是小牌
						stOutCard.cbCardType=_stTurnCard.cbCardType;
						stOutCard.cbCardCount=_stTurnCard.cbCardCount;
						stOutCard.cbLogicValue=0x0F;
						CHECK_MEMCPY(MAX_COUNT,stOutCard.cbCardCount*sizeof(BYTE));
						CopyMemory(stOutCard.cbCardData,stRsultTemp.cbResultCard,stOutCard.cbCardCount*sizeof(BYTE));
						return true;
					}
				}

				if (GetCardColor(stRsultTemp.cbResultCard[0])==0x40&&_stTurnCard.cbCardType==CT_SINGLE)
				{//拆两王
					if (nLittleCount==vecFastestOutCard[wMeChairID].size()&&nLittleCount>=2)
					{//剩的全是小牌
						stOutCard.cbCardType=CT_SINGLE;
						stOutCard.cbCardCount=_stTurnCard.cbCardCount;
						stOutCard.cbLogicValue=GetCardLogicValue(stRsultTemp.cbResultCard[0]);
						stOutCard.cbCardData[0]=stRsultTemp.cbResultCard[0];
						if (stOutCard.cbLogicValue>_stTurnCard.cbLogicValue) return true;
					}
				}
			}
		}
	}

	//提示出牌
	if (!IsAlly(wMeChairID,wOutCardUser))
	{//非盟友
		vecOutCard.clear();
		//ASSERT(cbTurnCardCount>0);
		int nResultCount=(int)SimplySearchResult(cbCardTemp[wMeChairID],cbTempCount[wMeChairID],_stTurnCard,vecOutCard);
		for (int i=0;i<nResultCount-1;i++)//排除不出
		{
			stOutCard=vecOutCard[i];
			if (stOutCard.cbCardCount==0||stOutCard.cbCardType>=CT_BOMB_CARD) continue;
			BYTE cbBufCount=cbTempCount[wMeChairID];
			BYTE cbCardBuf[MAX_COUNT]={0};
			CHECK_MEMCPY(MAX_COUNT,cbBufCount*sizeof(BYTE));
			CopyMemory(cbCardBuf,cbCardTemp[wMeChairID],cbBufCount*sizeof(BYTE));
			VERIFY(RemoveCard(stOutCard.cbCardData,stOutCard.cbCardCount,cbCardBuf,cbBufCount));
			cbBufCount-=stOutCard.cbCardCount;
			vector<tagOutCard> vecFastestOutCard2;
			FastestOutCard(cbCardBuf,cbBufCount,vecFastestOutCard2);

			//不太烂
			if ((int)vecFastestOutCard2.size()-(int)vecFastestOutCard[wMeChairID].size()<=1)		
				return true;

		}
	}

	ZeroMemory(&stOutCard,sizeof(stOutCard));
	return true;
}

bool CGameLogic::AnalyseLandScore(const BYTE cbCardData[], BYTE cbCardCount, DWORD Rule)
{
	CHECK_CARD_ARRAY(cbCardData,cbCardCount);

	if (Rule != 0) m_ppRule = Rule;
	
	//分析扑克
	BYTE cbWangCount=0;
	BYTE cbErCount=0;

	for (BYTE i=0;i<cbCardCount;i++)
	{
		//大王小王
		if (cbCardData[i] == 0x41 || cbCardData[i] == 0x42) cbWangCount++;

		//2的数量
		if (GetCardLogicValue(cbCardData[i]) == 15) cbErCount++;
	}

	//分析炸弹的数量
	BYTE cbBomCardData[MAX_COUNT] ;
	BYTE cbBomCardCount=0 ;

	GetAllBomCard(cbCardData, cbCardCount, cbBomCardData, cbBomCardCount) ;
	if ((Rule&0xFF) < RULE_ShuangWang)
	{//没有叫地主规则的时候
		//双王必须叫地主
		if (cbWangCount == 2) return true;

		//4个2必须叫地主
		if (cbErCount == 4) return true;

		//双2+1王
		if (cbWangCount > 0 && cbErCount >= 2) return true;
		//一王一2一炸必须叫地主
		if (cbBomCardCount > 0 && cbWangCount > 0 && cbErCount > 0) return true;

		//三2一炸必须叫地主
		if (cbBomCardCount > 0 && cbErCount >= 3) return true;
		//两二两炸
		if (cbBomCardCount >= 2 && cbErCount >= 2) return true;
		//一二 三炸
		if (cbBomCardCount >= 3 && cbErCount >= 1) return true;
		//四炸
		if (cbBomCardCount >= 4) return true;
	}
	if ((Rule&RULE_ShuangWang)>0 &&cbWangCount > 1) return true;
	//三个头子必抓是固定的游戏规则
	if ((Rule&RULE_3Zhua)>0 && (cbWangCount + cbErCount + cbBomCardCount) >= 3) return true;

	return false;
}

//打印扑克
void CGameLogic::PrintCardInfo(WORD wMeChairID,WORD wOutCardUser)
{
}

void CGameLogic::GetAllBomCard(BYTE const cbHandCardData[], BYTE const cbHandCardCount, BYTE cbBomCardData[], BYTE &cbBomCardCount)
{
	BYTE cbTmpCardData[MAX_COUNT] ;
	CHECK_MEMCPY(MAX_COUNT,cbHandCardCount);
	CopyMemory(cbTmpCardData, cbHandCardData, cbHandCardCount) ;

	//大小排序
	SortCardList(cbTmpCardData, cbHandCardCount, ST_ORDER);

	BYTE CardIndex = 0 ;

	if(cbHandCardCount<2) return ;

	//双王炸弹
	if(0x42==cbTmpCardData[0] && 0x41==cbTmpCardData[1])
	{
		cbBomCardData[CardIndex++] = cbTmpCardData[0];
		cbBomCardData[CardIndex++] = cbTmpCardData[1];
		cbBomCardCount++;
	}

	//扑克分析
	for (BYTE i=0;i<cbHandCardCount;i++)
	{
		//变量定义
		BYTE cbSameCount=1;
		BYTE cbLogicValue=GetCardLogicValue(cbTmpCardData[i]);

		//搜索同牌
		for (BYTE j=i+1;j<cbHandCardCount;j++)
		{
			//获取扑克
			if (GetCardLogicValue(cbTmpCardData[j])!=cbLogicValue) break;

			//设置变量
			cbSameCount++;
		}

		if(4==cbSameCount)
		{
			cbBomCardData[CardIndex++] = cbTmpCardData[i];
			cbBomCardData[CardIndex++] = cbTmpCardData[i + 1];
			cbBomCardData[CardIndex++] = cbTmpCardData[i + 2];
			cbBomCardData[CardIndex++] = cbTmpCardData[i + 3];
			cbBomCardCount++;
		}

		//设置索引
		i+=cbSameCount-1;
	}
}

bool CGameLogic::IsValidType(BYTE Type, BYTE cardCount)
{
	// printf("IsValidType:%d,%d\n",Type,cardCount);

	if (m_ppRule == 0) return true;
	if (Type == CT_THREE || Type == CT_THREE_LINE) return((m_ppRule&RULE_3_0) > 0 && ((m_ppRule&RULE_Off) > 0) || cardCount % 3 == 0);
	else if (Type == CT_THREE_TAKE_TWO) return (m_ppRule&RULE_3_2)>0;
	else if (Type == CT_FOUR_TAKE_ONE) return ((m_ppRule&RULE_4_1) > 0 && ((m_ppRule&RULE_Off) > 0) || cardCount % 6 == 0);
	else if (Type == CT_FOUR_TAKE_TWO) return (m_ppRule&RULE_4_2)>0;
	return true;
}

void CGameLogic::ReSetCardCount(BYTE cbAllUserCard[GAME_PLAYER][MAX_COUNT], BYTE cbAllCount[])
{
	ZeroMemory(cbAllCount, sizeof(BYTE)* GAME_PLAYER);
	for (int index = 0; index < GAME_PLAYER; ++index)
	{
		for (int i = 0; i < MAX_COUNT; ++i)
		{
			if (cbAllUserCard[index][i] == 0) break;
			cbAllCount[index]++;
		}
	}
}

void CGameLogic::LandTest()
{
	//////////////////////////////////////////////////////////////////////////
	//wxq  测试庄家只有最后一张牌时候的算法
	//WORD wMeChairID = 2;
	//tagOutCard stOutCard;
	//ZeroMemory(&stOutCard, sizeof(stOutCard));
	//m_cbTurnCardCount = 0;
	//m_wBankerUser = 2;
	//m_GameLogic.SetBanker(m_wBankerUser);
	//ZeroMemory(m_cbHandCardData, sizeof(m_cbHandCardData));

	/*ZeroMemory(m_cbAllCardData, sizeof(m_cbAllCardData));
	m_cbAllCount[0] = 17;
	m_cbAllCount[1] = 17;
	m_cbAllCount[2] = 20;
	m_cbOutCount[0] = 0;
	m_cbOutCount[1] = 0;
	m_cbOutCount[2] = 0;

	m_cbAllCardData[0][0] = 0x12;
	m_cbAllCardData[0][1] = 0x22;
	m_cbAllCardData[0][2] = 0x01;
	m_cbAllCardData[0][6] = 0x2c;
	m_cbAllCardData[0][3] = 0x1c;
	m_cbAllCardData[0][4] = 0x09;
	m_cbAllCardData[0][5] = 0x29;
	m_cbAllCardData[0][7] = 0x08;
	m_cbAllCardData[0][8] = 0x18;
	m_cbAllCardData[0][9] = 0x06;
	m_cbAllCardData[0][10] = 0x16;
	m_cbAllCardData[0][11] = 0x26;
	m_cbAllCardData[0][12] = 0x36;
	m_cbAllCardData[0][13] = 0x04;
	m_cbAllCardData[0][14] = 0x03;
	m_cbAllCardData[0][15] = 0x23;
	m_cbAllCardData[0][16] = 0x33;

	m_cbAllCardData[1][0] = 0x12;
	m_cbAllCardData[1][1] = 0x21;
	m_cbAllCardData[1][2] = 0x0d;
	m_cbAllCardData[1][6] = 0x2c;
	m_cbAllCardData[1][3] = 0x1c;
	m_cbAllCardData[1][4] = 0x0b;
	m_cbAllCardData[1][5] = 0x2b;
	m_cbAllCardData[1][7] = 0x0a;
	m_cbAllCardData[1][8] = 0x3a;
	m_cbAllCardData[1][9] = 0x29;
	m_cbAllCardData[1][10] = 0x38;
	m_cbAllCardData[1][11] = 0x08;
	m_cbAllCardData[1][12] = 0x07;
	m_cbAllCardData[1][13] = 0x05;
	m_cbAllCardData[1][14] = 0x25;
	m_cbAllCardData[1][15] = 0x15;
	m_cbAllCardData[1][16] = 0x35;

	m_cbAllCardData[2][0] = 0x42;
	m_cbAllCardData[2][1] = 0x41;
	m_cbAllCardData[2][2] = 0x01;
	m_cbAllCardData[2][6] = 0x11;
	m_cbAllCardData[2][3] = 0x1d;
	m_cbAllCardData[2][4] = 0x2d;
	m_cbAllCardData[2][5] = 0x3d;
	m_cbAllCardData[2][7] = 0x0b;
	m_cbAllCardData[2][8] = 0x2b;
	m_cbAllCardData[2][9] = 0x3a;
	m_cbAllCardData[2][10] = 0x1a;
	m_cbAllCardData[2][11] = 0x09;
	m_cbAllCardData[2][12] = 0x07;
	m_cbAllCardData[2][13] = 0x27;
	m_cbAllCardData[2][14] = 0x37;
	m_cbAllCardData[2][15] = 0x04;
	m_cbAllCardData[2][16] = 0x24;
	m_cbAllCardData[2][17] = 0x34;
	m_cbAllCardData[2][18] = 0x03;
	m_cbAllCardData[2][19] = 0x02;

	for (BYTE i = 0; i < GAME_PLAYER;++i)
	{
	SortCardList(m_cbAllCardData[i], m_cbAllCount[i], ST_ORDER);
	}*/

	////出牌次数
	//m_GameLogic.SetOutCount(m_cbOutCount);
	//if (m_cbTurnCardCount == 0 || m_wOutCardUser == wMeChairID) {
	//	m_wOutCardUser = INVALID_CHAIR;
	//	m_cbTurnCardCount = 0;
	//	ZeroMemory(m_cbTurnCardData, sizeof(m_cbTurnCardData));
	//}

	//m_GameLogic.SearchOutCard(m_cbHandCardData, m_cbHandCardCount[wMeChairID], m_cbTurnCardData, m_cbTurnCardCount, m_wOutCardUser, 2, stOutCard);

	//////////////////////////////////////////////////////////////////////////
}
/////////////////////////////////////////////////////////////////////////////////////