#ifndef _DDZ_AI_UTIL_H_
#define _DDZ_AI_UTIL_H_ 

#include <string>

#include "ddz_boyi_search.hpp"


//把牌面值转换成字符串
const char* pai_face_tostring(int face);


/* 把字符转换成牌的面值*/
int char_to_pai(const char s);


/* 把字符串转换成牌map */
std::map<int,int> str_to_pai_map(const char* str_pai);


//把牌转换成字符串，用于调试
std::string  pai_struct_tostring(const struct pai_struct& pai);


std::string paitypemap_tostring(const PaiTypeMap& paitype);

void print_paitypemap(const PaiTypeMap& paitype);

bool value_in_range(int s,int f,int t);




#endif /*_DDZ_AI_UTIL_H_*/

