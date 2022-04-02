#ifndef _FENPAI_H_
#define _FENPAI_H_

#include <map>
#include <vector>
#include "pai_struct.h"
#include "pai_type_map.h"
#include "ddz_enums.h"

//#include "ddz_ai_util.hpp"

using namespace std;


struct FenpaiData;

typedef int (*GetPaiScoreFunc)(FenpaiData* fenpai_data,const pai_struct& pai);
typedef PaiTypeMap* (*CompareFenpaiFunc)(FenpaiData* fenpai_data,PaiTypeMap* left , PaiTypeMap * right);
typedef void (*GetFenpaiValueFunc)(FenpaiData* data,PaiTypeMap* pai);




class QueryMap;


struct FenpaiData
{
	map<int,int> sz_min_len;
	map<int,int> sz_max_len;

	CompareFenpaiFunc compare_fenpai;
	GetFenpaiValueFunc get_fenpai_value;
	GetPaiScoreFunc get_pai_score;

	QueryMap* query_map;    //分数查询表

	map<int, int> kaiguan;   //牌型开关
	map<int, map<int, int>> pai_map;   //坐位牌每家

	bool has_fenpai_result;
	PaiTypeMap fen_pai_result;


	map<int, PaiTypeMap> fen_pai; //最终分牌结果
	map<int, PaiTypeMap> xjbest_fenpai; //最优分牌结果

	int my_seat_id;  //我的坐位号
	int dz_seat_id;  //地主的坐位号
	int seat_count;




};





template <typename K,typename V>
bool is_map_exist(const map<K, V> &_map,const K &key)
{
	return _map.find(key) == _map.end() ? false : true;
}

int map_pai_num(map<int, int> &_pai_map, int _pai,int _default = 0);



int get_pre_seat_id(int seat_id, int seat_nu);
int get_next_seat_id(int seat_id, int seat_nu);



bool analyse_sandai(
		FenpaiData* data, 
		PaiTypeMap& fen_pai_out,
		PaiTypeMap &fen_pai,
		map<int, int> &kaiguan 
		);


void analyse_pai(
		FenpaiData* data, 
		int seat_id,
		map<int,int>& pai_map,
		PaiTypeMap& fen_pai_out,
		map<int,int>& kaiguan
		);




bool analyse_pai_other(FenpaiData* data,
	PaiTypeMap& fen_pai_out,
	PaiTypeMap& fen_pai,

	map<int, int> &pai_map,
	map<int, int> &kaiguan);





// by cl:
bool extract_sandai_daipai(
		FenpaiData* data,
		PaiTypeMap& fen_pai_out,
		PaiTypeMap& fen_pai,
		vector<pai_struct>& sanda_info,
		int pos,
		map<int,int>& kaiguan);


// by cl
bool extract_bomb_daipai(
		FenpaiData* data,
		PaiTypeMap& fen_pai_out,
		const PaiTypeMap& fen_pai,
		vector<pai_struct>& sanda_info,
		int pos,
		map<int,int>& kaiguan);
	

// by cl 
bool extract_feiji_daipai(

		FenpaiData* data,
		PaiTypeMap& fen_pai_out,

		const PaiTypeMap& fen_pai,
		vector<pai_struct>& sanda_info,
		int pos,
		map<int,int>& kaiguan);

bool extract_rocket_daipai(
		FenpaiData* data,
		PaiTypeMap& fen_pai_out,

		const PaiTypeMap& fen_pai,
		vector<pai_struct>& sanda_info,
		int pos,
		map<int,int>& kaiguan);


bool extract_pair_daipai(
		FenpaiData* data,
		PaiTypeMap& fen_pai_out,

		const PaiTypeMap& fen_pai,
		vector<pai_struct>& sanda_info,
		int pos,
		map<int,int>& kaiguan);


std::pair<int,int> check_is_lianxu(std::map<int,int>& pai_map,int s,int len,int count,int limit);

void add_sz(PaiTypeMap& data,int s,int len,int type);
void reduce_sz(PaiTypeMap& data, int type);

void default_get_fenpai_value(FenpaiData* data, PaiTypeMap* fen_pai);
PaiTypeMap * default_compare_fenpai(FenpaiData*,PaiTypeMap *fen_pai_1, PaiTypeMap *fen_pai_2);

std::pair<int,int> check_is_xiajiao_special(FenpaiData* data,int seat_id,PaiTypeMap* fenpai,bool use_sure=false);
void get_fenpai_score(FenpaiData* data,PaiTypeMap* fenpai,int* score,int* shoushu,int* bomb_count);
int get_score_by_paitype(FenpaiData* data,const pai_struct& pai);
int query_map_get_pai_is_bigger_in_unkown(QueryMap* query_map,int seat_id,const PaiStruct& pai);

void analysis_pai_ctrl_type(FenpaiData* data,int type,std::vector<pai_struct>& pai,int seat_id,bool use_sure, int* status,int* ctrl,int* no_ctrl);

void get_extraNozhanshou_sum(FenpaiData* data,int type,std::vector<pai_struct>& pai,int seat_id,bool use_sure,int* extract_no_zhanshou,int* ctrl,int* no_ctrl);


void get_sure_zhanshou_data(FenpaiData* data,int type,std::vector<pai_struct>& pai,int seat_id,int* ctrl,int* no_ctrl);


void get_zhanshou_data(FenpaiData* data,int type,std::vector<pai_struct>& pai,int seat_id,int* ctrl,int* no_ctrl);


/* need lyx begin */ 
void fenpai_for_all(FenpaiData* data,std::map<int,std::map<int,int>>& pais,std::map<int,int>& sz_min,std::map<int,int>& sz_max,std::map<int,int> &kaiguan,int my_seat_id,int dz_seat_id,int seat_count);


void fenpai_for_one(FenpaiData* data,std::map<int,std::map<int,int>>& pais,std::map<int,int>& sz_min,std::map<int,int>& sz_max,std::map<int,int> &kaiguan,int my_seat_id,int dz_seat_id,int seat_count);


std::pair<int,bool> query_map_get_pai_score(QueryMap* query_map,int lseat_id, const PaiStruct& pai,bool use_all_unkown=false);

void destroy_query_map(QueryMap* query_map);




#endif /*_FENPAI_H_*/
