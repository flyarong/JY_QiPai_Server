#ifndef _TYPE_FACE_EXIST_MAP_H_
#define _TYPE_FACE_EXIST_MAP_H_ 

#include "lys_card.hpp"
class TypeFaceExistMap 
{
	public:
		TypeFaceExistMap();
		~TypeFaceExistMap();

	public:
		void clear();
		void merge(TypeFaceExistMap* map);
		void setCards( LysCard& cards);

		int getBiggerEqCardNu(int card_type,int serial_nu,int face);
		int getBiggerCardNu(int card_type,int serial,int face);


		void setSerialThreeFaceNu(int serial,int face,int value);
		int getSerialThreeFaceNu(int serial,int face);

		void setSerialPairFaceNu(int serial,int face,int value);
		int getSerialPairFaceNu(int serial,int face);


		void setSerialSingleFaceNu(int serial,int face,int value);
		int getSerialSingleFaceNu(int serial,int face);

		void setBombFaceNu(int face,int value);
		int getBombFaceNu(int face);


		void setThreeFaceNu(int face,int value);
		int getThreeFaceNu(int face);

		void setPairFaceNu(int face,int value);
		int getPairFaceNu(int face);

		void setSingleFaceNu(int face,int value);
		int getSingleFaceNu(int face);

		void setRocketNu(int value);
		int getRocketNu();




	public:
		void setSerialTypeFaceNu(int type,int serial,int face,int value);
		int  getSerialTypeFaceNu(int type,int serial,int face);

		void setNoSerialTypeFaceNu(int type,int face,int value);
		int getNoSerialTypeFaceNu(int type,int face);

		void setTypeFaceNu(int type,int serial,int face,int value);
		int getTypeFaceNu(int type,int serial,int face);



	protected:

		std::map<int,int> m_serialThrees[DdzCard::MaxFaceNu];
		std::map<int,int> m_serialPairs[DdzCard::MaxFaceNu];
		std::map<int,int> m_serialSingles[DdzCard::MaxFaceNu];



		int m_bombs[DdzCard::MaxFaceNu];
		int m_threes[DdzCard::MaxFaceNu];
		int m_pairs[DdzCard::MaxFaceNu];
		int m_singles[DdzCard::MaxFaceNu];

		int m_rocketNu;

		LysCard m_lysCards;
};





#endif /*_TYPE_FACE_EXIST_MAP_H_*/
