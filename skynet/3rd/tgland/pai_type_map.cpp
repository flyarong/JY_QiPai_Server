#include <assert.h>
#include "pai_type_map.h"
#include "ddz_ai_util.hpp"


void paitypemap_add_pai(PaiTypeMap* fen_pai,int type,const pai_struct& pai)
{
	assert(type== pai.type) ;
	fen_pai->pai[type].push_back(pai);
}


void paitypemap_add_danpai(PaiTypeMap* fen_pai,int face)
{
	paitypemap_add_pai(fen_pai,CardType::SINGLE,pai_struct_ctor_daipai(face));
}

void paitypemap_add_duizhi(PaiTypeMap* fen_pai,int face)
{
	paitypemap_add_pai(fen_pai,CardType::PAIR,pai_struct_ctor_duizhi(face));
}


void paitypemap_add_sanzhang(PaiTypeMap* fen_pai,int face)
{
	paitypemap_add_pai(fen_pai,CardType::THREE,pai_struct_ctor_sanzhang(face));
}


void paitypemap_add_sandai1(PaiTypeMap* fen_pai,int face,int vice)
{
	paitypemap_add_pai(fen_pai,CardType::THREE_SINGLE,pai_struct_ctor_sandai1(face,vice));
}


void paitypemap_add_sandai2(PaiTypeMap* fen_pai,int face,int vice)
{
	paitypemap_add_pai(fen_pai,CardType::THREE_PAIR,pai_struct_ctor_sandai2(face,vice));
}


void paitypemap_add_bomb(PaiTypeMap* fen_pai,int face)
{
	paitypemap_add_pai(fen_pai,CardType::BOMB,pai_struct_ctor_bomb(face));
}


void paitypemap_add_sidai_2dan(PaiTypeMap* fen_pai,int face,int v1,int v2)
{
	paitypemap_add_pai(fen_pai,CardType::FOUR_SINGLE2,pai_struct_ctor_sidai_2dan(face,v1,v2));
}

void paitypemap_add_sidai_2dui(PaiTypeMap* fen_pai,int face,int v1,int v2)
{
	paitypemap_add_pai(fen_pai,CardType::FOUR_PAIR2,pai_struct_ctor_sidai_2dui(face,v1,v2));
}


void paitypemap_add_feiji(PaiTypeMap* fen_pai,int face_from,int face_to)
{
	paitypemap_add_pai(fen_pai,CardType::SERIAL_THREE,pai_struct_ctor_feiji(face_from,face_to));
}


void paitypemap_add_feiji_dan(PaiTypeMap* fen_pai,int face_from,int face_to, const std::vector<int>& vice_face)
{
	paitypemap_add_pai(fen_pai,CardType::SERIAL_THREE_SINGLE,pai_struct_ctor_feiji_dan(face_from,face_to,vice_face));
}

void paitypemap_add_feiji_dui(PaiTypeMap* fen_pai,int face_from,int face_to, const std::vector<int>& vice_face)
{
	paitypemap_add_pai(fen_pai,CardType::SERIAL_THREE_PAIR,pai_struct_ctor_feiji_dui(face_from,face_to,vice_face));
}

void paitypemap_add_shuizhi(PaiTypeMap* fen_pai,int face_from,int face_to)
{
	paitypemap_add_pai(fen_pai,CardType::SERIAL_SINGLE,pai_struct_ctor_shuizhi(face_from,face_to));
}

void paitypemap_add_liandui(PaiTypeMap* fen_pai, int face_from,int face_to)
{
	paitypemap_add_pai(fen_pai,CardType::SERIAL_PAIR,pai_struct_ctor_liandui(face_from,face_to));
}


void paitypemap_add_rocket(PaiTypeMap* fen_pai)
{
	paitypemap_add_pai(fen_pai,CardType::ROCKET,pai_struct_ctor_rocket());
}


std::vector<int> remove_danpai(PaiTypeMap* fen_pai, int count, int ignore_from, int ignore_to)
{
	std::vector<int> ret;

	int f1_nu=fen_pai->pai[1].size();
	int f2_nu=fen_pai->pai[2].size();


	if(f1_nu+f2_nu*2  <count )
	{
		return ret;
	}

	for(int iter=0;iter<f1_nu+f2_nu*2;iter++)
	{
		if(fen_pai->pai[1].size()==0)
		{
			for(int i=fen_pai->pai[2].size()-1; i>=0;i--)
			{
				int face=pai_struct_get_face(fen_pai->pai[2][i]);
				if(!value_in_range(face,ignore_from,ignore_to))
				{
					fen_pai->pai[2].erase(fen_pai->pai[2].begin()+i);
					paitypemap_add_danpai(fen_pai,face);
					paitypemap_add_danpai(fen_pai,face);
					break;
				}
			}
		}

		int face1_nu=fen_pai->pai[1].size();

		if(face1_nu==0)
		{
			break;
		}

		for(int pos=face1_nu-1;pos>=0;pos--)
		{
			int face1=pai_struct_get_face(fen_pai->pai[1].back());
			if(!value_in_range(face1,ignore_from,ignore_to)) 
			{
				ret.push_back(face1);
				fen_pai->pai[1].pop_back();
				if((int)ret.size()>=count)
				{
					return ret;
				}
			}
		}
	}

	return std::vector<int>();
}


std::vector<int> remove_duizhi(PaiTypeMap* fen_pai, int count, int ignore_from, int ignore_to)
{
	std::vector<int> ret;

	int f2_nu=fen_pai->pai[2].size();
	if(f2_nu<count)
	{
		return ret;
	}



	for(int i=0;i<f2_nu;i++)
	{
		int face=pai_struct_get_face(fen_pai->pai[2].back());
		if (!value_in_range(face, ignore_from, ignore_to))
		{
			fen_pai->pai[2].pop_back();
			ret.push_back(face);
			if ((int)ret.size() >= count)
			{
				return ret;
			}
		}
	}

	return ret;
}










