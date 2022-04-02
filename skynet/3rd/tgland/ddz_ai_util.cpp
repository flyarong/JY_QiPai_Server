#include <assert.h>
#include "ddz_ai_util.hpp"

#include "lys_card.hpp"


std::string mul_face_string(int face,int mul)
{
	std::string ret;
	for(int i=0;i<mul;i++)
	{
		ret+= pai_face_tostring(face);
	}
	return ret;
}

std::string serial_face_string(int face_from,int face_to,int mul_value)
{
	std::string ret;
	if (face_from > face_to)
	{
		for (int i = face_from; i >= face_to; i--)
		{
			ret += mul_face_string(i, mul_value);
		}
	}
	else
	{
		for (int i = face_from; i <= face_to; i++)
		{
			ret += mul_face_string(i, mul_value);
		}

	}
	return ret;
}


static const char* s_paiface[DdzCard::MaxFaceNu] = {
	"X",  //0
	"X",  //1 
	"X",  //2 
	"3",  //3 
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"T",
	"J",
	"Q",
	"K",
	"A",
	"2",
	"w",
	"W",
};

const char* pai_face_tostring(int face)
{
	assert(face>=DdzCard::Three&&face<=DdzCard::B_Wang);
	return s_paiface[face];
}



std::string pai_struct_tostring(const struct pai_struct& pai)
{
	if(pai.type == CardType::SINGLE)
	{
		return pai_face_tostring(pai.pai[0]);
	}

	if(pai.type == CardType::PAIR)
	{
		return mul_face_string(pai.pai[0],2);
	}

	if(pai.type == CardType::THREE)
	{
		return mul_face_string(pai.pai[0],3);
	}

	if(pai.type==CardType::BOMB)
	{
		return mul_face_string(pai.pai[0],4);
	}

	if(pai.type==CardType::ROCKET)
	{
		return std::string(pai_face_tostring(DdzCard::B_Wang))+ std::string(pai_face_tostring(DdzCard::L_Wang));
	}

	if(pai.type ==CardType::THREE_SINGLE)
	{
		std::string ret= mul_face_string(pai.pai[0],3) +  pai_face_tostring(pai.pai[1]);
		return ret;

	}

	if(pai.type ==CardType::THREE_PAIR)
	{
		std::string ret= mul_face_string(pai.pai[0],3) +  mul_face_string(pai.pai[1],2);
		return ret;
	}

	if(pai.type == CardType::FOUR_SINGLE2) 
	{
		std::string ret;
		ret= mul_face_string(pai.pai[0],4) + pai_face_tostring(pai.pai[1]) + pai_face_tostring(pai.pai[2]);
		return ret ;
	}

	if(pai.type == CardType::FOUR_PAIR2) 
	{
		std::string ret;
		ret= mul_face_string(pai.pai[0],4) + mul_face_string(pai.pai[1],2) + mul_face_string(pai.pai[2],2);
		return ret ;
	}

	if(pai.type == CardType::SERIAL_SINGLE) 
	{
		std::string ret ;
		ret=serial_face_string(pai.pai[1],pai.pai[0],1);
		return ret;

	}

	if(pai.type == CardType::SERIAL_PAIR) 
	{
		std::string ret ;
		ret=serial_face_string(pai.pai[1],pai.pai[0],2);
		return ret;
	}

	if(pai.type == CardType::SERIAL_THREE)
	{
		std::string ret; 
		ret=serial_face_string(pai.pai[1],pai.pai[0],3);
		return ret;
	}

	if(pai.type == CardType::SERIAL_THREE_SINGLE) 
	{
		std::string ret;
		ret=serial_face_string(pai.pai[1],pai.pai[0],3);

		int serial_nu = pai.pai[1]-pai.pai[0] +1 ;
		for (int i=0;i<serial_nu;i++)
		{
			ret+=mul_face_string(pai.pai[i+2],1);
		}
		return ret;
	}

	if(pai.type == CardType::SERIAL_THREE_PAIR)
	{
		std::string ret;
		ret=serial_face_string(pai.pai[1],pai.pai[0],3);

		int serial_nu = pai.pai[1]-pai.pai[0] +1 ;
		for (int i=0;i<serial_nu;i++)
		{
			ret+=mul_face_string(pai.pai[i+2],2);
		}
		return ret;
	}

	assert(false);
	return std::string();
}



int char_to_pai(const char s)
{
	switch(s)
	{
		case 'W': return 17;
		case 'w': return 16;
		case '2': return 15;
		case 'A': return 14;
		case 'K': return 13;
		case 'Q': return 12;
		case 'J': return 11;
		case 'T': return 10;
		case '9': return 9;
		case '8': return 8;
		case '7': return 7;
		case '6': return 6;
		case '5': return 5;
		case '4': return 4;
		case '3': return 3;
	}

	assert(false);
	return 0;
}

std::map<int,int> str_to_pai_map(const char* _str_pai)
{
	std::string str_pai(_str_pai);
	std::map<int,int> ret;
	for(unsigned int i=0;i<str_pai.length();i++)
	{
		char c_f=str_pai[i];
		if(c_f==' ')
		{
			continue;
		}

		int face = char_to_pai(c_f);

		ret[face]++;
	}

	return ret;
}

bool value_in_range(int value,int f,int t)
{
	if(f<t )
	{
		return value>=f && value<=t ;
	}


	return value>=t && value <= f;
}

std::string paitypemap_tostring(const PaiTypeMap& pais)
{
	std::string ret;
	char buf[1024];
	snprintf(buf,1024,"s(score=%d,shoushu=%d,bomb_count=%d,xiajiao=%d,no_xiajiao_score=%d){ ",pais.score,pais.shoushu,pais.bomb_count,pais.xiajiao,pais.no_xiajiao_score);

	ret+=std::string(buf);

	for(auto& type_pai: pais.pai)
	{
		for(auto& pai:type_pai.second)
		{
			std::string str_pai=pai_struct_tostring(pai);
			snprintf(buf,1024," %s(%d)", str_pai.c_str(),pai.score);
			ret+=buf;
		}
	}
	ret+="}";
	return ret;
}

void print_paitypemap(const PaiTypeMap& paitype)
{
	std::string pai=paitypemap_tostring(paitype);

	printf("%s\n",pai.c_str());
}























