//
//  mj_hupai_typ_ compute.cpp
//  mj_hp_table
//
//  Created by 何威 on 2018/11/9.
//  Copyright © 2018年 何威. All rights reserved.
//

#include "mj_hupai_typ_compute.hpp"
//#include "nor_mj_auto_algorithm_lib.hpp"
#include <stdio.h>
#include <vector>
#include <map>
#include <iostream>
#include <string.h>
#include <time.h>
using namespace std;

std::map<int,std::vector<int>> no_jiang_nor_mj_hp_relation_map;
std::map<int,std::vector<int>> jiang_nor_mj_hp_relation_map;

int my_dp_limit=5;
//vecvtor是这一层的父亲
map<int,vector<int>> hu_type_father;
map<int,bool> dp_hu_type_map[2];
int get_pai_hash_value(int * pai_map)
{
    int v=1;
    int hash_v=0;
    for(int i=9;i>0;i--)
    {
        if (pai_map[i])
        {
            hash_v=hash_v+pai_map[i]*v;
        }
        v=v*10;
    }
    return hash_v;
}
int get_pai_hash_value_by_color(map<int,int> *pai_map,int color)
{
    
    int s=color*10;
    int e=s+9;
    
    int v=1;
    int hash_v=0;
    for(;e>s;e--)
    {
        if (pai_map->find(e)!=pai_map->end())
        {
            hash_v=hash_v+pai_map->at(e)*v;
        }
        v=v*10;
    }
    return hash_v;
}
int get_pai_value_by_num(int * pai_map,int num)
{
    int count=0;
    for(int i=9;i>0;i--)
    {
        pai_map[i]=num%10;
        count+=pai_map[i];
        num/=10;
        if (num==0)
        {
            return count;
        }
    }
    return count;
}
int get_pai_value_by_pai_map(int * pai_map,map<int,int> *re_pai_hash,int color)
{
    int pos=color*10+9;
    int count=0;
    for(int i=9;i>0;i--)
    {
        if (re_pai_hash->find(pos)!=re_pai_hash->end())
        {
            pai_map[i]=re_pai_hash->at(pos);
            count+=pai_map[i];
        }
        else
        {
            pai_map[i]=0;
        }
        pos--;
    }
    return count;
}
int add_jiang(int pai_no,int *pai_count,int *pai_map)
{
    if(*pai_count+2<15 && pai_map[pai_no]+2<5)
    {
        *pai_count+=2;
        pai_map[pai_no]=pai_map[pai_no]+2;
        return 1;
    }
    return 0;
}
int add_shunzi(int pai_no,int *pai_count,int *pai_map)
{
    if(pai_no<8 && *pai_count+3<15 && pai_map[pai_no]+1<5 && pai_map[pai_no+1]+1<5 && pai_map[pai_no+2]+1<5)
    {
        *pai_count+=3;
        for(int i=0;i<3;i++)
        {
            pai_map[pai_no+i]=pai_map[pai_no+i]+1;
        }
        return 1;
    }
    return 0;
}
int add_duizi(int pai_no,int *pai_count,int *pai_map)
{
    if(*pai_count+3<15 && pai_map[pai_no]+3<5)
    {
        *pai_count+=3;
        pai_map[pai_no]=pai_map[pai_no]+3;
        return 1;
    }
    return 0;
}
int reduce_jiang(int pai_no,int *pai_count,int *pai_map)
{
    *pai_count-=2;
    pai_map[pai_no]=pai_map[pai_no]-2;
    return 1;
}
int reduce_shunzi(int pai_no,int *pai_count,int *pai_map)
{
    *pai_count-=3;
    for(int i=0;i<3;i++)
    {
        pai_map[pai_no+i]=pai_map[pai_no+i]-1;
    }
    return 1;
}
int reduce_duizi(int pai_no,int *pai_count,int *pai_map)
{
    *pai_count-=3;
    pai_map[pai_no]=pai_map[pai_no]-3;
    return 1;
}
//获得一共有多少种胡牌种类
void get_hp_type_count(int *count,int is_jiang,int *pai_count,int *pai_map,int * hp_list, int *hp_list_count,int * hp_jiang_list, int *hp_jiang_list_count)
{
    if(is_jiang==0)
    {
        for(int i=1;i<10;i++)
        {
            if (add_jiang(i, pai_count, pai_map)==1)
            {
                *count=*count+1;
                hp_jiang_list[*hp_jiang_list_count]=get_pai_hash_value(pai_map);
                *hp_jiang_list_count+=1;
                get_hp_type_count(count,1,pai_count,pai_map,hp_list,hp_list_count,hp_jiang_list,hp_jiang_list_count);
                reduce_jiang(i, pai_count, pai_map);
            }
        }
    }
    for(int i=0;i<10;i++)
    {
        if (i>0 && add_shunzi(i, pai_count, pai_map)==1)
        {
            *count=*count+1;
            if(is_jiang==1)
            {
                hp_jiang_list[*hp_jiang_list_count]=get_pai_hash_value(pai_map);
                *hp_jiang_list_count+=1;
            }
            else
            {
                hp_list[*hp_list_count]=get_pai_hash_value(pai_map);
                *hp_list_count+=1;
            }
            get_hp_type_count(count,is_jiang,pai_count,pai_map,hp_list,hp_list_count,hp_jiang_list,hp_jiang_list_count);
            reduce_shunzi(i, pai_count, pai_map);
        }
    }
    for(int i=0;i<10;i++)
    {
        if (i>0 && add_duizi(i, pai_count, pai_map)==1)
        {
            *count=*count+1;
            if(is_jiang==1)
            {
                hp_jiang_list[*hp_jiang_list_count]=get_pai_hash_value(pai_map);
                *hp_jiang_list_count+=1;
            }
            else
            {
                hp_list[*hp_list_count]=get_pai_hash_value(pai_map);
                *hp_list_count+=1;
            }
            get_hp_type_count(count,is_jiang,pai_count,pai_map,hp_list,hp_list_count,hp_jiang_list,hp_jiang_list_count);
            reduce_duizi(i, pai_count, pai_map);
        }
    }
}
void jisuan_next_level_type(int pos,int num)
{
    int pai_map[10]={0,0,0,0,0,0,0,0,0,0};
    get_pai_value_by_num(pai_map,num);
    for (int i=1;i<10;i++)
    {
        if (pai_map[i]>0)
        {
            pai_map[i]--;
            int v=get_pai_hash_value(pai_map);
            
            dp_hu_type_map[pos][v]=true;
            
            
            if(hu_type_father.find(v)==hu_type_father.end())
            {
                hu_type_father[v]=vector<int>();
            }
            
            hu_type_father[v].push_back(num);
            
            pai_map[i]++;
        }
    }
}
void get_paixing_hp_relation_by_dp(int r_count)
{
    if(r_count>my_dp_limit)
    {
        return ;
    }
    cout<<"level "<<r_count<<endl;
    int pos=(r_count+1)%2;
    int next_pos=pos+1;
    if (next_pos>1)
    {
        next_pos=0;
    }
    int ls_c=0;
    for(auto i=dp_hu_type_map[pos].begin();i!=dp_hu_type_map[pos].end();i++)
    {
        ls_c++;
        jisuan_next_level_type(next_pos,i->first);
    }
    dp_hu_type_map[pos].clear();
    get_paixing_hp_relation_by_dp(r_count+1);
}
void get_paixing_hp_relation(int * hp_list,int hp_list_count)
{
    for (int i=0;i<hp_list_count;i++)
    {
        dp_hu_type_map[0][hp_list[i]]=true;
        hu_type_father[hp_list[i]]=vector<int>();
    }
    get_paixing_hp_relation_by_dp(1);
}

void output_paixing_hp_relation_to_text(string str,string map_name)
{
    FILE *fp;
    fp=fopen(str.c_str(),"w+");
    fprintf(fp,"#include <stdio.h>\n#include <vector>\n#include <map>\n#include <iostream>\n#include <string.h>\n\nextern std::map<int,std::vector<int>> ");
    fprintf(fp,"%s",map_name.c_str());
    fprintf(fp,"={\n");
    for(auto i=hu_type_father.begin();i!=hu_type_father.end();i++)
    {
        fprintf(fp,"{%d,{",i->first);
        for(auto k:(i->second))
        {
            fprintf(fp,"%d,\n",k);
        }
        fprintf(fp,"}},");
    }
    fprintf(fp,"};\n");
    
    fclose(fp);
}

void create_hu_relation_hash()
{
    int count=0;
    int pai_count=0;
    int pai_map[]={0,0,0,0,0,0,0,0,0,0};
    
    int *hp_list=new int[2000000];
    int hp_list_count=0;
    
    int *hp_jiang_list=new int[2000000];
    int hp_jiang_list_count=0;
    
    get_hp_type_count(&count,0,&pai_count,pai_map,hp_list,&hp_list_count,hp_jiang_list,&hp_jiang_list_count);
    
    get_paixing_hp_relation(hp_list,hp_list_count);
//    output_paixing_hp_relation_to_text("/Users/hewei/Documents/mj_hp_relation_hash.cpp","no_jiang_nor_mj_hp_relation_map");
    no_jiang_nor_mj_hp_relation_map=hu_type_father;
    hu_type_father.clear();
    dp_hu_type_map[0].clear();
    dp_hu_type_map[1].clear();
    
    get_paixing_hp_relation(hp_jiang_list,hp_jiang_list_count);
//    output_paixing_hp_relation_to_text("/Users/hewei/Documents/mj_jiang_hp_relation_hash.cpp","jiang_nor_mj_hp_relation_map");
    jiang_nor_mj_hp_relation_map=hu_type_father;
    
    delete [] hp_list;
    delete [] hp_jiang_list;
    
}
