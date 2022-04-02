#ifndef _PAI_STRUCT_H_
#define _PAI_STRUCT_H_ 
#include<stdlib.h>
#include<string.h>
#include<vector>


#include "ddz_enums.h"

struct pai_struct
{
	pai_struct()
	{
		type=-1;
		for(int i=0;i<7;i++)
		{
			pai[i]=0;
		}
		score=0;
		other1=0;
		other2=0;
	}

    int type;
	int pai[7];
    int score;

	int other1;
	int other2;
};

typedef struct pai_struct PaiStruct;

inline pai_struct pai_struct_ctor_daipai(int face)
{
	pai_struct ret;
	memset(&ret,0,sizeof(ret));
	ret.type =1;
	ret.pai[0]=face;
	return ret;

}

inline pai_struct pai_struct_ctor_duizhi(int face)
{
	pai_struct ret;
	memset(&ret,0,sizeof(ret));
	ret.type =2;
	ret.pai[0]=face;
	return ret;
}


inline pai_struct pai_struct_ctor_sanzhang(int face)
{
	pai_struct ret;
	memset(&ret,0,sizeof(ret));
	ret.type =3;
	ret.pai[0]=face;
	return ret;

}


inline pai_struct pai_struct_ctor_sandai1(int s,int v)
{
	pai_struct ret;
	memset(&ret,0,sizeof(ret));
	ret.type =4;
	ret.pai[0]=s;
	ret.pai[1]=v;
	return ret;
}

inline pai_struct pai_struct_ctor_sandai2(int s,int v)
{
	pai_struct ret;
	memset(&ret,0,sizeof(ret));
	ret.type =5;
	ret.pai[0]=s;
	ret.pai[1]=v;
	return ret;
}

inline pai_struct pai_struct_ctor_bomb(int face)
{
	pai_struct ret;
	memset(&ret,0,sizeof(ret));
	ret.type = CardType::BOMB;
	ret.pai[0]=face;

	return ret;
}

inline pai_struct pai_struct_ctor_sidai_2dan(int face,int v1,int v2)
{
	pai_struct ret;
	memset(&ret,0,sizeof(ret));

	ret.type=CardType::FOUR_SINGLE2;

	ret.pai[0]=face;
	ret.pai[1]=v1;
	ret.pai[2]=v2;

	return ret;
}

inline pai_struct pai_struct_ctor_sidai_2dui(int face,int v1,int v2)
{
	pai_struct ret;
	memset(&ret,0,sizeof(ret));

	ret.type =CardType::FOUR_PAIR2;

	ret.pai[0]=face;
	ret.pai[1]=v1;
	ret.pai[2]=v2;

	return ret;
}

inline pai_struct pai_struct_ctor_feiji(int face_from,int face_to)
{
	pai_struct ret;
	memset(&ret,0,sizeof(ret));

	ret.type = CardType::SERIAL_THREE;

	ret.pai[0]=face_from;
	ret.pai[1]=face_to;

	return ret;
}

inline pai_struct pai_struct_ctor_feiji_dan(int face_from,int face_to,const std::vector<int>& vice_face)
{
	pai_struct ret;
	memset(&ret,0,sizeof(ret));
	ret.type =CardType::SERIAL_THREE_SINGLE;

	ret.pai[0]=face_from;
	ret.pai[1]=face_to;

	for(int i=0;i<(int)vice_face.size();i++)
	{
		ret.pai[2+i]= vice_face[i];
	}
	return ret;
}

inline pai_struct pai_struct_ctor_feiji_dui(int face_from,int face_to,const std::vector<int>& vice_face){
	pai_struct ret;
	memset(&ret,0,sizeof(ret));
	ret.type =CardType::SERIAL_THREE_PAIR;

	ret.pai[0]=face_from;
	ret.pai[1]=face_to;

	for(int i=0;i<(int)vice_face.size();i++)
	{
		ret.pai[2+i]= vice_face[i];
	}
	return ret;
}

inline pai_struct pai_struct_ctor_rocket()
{
	pai_struct ret;
	memset(&ret,0,sizeof(ret));
	ret.type =CardType::ROCKET;
	return ret;
}
inline pai_struct pai_struct_ctor_shuizhi(int face_from,int face_to)
{
	pai_struct ret;
	memset(&ret,0,sizeof(ret));

	ret.type =CardType::SERIAL_SINGLE;
	ret.pai[0]=face_from;
	ret.pai[1]=face_to;

	return ret;
}

inline pai_struct pai_struct_ctor_liandui(int face_from,int face_to)
{
	pai_struct ret;
	memset(&ret,0,sizeof(ret));

	ret.type =CardType::SERIAL_PAIR;
	ret.pai[0]=face_from;
	ret.pai[1]=face_to;

	return ret;
}







int pai_struct_get_type(const PaiStruct& pai);
int pai_struct_get_serial(const PaiStruct& pai);
int pai_struct_get_face(const PaiStruct& pai);
int pai_struct_get_face_from(const PaiStruct& pai);
int pai_struct_get_face_to(const PaiStruct& pai);

int pai_struct_get_card_nu(const PaiStruct& pai);


#endif /*_PAI_STRUCT_H_*/

