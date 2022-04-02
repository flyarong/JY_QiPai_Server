//
// 作者: 隆元线
// Date: 2018/10/30
// Time: 14:48
// 麻将计算（从 lua 移植）
//

#ifndef HEARDER_MAJIANG_H
#define HEARDER_MAJIANG_H

#include <vector>
#include <string>
#include <map>

#include <algorithm>

typedef int MJ_PAI;
typedef unsigned int UINT;

// 一靠牌
struct PaiItem
{
	int type;			// 1 将  2 大对子 3 连子
	MJ_PAI pai_type;	// 牌类型  若type==3 则为起始位置的牌
};

// 胡牌结构
struct HuPaiData
{
	int jiang_num;
	int list_pos;
	std::vector<PaiItem> list;
};

typedef std::map<MJ_PAI, int>				PAI_MAP;
typedef std::map<MJ_PAI,std::string>		PG_MAP;
typedef std::map<std::string,bool>			KAI_GUAN;
typedef std::vector<PaiItem>				PAI_LIST;
typedef std::vector<HuPaiData>				HUPAI_LIST;
typedef std::map<std::string,int>			MULTI_TYPES;

template <typename K,typename V>
bool map_exists(const std::map<K, V> &m, const K &k)
{
	return m.find(k) != m.end();
}

// 胡牌信息
struct HuPaiInfo
{
	MULTI_TYPES hu_type_info;
	int mul;
	int geng_num;
};

// 玩家手上的牌信息
struct PlayerPaiInfo
{
	std::map<int,int> pai_map;
	std::map<int,std::string> pg_map;    // 碰杠信息： "peng","zg","wg","ag"
	int ding_que;
};

// 听牌信息
struct TingPaiInfo
{
	MJ_PAI ting_pai;
	HuPaiInfo hu_type_info;
};


PaiItem & ensure_pai_list(PAI_LIST &list, int index);
int get_geng_num(PAI_MAP &pai_map,PG_MAP &pg_map);
bool check_is_daduizi(PAI_LIST &list,KAI_GUAN &kaiguan);
bool check_is_jiangdui(PAI_LIST &list,PAI_MAP &pai_map,PG_MAP &pg_map,KAI_GUAN &kaiguan);
bool check_is_yaojiu(PAI_LIST &list,PG_MAP &pg_map,KAI_GUAN &kaiguan);
bool check_7d_hupai_info(PAI_MAP &pai_map,int all_num,KAI_GUAN &kaiguan , int maxShouPaiNum);
bool check_is_menqing(PG_MAP &pg_map,KAI_GUAN &kaiguan);
bool check_is_zhongzhang(PAI_MAP &pai_map,PG_MAP &pg_map,KAI_GUAN &kaiguan);
bool check_is_jingoudiao(PAI_MAP &pai_map,KAI_GUAN &kaiguan);
int tongji_pai_info(PAI_MAP &pai_map,std::map<int,int> * huaSe = nullptr);
int tongji_penggang_info(PG_MAP &pg_map,std::map<int,int> *huaSe = nullptr);

// ★注意： 没有处理 杠上花 和 杠上炮，需要在 lua 层处理
bool compute_hupai_info(PAI_MAP &pai_map,PG_MAP &pg_map,int all_num,int huaSe_count,
	KAI_GUAN &kaiguan,MULTI_TYPES &multi_types , int maxShouPaiNum,HuPaiInfo &outHupaiInfo);

void compute_nor_hupai_info(PAI_MAP &pai_map, MJ_PAI _s,
	int all_num, int jiang_num, PAI_LIST &list,
	int list_pos, HUPAI_LIST &info);

// 计算听牌信息。未听牌 返回 false
bool get_ting_info(PAI_MAP &pai_map,PG_MAP &pg_map,MJ_PAI must_que,
	KAI_GUAN &kaiguan,MULTI_TYPES &multi_types,int maxShouPaiNum,
	std::vector<TingPaiInfo> &out_ting_info);

// 计算胡牌信息
bool get_hupai_info(PAI_MAP &pai_map,PG_MAP &pg_map,MJ_PAI must_que,
	KAI_GUAN &kaiguan,MULTI_TYPES &multi_types,int maxShouPaiNum,HuPaiInfo &outHupaiInfo);

#endif