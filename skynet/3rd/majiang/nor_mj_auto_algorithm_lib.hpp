//
//  nor_mj_auto_ algorithm_lib.hpp
//  mj_hp_table
//
//  Created by 何威 on 2018/11/2.
//  Copyright © 2018年 何威. All rights reserved.
//

#ifndef nor_mj_auto__algorithm_lib_hpp
#define nor_mj_auto__algorithm_lib_hpp

#include <stdio.h>
#include <vector>
#include <map>
#include <iostream>
#include <string.h>
#include <math.h>
#include "majiang.h"

using namespace std;


extern std::map<int,double> no_jiang_nor_mj_hp_map;
extern std::map<int,double> jiang_nor_mj_hp_map;

extern std::map<int,std::vector<int>> no_jiang_nor_mj_hp_relation_map;
extern std::map<int,std::vector<int>> jiang_nor_mj_hp_relation_map;

double get_one_pai_value(int num,bool is_jiang);
double get_base_pai_value(map<int,int> *pai_map,int dq_color);
bool check_have_dingque_pai(map<int,int> *pai_map,int dq_color);
int chupai_by_dingque_pai(map<int,int> *pai_map,int dq_color);
int base_chupai(PlayerPaiInfo &players_pai_info,map<int,int> &re_pai,map<int,int> &chu_pai);
int get_chupai(vector<PlayerPaiInfo> &players_pai,vector<int> &pai_pool,map<int,int> &chu_pai,int tuguan_level);
int special_deal_chupai(map<int,int> &pai_map,int dq_color, map<int,int> &chu_pai);

//level 2
void get_one_pai_value_lv2(map<int,int> * my_pai_map,
                       map<int,int> * re_pai,
                       int s_color,
                       double *jiang,
                       double * no_jiang);
//jddg  简单递归
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
                          int &test_count);
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
                            );
double get_pai_value_lv2(map<int,int> *pai_map,map<int,int> *re_pai,int dq_color, map<int,double> &jiang_map,map<int,double> &no_jiang_map);
int chupai_lv2(PlayerPaiInfo &players_pai_info,map<int,int> &re_pai,map<int,int> &chu_pai);
int can_peng(vector<PlayerPaiInfo> &players_pai,vector<int> &pai_pool,map<int,int> &chu_pai,int peng);
int can_gang(vector<PlayerPaiInfo> &players_pai,vector<int> &pai_pool,map<int,int> &chu_pai,int gang);

void get_one_pai_value_lv2_by_hash(map<int,int> * my_pai_map,
                           map<int,int> * re_pai,
                           int s_color,
                           double *jiang,
                           double * no_jiang);
#endif /* nor_mj_auto__algorithm_lib_hpp */
