//
//  mj_hupai_typ_ compute.hpp
//  mj_hp_table
//
//  Created by 何威 on 2018/11/9.
//  Copyright © 2018年 何威. All rights reserved.
//

#ifndef mj_hupai_typ__compute_hpp
#define mj_hupai_typ__compute_hpp

#include <stdio.h>
#include <vector>
#include <map>
#include <iostream>
#include <string.h>
#include <math.h>

extern std::map<int,std::vector<int>> no_jiang_nor_mj_hp_relation_map;
extern std::map<int,std::vector<int>> jiang_nor_mj_hp_relation_map;

int get_pai_hash_value(int * pai_map);
int get_pai_hash_value_by_color(std::map<int,int> *pai_map,int color);
int get_pai_value_by_num(int * pai_map,int num);
int get_pai_value_by_pai_map(int * pai_map,std::map<int,int> *re_pai_hash,int color);
int add_jiang(int pai_no,int *pai_count,int *pai_map);
int add_shunzi(int pai_no,int *pai_count,int *pai_map);
int add_duizi(int pai_no,int *pai_count,int *pai_map);
int reduce_jiang(int pai_no,int *pai_count,int *pai_map);
int reduce_shunzi(int pai_no,int *pai_count,int *pai_map);
int reduce_duizi(int pai_no,int *pai_count,int *pai_map);
//获得一共有多少种胡牌种类
void get_hp_type_count(int *count,int is_jiang,int *pai_count,int *pai_map,int * hp_list, int *hp_list_count,int * hp_jiang_list, int *hp_jiang_list_count);

void create_hu_relation_hash();
#endif /* mj_hupai_typ__compute_hpp */
