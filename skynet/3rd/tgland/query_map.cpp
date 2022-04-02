#include <algorithm>
#include "query_map.h"
//#include "fenpai.h"

QueryMap* QueryMap::create(int dz_seat_id,const map<int,map<int,int>>& pai_maps)
{
	QueryMap* ret_map=new QueryMap;
	int seat_nu = pai_maps.size();

	ret_map->m_dzSeatId=dz_seat_id;
	ret_map->m_seatNu=seat_nu;


	for(auto& iter:pai_maps)
	{
		ret_map->m_lysCards[SEAT_L2C(iter.first)].setFaces(iter.second);

	}




	//生成自己的
	for(int i=1;i<=seat_nu;i++)
	{
		ret_map->m_cardTypeExist[i].setCards(ret_map->m_lysCards[i]);
		ret_map->m_allCardExit.merge(&ret_map->m_cardTypeExist[i]);
		ret_map->m_seatCardNu[i]=ret_map->m_lysCards[i].getCardNu();
	}




	/* 生成对手的 */
	for(int i=1;i<=seat_nu;i++)
	{
		LysCard unkown_cards;
		for (auto& iter:pai_maps) 
		{
			int seat=SEAT_L2C(iter.first);
			if(seat!=i )
			{
				unkown_cards.addFaces(iter.second);
			}
		}


		ret_map->m_opUnkownExist[i].setCards(unkown_cards);


		int pre_id= get_pre_seat_id(i,seat_nu);
		int next_id=get_next_seat_id(i,seat_nu);
		ret_map->m_allIsOpCardTypeExist[i].merge(&ret_map->m_cardTypeExist[pre_id]);
		if(pre_id!=next_id) 
		{
			ret_map->m_allIsOpCardTypeExist[i].merge(&ret_map->m_cardTypeExist[next_id]);
		}

		if(i!=dz_seat_id ) 
		{
			ret_map->m_opMaxCardNu[i]=ret_map->m_seatCardNu[dz_seat_id];
			ret_map->m_opCardTypeExist[i]=ret_map->m_cardTypeExist[dz_seat_id];
		}
		else 
		{
			ret_map->m_opCardTypeExist[i]=ret_map->m_allIsOpCardTypeExist[i];
			ret_map->m_opMaxCardNu[i]=std::max(ret_map->m_seatCardNu[pre_id],ret_map->m_seatCardNu[next_id]);
			if(pre_id!=next_id)
			{
				ret_map->m_landOpExist.push_back(ret_map->m_cardTypeExist[pre_id]);
				ret_map->m_landOpExist.push_back(ret_map->m_cardTypeExist[next_id]);
			}
			else 
			{
				ret_map->m_landOpExist.push_back(ret_map->m_cardTypeExist[next_id]);
			}
		}

	}

	return ret_map;
}






































