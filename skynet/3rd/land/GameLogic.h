#ifndef GAME_LOGIC_HEAD_FILE
#define GAME_LOGIC_HEAD_FILE

#pragma once

#include <vector>
#include <list>
#include <queue>
#include <string>

//////////////////////////////////////////////////////////////////////////

//排序类型
#define ST_ORDER					0									//大小排序
#define ST_COUNT					1									//数目排序
#define ST_CUSTOM					2									//自定排序

//////////////////////////////////////////////////////////////////////////
//分析结构
struct tagAnalyseResult
{
	BYTE 							cbBlockCount[4];					//扑克数目(lyx 依次存：单牌数量，对子数量，三张相同数量，四张相同数量，参见 CGameLogic::AnalysebCardData ）
	BYTE							cbCardData[4][MAX_COUNT*2];			//扑克数据
	BYTE							cbCardType;							//扑克类型
	BYTE							cbLogicValue;						//扑克大小
};

//出牌结构
struct tagOutCard
{
	BYTE							cbCardData[MAX_COUNT];				//扑克数据
	BYTE							cbCardCount;						//扑克数目
	BYTE							cbCardType;							//扑克类型
	BYTE							cbLogicValue;						//扑克大小
};

//连牌结构
struct tagLinkCard
{
	BYTE							cbLinkCount;						//连牌长度
	BYTE							cbCardData[MAX_COUNT];				//扑克数据
	BYTE							cbCardCount;						//扑克张数
	BYTE							cbLogicValue;						//逻辑大小
	BYTE							cbCardType;							//连牌类型
};

//出牌结果
struct tagOutCardResult
{
	BYTE							cbCardCount;						//扑克数目
	BYTE							cbResultCard[MAX_COUNT];			//结果扑克
};

//分布信息
struct tagDistributing
{
	BYTE							cbCardCount;						//扑克数目
	BYTE							cbDistributing[15][6];				//分布信息
};

//上次出牌
struct tagLastOutCard
{
	WORD							wOutUser;							//出牌玩家
	tagOutCard						stLastCard;							//上次出牌
};

//搜索结果
struct tagSearchCardResult
{
	BYTE							cbSearchCount;						//结果数目
	BYTE							cbCardCount[MAX_COUNT];				//扑克数目
	BYTE							cbResultCard[MAX_COUNT][MAX_COUNT];	//结果扑克
};

//搜索条目
struct tagSearchItem
{
public:
	BYTE				cbWin;											//最终结局
	int					nIndex;											//搜索索引
	BYTE				cbAllCount[GAME_PLAYER];						//手牌张数
	BYTE				cbAllCard[GAME_PLAYER][MAX_COUNT];				//手牌数据

	WORD				wChairID;										//自己座位
	WORD				wOutUser;										//出牌玩家
	tagOutCard			stTurnCard;										//出牌数据
	std::vector<tagOutCard>	vecSearchReslut;							//搜索结果

	tagSearchItem() 
	{
		cbWin=0;
		nIndex=0;
		ZeroMemory(cbAllCount,sizeof(cbAllCount));
		ZeroMemory(cbAllCard,sizeof(cbAllCard));
		ZeroMemory(&stTurnCard,sizeof(stTurnCard));
		wChairID=INVALID_CHAIR;
		wOutUser=INVALID_CHAIR;
	}

	void reset()
	{
		cbWin=0;
		nIndex=0;
		ZeroMemory(cbAllCount,sizeof(cbAllCount));
		ZeroMemory(cbAllCard,sizeof(cbAllCard));
		ZeroMemory(&stTurnCard,sizeof(stTurnCard));
		wChairID=INVALID_CHAIR;
		wOutUser=INVALID_CHAIR;

		vecSearchReslut.clear();
	}
};


#ifdef USE_LOG_TRACE

class CFunTrace
{
public:
	CFunTrace();
	~CFunTrace();

	void Push(LPCTSTR lpsInfo);
	void Pop();
private:
	void Save();
	void CheckLen(DWORD dwLen);
	static DWORD WINAPI CheckThread(PVOID pUserData);
private:
	HANDLE		m_hMutex;
	HANDLE		m_hCheckThread;
	bool		m_bDirty;
	CFile		m_File;
	TCHAR*		m_pPath;
	DWORD		m_dwPathLen;
	DWORD		m_dwCurLen;
	DWORD		m_dwLastTick;
};

inline CFunTrace::CFunTrace()
{
	TCHAR szPath[MAX_PATH];
	GetModuleFileName(NULL, szPath, MAX_PATH);
	CString strFile = szPath;
	strFile = strFile + TEXT("_funlog.txt");
	m_File.Open(strFile, CFile::modeCreate | CFile::modeReadWrite | CFile::shareDenyWrite);
	m_pPath = NULL;
	m_dwPathLen = 0;
	m_dwCurLen = 0;
	m_hMutex = CreateMutex(NULL, FALSE, NULL);
	m_bDirty = false;
	DWORD dwid = 0;
	m_hCheckThread = CreateThread(NULL, 0, CheckThread, this, 0, &dwid);
	m_dwLastTick = GetTickCount();
}

inline CFunTrace::~CFunTrace()
{
	if (m_File.m_hFile != INVALID_HANDLE_VALUE)
		m_File.Close();

	TerminateThread(m_hCheckThread, 0);
	CloseHandle(m_hMutex);
}

inline DWORD CFunTrace::CheckThread(PVOID pUserData)
{
	CFunTrace* pTrace = (CFunTrace*)pUserData;
	while (true)
	{
		Sleep(1000);
		//CLock l(pTrace->m_hMutex);
		if (GetTickCount() - pTrace->m_dwLastTick > 60000)//一分钟没有反应了
		{
			pTrace->Save();
			pTrace->m_dwLastTick = GetTickCount();
		}
	}
}

inline void CFunTrace::Save()
{
	if (m_File.m_hFile == INVALID_HANDLE_VALUE || m_pPath == NULL) return;
	m_File.SetLength(2 + m_dwCurLen * sizeof(TCHAR));
	m_File.Seek(0, CFile::begin);
	BYTE cbHead[2] = { 0xff, 0xfe };
	m_File.Write(cbHead, 2);
	m_File.Write(m_pPath, m_dwCurLen * sizeof(TCHAR));
	//m_File.Flush();
}

inline void CFunTrace::CheckLen(DWORD dwLen)
{
	if (m_dwPathLen >= dwLen) return;
	TCHAR* pTemp = new TCHAR[dwLen];
	if (m_dwPathLen)
		CopyMemory(pTemp, m_pPath, m_dwPathLen * sizeof(TCHAR));
	else
		pTemp[0] = 0;
	SafeDeleteArray(m_pPath);
	m_pPath = pTemp;
	m_dwPathLen = dwLen;
}

inline void CFunTrace::Push(LPCTSTR lpsInfo)
{
#ifdef USE_LOG_TRACE
	CLock l(m_hMutex);
	m_dwLastTick = GetTickCount();
	if (lpsInfo == NULL) return;
	CString str = lpsInfo;
	if (str.GetLength() == 0) return;
	str.Replace(TEXT('\\'), TEXT('#'));
	str = TEXT("\\") + str;
	m_dwCurLen += str.GetLength();
	CheckLen(m_dwCurLen + 1);
	_tcscat_s(m_pPath, m_dwCurLen + 1, str);
#endif
}

inline void CFunTrace::Pop()
{
#ifdef USE_LOG_TRACE
	CLock l(m_hMutex);
	m_dwLastTick = GetTickCount();
	if (m_dwCurLen == 0) return;
	TCHAR* pTemp = _tcsrchr(m_pPath, TEXT('\\'));
	if (pTemp == NULL)
	{
		//最后一层
		m_pPath[0] = 0;
		m_dwCurLen = 0;
	}
	else
	{
		*pTemp = 0;
		m_dwCurLen = _tcslen(m_pPath);
	}
#endif
}

extern CFunTrace g_FunTrace;

#endif // #ifdef USE_LOG_TRACE

class CFunItem
{
public:
	CFunItem(LPCSTR lpsFunName, LPCTSTR lpsFMT = NULL, ...);
	~CFunItem();
private:
	
#ifdef USE_LOG_TRACE	
	CString m_strFunName;
#endif
};


inline CFunItem::CFunItem(LPCSTR lpsFunName, LPCTSTR lpsFMT, ...)
{
#ifdef USE_LOG_TRACE
	ASSERT(lpsFunName);
	if (lpsFunName == NULL) return;
	USES_CONVERSION;
	m_strFunName = TEXT("Android ");
	m_strFunName += A2T(lpsFunName);
	CString strTrace;
	if (lpsFMT)
	{
		va_list _va_list;
		va_start(_va_list, lpsFMT);
		strTrace.FormatV(lpsFMT, _va_list);
		va_end(_va_list);
		if (strTrace.GetLength())
			strTrace = TEXT("(") + strTrace + TEXT(")");
	}
	g_FunTrace.Push(m_strFunName + strTrace);
#endif
}

inline CFunItem::~CFunItem()
{
#ifdef USE_LOG_TRACE
	if (m_strFunName.GetLength() == 0) return;
	g_FunTrace.Pop();
#endif
}


// 转换牌信息 到字符串
std::string cardDataToString(const BYTE * data,BYTE len);
void CHECK_CARD_ARRAY(const BYTE cbCardData[],BYTE cbCardCount,BYTE maxCount = -1);

//////////////////////////////////////////////////////////////////////////

class CGameUserItemSink;
class CGameLogic;

void CheckGameLogicData(CGameLogic * pLogic,CGameUserItemSink *userSink);

//游戏逻辑类
class CGameLogic
{
	//变量定义
public:
	static const BYTE				m_cbCardData[FULL_COUNT];			//扑克数据
	DWORD							m_ppRule;
	//AI变量
public:

	// by lyx
	CGameUserItemSink 			*	m_userSink;

	BYTE							m_cbLandScoreCardData[MAX_COUNT];	//叫牌扑克
	BYTE							m_cbAllCount[GAME_PLAYER];			//扑克数目
	BYTE							m_cbAllCardData[GAME_PLAYER][MAX_COUNT];//所有扑克
	WORD							m_wBankerUser;						//地主玩家
	bool							m_bMayChunTian;						//可以打春天
	BYTE							m_cbOutCount[GAME_PLAYER];			//出牌次数
	tagLastOutCard					m_LastOutCard;						//上次出牌

	//函数变量
	WORD							_wNextUser;							//下家
	WORD							_wFrontUser;						//上家
	WORD							_wAllyID;							//盟友
	WORD							_wAfterBanker;						//地主下家
	WORD							_wFrontBanker;						//地主上家
	bool							_bCanBomb;							//能否出炸
	bool							_bTrySearch;						//是否尝试
	BYTE							_cb2Card[MAX_COUNT*2];				//另两家牌
	BYTE							_cb2CardCount;						//另两家张数
	tagOutCard						_stTurnCard;						//桌面扑克
	tagAnalyseResult				_stAnalyseResult[GAME_PLAYER];		//手牌分析
	std::vector<tagOutCardResult>	_vecBombCardResult[GAME_PLAYER];	//手牌炸弹

	//搜索内存池
	std::vector<tagSearchItem*> 	m_SearchItemPool;
	// del by lyx 2018-9-29 std::queue<tagSearchItem*>	m_SearchItemUsed;

public:
	// by lyx
	void copy(CGameLogic &other)
	{
        CopyMemory(&other.m_ppRule,&m_ppRule,(char *)&_vecBombCardResult-(char *)&m_ppRule);

        for (int i=0;i<GAME_PLAYER;++i)
        	other._vecBombCardResult[i] = _vecBombCardResult[i];

        for (auto it=m_SearchItemPool.begin();it != m_SearchItemPool.end(); ++it)
        {
        	auto item = new tagSearchItem;
        	*item = **it;
        	other.m_SearchItemPool.push_back(item);
        }
	}
	void save(const char * file)
	{
		FILE * fp = fopen(file,"wb+");
		fwrite((char *)&m_ppRule,(char *)&_vecBombCardResult-(char *)&m_ppRule,1,fp);

        for (int i=0;i<GAME_PLAYER;++i)
        {
        	int count = (int)_vecBombCardResult[i].size();
        	fwrite(&count,sizeof(count),1,fp);
        	for (int j=0;j<count;++j)
        		fwrite((char *)&_vecBombCardResult[i],sizeof(tagOutCardResult),1,fp);
        }

        fclose(fp);
	}
	void load(const char * file)
	{
		FILE * fp = fopen(file,"rb");
		fread(&m_ppRule,(char *)&_vecBombCardResult-(char *)&m_ppRule,1,fp);

        for (int i=0;i<GAME_PLAYER;++i)
        {
        	int count = 0;
        	fread(&count,sizeof(count),1,fp);
        	for (int j=0;j<count;++j)
        	{
        		tagOutCardResult tor = {0};
        		fread(&tor,sizeof(tor),1,fp);
        		_vecBombCardResult[i].push_back(tor);
        	}
        }
	}


	//函数定义
public:
	//构造函数
	CGameLogic();
	//析构函数
	virtual ~CGameLogic();

	//类型函数
public:
	//获取类型
	BYTE GetCardType(const BYTE cbCardData[], BYTE cbCardCount);
	//分析出牌
	BYTE AnalyseOutCard(const BYTE cbTurnCardData[],BYTE cbTurnCardCount,tagAnalyseResult &stAnalyseResult);
	//分析出牌
	BYTE AnalyseOutCard(const BYTE cbTurnCardData[],BYTE cbTurnCardCount,tagOutCard &stOutCard);
	//获取数值
	BYTE GetCardValue(BYTE cbCardData) { return cbCardData&MASK_VALUE; }
	//获取花色
	BYTE GetCardColor(BYTE cbCardData) { return cbCardData&MASK_COLOR; }

	//控制函数
public:
	//混乱扑克
	VOID RandCardList(BYTE cbCardBuffer[], BYTE cbBufferCount);
	//获取好牌
	VOID RandGoodCardList(BYTE cbCardBuffer[], BYTE cbBufferCount, WORD UserID, BYTE CardType[]);
	//获取差牌
	VOID RandBadCardList(BYTE cbCardBuffer[], BYTE cbBufferCount, WORD UserID);
	//获取牌的花色
	VOID RandCardColor(BYTE cbCardCode[], BYTE cbCardValue, BYTE cbCount);
	//排列扑克
	VOID SortCardList(BYTE cbCardData[], BYTE cbCardCount, BYTE cbSortType);
	//删除扑克
	bool RemoveCard(const BYTE cbRemoveCard[], BYTE cbRemoveCount, BYTE cbCardData[], BYTE cbCardCount);

	//逻辑函数
public:
	//有效判断
	bool IsValidCard(BYTE cbCardData);
	//逻辑数值
	BYTE GetCardLogicValue(BYTE cbCardData);
	//对比扑克
	bool CompareCard(const BYTE cbFirstCard[], const BYTE cbNextCard[], BYTE cbFirstCount, BYTE cbNextCount);

	//内部函数
public:
	//构造扑克
	BYTE MakeCardData(BYTE cbValueIndex, BYTE cbColorIndex);
	//分析扑克
	VOID AnalysebCardData(const BYTE cbCardData[], BYTE cbCardCount, tagAnalyseResult & AnalyseResult);
	//分析分布
	VOID AnalysebDistributing(const BYTE cbCardData[], BYTE cbCardCount, tagDistributing & Distributing);
	//叫地主分析
	bool AnalyseLandScore(const BYTE cbCardData[], BYTE cbCardCount,DWORD Rule = 0);
	//////////////////////////////////////////////////////////////////////////
	//AI函数

	//设置函数
public:
	//设置扑克
	VOID SetUserCard(WORD wChairID, BYTE cbCardData[], BYTE cbCardCount) ;
	//设置底牌
	VOID SetBackCard(WORD wChairID, BYTE cbBackCardData[], BYTE cbCardCount) ;
	//设置庄家
	VOID SetBanker(WORD wBanker) ;
	//叫牌扑克
	VOID SetLandScoreCardData(BYTE cbCardData[], BYTE cbCardCount) ;
	//删除扑克
	VOID RemoveUserCardData(WORD wChairID, BYTE cbRemoveCardData[], BYTE cbRemoveCardCount) ;
	//设置出牌
	VOID SetLastOutCard(WORD wOutUser,BYTE cbCardData[],BYTE cbCardCount);
	//出牌次数
	VOID SetOutCount(const BYTE cbOutCount[]);

	//辅助函数
public:
	//叫分判断
	BYTE LandScore(WORD wMeChairID, BYTE cbCurrentLandScore) ;
	//同牌搜索
	BYTE SearchSameCard( const BYTE cbHandCardData[], BYTE cbHandCardCount, BYTE cbReferCard, BYTE cbSameCardCount,tagSearchCardResult *pSearchCardResult );
	//送牌搜索
	bool SearchSamllerResult(const BYTE cbCardData[],BYTE cbCardCount,tagOutCard stOutCard,tagOutCard &stSearchResult);

	//算法测试
public:
	void LandTest();
	//主要函数
public:
	//最快出牌(无人管牌)
	size_t FastestOutCard(const BYTE cbCardData[],BYTE cbCardCount,std::vector<tagOutCard> &OvecOutCard);
	//寻找最快出牌(辅助函数)
	void FindFastest(const BYTE cbCardData[],BYTE cbCardCount,std::vector<tagOutCard> &vecFastestResult,std::vector<tagOutCard> &vecCurrentResult);
	//寻找炸弹
	BYTE SearchBombCard(tagAnalyseResult stAnalyseResult,std::vector<tagOutCardResult> &vecBombCardResult);
	//连续最大尝试
	bool TryAllBiggestCard(const BYTE cbAllUserCard[GAME_PLAYER][MAX_COUNT],BYTE cbAllCount[GAME_PLAYER],WORD wMeChairID,const tagOutCard &stTurnCard,std::vector<tagOutCard> &vecOutCard);
	//出牌搜索
	bool SearchOutCard(const BYTE cbHandCardData[], BYTE cbHandCardCount, const BYTE cbTurnCardData[], BYTE cbTurnCardCount, WORD wOutCardUser, WORD wMeChairID, tagOutCard &stOutCard);
	//循环深度搜索最佳出牌
	bool SimplySearchTheBest(const BYTE cbAllUserCard[GAME_PLAYER][MAX_COUNT], BYTE cbAllCount[GAME_PLAYER],const tagOutCard stTurnCard,WORD wMeChairID, WORD wOutUser,tagOutCard &stOutCard,bool bFourTake=false,bool bFixedBankerBomb=false);
	//递归深度搜索最佳出牌
	bool SimplySearchTheBest(const BYTE cbAllUserCard[GAME_PLAYER][MAX_COUNT], BYTE cbAllCount[GAME_PLAYER],const tagOutCard stTurnCard,WORD wMeChairID, WORD wOutUser,tagOutCard &stOutCard,size_t &nTime/*初始值必须是0*/,bool bFourTake=false);
	//构造条目
	tagSearchItem* ConstructItem(const BYTE cbAllUserCard[GAME_PLAYER][MAX_COUNT], BYTE cbAllCount[GAME_PLAYER],const tagOutCard stTurnCard,WORD wMeChairID, WORD wOutUser,bool bFourTake=false,bool bFixedBomb=false);
	//循环处理
	bool DealWithSearchItem(std::vector<tagSearchItem*> &vecpSearchItem,bool bFourTake=false,bool bFixedBankerBomb=false);
	//简化搜索
	size_t SimplySearchResult(const BYTE cbHandCardData[],BYTE cbHandCardCount,tagOutCard TurnCardResult,std::vector<tagOutCard> &vecPossibleResult,bool bFourTake=false,bool bFixedBomb=false);
	//简化搜索
	size_t SearchAllLink(const BYTE cbCardData[],BYTE cbCardCount,BYTE cbSameCardCount,std::vector<tagLinkCard> &vecLinkCard);
	//简化搜索
	size_t SimplySearchFastest(const BYTE cbHandCardData[],BYTE cbHandCardCount,std::vector<tagOutCard> &vecPossibleResult);
	//提出单牌
	BYTE DrawSingleCard(const std::vector<tagOutCard> &vecOutCard,BYTE cbSingleCard[MAX_COUNT]);
	//盟友判断
	bool IsAlly(WORD wMeChairID,WORD wID);

	tagSearchItem* AllocSearchItem();
	void FreeSearchItem(tagSearchItem* pItem);

	//打印扑克
	void PrintCardInfo(WORD wMeChairID,WORD wOutCardUser);
	//判断牌型是否是允许牌型
	bool IsValidType(BYTE Type,BYTE cardCount = 0);
	void SetppRule(DWORD rule);
	//拆分函数
private:
	//春天尝试
	bool TryChunTian(const BYTE cbTurnCardData[], BYTE cbTurnCardCount, WORD wOutCardUser, WORD wMeChairID, tagOutCard &stOutCard);
	//单人连续
	bool TrySingleOutAll(const BYTE cbTurnCardData[], BYTE cbTurnCardCount, WORD wOutCardUser, WORD wMeChairID, tagOutCard &stOutCard);
	//连续出牌
	bool TryOutAllCard(const BYTE cbTurnCardData[], BYTE cbTurnCardCount, WORD wOutCardUser, WORD wMeChairID, tagOutCard &stOutCard);
	//循环搜索
	bool TrySingleLoopSearch(const BYTE cbTurnCardData[], BYTE cbTurnCardCount, WORD wOutCardUser, WORD wMeChairID, tagOutCard &stOutCard);
	//循环搜索
	bool TryLoopSearch(const BYTE cbTurnCardData[], BYTE cbTurnCardCount, WORD wOutCardUser, WORD wMeChairID, tagOutCard &stOutCard);
	//经验出牌
	bool NormalOutCard(const BYTE cbTurnCardData[], BYTE cbTurnCardCount, WORD wOutCardUser, WORD wMeChairID, tagOutCard &stOutCard);
	//分析炸弹
	void GetAllBomCard(BYTE const cbHandCardData[], BYTE const cbHandCardCount, BYTE cbBomCardData[], BYTE &cbBomCardCount);
	//统计手牌数量
	void ReSetCardCount(BYTE cbAllUserCard[GAME_PLAYER][MAX_COUNT], BYTE cbAllCount[]);
};
//////////////////////////////////////////////////////////////////////////

#endif