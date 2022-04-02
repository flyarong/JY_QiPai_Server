//
// 作者: 隆元线
// Date: 2018/10/30
// Time: 14:48
// 麻将计算（从 lua 移植）
//

#include <vector>
#include <string>
#include <map>

#include <algorithm>
#include "majiang.h"

PaiItem & ensure_pai_list(PAI_LIST &list, int index)
{
	if (index >= (int)list.size())
		for (int i = (int)list.size(); i <= index; ++i)
			list.push_back(PaiItem());

	return list[index];
}

inline bool check_kg(const KAI_GUAN &kg, const char *name)
{
	auto it = kg.find(name);
	if (it == kg.end())
		return false;
	return it->second;
}

// jiang_num 将牌的数量（对子）
//  list=
// 
// 	type 1 将  2 大对子 3 连子
// 	pai_type 牌类型  若type==3 则为起始位置的牌
// 
void compute_nor_hupai_info(PAI_MAP &pai_map, MJ_PAI _s,
	int all_num, int jiang_num, PAI_LIST &list,
	int list_pos, HUPAI_LIST &info)
{
	for (MJ_PAI s = _s; s <= 39; ++s)
	{
		if (map_exists(pai_map,s) && pai_map[s] > 0)
		{
			//先取 （大对子）
			if (pai_map[s] > 2)
			{
				PaiItem &item = ensure_pai_list(list, list_pos);
				item.type = 2;
				item.pai_type = s;

				if (all_num - 3 == 0)
				{
					if (jiang_num == 1)
					{
						HuPaiData hpd;
						hpd.jiang_num = jiang_num;
						hpd.list_pos = list_pos;
						hpd.list = list;
						info.push_back(hpd);
					}
					return;
				}
				pai_map[s] -= 3;

				MJ_PAI next = s;
				if (pai_map[s] == 0)
				{
					next = s + 1;
				}
				compute_nor_hupai_info(pai_map, next, all_num - 3, jiang_num, list, list_pos + 1, info);

				pai_map[s] += 3;
			}
			//取顺子  
			if (s + 2 <= 39 && map_exists(pai_map,s) && pai_map[s + 1] && map_exists(pai_map,s + 2) && pai_map[s + 1] > 0 && pai_map[s + 2] > 0)
			{
				PaiItem &item = ensure_pai_list(list, list_pos);
				item.type = 3;
				item.pai_type = s;

				if (all_num - 3 == 0)
				{
					if (jiang_num == 1)
					{
						HuPaiData hpd;
						hpd.jiang_num = jiang_num;
						hpd.list_pos = list_pos;
						hpd.list = list;
						info.push_back(hpd);
					}
					return;
				}
				pai_map[s] = pai_map[s] - 1;
				pai_map[s + 1] = pai_map[s + 1] - 1;
				pai_map[s + 2] = pai_map[s + 2] - 1;

				MJ_PAI next = s;
				if (pai_map[s] == 0)
				{
					next = s + 1;
				}

				compute_nor_hupai_info(pai_map, next, all_num - 3, jiang_num, list, list_pos + 1, info);

				pai_map[s] += 1;
				pai_map[s + 1] += 1;
				pai_map[s + 2] += 1;
			}
			//取将
			if (map_exists(pai_map,s) && pai_map[s] > 1 && jiang_num == 0)
			{

				PaiItem &item = ensure_pai_list(list, list_pos);
				item.type = 1;
				item.pai_type = s;

				if (all_num - 2 == 0)
				{
					HuPaiData hpd;
					hpd.jiang_num = jiang_num;
					hpd.list_pos = list_pos;
					hpd.list = list;
					info.push_back(hpd);
					return;
				}
				pai_map[s] -= 2;

				MJ_PAI next = s;
				if (pai_map[s] == 0)
				{
					next = s + 1;
				}

				compute_nor_hupai_info(pai_map, next, all_num - 2, jiang_num + 1, list, list_pos + 1, info);

				pai_map[s] += 2;

			}

			return;
		}
	}
}

// 根数量
int get_geng_num(PAI_MAP &pai_map,PG_MAP &pg_map)
{
	int num=0;
	for ( auto &pair:pai_map) 
	{
		if ( pair.second==4 )
		{
			num=num+1;
		}
		else if(pair.second==1 && map_exists(pg_map,pair.first) && (pg_map[pair.first]=="peng"/* || pg_map[pair.first]==3*/) )
		{
			num=num+1;
		}
	}
	for (auto &pair:pg_map)
	{
		if ( pair.second=="wg" || pair.second=="zg" || pair.second=="ag" /*|| pair.second==4*/ )
		{
			num=num+1;
		}
	}
	return num;
}

//大对子
bool check_is_daduizi(PAI_LIST &list,KAI_GUAN &kaiguan)
{
	if (!check_kg(kaiguan,"da_dui_zi"))
		return false;

	for (auto &pi:list)
	{
		if (pi.type!=1 && pi.type!=2)
			return false;
	}
	return true;
}

//将对
bool check_is_jiangdui(PAI_LIST &list,PAI_MAP &pai_map,PG_MAP &pg_map,KAI_GUAN &kaiguan)	
{
	if (!check_kg(kaiguan,"jiang_dui"))
		return false;

	for (auto &pi:list)
	{
		if (pi.type!=1 && pi.type!=2)
			return false;
	}

	for (auto &pair:pai_map)
	{
		if ( pair.second>0) 
		{
			int c=pair.first%10;
			if ( c!=2 &&  c!=5 &&  c!=8) 
			{
				return false;
			}
		}
	}

	for (auto &pair:pg_map)
	{
		int c=pair.first%10;

		if ( c!=2 &&  c!=5 && c!=8 )
		{
			return false;
		}
	}

	return true;
}

//幺九
bool check_is_yaojiu(PAI_LIST &list,PG_MAP &pg_map,KAI_GUAN &kaiguan)
{
	if ( !check_kg(kaiguan,"yao_jiu") )
	{
		return false;
	}
	for ( auto &v:list)
	{
		if ( v.type==3 )
		{
			int p=v.pai_type%10;
			if ( p!=1 && p!=7 )
			{
				return false;
			}
		}
		else
		{
			int p=v.pai_type%10;
			if ( p!=1 && p!=9 )
			{
				return false;
			}
		}
	}
	for ( auto &pair:pg_map) 
	{
		int c=pair.first%10;
		if ( c!=1 &&  c!=9 )
		{
			return false;
		}
	}
	return true;
}

//7对
bool check_7d_hupai_info(PAI_MAP &pai_map,int all_num,KAI_GUAN &kaiguan , int maxShouPaiNum)
{
	if ( !check_kg(kaiguan,"qi_dui") )
	{
		return false;
	}
	if ( all_num!= maxShouPaiNum )
	{
		return false;
	}
	for ( auto &pair:pai_map) 
	{
		if ( pair.second>0 && pair.second!=2 && pair.second!=4 )
		{
			return false;
		}
	}
	return true;
}

//门清
bool check_is_menqing(PG_MAP &pg_map,KAI_GUAN &kaiguan)
{
	if ( !check_kg(kaiguan,"men_qing") )
	{
		return false;
	}
	for ( auto &pair:pg_map)
	{
		if ( pair.second!="ag" )
		{
			return false;
		}
	}
	return true;
}

//中章
bool check_is_zhongzhang(PAI_MAP &pai_map,PG_MAP &pg_map,KAI_GUAN &kaiguan)
{
	if ( !check_kg(kaiguan,"zhong_zhang") )
	{
		return false;
	}
	for ( auto &pair:pai_map) 
	{
		if ( pair.second>0 )
		{
			int c=pair.first%10;
			if ( c==1 ||  c==9 )
			{
				return false;
			}
		}
	}
	for ( auto &pair:pg_map)
	{
		int c=pair.first%10;
		if ( c==1 ||  c==9 )
		{
			return false;
		}
	}
	return true;
}

//金钩钓
bool check_is_jingoudiao(PAI_MAP &pai_map,KAI_GUAN &kaiguan)
{
	if ( !check_kg(kaiguan,"jin_gou_diao") )
	{
		return false;
	}
	int count=0;
	for ( auto &pair:pai_map)
	{
		count+=pair.second;

		// 提前退出，by lyx 
		if (count>2)
			return false;
	}
	if ( count==2 )
	{
		return true;
	}
	return false;
}


// ★注意： 没有处理 杠上花 和 杠上炮，需要在 lua 层处理
bool compute_hupai_info(PAI_MAP &pai_map,PG_MAP &pg_map,int all_num,int huaSe_count,
	KAI_GUAN &kaiguan,MULTI_TYPES &multi_types , int maxShouPaiNum,HuPaiInfo &outHupaiInfo)
{
	outHupaiInfo.mul = 0;
	outHupaiInfo.geng_num = 0;

	HUPAI_LIST info;
	PAI_MAP pai_tmp = pai_map; // 拷贝一份
	PAI_LIST list;
	compute_nor_hupai_info(pai_tmp,11,all_num,0,list,0,info);
	// 1 平胡 2 大对子 3 7对 4幺九 5将对
	int hupai_type = 0;
	if ( info.size()>0 )
	{
		hupai_type=1;
		//计算最大胡牌
		for ( auto &hpd:info) 
		{
			//是否为大对子
			if ( 2>hupai_type )
			{
				if ( check_is_daduizi(hpd.list,kaiguan) )
				{
					hupai_type=2;
				}
			}
			//是否为将对
			if ( 5>hupai_type )
			{
				if ( check_is_jiangdui(hpd.list,pai_map,pg_map,kaiguan) )
				{
					hupai_type=5;
				}
			}
			//幺舅九
			if ( 4>hupai_type )
			{
				if ( check_is_yaojiu(hpd.list,pg_map,kaiguan) )
				{
					hupai_type=4;
				}
			}
		}
	}
	if ( check_7d_hupai_info(pai_map,all_num,kaiguan , maxShouPaiNum) )
	{
		if ( ! hupai_type || 3>hupai_type )
		{
			hupai_type=3;
		}
	}
	if ( hupai_type )
	{
		outHupaiInfo.geng_num=get_geng_num(pai_map,pg_map);
		auto &res=outHupaiInfo.hu_type_info;

		if ( hupai_type==3 )
		{
			if ( outHupaiInfo.geng_num>0 )
			{
				//龙7对
				outHupaiInfo.geng_num -= 1;
				res["long_qi_dui"]=multi_types["long_qi_dui"];
			}
			else
			{
				//7对
				res["qi_dui"]=multi_types["qi_dui"];
			}
		}
		else if(  hupai_type==2 )
		{
			//大对子
			res["da_dui_zi"]=multi_types["da_dui_zi"];
		}
		else if( hupai_type==5 )
		{
			//将对
			res["jiang_dui"]=multi_types["jiang_dui"];
		}
		else if( hupai_type==4 )
		{
			//幺九
			res["yao_jiu"]=multi_types["yao_jiu"];
		}
		if ( outHupaiInfo.geng_num>0 )
		{
			res["dai_geng"] = outHupaiInfo.geng_num;
		}
		//检查清一色
		if ( huaSe_count==1 && check_kg(kaiguan,"qing_yi_se") )
		{
			res["qing_yi_se"]=multi_types["qing_yi_se"];
		}
		//检查中章 
		if ( check_is_zhongzhang(pai_map,pg_map,kaiguan) )
		{
			res["zhong_zhang"]=multi_types["zhong_zhang"];
		}
		//检查门清
		if ( check_is_menqing(pg_map,kaiguan) )
		{
			res["men_qing"]=multi_types["men_qing"];
		}
		//检查金钩钓
		if ( check_is_jingoudiao(pai_map,kaiguan) )
		{
			res["jin_gou_diao"]=multi_types["jin_gou_diao"];
		}

		for ( auto &pair:res) 
		{
			outHupaiInfo.mul +=pair.second;
		}
		
		return true;
	}
	return false;
}



int tongji_pai_info(PAI_MAP &pai_map,std::map<int,int> *huaSe /*= nullptr*/)
{
	int count=0;
	for ( auto &pair:pai_map) 
	{
		if ( pair.second>0 )
		{
			if (huaSe)
				(*huaSe)[pair.first/10]=1;
			count+=pair.second;
		}
	}
	return count;
}
int tongji_penggang_info(PG_MAP &pg_map,std::map<int,int> *huaSe /*= nullptr*/)
{
	int count=0;
	for ( auto &pair:pg_map) 
	{
		if (huaSe)
			(*huaSe)[pair.first/10]=1;
		count+=3;
	}

	return count;
}



/*

	参数 总张数14张
	pai_map  手里还没出的牌
	pg  碰杠的牌
	返回参数 outHupaiInfo
	{
		hu_type_info 其他表示胡牌类型 
		mul 总番数
		geng_num
	}
	返回 false 表示不糊
*/
bool get_hupai_info(PAI_MAP &pai_map,PG_MAP &pg_map,MJ_PAI must_que,
	KAI_GUAN &kaiguan,MULTI_TYPES &multi_types,int maxShouPaiNum,HuPaiInfo &outHupaiInfo)
{
	std::map<int,int> huaSeMap={{1,0},{2,0},{3,0}};
	int count1=tongji_pai_info(pai_map,&huaSeMap);
	int count2=tongji_penggang_info(pg_map,&huaSeMap);

	int huaSe_count=huaSeMap[1]+huaSeMap[2]+huaSeMap[3];

	if (count1+count2!=maxShouPaiNum || huaSe_count>2)
	{
		return false;
	}
	if (must_que && huaSeMap[must_que] && huaSeMap[must_que]>0)
	{
		return false;
	}

	return compute_hupai_info(pai_map,pg_map,count1,huaSe_count,kaiguan,multi_types , maxShouPaiNum,outHupaiInfo);
}

bool check_have_lianzi(PAI_MAP &pm,MJ_PAI s)
{
    if ( s+2<40 && pm[s] && pm[s+1] && pm[s+2] && pm[s]>0 && pm[s+1]>0 && pm[s+2]>0  )
	{
      return true;
    }
    if ( s-1>10 && s+1<40 && pm[s] && pm[s+1] && pm[s-1] && pm[s]>0 && pm[s+1]>0 && pm[s-1]>0  )
	{
      return true;
    }
    if ( s-2>10  && pm[s] && pm[s-1] && pm[s-2] && pm[s]>0 && pm[s-1]>0 && pm[s-2]>0  )
	{
      return true;
    }
    return false;
}

template <typename K,typename V>
void remove_map(std::map<K,V> &m,K &k)
{
	auto it = m.find(k);
	if (it != m.end())
		m.erase(it);
}

bool get_ting_info(PAI_MAP &pai_map,PG_MAP &pg_map,MJ_PAI must_que,
	KAI_GUAN &kaiguan,MULTI_TYPES &multi_types,int maxShouPaiNum,
	std::vector<TingPaiInfo> &out_ting_info)
{
	std::map<int,int> huaSeMap={{1,0},{2,0},{3,0}};
	int count1=tongji_pai_info(pai_map,&huaSeMap);
	int count2=tongji_penggang_info(pg_map,&huaSeMap);

	int huaSe_count=huaSeMap[1]+huaSeMap[2]+huaSeMap[3];

	if (count1+count2!=maxShouPaiNum || huaSe_count>2)
	{
		return false;
	}
	if (must_que && huaSeMap[must_que] && huaSeMap[must_que]>0)
	{
		return false;
	}


  	PAI_MAP pai_map_copy=pai_map;
  	for (int s=11;s<=39;++s )
	{
  		if ( s%10!=0 )
		{
		    pai_map_copy[s]=pai_map_copy[s] or 0;
		    pai_map_copy[s]=pai_map_copy[s] + 1;
		    if ( pai_map_copy[s]>1 or check_have_lianzi(pai_map_copy,s) )
			{
		    	int count=tongji_pai_info(pai_map_copy);

		    	TingPaiInfo tingInfo;
		    	PAI_MAP pai_map_copy_tmp;
		      	if ( compute_hupai_info(pai_map_copy_tmp,pg_map,count,huaSe_count,kaiguan,multi_types, maxShouPaiNum,tingInfo.hu_type_info) )
				{
		        	tingInfo.ting_pai=s;
		        	out_ting_info.push_back(tingInfo);
		     	}
		    }
		    pai_map_copy[s]=pai_map_copy[s] - 1;
		    if ( pai_map_copy[s]==0 )
		    	remove_map(pai_map_copy,s);
		}
	}

	return true;
}


