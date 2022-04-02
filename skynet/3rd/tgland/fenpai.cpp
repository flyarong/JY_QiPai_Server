#include "fenpai.h"
#include "query_map.h"
#include <iso646.h>
#include <math.h>
#include <algorithm>
#include "ddz_ai_util.hpp"


bool pai_struct_face_greater_cmp_func(const pai_struct& left,const pai_struct& right)
{
	return pai_struct_get_face(left)> pai_struct_get_face(right);
}

int get_pre_seat_id(int seat_id, int seat_nu)
{
	int pre_seat_id = seat_id - 1;

	if (pre_seat_id<=0)
	{
		pre_seat_id += seat_nu;
	}

	return pre_seat_id;
}

int get_next_seat_id(int seat_id, int seat_nu)
{
	int next_seat_id = seat_id + 1;
	if (next_seat_id > seat_nu)
	{
		next_seat_id -= seat_nu;
	}

	return next_seat_id;
}


int query_map_get_pai_is_bigger_in_unkown(QueryMap* query_map,int seat_id,const PaiStruct& pai)
{

	int pai_card_nu= pai_struct_get_card_nu(pai);

	int op_max_card_nu= query_map->m_opMaxCardNu[seat_id];

	TypeFaceExistMap* unkown_table=&query_map->m_opUnkownExist[seat_id];

	int pai_serial = pai_struct_get_serial(pai);
	int pai_type = pai_struct_get_type(pai);

	int pai_face = pai_struct_get_face(pai);

	if(op_max_card_nu< pai_card_nu)
	{
		return 0;
	}


	if(pai_type == 14 )
	{
		return 0;
	}

	int bigger_nu= unkown_table->getBiggerCardNu(pai_type,pai_serial,pai_face);

	return bigger_nu;
}

std::pair<int,bool> query_map_get_pai_score(QueryMap* query_map,int lseat_id, const PaiStruct& pai,bool use_all_unkown/*=false*/)
{
	//std::string str_pai= pai_struct_tostring(pai);
	//printf("pai=%s\n", str_pai.c_str());
	int pai_type = pai_struct_get_type(pai);
	int pai_serial=pai_struct_get_serial(pai);
	int pai_face=pai_struct_get_face(pai);


	int seat_id = SEAT_L2C(lseat_id);

	if(pai.type ==0)
	{
		return std::make_pair(0,false);
	}

	TypeFaceExistMap* op_table=NULL;

	if(use_all_unkown) 
	{
		op_table=&query_map->m_allIsOpCardTypeExist[seat_id];
	}
	else 
	{
		op_table=&query_map->m_opCardTypeExist[seat_id];
	}


	TypeFaceExistMap* all_table=&query_map->m_allCardExit;
	TypeFaceExistMap* my_table=&query_map->m_cardTypeExist[seat_id];


	bool biggest=false;

	if(pai.type == 13)
	{
		int bomb_nu=all_table->getBiggerEqCardNu(pai_type,pai_serial,DdzCard::Three);
		int bigger_nu= op_table->getBiggerCardNu(pai_type,pai_serial,pai_face);

		if(bigger_nu == 0 )
		{
			return std::make_pair(7+bomb_nu-bigger_nu,true);
		}
		else 
		{
			return std::make_pair(7+bomb_nu-bigger_nu,false);
		}

	}

	if(pai.type ==14)
	{
		int bomb_nu=all_table->getBiggerEqCardNu(pai_type,pai_serial,DdzCard::Three);
		return std::make_pair(7+bomb_nu,true);
	
	}


	int bigger_nu = all_table->getBiggerCardNu(pai_type,pai_serial,pai_face);
	//printf("bigger_nu=%d,pai_type=%d,pai_serial=%d,pai_face=%d\n", bigger_nu, pai_type, pai_serial, pai_face);
	int score=7-bigger_nu;
	bool has_eq=false;


	if(seat_id != query_map->m_dzSeatId )
	{
		int op_bigger_nu=op_table->getBiggerCardNu(pai_type,pai_serial,pai_face);
		if(op_bigger_nu == 0 )
		{
			if(op_table->getTypeFaceNu(pai_type,pai_serial,pai_face) ==0 )
			{
				return std::make_pair(7,true);
			}

			return std::make_pair(7,false);
		}
	}
	else 
	{
		bool has=false;
		bool is_biggest=true;
		for(auto& iter:query_map->m_landOpExist)
		{
			int big_nu= (iter).getBiggerCardNu(pai_type,pai_serial,pai_face);

			if(big_nu > 0 )
			{
				has=true;
				is_biggest=false;
				break;
			}
			else 
			{
				if((iter).getTypeFaceNu(pai_type,pai_serial,pai_face) >0 )
				{
					is_biggest=false;
				}
			}
		}
	
		if(!has )
		{
			return std::make_pair(7,is_biggest);
		}
	}

	return std::make_pair(score,false);


}




int map_pai_num(map<int, int> &_pai_map, int _pai,int _default /*= 0*/)
{
	auto it = _pai_map.find(_pai);
	return it == _pai_map.end() ? _default : it->second;
}


// by lyx: 分析三带
bool analyse_sandai(
		FenpaiData* data,
		PaiTypeMap& fen_pai_out,
		PaiTypeMap &fen_pai,
		map<int, int> &kaiguan)
{
	int count = 0;
	vector<pai_struct> sanda_info;


	auto fj_info=fen_pai.pai[12];
	auto sz_info=fen_pai.pai[3];
	auto zd_info=fen_pai.pai[13];

	// 能带完的情况
	fen_pai.pai[12]=vector<pai_struct>();
	fen_pai.pai[3]=vector<pai_struct>();
	fen_pai.pai[13]=vector<pai_struct>();
	

	//提取最大队
	
	if ( fen_pai.pai[2].size() > 0  ) { 
		auto pai_data=fen_pai.pai[2][0];
		fen_pai.pai[2].erase(fen_pai.pai[2].begin());
		sanda_info.push_back(pai_data);
	}


	//提取王炸
	auto it = fen_pai.pai.find(14);
	if ( it != fen_pai.pai.end() && it->second.size()>0 ) { 
		sanda_info.push_back(it->second[0]);
		fen_pai.pai.erase(it);
	}

	//提取炸弹
	int bomb_nu =0;
	for ( auto &pai_data : zd_info ) 
	{
		if ( bomb_nu <=2 ) 
		{ 
			sanda_info.push_back(pai_data);
			bomb_nu=bomb_nu + 1;
		}
		else 
		{
			fen_pai.pai[13].push_back(pai_data);
		}
	}


	//提取三张
	for (std::size_t i=0;i<sz_info.size();++i) { 

		sanda_info.push_back(sz_info[i]);

		if ( i == sz_info.size() - 1 )  
			sanda_info.back().other1 = 1;
		else 
			sanda_info.back().other1 = 0;
	}

	//提取飞机
	for ( auto &pai_data : fj_info )
	{
		sanda_info.push_back(pai_data);
	}

	/*
	for( auto& i:sanda_info ) 
	{
		printf("%d ",i.type);
	}
	printf("\n");
	*/

	

	return extract_sandai_daipai(data,fen_pai_out,fen_pai,sanda_info,0,kaiguan);
}


inline pai_struct gen_pai(int _type,std::vector<int> _pai)
{
	pai_struct ps;
	ps.type = _type;
	for(std::size_t i=0;i<_pai.size() && i<7;++i)
		ps.pai[i] = _pai[i];

	return ps;
}

// by lyx: 
bool analyse_pai_other(	
		FenpaiData* data,
		PaiTypeMap& fen_pai_out,
		PaiTypeMap& fen_pai,
		map<int,int>& pai_map,
		map<int, int>& kaiguan)
{
	//提取 王炸
	
	if (map_pai_num(pai_map,16) and map_pai_num(pai_map,17)) 
	{
		fen_pai.pai[14] = {pai_struct_ctor_rocket()};
	}
	else
	{
		for (int i=17;i>=16; --i) 
		{
			if (map_pai_num(pai_map,i) == 1)
			{
				paitypemap_add_danpai(&fen_pai,i);
			}
		}
	}

	//
	int sd_count=0;
	for (auto &item:pai_map ) {
		if ( item.second==3 ) {
			sd_count=sd_count+1;
		}
	}

	fen_pai_out = fen_pai;
	int i=15;
	while( i>2 ) {
		int _num = map_pai_num(pai_map,i);
		if ( _num > 0 ) 
		{
			//提取炸弹
			if (  _num==4 ) 
			{
				paitypemap_add_bomb(&fen_pai,i);
			}
			//提取三带或飞机
			else if( _num==3 ) 
			{
				paitypemap_add_sanzhang(&fen_pai,i);
			}
			//提取对子
			else if( _num==2 ) 
			{
				paitypemap_add_duizhi(&fen_pai,i);
			}
			//提取单牌    
			else if( _num==1 ) 
			{            
				paitypemap_add_danpai(&fen_pai,i);
			}
		}
		--i;
	}

	return analyse_sandai(data,fen_pai_out,fen_pai,kaiguan);
}

// by lyx:
bool chang_value_by_lianxu(	map<int,int> &pai_map,
							int s,
							int len,
							int count)
{
    for (int k=s;k<s+len; ++k) 
	{

        if ( count<0 and map_pai_num(pai_map,k)<-count ) 
            return false;

        pai_map[k] = map_pai_num(pai_map,k)+count;
    }


	return true;
}

PaiTypeMap * default_compare_fenpai(FenpaiData* data,PaiTypeMap *fen_pai_1,PaiTypeMap *fen_pai_2)
{

	if(!fen_pai_1 && !fen_pai_2)
	{
		return NULL;
	}

	if(!fen_pai_1 )
	{
		return fen_pai_2;
	}

	if(!fen_pai_2)
	{
		return fen_pai_1;
	}


	if(fen_pai_1->xiajiao>0 && fen_pai_2->xiajiao==0 )
	{
		return fen_pai_1;
	}


	if(fen_pai_1->xiajiao==0 &&fen_pai_2->xiajiao>0 )
	{
		return fen_pai_2;
	}


	if( fen_pai_1->xiajiao==0 && fen_pai_2->xiajiao==0 )
	{
		if( fen_pai_1->no_xiajiao_score>fen_pai_2->no_xiajiao_score )
		{
			return fen_pai_1;
		}

		if( fen_pai_1->no_xiajiao_score<fen_pai_2->no_xiajiao_score )
		{
			return fen_pai_2;
		} 
	}


	//炸弹数量
	if( fen_pai_1->bomb_count>fen_pai_2->bomb_count )
	{
		return fen_pai_1;
	}

	if( fen_pai_1->bomb_count<fen_pai_2->bomb_count )
	{
		return fen_pai_2;
	}

	//下叫类型
	if( fen_pai_1->xiajiao<fen_pai_2->xiajiao )
	{
		return fen_pai_1;
	} 

	if( fen_pai_1->xiajiao>fen_pai_2->xiajiao )
	{
		return fen_pai_2;
	}

	//分数
	if( fen_pai_1->score>fen_pai_2->score )
	{
		return fen_pai_1;
	}

	if( fen_pai_1->score<fen_pai_2->score )
	{
		return fen_pai_2;
	}


	if( fen_pai_1->shoushu<fen_pai_2->shoushu )
	{
		return fen_pai_1;
	} 

	if( fen_pai_1->shoushu>fen_pai_2->shoushu )
	{
		return fen_pai_2;
	}

	return fen_pai_2;
}

void get_fenpai_value(FenpaiData* data,PaiTypeMap *fen_pai)
{

	if(data->get_fenpai_value)
	{
		data->get_fenpai_value(data,fen_pai);
	}
	else 
	{
		default_get_fenpai_value(data,fen_pai);
	}
}


void default_get_fenpai_value(FenpaiData* data,PaiTypeMap* fen_pai)
{
	int score,shoushu,bomb_count;
	get_fenpai_score(data,fen_pai,&score,&shoushu,&bomb_count);

	std::pair<int,int> xiao_jiao_info=check_is_xiajiao_special(data,data->my_seat_id,fen_pai);


	fen_pai->score=score;
	fen_pai->shoushu=shoushu;
	fen_pai->bomb_count=bomb_count;

	fen_pai->xiajiao=xiao_jiao_info.first;
	fen_pai->no_xiajiao_score=xiao_jiao_info.second;
}


void get_fenpai_value_by_realxj(FenpaiData* data,PaiTypeMap* fen_pai)
{

	int score,shoushu,bomb_count;
	get_fenpai_score(data,fen_pai,&score,&shoushu,&bomb_count);

	std::pair<int,int> xiao_jiao_info=check_is_xiajiao_special(data,data->my_seat_id,fen_pai,true);

	fen_pai->score=score;
	fen_pai->shoushu=shoushu;
	fen_pai->bomb_count=bomb_count;
	fen_pai->xiajiao=xiao_jiao_info.first;
	fen_pai->no_xiajiao_score=xiao_jiao_info.second;
}

PaiTypeMap * xiaojiaobest_compare_fenpai(FenpaiData* data,PaiTypeMap *fen_pai_1,PaiTypeMap *fen_pai_2)
{

	if(!fen_pai_1 && !fen_pai_2)
	{
		return NULL;
	}

	if(!fen_pai_1 )
	{
		return fen_pai_2;
	}

	if(!fen_pai_2)
	{
		return fen_pai_1;
	}


	if(fen_pai_1->xiajiao>0 && fen_pai_2->xiajiao==0 )
	{
		return fen_pai_1;
	}


	if(fen_pai_1->xiajiao==0 &&fen_pai_2->xiajiao>0 )
	{
		return fen_pai_2;
	}


	if( fen_pai_1->xiajiao==0 && fen_pai_2->xiajiao==0 )
	{
		if( fen_pai_1->no_xiajiao_score>fen_pai_2->no_xiajiao_score )
		{
			return fen_pai_1;
		}

		if( fen_pai_1->no_xiajiao_score<fen_pai_2->no_xiajiao_score )
		{
			return fen_pai_2;
		} 
	}

	if(fen_pai_1->xiajiao>0 && fen_pai_2->xiajiao>0 )
	{
		if(fen_pai_1->xiajiao<fen_pai_2->xiajiao)
		{
			return fen_pai_1;
		}

		if(fen_pai_1->xiajiao>fen_pai_2->xiajiao)
		{
			return fen_pai_2;
		}
	}



	//炸弹数量
	if( fen_pai_1->bomb_count>fen_pai_2->bomb_count )
	{
		return fen_pai_1;
	}

	if( fen_pai_1->bomb_count<fen_pai_2->bomb_count )
	{
		return fen_pai_2;
	}

	//下叫类型
	if( fen_pai_1->xiajiao<fen_pai_2->xiajiao )
	{
		return fen_pai_1;
	} 

	if( fen_pai_1->xiajiao>fen_pai_2->xiajiao )
	{
		return fen_pai_2;
	}

	//分数
	if( fen_pai_1->score>fen_pai_2->score )
	{
		return fen_pai_1;
	}

	if( fen_pai_1->score<fen_pai_2->score )
	{
		return fen_pai_2;
	}


	if( fen_pai_1->shoushu<fen_pai_2->shoushu )
	{
		return fen_pai_1;
	} 

	if( fen_pai_1->shoushu>fen_pai_2->shoushu )
	{
		return fen_pai_2;
	}

	return fen_pai_2;
}





// by lyx:
PaiTypeMap* compare_fenpai(FenpaiData * fenpai_data,PaiTypeMap *fen_pai_1,PaiTypeMap *fen_pai_2)
{
	if( fen_pai_1 and  fen_pai_1->score == UNKOWN_PAI_TYPE_SCORE ) {
		get_fenpai_value(fenpai_data,fen_pai_1);
	}
	if( fen_pai_2 and fen_pai_2->score == UNKOWN_PAI_TYPE_SCORE) {
		get_fenpai_value(fenpai_data,fen_pai_2);
	}

	if( fenpai_data->compare_fenpai ) {
		return fenpai_data->compare_fenpai(fenpai_data,fen_pai_1,fen_pai_2);
	}

	return default_compare_fenpai(fenpai_data,fen_pai_1,fen_pai_2);
}



// by cl: 

bool extract_sandai_daipai( 
		FenpaiData* data,
		PaiTypeMap& fen_pai_out,
		PaiTypeMap& fen_pai,
		vector<pai_struct>& sanda_info,
		int pos,
		map<int,int>& kaiguan)
{
	if( pos >= (int)sanda_info.size() ) 
	{
		fen_pai_out= fen_pai;
		return true;
	}

	pai_struct& pai_info=sanda_info[pos];

	if(pai_info.type == 12)
	{
		return extract_feiji_daipai(data,fen_pai_out,fen_pai,sanda_info,pos,kaiguan);
	}

	if(pai_info.type == 13 )
	{
		return extract_bomb_daipai(data,fen_pai_out,fen_pai,sanda_info,pos,kaiguan);
	}


	if(pai_info.type ==14 ) 
	{
		return extract_rocket_daipai(data,fen_pai_out,fen_pai,sanda_info,pos,kaiguan);
	}


	if(pai_info.type == 2) 
	{
		return extract_pair_daipai(data,fen_pai_out,fen_pai,sanda_info,pos,kaiguan);
	}


	int pai_info_face=pai_struct_get_face(pai_info);



	std::vector<PaiTypeMap*> ret_table;

	//折成 1+1+1 
	{
		PaiTypeMap* fen_pai_1_1_1=new PaiTypeMap; 
		*fen_pai_1_1_1=fen_pai;

		paitypemap_add_danpai(fen_pai_1_1_1, pai_info_face);
		paitypemap_add_danpai(fen_pai_1_1_1, pai_info_face);
		paitypemap_add_danpai(fen_pai_1_1_1, pai_info_face);
	

		std::sort(fen_pai_1_1_1->pai[1].begin(),fen_pai_1_1_1->pai[1].end(),pai_struct_face_greater_cmp_func);

		if(extract_sandai_daipai(data,*fen_pai_1_1_1,*fen_pai_1_1_1,sanda_info,pos+1,kaiguan))
		{
			ret_table.push_back(fen_pai_1_1_1);
		}
		else 
		{
			delete fen_pai_1_1_1;
		}
	}

	//折成 2+1 
	{
		PaiTypeMap* fen_pai_2_1 =new PaiTypeMap;
		*fen_pai_2_1=fen_pai;

		fen_pai_2_1->pai[1].push_back(pai_struct_ctor_daipai(pai_struct_get_face(pai_info)));
		fen_pai_2_1->pai[2].push_back(pai_struct_ctor_duizhi(pai_struct_get_face(pai_info)));

		std::sort(fen_pai_2_1->pai[1].begin(),fen_pai_2_1->pai[1].end(),pai_struct_face_greater_cmp_func);
		std::sort(fen_pai_2_1->pai[2].begin(),fen_pai_2_1->pai[2].end(),pai_struct_face_greater_cmp_func);

		if(extract_sandai_daipai(data,*fen_pai_2_1,*fen_pai_2_1,sanda_info,pos+1,kaiguan))
		{
			ret_table.push_back(fen_pai_2_1);
		}
		else 
		{
			delete fen_pai_2_1;
		}
	}

	//三不带的情况
	if(kaiguan[3] ==1 or pai_info.other1)
	{
		PaiTypeMap* fen_pai0=new PaiTypeMap; 
		*fen_pai0=fen_pai;

		fen_pai0->pai[3].push_back(pai_struct_ctor_sanzhang(pai_struct_get_face(pai_info)));
		std::sort(fen_pai0->pai[3].begin(),fen_pai0->pai[3].end(),pai_struct_face_greater_cmp_func);
		if(extract_sandai_daipai(data,*fen_pai0,*fen_pai0,sanda_info,pos+1,kaiguan))
		{
			ret_table.push_back(fen_pai0);
		}
		else 
		{
			delete fen_pai0;
		}
	}

	//带一的情况 
	{
		PaiTypeMap* fen_pai1=new PaiTypeMap; 
		*fen_pai1=fen_pai;

		std::vector<int> danpai_list= remove_danpai(fen_pai1,1,pai_info_face,pai_info_face);
		if(danpai_list.size()>0)
		{
			fen_pai1->pai[4].push_back(pai_struct_ctor_sandai1(pai_struct_get_face(pai_info),danpai_list[0]));
			if(extract_sandai_daipai(data,*fen_pai1,*fen_pai1,sanda_info,pos+1,kaiguan))
			{
				ret_table.push_back(fen_pai1);
			}
			else 
			{
				delete fen_pai1;
			}
		}
		else 
		{
			delete fen_pai1;
		}

	}

	//带二的情况
	
	if(kaiguan[5]==1)
	{
		PaiTypeMap* fen_pai2=new PaiTypeMap; 
		*fen_pai2=fen_pai;

		std::vector<int> dui_zhi_list= remove_duizhi(fen_pai2,1,pai_info_face,pai_info_face);
		if(dui_zhi_list.size()>0) 
		{
			fen_pai2->pai[5].push_back(pai_struct_ctor_sandai2(pai_struct_get_face(pai_info),dui_zhi_list[0]));

			if(extract_sandai_daipai(data,*fen_pai2,*fen_pai2,sanda_info,pos+1,kaiguan))
			{
				ret_table.push_back(fen_pai2);
			}
			else 
			{
				delete fen_pai2;
			}
		}
		else 
		{
			delete fen_pai2;
		}
	}


	if(ret_table.size()==0)
	{
		return false;
	}

	PaiTypeMap* best=NULL;
	for(int i=0;i<(int)ret_table.size();i++)
	{
		best=compare_fenpai(data,best,ret_table[i]);
	}
	fen_pai_out = *best;

	for(int i=0;i<(int)ret_table.size();i++)
	{
		delete ret_table[i];
	}


	return true;
}



bool extract_bomb_daipai(
		FenpaiData* data,
		PaiTypeMap& fen_pai_out,
		const PaiTypeMap& fen_pai,
		vector<pai_struct>& sanda_info,
		int pos,

		map<int,int>& kaiguan)
{
	pai_struct& pai_info=sanda_info[pos];

	int pai_face = pai_struct_get_face(pai_info);

	std::vector<PaiTypeMap*> ret_table;

	//折分为1+1+1+1 
	{
		PaiTypeMap* fen_pai_1_1_1_1 = new PaiTypeMap; 
		*fen_pai_1_1_1_1=fen_pai;

		paitypemap_add_danpai(fen_pai_1_1_1_1,pai_face);
		paitypemap_add_danpai(fen_pai_1_1_1_1,pai_face);
		paitypemap_add_danpai(fen_pai_1_1_1_1,pai_face);
		paitypemap_add_danpai(fen_pai_1_1_1_1,pai_face);

		std::sort(fen_pai_1_1_1_1->pai[1].begin(),fen_pai_1_1_1_1->pai[1].end(),pai_struct_face_greater_cmp_func);

		if(extract_sandai_daipai(data,*fen_pai_1_1_1_1,*fen_pai_1_1_1_1,sanda_info,pos+1,kaiguan))
		{
			ret_table.push_back(fen_pai_1_1_1_1);
		}
		else 
		{
			delete fen_pai_1_1_1_1;
		}
	}

	//折分为2+1+1 
	{
		PaiTypeMap* fen_pai_2_1_1 =new PaiTypeMap;
		*fen_pai_2_1_1=fen_pai;

		paitypemap_add_danpai(fen_pai_2_1_1,pai_face);
		paitypemap_add_danpai(fen_pai_2_1_1,pai_face);
		paitypemap_add_duizhi(fen_pai_2_1_1,pai_face);
		std::sort(fen_pai_2_1_1->pai[1].begin(),fen_pai_2_1_1->pai[1].end(),pai_struct_face_greater_cmp_func);
		std::sort(fen_pai_2_1_1->pai[2].begin(),fen_pai_2_1_1->pai[2].end(),pai_struct_face_greater_cmp_func);
		if(extract_sandai_daipai(data,*fen_pai_2_1_1,*fen_pai_2_1_1,sanda_info,pos+1,kaiguan))
		{
			ret_table.push_back(fen_pai_2_1_1);
		}
		else 
		{
			delete fen_pai_2_1_1;
		}
	}

	//折分2+2 
	{
		PaiTypeMap* fen_pai_2_2=new PaiTypeMap; 
		*fen_pai_2_2 =fen_pai;
		paitypemap_add_duizhi(fen_pai_2_2,pai_face);
		paitypemap_add_duizhi(fen_pai_2_2,pai_face);
		std::sort(fen_pai_2_2->pai[2].begin(),fen_pai_2_2->pai[2].end(),pai_struct_face_greater_cmp_func);

		if(extract_sandai_daipai(data,*fen_pai_2_2,*fen_pai_2_2,sanda_info,pos+1,kaiguan)) 
		{
			ret_table.push_back(fen_pai_2_2);
		}
		else 
		{
			delete fen_pai_2_2;
		}
	}
	
	//折分3+1 
	{
		PaiTypeMap* fen_pai_3_1=new PaiTypeMap; 
		*fen_pai_3_1=fen_pai;

		paitypemap_add_sanzhang(fen_pai_3_1,pai_face);
		paitypemap_add_danpai(fen_pai_3_1,pai_face);

		std::sort(fen_pai_3_1->pai[3].begin(),fen_pai_3_1->pai[3].end(),pai_struct_face_greater_cmp_func);
		std::sort(fen_pai_3_1->pai[1].begin(),fen_pai_3_1->pai[1].end(),pai_struct_face_greater_cmp_func);

		if(extract_sandai_daipai(data,*fen_pai_3_1,*fen_pai_3_1,sanda_info,pos+1,kaiguan))
		{
			ret_table.push_back(fen_pai_3_1);
		}
		else 
		{
			delete fen_pai_3_1;
		}
	}

	//不带的情况
	{
		PaiTypeMap* fen_pai0=new PaiTypeMap; 
		*fen_pai0=fen_pai;

		paitypemap_add_bomb(fen_pai0,pai_face);
		std::sort(fen_pai0->pai[4].begin(),fen_pai0->pai[4].end(),pai_struct_face_greater_cmp_func);

		if(extract_sandai_daipai(data,*fen_pai0,*fen_pai0,sanda_info,pos+1,kaiguan))
		{
			ret_table.push_back(fen_pai0);
		}
		else 
		{
			delete fen_pai0;
		}
	}

	//带单的情况 
	if(kaiguan[8]==1)
	{
		PaiTypeMap* fen_pai1=new PaiTypeMap; 
		*fen_pai1=fen_pai;

		std::vector<int> danpai_list= remove_danpai(fen_pai1,2,pai_face,pai_face);

		if(danpai_list.size()>=2)
		{
			paitypemap_add_sidai_2dan(fen_pai1, pai_face,(danpai_list[0]),(danpai_list[1]));

			if(extract_sandai_daipai(data,*fen_pai1,*fen_pai1,sanda_info,pos+1,kaiguan))
			{
				ret_table.push_back(fen_pai1);
			}
			else 
			{
				delete fen_pai1;
			}
		}
		else 
		{
			delete fen_pai1;
		}
	}


	//带对的情况
	if(kaiguan[9]==1)
	{
		PaiTypeMap* fen_pai2=new PaiTypeMap;
		*fen_pai2=fen_pai;

		std::vector<int> duipai_list=remove_duizhi(fen_pai2,2,pai_face,pai_face);
		if(duipai_list.size()>=2)
		{
			paitypemap_add_sidai_2dui(fen_pai2, pai_face,(duipai_list[0]),(duipai_list[1]));

			if(extract_sandai_daipai(data,*fen_pai2,*fen_pai2,sanda_info,pos+1,kaiguan))
			{
				ret_table.push_back(fen_pai2);
			}
			else 
			{
				delete fen_pai2;
			}
		}
		else 
		{
			delete fen_pai2;
		}
	}


	if(ret_table.size()==0)
	{
		return false;
	}

	PaiTypeMap* best=NULL;
	for(int i=0;i<(int)ret_table.size();i++)
	{
		best=compare_fenpai(data,best,ret_table[i]);
	}
	fen_pai_out = *best;

	for(int i=0;i<(int)ret_table.size();i++)
	{
		delete ret_table[i];
	}



	return true;



}


bool extract_feiji_daipai(
		FenpaiData* data,
		PaiTypeMap& fen_pai_out,
		const PaiTypeMap& fen_pai,
		vector<pai_struct>& sanda_info,
		int pos,
		map<int,int>& kaiguan)
{

	std::vector<PaiTypeMap*> ret_table;
	pai_struct& pai_info=sanda_info[pos];

	int pai_face = pai_struct_get_face(pai_info);
	int pai_serial=pai_struct_get_serial(pai_info);
	int pai_face_from=  pai_struct_get_face_from(pai_info);
	int pai_face_to = pai_struct_get_face_to(pai_info);



	// 不带的情况
	if(kaiguan[3]==1)
	{
		PaiTypeMap* fenpai0= new PaiTypeMap;
		*fenpai0=fen_pai;


		paitypemap_add_feiji(fenpai0,pai_face_from,pai_face_to);
		if(extract_sandai_daipai(data,*fenpai0,*fenpai0,sanda_info,pos+1,kaiguan))
		{
			ret_table.push_back(fenpai0);
		}
		else 
		{
			delete fenpai0;
		}
	}

	//带1的情况 
	{
		PaiTypeMap* fenpai1 = new PaiTypeMap;
		*fenpai1=fen_pai;

		std::vector<int> danpai_list=remove_danpai(fenpai1,pai_serial,pai_face_from,pai_face_to);
		//printf("danpai_list_size=%ld,pai_serial=%d\n", danpai_list.size(), pai_serial);
		if((int)danpai_list.size()>=pai_serial)
		{
			paitypemap_add_feiji_dan(fenpai1,pai_face_from,pai_face_to,danpai_list);

			if(extract_sandai_daipai(data,*fenpai1,*fenpai1,sanda_info,pos+1,kaiguan))
			{
				ret_table.push_back(fenpai1);
			}
			else 
			{
				delete fenpai1;
			}
		}
		else 
		{
			delete fenpai1;
		}

	}

	//带2的情况
	if(kaiguan[5]==1)
	{
		PaiTypeMap* fenpai2 = new PaiTypeMap;
		*fenpai2=fen_pai;

		std::vector<int> duizhi_list=remove_duizhi(fenpai2,pai_serial,pai_face_from,pai_face_to);
		if((int)duizhi_list.size()>=pai_serial)
		{
			paitypemap_add_feiji_dui(fenpai2,pai_face_from,pai_face_to, duizhi_list);
			if(extract_sandai_daipai(data,*fenpai2,*fenpai2,sanda_info,pos+1,kaiguan))
			{
				ret_table.push_back(fenpai2);
			}
			else 
			{

				delete fenpai2;
			}
		}
		else 
		{
				delete fenpai2;
		}
	}


	if(ret_table.size()==0)
	{
		return false;
	}

	PaiTypeMap* best=NULL;
	for(int i=0;i<(int)ret_table.size();i++)
	{
		best=compare_fenpai(data,best,ret_table[i]);
	//	print_paitypemap(*ret_table[i]);
	}
	fen_pai_out = *best;

	for(int i=0;i<(int)ret_table.size();i++)
	{
		delete ret_table[i];
	}



	return true;
}

bool extract_rocket_daipai(
		FenpaiData* data,
		PaiTypeMap& fen_pai_out,
		const PaiTypeMap& fen_pai,
		vector<pai_struct>& sanda_info,
		int pos,
		map<int,int>& kaiguan)
{
	std::vector<PaiTypeMap*> ret_table;

	//不拆王
	{
		PaiTypeMap* fenpai0=new PaiTypeMap ;
		*fenpai0 = fen_pai;

		paitypemap_add_rocket(fenpai0);

		if(extract_sandai_daipai(data,*fenpai0,*fenpai0,sanda_info,pos+1,kaiguan))
		{
			ret_table.push_back(fenpai0);
		}
		else 
		{
			delete fenpai0;
		}

	}


	//分成两张单牌
	{
		PaiTypeMap* fenpai1=new PaiTypeMap;
		*fenpai1=fen_pai;

		paitypemap_add_danpai(fenpai1,DdzCard::L_Wang);
		paitypemap_add_danpai(fenpai1,DdzCard::B_Wang);
		std::sort(fenpai1->pai[1].begin(),fenpai1->pai[1].end(),pai_struct_face_greater_cmp_func);

		if(extract_sandai_daipai(data,*fenpai1,*fenpai1,sanda_info,pos+1,kaiguan))
		{
			ret_table.push_back(fenpai1);
		}
		else 
		{
			delete fenpai1;
		}

	}



	if(ret_table.size()==0)
	{
		return false;
	}

	PaiTypeMap* best=NULL;
	for(int i=0;i<(int)ret_table.size();i++)
	{
		best=compare_fenpai(data,best,ret_table[i]);
	}
	fen_pai_out = *best;

	for(int i=0;i<(int)ret_table.size();i++)
	{
		delete ret_table[i];
	}



	return true;
}


bool extract_pair_daipai(
		FenpaiData* data,
		PaiTypeMap& fen_pai_out,
		const PaiTypeMap& fen_pai,
		vector<pai_struct>& sanda_info,
		int pos,
		map<int,int>& kaiguan)
{
	std::vector<PaiTypeMap*> ret_table;
	pai_struct& pai_info=sanda_info[pos];
	int pai_face = pai_struct_get_face(pai_info);

	//拆成1+1
	{
		PaiTypeMap* fen_pai_1_1 =new PaiTypeMap;
		*fen_pai_1_1=fen_pai;

		paitypemap_add_danpai(fen_pai_1_1,pai_face);
		paitypemap_add_danpai(fen_pai_1_1,pai_face);
		std::sort(fen_pai_1_1->pai[1].begin(),fen_pai_1_1->pai[1].end(),pai_struct_face_greater_cmp_func);

		if(extract_sandai_daipai(data,*fen_pai_1_1,*fen_pai_1_1,sanda_info,pos+1,kaiguan))
		{
			ret_table.push_back(fen_pai_1_1);
		}
		else 
		{
			delete fen_pai_1_1;
		}
	}

	//不拆
	{
		PaiTypeMap* fen_pai_2= new PaiTypeMap; 
		*fen_pai_2=fen_pai;
		paitypemap_add_duizhi(fen_pai_2,pai_face);

		if(extract_sandai_daipai(data,*fen_pai_2,*fen_pai_2,sanda_info,pos+1,kaiguan))
		{
			ret_table.push_back(fen_pai_2);
		}
		else 
		{
			delete fen_pai_2;
		}
	}



	if(ret_table.size()==0)
	{
		return false;
	}

	PaiTypeMap* best=NULL;
	for(int i=0;i<(int)ret_table.size();i++)
	{
		best=compare_fenpai(data,best,ret_table[i]);
	}
	fen_pai_out = *best;

	for(int i=0;i<(int)ret_table.size();i++)
	{
		delete ret_table[i];
	}

	return true;

}

void analyse_pai(
		FenpaiData* data,
		int seat_id, 
		std::map<int,int>& pai_map,
		PaiTypeMap& fen_pai_out,
		map<int,int>& kaiguan
		)
{
	// type: 0 表示顺子， 1表示连队，3表示飞机
	for(int type =1;type<=3;type++)
	{
		int start_p=SZ_START_PAI;
		int end_p= SZ_END_PAI- data->sz_min_len[type] +1;
		
		while(start_p<=end_p)
		{
			int len=data->sz_min_len[type];

			while(len<=data->sz_max_len[type]) 
			{
				std::pair<int,int> status_next=check_is_lianxu(pai_map,start_p,len,type,15);

				if(status_next.first)
				{
					int pai_type = 5+type;
					if(type ==3) 
					{
						pai_type= 12 ;
					}
					chang_value_by_lianxu(pai_map,start_p,len,-type);
					add_sz(fen_pai_out,start_p,len,pai_type);
					analyse_pai(data,seat_id,pai_map,fen_pai_out,kaiguan);
					chang_value_by_lianxu(pai_map,start_p,len,type);
					reduce_sz(fen_pai_out,pai_type);
				}
				else 
				{
					if(len==data->sz_min_len[type])
					{
						start_p=status_next.second-1;
					}
					break;
				}

				len=len+1;
			}

			start_p=start_p+1;
		}
	}

	std::map<int,int> pai_map_copy=pai_map;
	PaiTypeMap fen_pai_copy=fen_pai_out;

	PaiTypeMap fen_result;

	if(analyse_pai_other(data,fen_result,fen_pai_copy,pai_map_copy,kaiguan))
	{
		if (!data->has_fenpai_result)
		{
			data->fen_pai_result= *compare_fenpai(data,&fen_result,NULL);
			data->has_fenpai_result=true;
		}
		else 
		{
			data->fen_pai_result= *compare_fenpai(data,&data->fen_pai_result,&fen_result);
		}
	}
}

std::pair<int,int> check_is_lianxu(std::map<int,int>& pai_map,int s,int len,int count,int limit)
{
	for(int k=s;k<=s+len-1;k++) 
	{
		if( pai_map[k]<count || k >=limit) 
		{
			for(int i=k+1;i<=s+len-1;i++)
			{
				if(pai_map[i]>=count)
				{
					return std::make_pair(0,i);
				}
			}

			return std::make_pair(0,s+len);
		}
	}

	return std::make_pair(1,0);
}


void  add_sz(PaiTypeMap& data,int s,int len,int type)
{
	if(type==CardType::SERIAL_SINGLE)
	{
		paitypemap_add_shuizhi(&data,s,s+len-1);
	}
	else if(type==CardType::SERIAL_PAIR)
	{
		paitypemap_add_liandui(&data,s,s+len-1);
	}
	else if(type==CardType::SERIAL_THREE)
	{
		paitypemap_add_feiji(&data,s,s+len-1);
	}
}


void reduce_sz(PaiTypeMap& data,int type)
{
	data.pai[type].pop_back();
}

void get_fenpai_score(FenpaiData* data,PaiTypeMap* fenpai,int* _score,int* _shoushu,int* _bomb_count)
{
	int score=0;
	int shoushu=0;
	int bomb_count=0;

	for(int i=1;i<=13 ;i++)
	{
		if(is_map_exist(fenpai->pai,i)) 
		{
			for(auto& v : fenpai->pai[i])
			{
				int pai_score=  get_score_by_paitype(data,v);
				score = score + pai_score;
				//std::string pai_str= pai_struct_tostring(v);
			//	printf("%s=%d\n",pai_str.c_str(),pai_score);
				shoushu=shoushu+1;
			}
			if( i==13 )
			{
				bomb_count=bomb_count+fenpai->pai[i].size();;
			}
		}
	}
	if(fenpai->pai[14].size()>0 )
	{
		score = score + get_score_by_paitype(data,fenpai->pai[14][0]);
		shoushu=shoushu+1;
		bomb_count=bomb_count+1;
	}


	score=score-(shoushu-bomb_count-1)*7;

	*_score=score;
	*_shoushu=shoushu;
	*_bomb_count=bomb_count;
}

int get_score_by_paitype(FenpaiData* data,const pai_struct& pai)
{
	return data->get_pai_score(data,pai);
}



int get_score_by_paitype_dynamic(FenpaiData* data,const pai_struct& pai)
{
	std::pair<int,bool> pai_info=query_map_get_pai_score(data->query_map,data->my_seat_id,pai,false);
	return pai_info.first;

}




int get_score_by_paitype_static(FenpaiData* data,const pai_struct& pai)
{
	int type = pai_struct_get_type(pai);
	int face=pai_struct_get_face(pai);
	int serial=pai_struct_get_serial(pai);

	int face_from=pai_struct_get_face_from(pai);
	int face_to=pai_struct_get_face_to(pai);

	int base_score=face-10;

	switch(type)
	{
		case CardType::SINGLE:
			return base_score;

		case CardType::PAIR:
			{
				if(face<=10)
				{
					return base_score+1;
				}

				return base_score+2;
			}
		case CardType::THREE:
		case CardType::THREE_SINGLE:
		case CardType::THREE_PAIR:
			{
				return base_score+2;
			}

		case CardType::SERIAL_SINGLE:
			{
				int len_s=(int)floor((serial-5)/3.0f);
				int ret=base_score+len_s+4;
				if(ret> 7 )
				{
					return 7;
				}
				return ret;
			}

		case CardType::SERIAL_PAIR:
			{
				int s=0;
				if(face<7)
				{
					s=2;
				}
				else if(face<9)
				{
					s=3;
				}
				else 
				{
					s=2+face-9;
				}
				s=s+serial-3;
				if(s>7)
				{
					s=7;
				}
				return s;
			}

		case CardType::FOUR_SINGLE2:
		case CardType::FOUR_PAIR2:
			{
				int s=7;
				if(face<6)
				{
					s=3;
				}
				else if(face<8)
				{
					s=4;
				}
				else if(face<11)
				{
					s=5;
				}
				else if(face<14)
				{
					s=6;
				}
				return s;
			}

		case CardType::SERIAL_THREE_PAIR:
		case CardType::SERIAL_THREE_SINGLE:
		case CardType::SERIAL_THREE:
			{
				int s=0;
				if(face<7)
				{
					s=4;
				}
				else if(face<10)
				{
					s=5;
				}
				else if(face<13)
				{
					s=6;
				}
				else 
				{
					s=7;
				}

				s=s+serial-1;
				if(s>7)
				{
					s=7;
				}
				return s;
			}

		case CardType::BOMB:
			return 15;

		case CardType::ROCKET:
			return 15;

	}

	return 0;

}


std::pair<int,int> check_is_xiajiao_special(FenpaiData* data,int seat_id,PaiTypeMap* fenpai,bool use_sure)
{
	int a = 0;
	int ab = 0;
	int abc = 0;

	int no = 0;
	int extraNozhanshou = 0;

	int no_shoushu = 0;

	//统计炸弹数量
	int bomb = 0;

	bomb=bomb+fenpai->pai[13].size();

	if(fenpai->pai[14].size()>0 )
	{
		bomb=bomb+1;
	}


	for (int i=1;i<=5;i++) 
	{
		if(fenpai->pai[i].size() && data->kaiguan[i]==1)
		{
			int status,ctrl,no_ctrl; 
			analysis_pai_ctrl_type(data,i,fenpai->pai[i],seat_id,use_sure,&status,&ctrl,&no_ctrl);

			if(status==0)
			{
				if(no_ctrl==0)
				{
					a=a+1;
				}
				else
				{
					ab=ab+1;
				}
			}
			else if(status==1)
			{
				abc=abc+1;
				extraNozhanshou=extraNozhanshou+1;
				no_shoushu=no_shoushu+no_ctrl+ctrl;
			}
			else if(status==2 )
			{
				no=no+1;
				extraNozhanshou=extraNozhanshou+no_ctrl-ctrl;
				no_shoushu=no_shoushu+no_ctrl+ctrl;
			}

		}
	}

	//如果不允许三不带  最后三张牌也可以三不带
	if(data->kaiguan[3]!=1 && fenpai->pai[3].size() >0 )
	{
		int shoushu=0;

		for(int i=1;i<=14;i++)
		{
				shoushu=shoushu+fenpai->pai[i].size();
		}
		if(shoushu>1 )
		{
			no=no+1;
			extraNozhanshou=extraNozhanshou+1;
		}
		else
		{
			a=a+1;
		}
	}


	if(extraNozhanshou-bomb>1 )
	{
		return std::make_pair(0,bomb-extraNozhanshou);

	}
	if( ab==0 && abc==0 && no==0 )
	{
		return std::make_pair(1,0 );
	}

	if(extraNozhanshou==1 && no_shoushu==1 && ab==0 && abc<=1 )
	{
		return std::make_pair(2,0);
	}


	if(extraNozhanshou-bomb<=0 )
	{
		if(ab<2 && abc<1 && no<1 )
		{
			return std::make_pair(2,0 );
		}
		return std::make_pair(3,0);
	}
	return std::make_pair(4,0);

}



void analysis_pai_ctrl_type(FenpaiData* data,int type,std::vector<pai_struct>& pai,int seat_id,bool use_sure, int* _status,int* _ctrl,int* _no_ctrl)
{
	int extraNozhanshou_sum,ctrl,no_ctrl; 
	get_extraNozhanshou_sum(data,type,pai,seat_id,use_sure,&extraNozhanshou_sum,&ctrl,&no_ctrl);

	if(extraNozhanshou_sum==0 )
	{
		*_status=0;
		*_ctrl=ctrl;
		*_no_ctrl=no_ctrl;
		return ;
	}
	else if(extraNozhanshou_sum==1 )
	{
		*_status=1;
		*_ctrl=ctrl;
		*_no_ctrl=no_ctrl;
		return ;
	}
	else
	{
		*_status=2;
		*_ctrl=ctrl;
		*_no_ctrl=no_ctrl;
	}
}


void get_extraNozhanshou_sum(FenpaiData* data,int type,std::vector<pai_struct>& pai,int seat_id,bool use_sure,int* _extract_no_zhanshou,int* _ctrl,int* _no_ctrl)
{
	int ctrl =0;
	int no_ctrl =0;

	if(use_sure)
	{
		get_sure_zhanshou_data(data,type,pai,seat_id,&ctrl,&no_ctrl);
	}
	else 
	{
		get_zhanshou_data(data,type,pai,seat_id,&ctrl,&no_ctrl);
	}

	if(no_ctrl-ctrl<0)
	{
		*_extract_no_zhanshou=0;
		*_ctrl=ctrl;
		*_no_ctrl=no_ctrl;
		return; 
	}

	*_extract_no_zhanshou=no_ctrl-ctrl;
	*_ctrl=ctrl;
	*_no_ctrl=no_ctrl;
}


void get_zhanshou_data(FenpaiData* data,int type,std::vector<pai_struct>& pai_data,int seat_id,int* _ctrl,int* _no_ctrl)
{
	if(pai_data.size()> 0)
	{

		int ctrl=0;
		int no_ctrl=0;
		for(auto&  v :pai_data)
		{
			auto score_info= query_map_get_pai_score(data->query_map, seat_id, v);
			int s = score_info.first;
			v.score = s;
			if(s>6 || (pai_struct_get_type(v)==1 && pai_struct_get_face(v)>14) )
			{
				ctrl=ctrl+1;
			}
			else 
			{
				no_ctrl=no_ctrl+1;
			}
		}

		*_ctrl=ctrl;
		*_no_ctrl=no_ctrl;
		return ;
	}

	*_ctrl=0;
	*_no_ctrl=0;
}

void get_sure_zhanshou_data(FenpaiData* data,int type,std::vector<pai_struct>& pai_data,int seat_id,int* _ctrl,int* _no_ctrl)
{

	if(pai_data.size()> 0)
	{

		int ctrl=0;
		int no_ctrl=0;
		for(auto&  v :pai_data)
		{
			auto score_info = query_map_get_pai_score(data->query_map, seat_id, v);
			int s = score_info.first;
			v.score = s;
			if(s>6 )
			{
				ctrl=ctrl+1;
			}
			else 
			{
				no_ctrl=no_ctrl+1;
			}
		}

		*_ctrl=ctrl;
		*_no_ctrl=no_ctrl;
		return ;
	}

	*_ctrl=0;
	*_no_ctrl=0;
}


void fenpai_for_all(FenpaiData* data, std::map<int, std::map<int, int>>& pais, std::map<int, int>& sz_min, std::map<int, int>& sz_max, std::map<int, int>& kaiguan, int my_seat_id, int dz_seat_id, int seat_count)
{
	data->sz_min_len=sz_min; 
	data->sz_max_len=sz_max;
	data->kaiguan=kaiguan;
	data->my_seat_id=my_seat_id;
	data->dz_seat_id=dz_seat_id;
	data->seat_count=seat_count;
	data->pai_map = pais;



	data->query_map=QueryMap::create(data->dz_seat_id,data->pai_map);

	data->compare_fenpai=default_compare_fenpai;
	data->get_fenpai_value=default_get_fenpai_value;
	data->get_pai_score= get_score_by_paitype_dynamic;
	data->has_fenpai_result=false;

	for(int i=1;i<=data->seat_count;i++)
	{

		data->my_seat_id=i;
		data->has_fenpai_result=false;
		PaiTypeMap fen_pai;
		analyse_pai(data,i,data->pai_map[i],fen_pai,data->kaiguan);
		data->fen_pai[i]=data->fen_pai_result;
	}

	data->compare_fenpai=xiaojiaobest_compare_fenpai;
	data->get_fenpai_value=get_fenpai_value_by_realxj;
	data->get_pai_score= get_score_by_paitype_dynamic;
	data->has_fenpai_result=false;
	for(int i=0;i<=data->seat_count;i++)
	{
		data->my_seat_id=i;
		data->has_fenpai_result=false;
		PaiTypeMap fen_pai;
		analyse_pai(data,i,data->pai_map[i],fen_pai,data->kaiguan);
		data->xjbest_fenpai[i]=data->fen_pai_result;
	}


}


void fenpai_for_one(FenpaiData* data, std::map<int, std::map<int, int>>& pais, std::map<int, int>& sz_min, std::map<int, int>& sz_max, std::map<int, int>& kaiguan, int my_seat_id, int dz_seat_id, int seat_count)
{
	data->sz_min_len=sz_min; 
	data->sz_max_len=sz_max;
	data->kaiguan=kaiguan;
	data->my_seat_id=my_seat_id;
	data->dz_seat_id=dz_seat_id;
	data->seat_count=seat_count;
	data->pai_map = pais;




	data->compare_fenpai=default_compare_fenpai;
	data->get_fenpai_value=default_get_fenpai_value;
	data->get_pai_score = get_score_by_paitype_dynamic;

	data->query_map=QueryMap::create(data->dz_seat_id,data->pai_map);

	data->my_seat_id=my_seat_id;
	data->has_fenpai_result=false;
	PaiTypeMap fen_pai;
	analyse_pai(data,my_seat_id,data->pai_map[my_seat_id],fen_pai,data->kaiguan);

	data->fen_pai[my_seat_id]=data->fen_pai_result;

	delete data->query_map;

}







void destroy_query_map(QueryMap* query_map)
{
	delete query_map;
}

