//
//  nor_mj_auto_ algorithm_lib.cpp
//  mj_hp_table
//
//  Created by 何威 on 2018/11/2.
//  Copyright © 2018年 何威. All rights reserved.
//

#include "nor_mj_auto_algorithm_lib.hpp"
#include "mj_hupai_typ_compute.hpp"
#include <vector>
#include <map>
#include <iostream>
#include <string.h>
#include <math.h>
using namespace std;

const int max_borrow_pai=5;

double get_one_pai_value(int num,bool is_jiang)
{
    if(is_jiang)
    {
        if (jiang_nor_mj_hp_map.find(num)!=jiang_nor_mj_hp_map.end())
        {
            return jiang_nor_mj_hp_map[num];
        }
    }
    else
    {
        if (no_jiang_nor_mj_hp_map.find(num)!=no_jiang_nor_mj_hp_map.end())
        {
            return no_jiang_nor_mj_hp_map[num];
        }
    }
    return 0;
}

//获得牌面价值--基础版
double get_base_pai_value(map<int,int> *pai_map,int dq_color)
{
    int color_num[4];
    for(int i=1;i<4;i++)
    {
        color_num[i]=get_pai_hash_value_by_color(pai_map,i);
    }
    double jiang_value[4];
    double no_jiang_value[4];
    for(int i=1;i<4;i++)
    {
        jiang_value[i]=get_one_pai_value(color_num[i],true);
        no_jiang_value[i]=get_one_pai_value(color_num[i],false);
    }
    double max=0;
    for(int i=1;i<4;i++)
    {
        if (i!=dq_color)
        {
            for(int k=1;k<4;k++)
            {
                if (k!=dq_color && k!=i)
                {
                    if(jiang_value[i]+no_jiang_value[k]>max)
                    {
                        max=jiang_value[i]+no_jiang_value[k];
                    }
                }

            }
        }
    }
    return max;
}
//检查是否含有定缺牌
bool check_have_dingque_pai(map<int,int> *pai_map,int dq_color)
{
    int s=dq_color*10+1;
    int e=s+9;
    for(;s<e;s++)
    {
        if(pai_map->find(s)!=pai_map->end())
        {
            return true;
        }
    }
    return false;
}
int chupai_by_dingque_pai(map<int,int> &pai_map,int dq_color,map<int,int> &chu_map)
{
    int s=dq_color*10+1;
    int e=s+9;
    int middle=(s+e)/2;
    int pai_no=0;
    for(;s<e;s++)
    {
        if(pai_map.find(s)!=pai_map.end())
        {
            //优先选未出现过的单张
            if(pai_map[s]==1 && chu_map.find(s)==chu_map.end())
            {
                return s;
            }
            else
            {
                 //否则靠中走
                if(pai_no==0 or abs(middle-s)<abs(middle-pai_no))
                {
                    pai_no=s;
                }
            }

        }
    }
    return pai_no;
}

int base_chupai(PlayerPaiInfo &players_pai_info,map<int,int> &re_pai,map<int,int> &chu_pai)
{
    auto dq_color=players_pai_info.ding_que;
    map<int,int> &pai_map=players_pai_info.pai_map;
    if(check_have_dingque_pai(&pai_map,dq_color))
    {
        return chupai_by_dingque_pai(pai_map,dq_color,chu_pai);
    }

    map<int,double> cp_value;
    double max=0;
    for(int i=11;i<49;i++)
    {
        if(pai_map.find(i)!=pai_map.end())
        {
            pai_map[i]--;
            cp_value[i]=get_base_pai_value(&pai_map,dq_color);
            if (cp_value[i]>max)
            {
                max=cp_value[i];
            }
            pai_map[i]++;
//            cout<<"cp_value  "<<i<<"  "<<cp_value[i]<<endl;
        }
    }
    int list[40];
    int len=0;
    for(auto i=cp_value.begin() ;i!=cp_value.end();i++)
    {
        if (i->second ==max)
        {
            list[len++]=i->first;
        }
    }
    return  list[rand()%len];

}

int get_arrangement(int n,int m)
{
    int v=1;
    for(int i=n;i>(n-m);i--)
    {
        v*=i;
    }
    return v;
}
int get_combination(int n,int m)
{
    int v=1;
    for(int i=m;i>0;i--)
    {
        v*=i;
    }
    return get_arrangement(n,m)/v;
}
////获得牌面价值 lv2

bool lv2_get_gl(map<int,int> * my_pai_map,
                map<int,int> * re_pai,
                int &my_pai_count,
                int &re_pai_count,
                int &borrow_pai_sum,
                int &all_pai_sum,
                int sum,
                int pai_no,
                int & my_pai_used,
                int & re_pai_uesd,
                double &cur_gl,
                double &_gl)
{
    if(all_pai_sum+sum>14 or my_pai_map->at(pai_no)+re_pai->at(pai_no)<sum)
    {
        return false;
    }
    if (my_pai_map->at(pai_no)>=sum)
    {
        my_pai_used=sum;
        re_pai_uesd=0;
        _gl=1;
    }
    else
    {
        my_pai_used=my_pai_map->at(pai_no);
        re_pai_uesd=(sum-my_pai_map->at(pai_no));
        if(borrow_pai_sum+re_pai_uesd>max_borrow_pai)
        {
            my_pai_used=0;
            re_pai_uesd=0;
            return false;
        }
//        _gl=1;
//        for(int i=0;i<re_pai_uesd;i++)
//        {
//            _gl*=1.0/(re_pai_count-i);
//        }
        _gl=get_combination(re_pai->at(pai_no),re_pai_uesd)*1.0/get_combination(re_pai_count,re_pai_uesd);
        cur_gl*=_gl;
    }
    re_pai->at(pai_no)-=re_pai_uesd;
    my_pai_map->at(pai_no)-=my_pai_used;
    my_pai_count-=my_pai_used;
    re_pai_count-=re_pai_uesd;
    borrow_pai_sum+=re_pai_uesd;
    all_pai_sum+=re_pai_uesd;
    all_pai_sum+=my_pai_used;
    return true;
}
void lv2_add_pai(map<int,int> * my_pai_map,
                 map<int,int> * re_pai,
                 int &my_pai_count,
                 int &re_pai_count,
                 int &borrow_pai_sum,
                 int &all_pai_sum,
                 int pai_no,
                 int my_pai_used,
                 int re_pai_used,
                 double &cur_gl,
                 double _gl)
{
    my_pai_map->at(pai_no)+=my_pai_used;
    re_pai->at(pai_no)+=re_pai_used;
    my_pai_count+=my_pai_used;
    re_pai_count+=re_pai_used;
    cur_gl/=_gl;
    borrow_pai_sum-=re_pai_used;
    all_pai_sum-=re_pai_used;
    all_pai_sum-=my_pai_used;
}
void get_one_pai_value_lv2(map<int,int> * my_pai_map,
                       map<int,int> * re_pai,
                       int s_color,
                       double *jiang,
                       double * no_jiang)
{
    int test_count=0;
    int re_pai_count=0;
    int my_pai_count=0;
    int s_start=10*s_color+1;
    int s_end=s_start+9;


    int my_pai_set[50];
    int re_pai_set[50];

    for(int i=s_start;i<s_end;i++)
    {
        if(my_pai_map->find(i)==my_pai_map->end())
        {
            (*my_pai_map)[i]=0;
        }
        if(re_pai->find(i)==re_pai->end())
        {
            (*re_pai)[i]=0;
        }
        my_pai_count+=my_pai_map->at(i);
        re_pai_count+=re_pai->at(i);

        my_pai_set[i]=my_pai_map->at(i);
        re_pai_set[i]=re_pai->at(i);

    }
    get_pai_value_lv2_dp(my_pai_set,
                             my_pai_count,
                             re_pai_set,
                             re_pai_count,
                             false,
                             s_start,
                             s_end,
                             0,
                             0,
                             1,
                             jiang,
                             no_jiang,
                             s_start,
                             0);

    if(*jiang>1)
    {
        *jiang=1;
    }
    if(*no_jiang>1)
    {
        *no_jiang=1;
    }
//    cout<<test_count<<"   times "<<endl;
}
/*
 map<int,int> *my_pai_map,我的牌
 int my_pai_count, 我的牌计数
 map<int,int> *re_pai, --牌池剩余的牌
 re_pai_count
 bool is_jiang,是否有将
 int s_start,搜索起点
 int s_end,搜索结束点
 double gl;
 double *jiang,有将的价值
 double * no_jiang,无将的牌面价值
 */

void get_pai_value_lv2_dp_jddg(map<int,int> * my_pai_map,
                       int my_pai_count,
                       map<int,int> * re_pai,
                       int re_pai_count,
                       bool is_jiang,
                       int s_start,
                       int s_end,
                       int borrow_pai_sum,
                       int all_pai_sum,
                       double gl,
                       double *jiang,
                       double * no_jiang,
                       int &test_count
                         )
{
    test_count=test_count+1;
//    cout<<"test_count  "<<test_count<<" borrow_pai_sum: "<<borrow_pai_sum<<endl;

    /*
        先取 my_pai_map 概率为1
        再取re_pai 概率为1/all
     */
    int my_pai_used_count=0;
    int re_pai_used_count=0;
    double _gl=1;
    //成为将
    if(not is_jiang)
    {
        for(int i=s_start;i<s_end;i++)
        {
                if(my_pai_map->at(i)+re_pai->at(i)>1)
                {
                    if (lv2_get_gl(my_pai_map,re_pai,my_pai_count,re_pai_count,borrow_pai_sum,all_pai_sum,2,i,my_pai_used_count,re_pai_used_count,gl,_gl))
                    {
                        if(my_pai_count<=0)
                        {
                            *jiang+=gl;
                        }
//                        printf("xxxxx1\n");
                        get_pai_value_lv2_dp_jddg(my_pai_map,
                                          my_pai_count,
                                          re_pai,
                                          re_pai_count,
                                          true,
                                          s_start,
                                          s_end,
                                          borrow_pai_sum,
                                          all_pai_sum,
                                          gl,
                                          jiang,
                                          no_jiang,
                                          test_count);

                        lv2_add_pai(my_pai_map,re_pai,my_pai_count,re_pai_count,borrow_pai_sum,all_pai_sum,i,my_pai_used_count,re_pai_used_count,gl,_gl);
                    }
                }
        }
    }
    if (*jiang>=1 && is_jiang)
    {
        return ;
    }

    for(int i=s_start;i<s_end;i++)
    {
        //成为对子
        if(my_pai_map->at(i)+re_pai->at(i)>2 && all_pai_sum+3<15)
        {
            if(lv2_get_gl(my_pai_map,re_pai,my_pai_count,re_pai_count,borrow_pai_sum,all_pai_sum,3,i,my_pai_used_count,re_pai_used_count,gl,_gl))
            {
                if(my_pai_count<=0)
                {
                    if (is_jiang)
                    {
                        *jiang+=gl;
                    }
                    else
                    {
                        *no_jiang+=gl;
                    }
                }
                get_pai_value_lv2_dp_jddg(my_pai_map,
                                  my_pai_count,
                                  re_pai,
                                  re_pai_count,
                                  is_jiang,
                                  s_start,
                                  s_end,
                                  borrow_pai_sum,
                                     all_pai_sum,
                                  gl,
                                  jiang,
                                  no_jiang,
                                  test_count);

                lv2_add_pai(my_pai_map,re_pai,my_pai_count,re_pai_count,borrow_pai_sum,all_pai_sum,i,my_pai_used_count,re_pai_used_count,gl,_gl);
            }
        }
    }
    for(int i=s_start;i<s_end;i++)
    {
         //成为顺子
        if(i<s_end-2 && all_pai_sum+3<15 &&my_pai_map->at(i)+re_pai->at(i)>0 && my_pai_map->at(i+1)+re_pai->at(i+1)>0 && my_pai_map->at(i+2)+re_pai->at(i+2)>0 )
        {

            if (lv2_get_gl(my_pai_map,re_pai,my_pai_count,re_pai_count,borrow_pai_sum,all_pai_sum,1,i,my_pai_used_count,re_pai_used_count,gl,_gl))
            {
                int my_pai_used_count_1=0;
                int re_pai_used_count_1=0;
                int my_pai_used_count_2=0;
                int re_pai_used_count_2=0;
                double _gl_1=1;
                double _gl_2=1;

                if(lv2_get_gl(my_pai_map,re_pai,my_pai_count,re_pai_count,borrow_pai_sum,all_pai_sum,1,i+1,my_pai_used_count_1,re_pai_used_count_1,gl,_gl_1) &&
                   lv2_get_gl(my_pai_map,re_pai,my_pai_count,re_pai_count,borrow_pai_sum,all_pai_sum,1,i+2,my_pai_used_count_2,re_pai_used_count_2,gl,_gl_2))
                {

                        if(my_pai_count<=0)
                        {
                            if (is_jiang)
                            {
                                (*jiang)+=gl;
                            }
                            else
                            {
                                (*no_jiang)+=gl;
                            }
                        }
                        get_pai_value_lv2_dp_jddg(my_pai_map,
                                          my_pai_count,
                                          re_pai,
                                          re_pai_count,
                                          is_jiang,
                                          s_start,
                                          s_end,
                                          borrow_pai_sum,
                                             all_pai_sum,
                                          gl,
                                          jiang,
                                          no_jiang,
                                          test_count);

                        lv2_add_pai(my_pai_map,re_pai,my_pai_count,re_pai_count,borrow_pai_sum,all_pai_sum,i,my_pai_used_count,re_pai_used_count,gl,_gl);
                        lv2_add_pai(my_pai_map,re_pai,my_pai_count,re_pai_count,borrow_pai_sum,all_pai_sum,i+1,my_pai_used_count_1,re_pai_used_count_1,gl,_gl_1);
                        lv2_add_pai(my_pai_map,re_pai,my_pai_count,re_pai_count,borrow_pai_sum,all_pai_sum,i+2,my_pai_used_count_2,re_pai_used_count_2,gl,_gl_2);
                }
                else
                {
                    lv2_add_pai(my_pai_map,re_pai,my_pai_count,re_pai_count,borrow_pai_sum,all_pai_sum,i,my_pai_used_count,re_pai_used_count,gl,_gl);
                    lv2_add_pai(my_pai_map,re_pai,my_pai_count,re_pai_count,borrow_pai_sum,all_pai_sum,i+1,my_pai_used_count_1,re_pai_used_count_1,gl,_gl_1);
                    lv2_add_pai(my_pai_map,re_pai,my_pai_count,re_pai_count,borrow_pai_sum,all_pai_sum,i+2,my_pai_used_count_2,re_pai_used_count_2,gl,_gl_2);
                }
            }
        }
    }
}

//获得牌面价值lv2
double get_pai_value_lv2(map<int,int> *pai_map,map<int,int> *re_pai,int dq_color,map<int,double> &jiang_map,map<int,double> &no_jiang_map)
{
    int color_num[4];
    for(int i=1;i<4;i++)
    {
        color_num[i]=get_pai_hash_value_by_color(pai_map,i);
    }
    double jiang_value[4];
    double no_jiang_value[4];
    for(int i=1;i<4;i++)
    {
        if(jiang_map.find(color_num[i])!=jiang_map.end())
        {
            jiang_value[i]=jiang_map[color_num[i]];
            jiang_value[i]=no_jiang_map[color_num[i]];
        }
        else
        {
            get_one_pai_value_lv2(pai_map,
                               re_pai,
                               i,
                               &(jiang_value[i]),
                               &(no_jiang_value[i]));
//            get_one_pai_value_lv2_by_hash(   pai_map,
//                                             re_pai,
//                                             i,
//                                             &(jiang_value[i]),
//                                             &(no_jiang_value[i]));

            jiang_map[color_num[i]]=jiang_value[i];
            no_jiang_map[color_num[i]]=no_jiang_value[i];
        }
    }
    double max=0;
    for(int i=1;i<4;i++)
    {
        if (i!=dq_color)
        {
            for(int k=1;k<4;k++)
            {
                if (k!=dq_color && k!=i)
                {
                    if(jiang_value[i]+no_jiang_value[k]>max)
                    {
                        max=jiang_value[i]+no_jiang_value[k];
                    }
                }

            }
        }
    }
    return max;
}

int chupai_lv2(PlayerPaiInfo &players_pai_info,map<int,int> &re_pai,map<int,int> &chu_pai)
{
    auto ding_que=players_pai_info.ding_que;
    map<int,int> &pai_map=players_pai_info.pai_map;
    if(check_have_dingque_pai(&pai_map,ding_que))
    {
        return chupai_by_dingque_pai(pai_map,ding_que,chu_pai);
    }

    map<int,double> jiang_value;
    map<int,double> no_jiang_value;

    map<int,double> cp_value;

    double max=0;
    for(int i=11;i<49;i++)
    {
        if(pai_map.find(i)!=pai_map.end() &&  pai_map[i]>0)
        {
            pai_map[i]--;
            cp_value[i]=get_pai_value_lv2(&pai_map,&re_pai,ding_que,jiang_value,no_jiang_value);
            if (cp_value[i]>max)
            {
                max=cp_value[i];
            }
            pai_map[i]++;
        }
    }
    //如果最大值为0 则尝试lv1的方式
    if(max==0)
    {
        return base_chupai(players_pai_info,re_pai,chu_pai);
    }

    int list[40];
    int len=0;
    for(auto i=cp_value.begin() ;i!=cp_value.end();i++)
    {
        if (i->second ==max)
        {
            list[len++]=i->first;
        }
    }
    return  list[rand()%len];
}
//剩余的牌初始化
void init_re_pai(map<int,int> &chu_pai,map<int,int> &re_pai)
{
    for(int i=11;i<40;i++)
    {
        re_pai[i]=0;
        if(i%10!=0)
        {
            re_pai[i]=4;
            if (chu_pai.find(i)!=chu_pai.end())
            {
                re_pai[i]-=chu_pai[i];
            }
        }
    }
}
void buquan_chu_pai(vector<PlayerPaiInfo> &players_pai,map<int,int> &chu_pai)
{
    //补全出牌  把碰杠也算到出牌里面
    for(auto i:players_pai)
    {
        for(auto &k:i.pg_map)
        {
            if (chu_pai.find(k.first)==chu_pai.end())
            {
                if(k.second=="peng")
                {
                    chu_pai[k.first]=3;
                }
                else
                {
                    chu_pai[k.first]=4;
                }
            }
            else
            {
                if(k.second=="peng")
                {
                    chu_pai[k.first]+=3;
                }
                else
                {
                    chu_pai[k.first]=4;
                }
            }
        }
    }
}
//struct PlayerPaiInfo
//{
//    std::map<int,int> pai_map;
//    std::map<int,std::string> pg_map;    // 碰杠信息： "peng","zg","wg","ag"
//    int ding_que;
//};
int get_chupai(vector<PlayerPaiInfo> &players_pai,vector<int> &pai_pool,map<int,int> &chu_pai,int tuguan_level)
{
    buquan_chu_pai(players_pai,chu_pai);
    map<int,int> re_pai;
    init_re_pai(chu_pai,re_pai);

    if(tuguan_level==1)
    {
        return base_chupai(players_pai[0],re_pai,chu_pai);
    }
    else if(tuguan_level==2)
    {
        return chupai_lv2(players_pai[0],re_pai,chu_pai);
    }
    return 0;
}
int can_peng(vector<PlayerPaiInfo> &players_pai,vector<int> &pai_pool,map<int,int> &chu_pai,int peng)
{
    //剩余的牌初始化
    buquan_chu_pai(players_pai,chu_pai);
    map<int,int> re_pai;
    init_re_pai(chu_pai,re_pai);

    auto ding_que=players_pai[0].ding_que;
    map<int,int> &pai_map=players_pai[0].pai_map;
    //还有未出完的定缺牌 一定碰
    if(check_have_dingque_pai(&pai_map,ding_que))
    {
        return 1;
    }
    //计算没碰之前的积分
    map<int,double> jiang_value;
    map<int,double> no_jiang_value;
    double max=get_pai_value_lv2(&pai_map,&re_pai,ding_que,jiang_value,no_jiang_value);
    pai_map[peng]-=2;

    for(int i=11;i<49;i++)
    {
        if(pai_map.find(i)!=pai_map.end())
        {
            pai_map[i]--;
            auto fen=get_pai_value_lv2(&pai_map,&re_pai,ding_que,jiang_value,no_jiang_value);
            if (fen>max)
            {
                return 1;
            }
            pai_map[i]++;
        }
    }
    return 0;
}
//暂时不启用
int can_gang(vector<PlayerPaiInfo> &players_pai,vector<int> &pai_pool,map<int,int> &chu_pai,int gang)
{
    buquan_chu_pai(players_pai,chu_pai);
    //剩余的牌初始化
    map<int,int> re_pai;
    init_re_pai(chu_pai,re_pai);

    auto ding_que=players_pai[0].ding_que;
    map<int,int> &pai_map=players_pai[0].pai_map;
    //还有未出完的定缺牌 一定杠
    if(check_have_dingque_pai(&pai_map,ding_que))
    {
        return 1;
    }
    //计算没杠之前的积分
    map<int,double> jiang_value;
    map<int,double> no_jiang_value;
//    double max=get_pai_value_lv2(&pai_map,&re_pai,ding_que,jiang_value,no_jiang_value);
    pai_map[gang]=0;


    auto fen=get_pai_value_lv2(&pai_map,&re_pai,ding_que,jiang_value,no_jiang_value);
    //只要杠了之后不是完全把牌废掉就杠
    if (fen>0)
    {
        return 1;
    }

    fen=get_base_pai_value(&pai_map,ding_que);
    if(fen>0.05)
    {
        return 1;
    }

    return 0;
}




bool ls_get_gl_lv2(int * my_pai_map,
                   int * re_pai,
                   int &my_pai_count,
                   int &re_pai_count,
                   int &borrow_pai_sum,
                   int &all_pai_sum,
                   int sum,
                   int pai_no,
                   int & my_pai_used,
                   int & re_pai_uesd,
                   double &_gl)
{
    if(all_pai_sum+sum>14 or my_pai_map[pai_no]+re_pai[pai_no]<sum)
    {
        return false;
    }
    if (my_pai_map[pai_no]>=sum)
    {
        my_pai_used=sum;
        re_pai_uesd=0;
        _gl=1;
    }
    else
    {
        my_pai_used=my_pai_map[pai_no];
        re_pai_uesd=(sum-my_pai_map[pai_no]);
        if(borrow_pai_sum+re_pai_uesd>max_borrow_pai)
        {
            my_pai_used=0;
            re_pai_uesd=0;
            return false;
        }
        _gl=get_combination(re_pai[pai_no],re_pai_uesd)*1.0/get_combination(re_pai_count,re_pai_uesd);
    }
    re_pai[pai_no]-=re_pai_uesd;
    my_pai_map[pai_no]-=my_pai_used;
    my_pai_count-=my_pai_used;
    re_pai_count-=re_pai_uesd;
    borrow_pai_sum+=re_pai_uesd;
    all_pai_sum+=re_pai_uesd;
    all_pai_sum+=my_pai_used;
    return true;
}
void ls_add_pai_lv2(int * my_pai_map,
                    int * re_pai,
                    int &my_pai_count,
                    int &re_pai_count,
                    int &borrow_pai_sum,
                    int &all_pai_sum,
                    int pai_no,
                    int my_pai_used,
                    int re_pai_used)
{
    my_pai_map[pai_no]+=my_pai_used;
    re_pai[pai_no]+=re_pai_used;
    my_pai_count+=my_pai_used;
    re_pai_count+=re_pai_used;
    borrow_pai_sum-=re_pai_used;
    all_pai_sum-=re_pai_used;
    all_pai_sum-=my_pai_used;
}

int test_count=0;
void get_pai_value_lv2_dp_only_re_pai(
                                      int * my_pai_map,
                                      int my_pai_count,
                                      int * re_pai,
                                      int re_pai_count,
                                      bool is_jiang,
                                      int s_start,
                                      int s_end,
                                      int borrow_pai_sum,
                                      int all_pai_sum,
                                      double gl,
                                      double *jiang,
                                      double * no_jiang,
                                      int cur_pos,
                                      int cur_type)
{
    if (is_jiang)
    {
        *jiang+=gl;
    }
    else
    {
        *no_jiang+=gl;
    }
//    return ;
    if(borrow_pai_sum>4 or all_pai_sum>14 or cur_pos>=s_end)
    {
        return ;
    }
    test_count=test_count+1;
    //    cout<<"test_count  "<<test_count<<" borrow_pai_sum: "<<borrow_pai_sum<<endl;


    int my_pai_used=0;
    int re_pai_used=0;
    double _gl=1;
    if(re_pai[cur_pos]>0)
    {
        if(cur_type==0)
        {
            if(not is_jiang && re_pai[cur_pos]>1 && ls_get_gl_lv2(my_pai_map,
                                                      re_pai,
                                                      my_pai_count,
                                                      re_pai_count,
                                                      borrow_pai_sum,
                                                      all_pai_sum,
                                                      2,
                                                      cur_pos,
                                                      my_pai_used,
                                                      re_pai_used,
                                                      _gl))
            {
                get_pai_value_lv2_dp_only_re_pai(my_pai_map,
                                           my_pai_count,
                                           re_pai,
                                           re_pai_count,
                                           is_jiang,
                                           s_start,
                                           s_end,
                                           borrow_pai_sum,
                                           all_pai_sum,
                                           gl*_gl,
                                           jiang,
                                           no_jiang,
                                           cur_pos,
                                           1);

                ls_add_pai_lv2(my_pai_map,
                                re_pai,
                                my_pai_count,
                                re_pai_count,
                                borrow_pai_sum,
                                all_pai_sum,
                                cur_pos,
                                my_pai_used,
                                re_pai_used);
            }
            if(re_pai[cur_pos]>2 && ls_get_gl_lv2(my_pai_map,
                                                      re_pai,
                                                      my_pai_count,
                                                      re_pai_count,
                                                      borrow_pai_sum,
                                                      all_pai_sum,
                                                      3,
                                                      cur_pos,
                                                      my_pai_used,
                                                      re_pai_used,
                                                      _gl))
            {

                get_pai_value_lv2_dp_only_re_pai(my_pai_map,
                                           my_pai_count,
                                           re_pai,
                                           re_pai_count,
                                           is_jiang,
                                           s_start,
                                           s_end,
                                           borrow_pai_sum,
                                           all_pai_sum,
                                           gl*_gl,
                                           jiang,
                                           no_jiang,
                                           cur_pos,
                                           1);

                ls_add_pai_lv2(my_pai_map,
                               re_pai,
                               my_pai_count,
                               re_pai_count,
                               borrow_pai_sum,
                               all_pai_sum,
                               cur_pos,
                               my_pai_used,
                               re_pai_used);
            }
        }
        //成为顺子
        if(cur_pos<s_end-2 && re_pai[cur_pos]>0 && re_pai[cur_pos+1]>0 && re_pai[cur_pos+2]>0)
        {
            int my_pai_used_count_1[3]={0,0,0};
            int re_pai_used_count_1[3]={0,0,0};
            double _gl_1[3]={1,1,1};
            bool flag=true;
            for(int i=0;i<3;i++)
            {
                if (not ls_get_gl_lv2(my_pai_map,
                              re_pai,
                              my_pai_count,
                              re_pai_count,
                              borrow_pai_sum,
                              all_pai_sum,
                              1,
                              cur_pos+i,
                              my_pai_used_count_1[i],
                              re_pai_used_count_1[i],
                              _gl_1[i]))
                {
                    flag=false;
                    break;
                }
            }

            if(flag)
            {

                    get_pai_value_lv2_dp_only_re_pai(my_pai_map,
                                   my_pai_count,
                                   re_pai,
                                   re_pai_count,
                                   is_jiang,
                                   s_start,
                                   s_end,
                                   borrow_pai_sum,
                                   all_pai_sum,
                                   gl*_gl_1[0]*_gl_1[1]*_gl_1[2],
                                   jiang,
                                   no_jiang,
                                   cur_pos,
                                   1);
                    for(int i=0;i<3;i++)
                    {
                        ls_add_pai_lv2(my_pai_map,
                                        re_pai,
                                        my_pai_count,
                                        re_pai_count,
                                        borrow_pai_sum,
                                        all_pai_sum,
                                        cur_pos+i,
                                        my_pai_used_count_1[i],
                                        re_pai_used_count_1[i]);
                    }

            }
            else
            {
                for(int i=0;i<3;i++)
                {
                    ls_add_pai_lv2(my_pai_map,
                                    re_pai,
                                    my_pai_count,
                                    re_pai_count,
                                    borrow_pai_sum,
                                    all_pai_sum,
                                    cur_pos+i,
                                    my_pai_used_count_1[i],
                                    re_pai_used_count_1[i]);
                }
            }

        }
    }
    else
    {
        int my_pai_used_count_1[4][3]={{0,0,0},{0,0,0},{0,0,0},{0,0,0}};
        int re_pai_used_count_1[4][3]={{0,0,0},{0,0,0},{0,0,0},{0,0,0}};
        double _gl_1[4][3]={{1,1,1},{1,1,1},{1,1,1},{1,1,1}};
        int len=0;
        for(int k=0;k<4;k++)
        {
            len++;
            if(cur_pos<s_end-2 && re_pai[cur_pos]>0 && re_pai[cur_pos+1]>0 && re_pai[cur_pos+2]>0)
            {
                bool flag=true;
                for(int i=0;i<3;i++)
                {
                    if (not ls_get_gl_lv2(my_pai_map,
                                  re_pai,
                                  my_pai_count,
                                  re_pai_count,
                                  borrow_pai_sum,
                                  all_pai_sum,
                                  1,
                                  cur_pos+i,
                                  my_pai_used_count_1[k][i],
                                  re_pai_used_count_1[k][i],
                                  _gl_1[k][i]))
                    {
                        flag=false;
                        break;
                    }
                }

                if(flag)
                {
                    get_pai_value_lv2_dp_only_re_pai(my_pai_map,
                               my_pai_count,
                               re_pai,
                               re_pai_count,
                               is_jiang,
                               s_start,
                               s_end,
                               borrow_pai_sum,
                               all_pai_sum,
                               gl*_gl_1[k][0]*_gl_1[k][1]*_gl_1[k][2],
                               jiang,
                               no_jiang,
                               cur_pos+1,
                               0);


                }
                else
                {
                    break;
                }
            }
            else
            {
                break;
            }
        }
        for(int k=0;k<len;k++)
        {
            for(int i=0;i<3;i++)
            {
                ls_add_pai_lv2(my_pai_map,
                                re_pai,
                                my_pai_count,
                                re_pai_count,
                                borrow_pai_sum,
                                all_pai_sum,
                                cur_pos+i,
                                my_pai_used_count_1[k][i],
                                re_pai_used_count_1[k][i]);
            }
        }
        get_pai_value_lv2_dp_only_re_pai(my_pai_map,
                                   my_pai_count,
                                   re_pai,
                                   re_pai_count,
                                   is_jiang,
                                   s_start,
                                   s_end,
                                   borrow_pai_sum,
                                   all_pai_sum,
                                   gl,
                                   jiang,
                                   no_jiang,
                                   cur_pos+1,
                                   0);
    }
}
/*
 map<int,int> *my_pai_map,我的牌
 int my_pai_count, 我的牌计数
 map<int,int> *re_pai, --牌池剩余的牌
 re_pai_count
 bool is_jiang,是否有将
 int s_start,搜索起点
 int s_end,搜索结束点
 double gl;
 double *jiang,有将的价值
 double * no_jiang,无将的牌面价值
 */
void get_pai_value_lv2_dp(int* my_pai_map,
                            int my_pai_count,
                            int * re_pai,
                            int re_pai_count,
                            bool is_jiang,
                            int s_start,
                            int s_end,
                            int borrow_pai_sum,
                            int all_pai_sum,
                            double gl,
                            double *jiang,
                            double * no_jiang,
                            int cur_pos,
                            int cur_type
                            )
{
    if(cur_pos>=s_end)
    {
        return ;
    }
    int my_pai_used=0;
    int re_pai_used=0;
    double _gl=1;
    if(my_pai_map[cur_pos]>0)
    {
        if(cur_type==0)
        {
            if(my_pai_map[cur_pos]>1 && ls_get_gl_lv2(my_pai_map,
                                                      re_pai,
                                                      my_pai_count,
                                                      re_pai_count,
                                                      borrow_pai_sum,
                                                      all_pai_sum,
                                                      2,
                                                      cur_pos,
                                                      my_pai_used,
                                                      re_pai_used,
                                                      _gl))
            {
                if(my_pai_count==0)
                {
                    get_pai_value_lv2_dp_only_re_pai(my_pai_map,
                                           my_pai_count,
                                           re_pai,
                                           re_pai_count,
                                           is_jiang,
                                           s_start,
                                           s_end,
                                           borrow_pai_sum,
                                           all_pai_sum,
                                           gl*_gl,
                                           jiang,
                                           no_jiang,
                                           s_start,
                                           0);
                }
                else
                {
                    get_pai_value_lv2_dp(my_pai_map,
                                           my_pai_count,
                                           re_pai,
                                           re_pai_count,
                                           is_jiang,
                                           s_start,
                                           s_end,
                                           borrow_pai_sum,
                                           all_pai_sum,
                                           gl*_gl,
                                           jiang,
                                           no_jiang,
                                           cur_pos,
                                           1);
                }
                ls_add_pai_lv2(my_pai_map,
                                re_pai,
                                my_pai_count,
                                re_pai_count,
                                borrow_pai_sum,
                                all_pai_sum,
                                cur_pos,
                                my_pai_used,
                                re_pai_used);
            }
            if(my_pai_map[cur_pos]>2 && ls_get_gl_lv2(my_pai_map,
                                                      re_pai,
                                                      my_pai_count,
                                                      re_pai_count,
                                                      borrow_pai_sum,
                                                      all_pai_sum,
                                                      3,
                                                      cur_pos,
                                                      my_pai_used,
                                                      re_pai_used,
                                                      _gl))
            {
                if(my_pai_count==0)
                {
                    get_pai_value_lv2_dp_only_re_pai(my_pai_map,
                                           my_pai_count,
                                           re_pai,
                                           re_pai_count,
                                           is_jiang,
                                           s_start,
                                           s_end,
                                           borrow_pai_sum,
                                           all_pai_sum,
                                           gl*_gl,
                                           jiang,
                                           no_jiang,
                                           s_start,
                                           0);
                }
                else
                {
                    get_pai_value_lv2_dp(my_pai_map,
                                           my_pai_count,
                                           re_pai,
                                           re_pai_count,
                                           is_jiang,
                                           s_start,
                                           s_end,
                                           borrow_pai_sum,
                                           all_pai_sum,
                                           gl*_gl,
                                           jiang,
                                           no_jiang,
                                           cur_pos,
                                           1);
                }
                ls_add_pai_lv2(my_pai_map,
                               re_pai,
                               my_pai_count,
                               re_pai_count,
                               borrow_pai_sum,
                               all_pai_sum,
                               cur_pos,
                               my_pai_used,
                               re_pai_used);
            }
        }
                //成为顺子
        if(cur_pos<s_end-2)
        {
            int my_pai_used_count_1[3]={0,0,0};
            int re_pai_used_count_1[3]={0,0,0};
            double _gl_1[3]={1,1,1};
            bool flag=true;
            for(int i=0;i<3;i++)
            {
                if (not ls_get_gl_lv2(my_pai_map,
                              re_pai,
                              my_pai_count,
                              re_pai_count,
                              borrow_pai_sum,
                              all_pai_sum,
                              1,
                              cur_pos+i,
                              my_pai_used_count_1[i],
                              re_pai_used_count_1[i],
                              _gl_1[i]))
                {
                    flag=false;
                    break;
                }
            }

            if(flag)
            {

                    if(my_pai_count==0)
                    {
                        get_pai_value_lv2_dp_only_re_pai(my_pai_map,
                                           my_pai_count,
                                           re_pai,
                                           re_pai_count,
                                           is_jiang,
                                           s_start,
                                           s_end,
                                           borrow_pai_sum,
                                           all_pai_sum,
                                           gl*_gl_1[0]*_gl_1[1]*_gl_1[2],
                                           jiang,
                                           no_jiang,
                                           s_start,
                                           0);
                    }
                    else
                    {
                        get_pai_value_lv2_dp(my_pai_map,
                                   my_pai_count,
                                   re_pai,
                                   re_pai_count,
                                   is_jiang,
                                   s_start,
                                   s_end,
                                   borrow_pai_sum,
                                   all_pai_sum,
                                   gl*_gl_1[0]*_gl_1[1]*_gl_1[2],
                                   jiang,
                                   no_jiang,
                                   cur_pos,
                                   1);
                    }
                    for(int i=0;i<3;i++)
                    {
                        ls_add_pai_lv2(my_pai_map,
                                        re_pai,
                                        my_pai_count,
                                        re_pai_count,
                                        borrow_pai_sum,
                                        all_pai_sum,
                                        cur_pos+i,
                                        my_pai_used_count_1[i],
                                        re_pai_used_count_1[i]);
                    }

            }
            else
            {
                for(int i=0;i<3;i++)
                {
                    ls_add_pai_lv2(my_pai_map,
                                    re_pai,
                                    my_pai_count,
                                    re_pai_count,
                                    borrow_pai_sum,
                                    all_pai_sum,
                                    cur_pos+i,
                                    my_pai_used_count_1[i],
                                    re_pai_used_count_1[i]);
                }
            }

        }
    }
    else
    {
        int my_pai_used_count_1[4][3]={{0,0,0},{0,0,0},{0,0,0},{0,0,0}};
        int re_pai_used_count_1[4][3]={{0,0,0},{0,0,0},{0,0,0},{0,0,0}};
        double _gl_1[4][3]={{1,1,1},{1,1,1},{1,1,1},{1,1,1}};
        int len=0;
        for(int k=0;k<4;k++)
        {
            len++;
            if(cur_pos<s_end-2 && (my_pai_map[cur_pos]>0 or my_pai_map[cur_pos+1]>0 or my_pai_map[cur_pos+2]>0))
            {
                bool flag=true;
                for(int i=0;i<3;i++)
                {
                    if (not ls_get_gl_lv2(my_pai_map,
                                  re_pai,
                                  my_pai_count,
                                  re_pai_count,
                                  borrow_pai_sum,
                                  all_pai_sum,
                                  1,
                                  cur_pos+i,
                                  my_pai_used_count_1[k][i],
                                  re_pai_used_count_1[k][i],
                                  _gl_1[k][i]))
                    {
                        flag=false;
                        break;
                    }
                }

                if(flag)
                {

                        if(my_pai_count==0)
                        {
                            get_pai_value_lv2_dp_only_re_pai(my_pai_map,
                                       my_pai_count,
                                       re_pai,
                                       re_pai_count,
                                       is_jiang,
                                       s_start,
                                       s_end,
                                       borrow_pai_sum,
                                       all_pai_sum,
                                       gl*_gl_1[k][0]*_gl_1[k][1]*_gl_1[k][2],
                                       jiang,
                                       no_jiang,
                                       s_start,
                                       0);
                        }
                        else
                        {
                            get_pai_value_lv2_dp(my_pai_map,
                                       my_pai_count,
                                       re_pai,
                                       re_pai_count,
                                       is_jiang,
                                       s_start,
                                       s_end,
                                       borrow_pai_sum,
                                       all_pai_sum,
                                       gl*_gl_1[k][0]*_gl_1[k][1]*_gl_1[k][2],
                                       jiang,
                                       no_jiang,
                                       cur_pos+1,
                                       0);
                        }

                }
                else
                {
                    break;
                }
            }
            else
            {
                break;
            }
        }
        for(int k=0;k<len;k++)
        {
            for(int i=0;i<3;i++)
            {
                ls_add_pai_lv2(my_pai_map,
                                re_pai,
                                my_pai_count,
                                re_pai_count,
                                borrow_pai_sum,
                                all_pai_sum,
                                cur_pos+i,
                                my_pai_used_count_1[k][i],
                                re_pai_used_count_1[k][i]);
            }
        }
        if(my_pai_count==0)
        {
            get_pai_value_lv2_dp_only_re_pai(my_pai_map,
                       my_pai_count,
                       re_pai,
                       re_pai_count,
                       is_jiang,
                       s_start,
                       s_end,
                       borrow_pai_sum,
                       all_pai_sum,
                       gl,
                       jiang,
                       no_jiang,
                       s_start,
                       0);
        }
        else
        {

            get_pai_value_lv2_dp(my_pai_map,
                                   my_pai_count,
                                   re_pai,
                                   re_pai_count,
                                   is_jiang,
                                   s_start,
                                   s_end,
                                   borrow_pai_sum,
                                   all_pai_sum,
                                   gl,
                                   jiang,
                                   no_jiang,
                                   cur_pos+1,
                                   0);
        }
    }
}

void get_mj_hp_relation(map<int,bool> &all_relation,int num,bool have_jiang)
{
    std::map<int,std::vector<int>> *data_map;
    if (have_jiang)
    {
        data_map=&jiang_nor_mj_hp_relation_map;
    }
    else
    {
        data_map=&no_jiang_nor_mj_hp_relation_map;
    }
    int vec[1000000];
    map<int,bool> ls_flag;
    int max=1;
    vec[0]=num;
    for(int i=0;i<max;i++)
    {
        if(data_map->find(vec[i])!=data_map->end())
        {
            vector<int> & father=data_map->at(vec[i]);
            if(father.empty())
            {
                all_relation[vec[i]]=true;
            }
            else
            {
                for(auto k:father)
                {
                    if(ls_flag.find(k)==ls_flag.end())
                    {
                        vec[max++]=k;
                        ls_flag[k]=true;
                    }
                }
            }
        }
    }
    cout<<max<<endl;

}
//plzh 排列组合
double calculate_gl_lv2_by_plzh( map<int,bool> & data_map,int num,int *re_pai_map,int all_count_re_pai)
{
    double all_gl=0;
    int pos_list[10];
    int value_lis[10];
    int len=0;
    for(auto i:data_map)
    {
        int need=i.first-num;
        int count=0;
        int value=0;
        bool flag=true;
        len=0;
        for(int k=9;k>0;k--)
        {
            value=need%10;
            if(re_pai_map[k]<value)
            {
                flag=false;
                break;
            }

            pos_list[len]=k;
            value_lis[len++]=value;

            count+=value;
            need/=10;
            if (need==0)
            {
                break;
            }
        }
        if(flag)
        {
            int ag=get_arrangement(all_count_re_pai,count);

            int c=1;
            for(int i=0;i<len;i++)
            {
                c*=get_combination(re_pai_map[pos_list[i]],value_lis[i]);
            }
            c*=get_arrangement(len,len);
            all_gl+=1.0*c/ag;
        }
    }
    return all_gl;
}
void get_one_pai_value_lv2_by_hash(map<int,int> * my_pai_map,
                           map<int,int> * re_pai,
                           int s_color,
                           double *jiang,
                           double * no_jiang)
{
    int my_pai_num=get_pai_hash_value_by_color(my_pai_map,s_color);

    int re_pai_map[10];
    int all_count=get_pai_value_by_pai_map(re_pai_map,re_pai,s_color);

    map<int,bool> jiang_map;
    map<int,bool> no_jiang_map;
    get_mj_hp_relation(jiang_map,my_pai_num,true);
    get_mj_hp_relation(no_jiang_map,my_pai_num,false);

    *jiang=calculate_gl_lv2_by_plzh(jiang_map,my_pai_num,re_pai_map,all_count);
    * no_jiang=calculate_gl_lv2_by_plzh( no_jiang_map,my_pai_num,re_pai_map,all_count);

}

int special_deal_chupai(map<int,int> &pai_map,int dq_color, map<int,int> &chu_pai)
{
    if(check_have_dingque_pai(&pai_map,dq_color))
    {
        return chupai_by_dingque_pai(pai_map,dq_color,chu_pai);
    }
    //暂时先随机出
    for(int i=11;i<40;i++)
    {
        if(pai_map.find(i)!=pai_map.end())
        {
                return i;
        }
    }
    return 0;
}

