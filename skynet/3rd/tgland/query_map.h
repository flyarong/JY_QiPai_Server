#ifndef _QUERY_MAP_H_
#define _QUERY_MAP_H_ 


#include <map>
#include <vector>


#include "lys_card.hpp"
#include "type_face_exist_map.h"
#include "fenpai.h"


class QueryMap 
{
	public:
		static QueryMap* create(int dz_seat_id,const std::map<int, std::map<int,int>>& pai_map);

	
	public:
		int m_dzSeatId;
		int m_seatNu;

		/*  每个位置对应的牌型查询表 */
		std::map<int,TypeFaceExistMap> m_cardTypeExist;

		/* 每个位置对手的查询表 */
		std::map<int, TypeFaceExistMap> m_opCardTypeExist;

		/* 每个位置对手的查询表 */
		std::map<int,TypeFaceExistMap> m_allIsOpCardTypeExist;

		/* 每个位置除自己以外的查询表 */
		std::map<int,TypeFaceExistMap> m_opUnkownExist;

		/* 所有的牌类型查询表 */
		TypeFaceExistMap m_allCardExit;

		std::vector <TypeFaceExistMap> m_landOpExist;

		/* 每个玩家手里面的牌 */
		std::map<int,LysCard> m_lysCards;



		std::map<int,int> m_opMaxCardNu;
		std::map<int,int> m_seatCardNu;

};


#endif /*_QUERY_MAP_H_*/
