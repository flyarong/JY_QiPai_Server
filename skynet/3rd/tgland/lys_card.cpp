#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include "lys_card.hpp"
#include "ddz_boyi_search.hpp"

typedef struct pai_struct PaiStruct;


LysCard::LysCard()
{
	clear();
}


void LysCard::setFaces(const std::map<int,int>& pai_map)
{
	for(auto iter:pai_map) 
	{
		setFaceNu(iter.first,iter.second);
	}
}

void LysCard::addFaces(const std::map<int,int>& pai_map)
{
	for(auto iter:pai_map)
	{
		addFace(iter.first,iter.second);
	}
}

void LysCard::addFace(int face,int value)
{
	m_facesNu[face]+=value;
}



void LysCard::clear()
{

	for(int i=0;i<DdzCard::MaxFaceNu;i++)
	{
		m_facesNu[i]=0;
	}
}


int LysCard::getFaceNu(int face)
{
	return m_facesNu[face];
}

int LysCard::getBiggerFaceNu(int value)
{
	int ret=0;
	for(int i=DdzCard::Three;i<=DdzCard::B_Wang;i++)
	{
		if(m_facesNu[i]>value) 
		{
			ret=ret+1;
		}
	}


	return ret;
}


void LysCard::setFaceNu(int face,int value)
{
	m_facesNu[face]=value;
}



int LysCard::getSerialSingle(int serial_nu,int face)
{
	if(face>DdzCard::Ace|| face-serial_nu+1 <DdzCard::Three)
	{
		return 0;
	}

	int max_nu=4;

	for(int i=0;i<serial_nu;i++)
	{
		if(m_facesNu[face-i]==0)
		{
			return 0;
		}
		if(m_facesNu[face-i]<max_nu)
		{
			max_nu=m_facesNu[face-i];
		}
	}
	return max_nu;
}

int LysCard::getSerialPair(int serial_nu,int face)
{
	if(face>DdzCard::Ace|| face-serial_nu+1 <DdzCard::Three)
	{
		return 0;
	}

	int max_nu=4;

	for(int i=0;i<serial_nu;i++)
	{
		if(m_facesNu[face-i]<2)
		{
			return 0;
		}
		if(m_facesNu[face-i]<max_nu)
		{
			max_nu=m_facesNu[face-i];
		}
	}

	if(max_nu==4)
	{
		return 2;
	}
	return 1;
}

int LysCard::getSerialThree(int serial_nu,int face)
{
	if(face>DdzCard::Ace|| face-serial_nu+1 <DdzCard::Three)
	{
		return 0;
	}
	for(int i=0;i<serial_nu;i++)
	{
		if(m_facesNu[face-i]<3)
		{
			return 0;
		}
	}
	return 1;
}



int LysCard::getBomb(int face)
{
	if(face ==DdzCard::B_Wang)
	{
		//printf("rocket: %d,%d\n",m_facesNu[DdzCard::B_Wang],m_facesNu[DdzCard::L_Wang]);
		if(m_facesNu[DdzCard::B_Wang]==1&&m_facesNu[DdzCard::L_Wang]==1)
		{
			return 1;
		}
		else 
		{
			return 0;
		}
	}

	if(face==DdzCard::L_Wang)
	{
		return 0;
	}


	if(m_facesNu[face]==4)
	{
		return 1;
	}
	return 0;
}


int LysCard::getThree(int face)
{
	if(m_facesNu[face]>=3)
	{
		return 1;
	}
	return 0;
}

int LysCard::getPair(int face)
{
	if(m_facesNu[face]==4)
	{
		return 2;
	}

	if(m_facesNu[face]<2)
	{
		return 0;
	}

	return 1;
}

int LysCard::getSingle(int face)
{
	return m_facesNu[face];
}

void LysCard::merge(const LysCard& other)
{
	for(int i =0;i<DdzCard::MaxFaceNu;i++)
	{
		m_facesNu[i]+=other.m_facesNu[i];
	}
}

int LysCard::getCardNu()
{
	int result=0;

	for(int i=0;i<DdzCard::MaxFaceNu;i++)
	{
		result+=m_facesNu[i];
	}

	return result;

}





std::map<int, std::vector<struct pai_struct>> lys_get_pai_enum(std::map<int, int>& pai_map, std::map<int, int>& kaiguan)
{
	std::map<int, int>::iterator kuaguan_iter;

	int min_serial_single_nu = 5;
	int max_serial_single_nu = 12;

	int min_serial_pair_nu = 3;
	int max_serial_pair_nu = 10;

	int min_serial_three_nu = 2;
	int max_serial_three_nu = 6;


	LysCard lys_cards;

	std::map<int, std::vector<struct pai_struct>>  result;

	for (std::map<int, int>::iterator iter = pai_map.begin(); iter != pai_map.end(); ++iter)
	{
		lys_cards.setFaceNu(iter->first, iter->second);
	}

	//处理单牌，对子，三张, 炸弹  
	for (int i = DdzCard::B_Wang; i >= DdzCard::Three; i--)
	{
		int face_nu = lys_cards.getFaceNu(i);
		if (face_nu >= 1)
		{
			PaiStruct pai;
			pai.type = CardType::SINGLE;
			pai.pai[0] = i;
			result[CardType::SINGLE].push_back(pai);
		}

		if (face_nu >= 2)
		{
			PaiStruct pai;
			pai.type = CardType::PAIR;
			pai.pai[0] = i;
			result[CardType::PAIR].push_back(pai);
		}


		if (face_nu >= 3)
		{
			PaiStruct pai;
			pai.type = CardType::THREE;
			pai.pai[0] = i;
			result[CardType::THREE].push_back(pai);
		}

		if (face_nu >= 4)
		{
			PaiStruct pai;
			pai.type = CardType::BOMB;
			pai.pai[0] = i;
			result[CardType::BOMB].push_back(pai);
		}
	}


	//处理顺子 
	for (int serial_nu = min_serial_single_nu; serial_nu <= max_serial_single_nu; serial_nu++)
	{
		for (int face = DdzCard::Ace; face >= DdzCard::Three + serial_nu - 1; face--)
		{
			int f_nu = lys_cards.getSerialSingle(serial_nu, face);
			if (f_nu > 0)
			{
				PaiStruct pai;
				pai.type = CardType::SERIAL_SINGLE;
				pai.pai[0] = face - serial_nu + 1;
				pai.pai[1] = face;

				result[CardType::SERIAL_SINGLE].push_back(pai);
			}
		}
	}

	//处理连对
	for (int serial_nu = min_serial_pair_nu; serial_nu <= max_serial_pair_nu; serial_nu++)
	{
		for (int face = DdzCard::Ace; face >= DdzCard::Three + serial_nu - 1; face--)
		{
			int f_nu = lys_cards.getSerialPair(serial_nu, face);
			if (f_nu > 0)
			{
				PaiStruct pai;
				pai.type = CardType::SERIAL_PAIR;
				pai.pai[0] = face - serial_nu + 1;
				pai.pai[1] = face;
				result[CardType::SERIAL_PAIR].push_back(pai);
			}
		}
	}
	//处理飞机

	for (int serial_nu = min_serial_three_nu; serial_nu <= max_serial_three_nu; serial_nu++)
	{
		for (int face = DdzCard::Ace; face >= DdzCard::Three + serial_nu - 1; face--)
		{
			int f_nu = lys_cards.getSerialThree(serial_nu, face);
			if (f_nu > 0)
			{
				PaiStruct pai;
				pai.type = CardType::SERIAL_THREE;
				pai.pai[0] = face - serial_nu + 1;
				pai.pai[1] = face;
				result[CardType::SERIAL_THREE].push_back(pai);
			}
		}
	}

	//处理三带1 和 三带1对 

	for(std::vector<PaiStruct>::iterator iter =  result[CardType::THREE].begin(); iter!=result[CardType::THREE].end();++iter)
	{
		int face3= (*iter).pai[0];

		//三带1 
		for(std::vector<PaiStruct>::iterator iter =  result[CardType::SINGLE].begin(); iter!=result[CardType::SINGLE].end();++iter)
		{
			int face1=(*iter).pai[0];

			if(face1==face3) 
			{
				continue;
			}

			PaiStruct pai;
			pai.type= CardType::THREE_SINGLE;
			pai.pai[0]=face3;
			pai.pai[1]=face1;

			result[CardType::THREE_SINGLE].push_back(pai);
		}

		//三带2 
		for(std::vector<PaiStruct>::iterator iter =  result[CardType::PAIR].begin(); iter!=result[CardType::PAIR].end();++iter)
		{
			int face2=(*iter).pai[0];

			if(face2==face3) 
			{
				continue;
			}

			PaiStruct pai;
			pai.type= CardType::THREE_PAIR;
			pai.pai[0]=face3;
			pai.pai[1]=face2;

			result[CardType::THREE_PAIR].push_back(pai);
		}
	}

	//王炸
	if(lys_cards.getBomb(DdzCard::B_Wang) >0  )
	{
		PaiStruct pai;
		pai.type= CardType::ROCKET;
		result[CardType::ROCKET].push_back(pai);
	}


	return result;
}









