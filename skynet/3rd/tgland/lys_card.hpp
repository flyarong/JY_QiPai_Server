#ifndef _FT_CARD_TYPE_ANALYSIS_H_
#define _FT_CARD_TYPE_ANALYSIS_H_
#include <map>
#include <vector>

#include "ddz_boyi_search.hpp"
#include "fenpai.h"


class LysCard
{
	public:
		LysCard();

	public:
		void setFaces(const std::map<int,int>& pai_map);
		void addFaces(const std::map<int,int>& pai_map);

	public:
		void clear();
		int getFaceNu(int face);
		void setFaceNu(int face,int value);
		void addFace(int face,int value);

		int getBiggerFaceNu(int value);

		void merge(const LysCard& other);

		int getCardNu();

	public:
		int getSerialSingle(int serial_nu,int face);
		int getSerialPair(int serial_nu,int face);
		int getSerialThree(int serial_nu,int face);
		int getBomb(int face);
		int getThree(int face);
		int getPair(int face);
		int getSingle(int face);


	protected:
		int m_facesNu[DdzCard::MaxFaceNu];
};

std::map<int,std::vector<struct pai_struct>> lys_get_pai_enum(map<int,int>& pai_map, std::map<int,int>& kaiguan);


#endif /*_FT_CARD_TYPE_ANALYSIS_H_*/



