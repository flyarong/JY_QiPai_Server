//
//  ddz_boyi_search.hpp
//  ddz_ai
//
//  Created by 何威 on 2019/4/1.
//  Copyright © 2019 何威. All rights reserved.
//

#ifndef ddz_boyi_search_hpp
#define ddz_boyi_search_hpp

#include <stdio.h>
#include <map>
#include <list>
#include <vector>
#include <string>

#include "fenpai.h"

using namespace std;

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
                    int times_limit);
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
                    int times_limit);

//void get_all_cp_value_boyi(
//                           vector<pai_struct> &cp_return_list,
//                           map<int,map<int,int>>&pai_map,
//                           map<int,int> &seat_type,
//                           map<int,int> &game_over_info,
//                           map<int,int> &kaiguan,
//                           map<int,int> &cp_count,
//                           int cur_p,
//                           int all_seat,
//                           int cp_p,
//                           pai_struct * cp_data,
//                           int times_limit);
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
                           int times_limit);
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
                         pai_struct * cp_data,
                         int depth,
                         int times_limit,
                         bool is_max,
                         int a_b_cut);

void change_pai_count_from_map(map<int,int> &pai_map,pai_struct *p_s,bool is_add);

#endif /* ddz_boyi_search_hpp */
