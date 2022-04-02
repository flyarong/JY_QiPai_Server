//
//  ddz_boyi_search.cpp
//  ddz_ai
//
//  Created by 何威 on 2019/4/1.
//  Copyright © 2019 何威. All rights reserved.
//

#include "ddz_boyi_search.hpp"
#include "lys_card.hpp"
#include <iostream>
#include <iso646.h>

#include "fenpai.h"

using namespace std;
int nil_value=-11111111;
int chuntian_score=1;
int get_pai_count(pai_struct * p_s)
{
    if(p_s->type<6)
    {
        return p_s->type;
    }
    else if (p_s->type<8)
    {
        return (p_s->pai[1]- p_s->pai[0]+1)*(p_s->type-5);
    }
    else if (p_s->type==8)
    {
        return 6;
    }
    else if (p_s->type==9)
    {
        return 8;
    }
    else if (p_s->type==10 or p_s->type==11)
    {
        return (p_s->pai[1]- p_s->pai[0]+1)*(p_s->type-9+3);
    }
    else if (p_s->type==12)
    {
        return (p_s->pai[1]- p_s->pai[0]+1)*3;
    }
    else if (p_s->type==13)
    {
        return 4;
    }
    else if (p_s->type==14)
    {
        return 2;
    }
        
    return 0;
}
void  change_pai_count(map<int,int> &pai_map,int pai,int count,bool is_add)
{
    if (pai_map.find(pai)!=pai_map.end())
    {
        if (is_add)
        {
            pai_map[pai]+=count;
        }
        else
        {
            pai_map[pai]-=count;
        }
    }
       
}
void change_pai_count_from_map(map<int,int> &pai_map,pai_struct *p_s,bool is_add)
{
    // 单牌 对子 三 不 带  
    if (p_s->type<4 && p_s->type>0)
        change_pai_count(pai_map,p_s->pai[0],p_s->type,is_add);
    else if(p_s->type==4)
    {
        change_pai_count(pai_map,p_s->pai[0],3,is_add);
        change_pai_count(pai_map,p_s->pai[1],1,is_add);
    }
    else if(p_s->type==5)
    {
        change_pai_count(pai_map,p_s->pai[0],3,is_add);
        change_pai_count(pai_map,p_s->pai[1],2,is_add);
    }
    else if(p_s->type==6 or p_s->type==7)
    {
        for(int i=p_s->pai[0];i<=p_s->pai[1];i++)
        {
            change_pai_count(pai_map,i,p_s->type-5,is_add);
        }
    }
    else if(p_s->type==8 or p_s->type==9)
    {
        change_pai_count(pai_map,p_s->pai[0],4,is_add);
        change_pai_count(pai_map,p_s->pai[1],p_s->type-7,is_add);
        change_pai_count(pai_map,p_s->pai[2],p_s->type-7,is_add);
    }
    else if(p_s->type==10 or p_s->type==11)
    {
        int pos=3;
        for(int i=p_s->pai[0];i<=p_s->pai[1];i++)
        {
            change_pai_count(pai_map,i,3,is_add);
            change_pai_count(pai_map,p_s->pai[pos],p_s->type-9,is_add);
            pos++;
        }
    }
    else if(p_s->type==12)
    {
        for(int i=p_s->pai[0];i<=p_s->pai[1];i++)
        {
            change_pai_count(pai_map,i,3,is_add);
        }
    }
    else if(p_s->type==13)
    {
        change_pai_count(pai_map,p_s->pai[0],4,is_add);
    }
    else if(p_s->type==14)
    {
        change_pai_count(pai_map,16,1,is_add);
        change_pai_count(pai_map,17,1,is_add);
    }
}


// by lyx: 判断手牌 是否包含要出的牌
// 参数 pai_data : {type=,pai=}
// 返回 true/false
bool check_pai_is_exist(map<int,int> &pai_map,int _type,int *_pai = nullptr)
{
	// 单牌, 对子,三不带 
	if (_type <= 3)
		return map_pai_num(pai_map, _pai[0]) >= _type;
	else if (_type == 4) //  三带一 
		return map_pai_num(pai_map, _pai[0]) >= 3 && map_pai_num(pai_map, _pai[1]) >= 1;
	else if (_type == 5) // 三带一对 
		return map_pai_num(pai_map, _pai[0]) >= 3 && map_pai_num(pai_map, _pai[1]) >= 2;
	else if (_type == 6 || _type == 7) // 顺子、连对 
	{
		int _count = _type == 6 ? 1 : 2;

		for (int i = _pai[0]; i <= _pai[1]; ++i)
		{
			if (map_pai_num(pai_map, i) < _count)
				return false;
		}

		return true;
	}
	else if (_type == 8) // 四带2 
		return	map_pai_num(pai_map, _pai[0]) >= 4 &&
		map_pai_num(pai_map, _pai[1]) >= 1 &&
		map_pai_num(pai_map, _pai[2]) >= 1;
	else if (_type == 9) // 四带2对 
		return	map_pai_num(pai_map, _pai[0]) >= 4 &&
		map_pai_num(pai_map, _pai[1]) >= 2 &&
		map_pai_num(pai_map, _pai[2]) >= 2;
	else if (_type == 10 || _type == 11 || _type == 12)
	{
		// 飞机带单牌、飞机带对子,飞机  不带 
		for (int i = _pai[0]; i <= _pai[1]; ++i)
		{
			if (map_pai_num(pai_map, i) < 3)
				return false;
		}

		if (_type == 10 || _type == 11)
		{
			int _count = _type == 10 ? 1 : 2;

			for (int i = 2; i <= 2 + (_pai[1] - _pai[0]); ++i)
			{
				if (map_pai_num(pai_map, _pai[i]) < _count)
					return false;
			}

		}

		return true;
	}
	else if (_type == 13) // 炸弹 
		return map_pai_num(pai_map, _pai[0]) >= 4;
	else if (_type == 14) // 王炸 
		return	map_pai_num(pai_map, 16) >= 1 &&
				map_pai_num(pai_map, 17) >= 1;

	return false;
}
bool check_pai_is_exist(map<int, int> &pai_map, pai_struct * pai_data)
{
	return check_pai_is_exist(pai_map,pai_data->type,pai_data->pai);
}

map<int,vector<pai_struct>> get_pai_enum(map<int,int> &pai_map,std::map<int,int>& kaiguan)
{
	return lys_get_pai_enum(pai_map,kaiguan);
}

// 获得关键牌 
int get_key_pai(int pai_type,int * pai_data)
{
	if (pai_type==0)
		return 0;

	else if (pai_type<6 || pai_type==8 || pai_type==9 || pai_type==13)
		return pai_data[0];
	
	else if(pai_type==6 or pai_type==7 or pai_type==10 or pai_type==11 or pai_type==12)
		return pai_data[1];

	else if(pai_type==14)
		return 17;

	else
		return 0;

}

/*
-- 判断能否出给定的牌
-- 参数 pai_data0 : 别人出的牌， nil 表示 自己首出
-- 参数 pai_data : 自己要出的牌
-- 返回 true/false
*/
bool check_can_chupai(pai_struct * pai_data0,pai_struct * pai_data = nullptr)
{
	if (!pai_data0)
		return true;

	// 王炸 最大 
	if (pai_data->type == 14)
	{

		return true;

	}
	else if (pai_data0->type == 14)
		return false;
	// 炸弹比大小 
	else if (pai_data->type == 13)
	{
		if (pai_data0->type == 13)
			return pai_data->pai[0] > pai_data0->pai[0];
		else
			return true;
	}
	else if (pai_data0->type == 13)
		return false;

	// 同类型比大小
	else if (pai_data->type == pai_data0->type)
    {
        // 连子 要比张数
        if (pai_data0->type == 6 || 
            pai_data0->type == 7 || 
            pai_data0->type == 10 || 
            pai_data0->type == 11 || 
            pai_data0->type == 12)
        {
            if ((pai_data0->pai[1]-pai_data0->pai[0]) != (pai_data->pai[1]-pai_data->pai[0]))
                return false;
        }

		return pai_data->pai[0] > pai_data0->pai[0];
    }
	else
		return false;

}

/* by lyx: 牌数组 加入到出牌 list
-- 参数：
	_pai_map 手牌
	_pai_array 拆分好的 牌分组的数组
	_cp_data 上家的出牌
	_cp_list 要加入的 出牌 list
*/
void append_chupai_list(map<int,int> &_pai_map,
						vector<pai_struct> & _pai_array,
						pai_struct * _cp_data,
						vector<pai_struct*> &_cp_list)
{
	for(std::size_t i=0;i<_pai_array.size();++i)
	{
		pai_struct &my_chupai = _pai_array[i];
		if (check_can_chupai(_cp_data,&my_chupai) && check_pai_is_exist(_pai_map,&my_chupai))
			_cp_list.push_back(&my_chupai);
	}
}

void add_cp_list_from_pai_enum(vector<pai_struct*> &cp_list,
                            map<int,int> &pai_map,
                            map<int,vector<pai_struct>>::iterator pai_enum_it)
{
    if ( pai_enum_it->first == 14 )
    {
        if (check_pai_is_exist(pai_map,&pai_enum_it->second[0]))
            cp_list.push_back(&pai_enum_it->second[0]);
    }
    else
    {
        for (std::size_t i = 0; i < pai_enum_it->second.size(); ++i)
        {
            pai_struct &my_chupai = pai_enum_it->second[i];
            if (check_pai_is_exist(pai_map, &my_chupai))
                cp_list.push_back(&my_chupai);
        }
    }
}

/* by lyx: 计算出牌列表
参数
pai_enum ：{ [type] = {pai1,pai2,...},... }
kaiguan ：允许的出牌类型 （如果是 3 不带 在最后，则总是允许）

返回 可能的出牌列表：{ {type=,pai = },... }
无法出牌 返回 nil
*/
void get_can_cp_list(vector<pai_struct*> &cp_list,
                     map<int,int> &pai_map,
                     map<int,vector<pai_struct>> &pai_enum,
                     std::map<int,int>& kaiguan,
                     pai_struct * cp_data
                     )
{
	if (cp_data)
	{
		// 对方王炸不用看了
		if (cp_data->type == 14)
			return;

		// 加入王炸
		if (is_map_exist(pai_enum,14))
		{
		

			if (check_pai_is_exist(pai_map,14))
				cp_list.push_back(&pai_enum[14][0]);
				
		}

		// 加入炸弹
		if (is_map_exist(pai_enum, 13))
		{
			append_chupai_list(pai_map,pai_enum[13],cp_data,cp_list);
		}

		// 加入同类型 
		if (cp_data->type != 13 && is_map_exist(pai_enum, cp_data->type))
		{
			append_chupai_list(pai_map,pai_enum[cp_data->type],cp_data,cp_list);
		}
	}
	else
	{
        // 先处理炸弹、王炸
        auto it = pai_enum.find(13);
        if (it != pai_enum.end())
        {
            add_cp_list_from_pai_enum(cp_list,pai_map,it);
        }
        it = pai_enum.find(14);
        if (it != pai_enum.end())
        {
            add_cp_list_from_pai_enum(cp_list,pai_map,it);
        }

		// 可以出所有的牌 
		for(auto it_pn = pai_enum.begin();it_pn != pai_enum.end(); ++it_pn)
		{
            if (it_pn->first == 13 || it_pn->first == 14)
                continue;

			// 处理3不带开关 
            auto it_kaiguan = kaiguan.find(it_pn->first);
			int _can_add = it_kaiguan != kaiguan.end() && it_kaiguan->second;

			if ( it_pn->first == 3 && !_can_add ){
				// 统计牌的张数 
				int _sum = 0;
				for(auto it = pai_map.begin();it != pai_map.end(); ++it)
					_sum = _sum + it->second;
				
				if ( _sum == 3 )
					_can_add = 1;
			}

			if ( _can_add ) 
            {
                add_cp_list_from_pai_enum(cp_list,pai_map,it_pn);
            }
		}		
	}
}
bool is_chuntian( std::map<int,int> &cp_count,
                 std::map<int,int> &seat_type,
                 int all_seat,
                 int cur_p)
{

    //计算春天当前是 地主获胜
    if(seat_type[cur_p]==1)
    {
        bool flag=true;
        for(int k=1;k<=all_seat;k++)
        {
            if(k!=cur_p && seat_type[cur_p]!=seat_type[k] && cp_count[k]>0)
            {
                flag=false;
                break;
            }
        }
        return flag;
    }
    else  //反春
    {
        bool flag=true;
        for(int k=1;k<=all_seat;k++)
        {
            if(k!=cur_p && seat_type[cur_p]!=seat_type[k] && cp_count[k]>1)
            {
                flag=false;
                break;
            }
        }
        return flag;
    }
}
//int times=0;
 void get_all_cp_value_boyi(
                           vector<pai_struct> &cp_return_list,
                           map<int,map<int,int>>&pai_map,
                           map<int,int> &seat_type,
                           map<int,int> &game_over_info,
                           map<int,int> &kaiguan,
                           map<int,int> &cp_count,
                           map<int,int> &pai_count,
                           map<int,map<int,vector<pai_struct>>> &pai_enum,
                           int cur_p,
                           int all_seat,
                           int cp_p,
                           pai_struct * cp_data,
                           int times_limit)
{
//    //生成pai_count
//    map<int,int> pai_count;
//    for(int i=1;i<=all_seat;i++)
//    {
//        int count=0;
//        for(auto k=pai_map[i].begin();k!=pai_map[i].end();k++)
//        {
//            count+=k->second;
//        }
//        pai_count[i]=count;
//    }
//
//    //生成pai_enum
//    map<int,map<int,vector<pai_struct>>> pai_enum;
//    for (int i=1;i<=all_seat;i++)
//    {
//        pai_enum[i]=lys_get_pai_enum(pai_map[i], kaiguan);
//    }
    //生成cp_list
    vector<pai_struct*> cp_list;
    get_can_cp_list(cp_list,pai_map[cur_p],pai_enum[cur_p],kaiguan,cp_data);
    
    int next_times=0;
    if (cp_data!=nullptr)
        next_times++;
    next_times+=cp_list.size();
    if(next_times==0)
    {
        next_times=1;
    }
    next_times=(int)(times_limit/next_times);
    
    int  next_p=cur_p+1;
    if (next_p>all_seat)
        next_p=1;
    
    bool _is_max=true;
    if (seat_type[cur_p]!=seat_type[next_p])
        _is_max=not _is_max;
    
   
    int value=-10000;
    
    if(not cp_list.empty())
    {
        for(auto i=cp_list.begin();i!=cp_list.end();i++)
        {
            int p_c=0;
            int score=0;
            //炸弹
            if ((*i)->type==13 or (*i)->type==14)
            {
                score++;
            }
            p_c=get_pai_count(*i);
            pai_count[cur_p]-=p_c;
            
            change_pai_count_from_map(pai_map[cur_p],*i,false);
            
            if (pai_count[cur_p]<=game_over_info[cur_p])
            {
                score++;
                if (is_chuntian( cp_count,seat_type,all_seat,cur_p))
                {
                    score+=chuntian_score;
                }
                
            }
            else if (next_times>0)
            {
                cp_count[cur_p]++;
                score=search_cp_value_boyi(pai_map,
                                            pai_count,
                                            cp_count,
                                            seat_type,
                                            game_over_info,
                                            pai_enum,
                                            kaiguan,
                                            cur_p,
                                            all_seat,
                                            score,
                                            next_p,
                                            cur_p,
                                            *i,
                                            1,
                                            next_times,
                                            _is_max,
                                            value);
                //cp_count[cur_p]//;
            }
            else
            {
                score=0;
            }
            
            pai_count[cur_p]+=p_c;
            change_pai_count_from_map(pai_map[cur_p],*i,true);

            //插入list
            (*i)->score=score;
            cp_return_list.push_back(**i);
        }
    }
    //过
    if (cp_data!=nullptr && next_times>0)
    {
        auto _cp_data=cp_data;
        if (next_p==cp_p)
            _cp_data=nullptr;
        
        int score=search_cp_value_boyi(pai_map,
                                        pai_count,
                                        cp_count,
                                        seat_type,
                                        game_over_info,
                                        pai_enum,
                                        kaiguan,
                                        cur_p,
                                        all_seat,
                                        0,
                                        next_p,
                                        cp_p,
                                        _cp_data,
                                        1,
                                        next_times,
                                        _is_max,
                                        value);
        
        
        //插入list
		pai_struct give_up;
		give_up.type =0 ;
		give_up.score=score;
		cp_return_list.push_back(give_up);
    }
//    cout<<times<<endl;
    
}
int search_cp_value_boyi(
                          map<int,map<int,int>> &pai_map,
                          map<int,int> &pai_count,
                          map<int,int> &cp_count,
                          map<int,int> &seat_type,
                          map<int,int> &game_over_info,
                          map<int,map<int,vector<pai_struct>>> pai_enum,
                          map<int,int> &kaiguan,
                          int owner_seat,
                          int all_seat,
                          int score,
                          int cur_p,
                          int cp_p,
                          pai_struct *cp_data,
                          int depth,
                          int times_limit,
                          bool is_max,
                          int a_b_cut)
{
//    times++;
    vector<pai_struct * > cp_list;
    get_can_cp_list(cp_list,pai_map[cur_p],pai_enum[cur_p],kaiguan,cp_data);
    
    int next_times=0;
    if (cp_data!=nullptr)
        next_times++;
    next_times+=cp_list.size();
    if(next_times==0)
    {
        next_times=1;
    }
    next_times=(int)(times_limit/next_times);
    
    int  next_p=cur_p+1;
    if (next_p>all_seat)
        next_p=1;
    
    bool _is_max=is_max;
    if (seat_type[cur_p]!=seat_type[next_p])
        _is_max=not _is_max;
    
    int  last_p=cur_p-1;
    if (last_p<1)
        last_p=all_seat;
    
    bool last_is_max=is_max;
    if (seat_type[cur_p]!=seat_type[last_p])
        last_is_max=not last_is_max;
    
    int value=10000;
    if (is_max)
        value=-10000;
    
    if(not cp_list.empty())
    {
        int p_c=0;
        int _score;
        //能过必过
        for(auto i=cp_list.begin();i!=cp_list.end();i++)
        {
            p_c=get_pai_count(*i);
            _score=score;
            if(pai_count[cur_p]-p_c<=game_over_info[cur_p] && ((*i)->type!=8 and (*i)->type!=9))
            {
                if ((*i)->type==13 or (*i)->type==14)
                {
                    _score++;
                }
                if (is_chuntian( cp_count,seat_type,all_seat,cur_p))
                {
                    _score+=chuntian_score;
                }
                _score=_score+1;
                if (seat_type[owner_seat]!=seat_type[cur_p])
                {
                    _score=-_score;
                }
                return _score;
            }
        }
        
        for(auto i=cp_list.begin();i!=cp_list.end();i++)
        {
            //炸弹
            if ((*i)->type==13 or (*i)->type==14)
            {
                score++;
            }
            p_c=get_pai_count(*i);
            pai_count[cur_p]-=p_c;
            
//            printf("%d  ",pai_count[cur_p]);
            change_pai_count_from_map(pai_map[cur_p],*i,false);
                
            if (pai_count[cur_p]<=game_over_info[cur_p])
            {
                _score=score+1;
                
                if (is_chuntian( cp_count,seat_type,all_seat,cur_p))
                {
                    _score+=chuntian_score;
                }
                
                if (seat_type[owner_seat]!=seat_type[cur_p])
                {
                    _score=-_score;
                }
            }
            else if (next_times>0 && depth<100)
            {
                cp_count[cur_p]++;
                _score=search_cp_value_boyi(
                                                    pai_map,
                                                    pai_count,
                                                    cp_count,
                                                    seat_type,
                                                    game_over_info,
                                                    pai_enum,
                                                    kaiguan,
                                                    owner_seat,
                                                    all_seat,
                                                    score,
                                                    next_p,
                                                    cur_p,
                                                    *i,
                                                    depth+1,
                                                    next_times,
                                                    _is_max,
                                                    value);
                cp_count[cur_p]--;
            }
            else
            {
                _score=0;
            }
            
            if (is_max)
            {
                if (_score>value)
                    value=_score;
            }
            else
            {
                if (_score<value)
                    value=_score;
            }
    
            if ((*i)->type==13 or (*i)->type==14)
            {
                score--;
            }
            pai_count[cur_p]+=p_c;
            change_pai_count_from_map(pai_map[cur_p],*i,true);
    
            
            if (is_max)
            {
                if (is_max)
                 if (last_is_max==false && value>=a_b_cut)
                 {
                     return value;
                 }
            }
            else
            {
                //上一个是max
                if (last_is_max && value<=a_b_cut)
                {
                    return value;
                }
            }
            
        }
    }
    //过
    if (cp_data!=nullptr && next_times>0 && depth<100)
    {
        
        auto _cp_data=cp_data;
        if (next_p==cp_p)
        {
            _cp_data=nullptr;
        }
        
        int _score=search_cp_value_boyi(pai_map,
                                        pai_count,
                                        cp_count,
                                        seat_type,
                                        game_over_info,
                                        pai_enum,
                                        kaiguan,
                                        owner_seat,
                                        all_seat,
                                        score,
                                        next_p,
                                        cp_p,
                                        _cp_data,
                                        depth+1,
                                        next_times,
                                        _is_max,
                                        value);
        if (is_max)
        {
            if (_score>value)
                value=_score;
        }
        else
        {
            if (_score<value)
                value=_score;
        }
    }
    if (value==10000 || value==-10000)
        value=0;

    return value;
}


void get_boyiSearch(
                    vector<pai_struct> &cp_return_list,
                    map<int,map<int,int>>&pai_map,
                    map<int,int> &seat_type,
                    map<int,int> &game_over_info,
                    map<int,int> &kaiguan,
                    map<int,int> &cp_count,
                    
                    int cur_p,
                    int all_seat,
                    int cp_p,
                    pai_struct * cp_data,
                    int times_limit)
{
    //生成pai_count
    map<int,int> pai_count;
    for(int i=1;i<=all_seat;i++)
    {
        int count=0;
        for(auto k=pai_map[i].begin();k!=pai_map[i].end();k++)
        {
            count+=k->second;
        }
        pai_count[i]=count;
    }

    //生成pai_enum
    map<int,map<int,vector<pai_struct>>> pai_enum;
    for (int i=1;i<=all_seat;i++)
    {
        pai_enum[i]=lys_get_pai_enum(pai_map[i], kaiguan);
    }
    
    get_all_cp_value_boyi(
                          cp_return_list,
                          pai_map,
                          seat_type,
                          game_over_info,
                          kaiguan,
                          cp_count,
                          pai_count,
                          pai_enum,
                          cur_p,
                          all_seat,
                          cp_p,
                          cp_data,
                          times_limit);
    
}

void get_boyiSearch_have_pe(
                    vector<pai_struct> &cp_return_list,
                    map<int,map<int,int>>&pai_map,
                    map<int,int> &seat_type,
                    map<int,int> &game_over_info,
                    map<int,int> &kaiguan,
                    map<int,int> &cp_count,
                    map<int,map<int,vector<pai_struct>>> &pai_enum,
                    int cur_p,
                    int all_seat,
                    int cp_p,
                    pai_struct * cp_data,
                    int times_limit)
{
    //生成pai_count
    map<int,int> pai_count;
    for(int i=1;i<=all_seat;i++)
    {
        int count=0;
        for(auto k=pai_map[i].begin();k!=pai_map[i].end();k++)
        {
            count+=k->second;
        }
        pai_count[i]=count;
    }
    

    
    get_all_cp_value_boyi(
                          cp_return_list,
                          pai_map,
                          seat_type,
                          game_over_info,
                          kaiguan,
                          cp_count,
                          pai_count,
                          pai_enum,
                          cur_p,
                          all_seat,
                          cp_p,
                          cp_data,
                          times_limit);
    
}

////////////////////////////////////////////////////////

// can_cp_test
void can_cp_test()
{
	map<int, int> pai_map = 
	{ 
		{3,1},
		{4,1},
		{5,2},
		{6,3},
		{7,3},
		{8,4},
		{9,2},
		{10,3},
		{11,3},
		{12,4},
		{13,2},
		{16,1},
		{17,1}
	};

	int iiii = 2343;

	map<int, vector<pai_struct>> pai_enum; /*=
	{
		{1,{ {1,0,{3}},{1,0,{4}},{1,0,{5}},{1,0,{6}},{1,0,{6}},{1,0,{6}},{1,0,{7}},{1,0,{7}},{1,0,{7}},{1,0,{8}},{1,0,{8}},{1,0,{8}},{1,0,{8}},{1,0,{9}},{1,0,{9}},{1,0,{10}},{1,0,{10}},{1,0,{10}},{1,0,{11}},{1,0,{11}},{1,0,{12}},{1,0,{12}},{1,0,{13}},{1,0,{13}} }},
		{2,{ {2,0,{6}},{2,0,{7}},{2,0,{8}},{2,0,{8}},{2,0,{9}},{2,0,{10}},{2,0,{11}},{2,0,{12}},{2,0,{13}} }},
		{3,{ {3,0,{6}},{3,0,{7}},{3,0,{8}},{3,0,{10}} }},
		{4,{ {4,0,{6,3}},{4,0,{6,4}},{4,0,{7,4}},{4,0,{7,3}},{4,0,{8,5}},{4,0,{10,6}},{4,0,{10,7}} }},
		{5,{ {5,0,{6,5}},{5,0,{6,8}},{5,0,{7,9}},{5,0,{7,8}},{5,0,{8,5}},{5,0,{10,6}},{5,0,{10,7}},{5,0,{10,16}},{5,0,{9,7}} }},
		{6,{ {6,0,{3,13}},{6,0,{3,7}},{6,0,{4,8}},{6,0,{5,9}},{6,0,{4,10}} }},
		{7,{ {7,0,{5,13}},{7,0,{6,10}},{7,0,{8,13}},{7,0,{5,9}},{7,0,{5,10}} }},
		{8,{ {8,0,{8,3,4}},{8,0,{12,3,5}} }},
		{9,{ {9,0,{8,5,6}},{9,0,{12,9,10}} }},
		{10,{ {10,0,{6,8,3,4,5}},{10,0,{10,12,4,6,13}} }},
		{11,{ {11,0,{6,8,5,9,10}},{11,0,{10,12,6,7,9}} }},
		{12,{ {11,0,{6,8}},{11,0,{10,12}} }},
		{13,{ {13,0,{8}},{13,0,{12}} }},
		{14,{ {14,0,{}} }}
	*/

    map<int,int> kaiguan;
    kaiguan[0]=1;
    kaiguan[1]=1;
    kaiguan[2]=1;
    kaiguan[3]=1;
    kaiguan[4]=1;
    kaiguan[5]=1;
    kaiguan[6]=1;
    kaiguan[7]=1;
    kaiguan[8]=1;
    kaiguan[9]=1;
    kaiguan[10]=1;
    kaiguan[11]=1;
    kaiguan[12]=1;
    kaiguan[13]=1;
    kaiguan[14]=1;

	vector<pai_struct*> cp_list;

	//pai_struct cp_data = {4,0,{9,5}};
	//pai_struct cp_data = {1,0,{6}};

	get_can_cp_list(cp_list,pai_map,pai_enum,kaiguan,nullptr);
}


