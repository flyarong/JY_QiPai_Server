#ifndef _PAI_TYPE_MAP_H_
#define _PAI_TYPE_MAP_H_ 

#include <map>
#include <vector>


#include "ddz_enums.h"
#include "pai_struct.h"

struct PaiTypeMap
{
	PaiTypeMap()
	{
		score = UNKOWN_PAI_TYPE_SCORE;
		shoushu = 0;
		bomb_count = 0;
		xiajiao = 0;
		no_xiajiao_score = 0;
	}

	std::map<int, std::vector<pai_struct>>  pai;
	int score;
	int shoushu;
	int bomb_count;
	int xiajiao;
	int no_xiajiao_score;
};




void paitypemap_add_pai(PaiTypeMap* fen_pai,int type,const pai_struct& pai);

void paitypemap_add_danpai(PaiTypeMap* fen_pai,int face);
void paitypemap_add_duizhi(PaiTypeMap* fen_pai,int face);
void paitypemap_add_sanzhang(PaiTypeMap* fen_pai,int face);
void paitypemap_add_sandai1(PaiTypeMap* fen_pai,int face,int vice);
void paitypemap_add_sandai2(PaiTypeMap* fen_pai,int face,int vice);
void paitypemap_add_bomb(PaiTypeMap* fen_pai,int face);

void paitypemap_add_sidai_2dan(PaiTypeMap* fen_pai,int face,int v1,int v2);
void paitypemap_add_sidai_2dui(PaiTypeMap* fen_pai,int face,int v1,int v2);

void paitypemap_add_shuizhi(PaiTypeMap* fen_pai,int face_from,int face_to);
void paitypemap_add_liandui(PaiTypeMap* fen_pai, int face_from,int face_to);

void paitypemap_add_feiji(PaiTypeMap* fen_pai,int face_from,int face_to);

void paitypemap_add_feiji_dan(PaiTypeMap* fen_pai,int face_from,int face_to, const std::vector<int>& vice_face);
void paitypemap_add_feiji_dui(PaiTypeMap* fen_pai,int face_from,int face_to, const std::vector<int>& vice_face);

void paitypemap_add_rocket(PaiTypeMap* fen_pai);


std::vector<int> remove_danpai(PaiTypeMap* fen_pai, int count, int ignore_from, int ignore_to);
std::vector<int> remove_duizhi(PaiTypeMap* fen_pai, int count, int ignore_from, int ignore_to);


#endif /*_PAI_TYPE_MAP_H_*/





