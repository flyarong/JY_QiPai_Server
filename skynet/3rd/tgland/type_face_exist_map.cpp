#include <assert.h>
#include "type_face_exist_map.h"

TypeFaceExistMap::TypeFaceExistMap()
{
}

TypeFaceExistMap::~TypeFaceExistMap()
{

}



void TypeFaceExistMap::clear()
{
	for(int i =0;i<DdzCard::MaxFaceNu;i++)
	{
		m_serialThrees[i].clear();
		m_serialPairs[i].clear();
		m_serialSingles[i].clear();

		m_bombs[i]=0;
		m_threes[i]=0;
		m_pairs[i]=0;
		m_singles[i]=0;
	}
	m_rocketNu=0;
}


void TypeFaceExistMap::setTypeFaceNu(int type,int serial,int face,int value)
{
	if(serial==1)
	{
		setNoSerialTypeFaceNu(type, face, value);
	}
	else 
	{
		setSerialTypeFaceNu(type,serial,face,value);
	}
}


int TypeFaceExistMap::getTypeFaceNu(int type,int serial,int face)
{

	
	if (type == CardType::THREE_SINGLE)
	{
		if (m_lysCards.getBiggerFaceNu(0)<2)
		{
			return 0;
		}
	}


	if (type == CardType::THREE_PAIR)
	{
		if (m_lysCards.getBiggerFaceNu(1) < 2)
		{
			return 0;
		}
	}

	if (type == CardType::SERIAL_THREE_SINGLE)
	{
		if (m_lysCards.getBiggerFaceNu(0) < serial * 2)
		{
			return 0;
		}
	}

	if (type == CardType::SERIAL_THREE_PAIR)
	{
		if (m_lysCards.getBiggerFaceNu(1)< serial * 2)
		{
			return 0;
		}
	}

	if (type == CardType::FOUR_SINGLE2)
	{
		if (m_lysCards.getBiggerFaceNu(0) < 3)
		{
			return 0;
		}
	}

	if (type == CardType::FOUR_PAIR2)
	{
		if (m_lysCards.getBiggerFaceNu(1) < 3)
		{
			return 0;
		}
	}

	static const std::map<int, int>  card_type_cast_map = {
		{ 1, 1 },
		{ 2, 2 },
		{ 3, 3 },
		{ 4, 3 },
		{ 5, 3 },
		{ 6, 6 },
		{ 7, 7 },
		{ 8, 13 },
		{ 9, 13 },
		{ 10, 12 },
		{ 11, 12 },
		{ 12, 12 },
		{ 13, 13 },
		{ 14, 14 },
		{ 15, 15 },
	};

	auto iter = card_type_cast_map.find(type);
	type = iter->second;





	if(serial!=1)
	{
		return getSerialTypeFaceNu(type,serial,face);
	}

	if (type == CardType::ROCKET)
	{
		return getRocketNu();
	}


	return getNoSerialTypeFaceNu(type,face);
}

void TypeFaceExistMap::setNoSerialTypeFaceNu(int type,int face,int value)
{
	if(type == CardType::BOMB) 
	{
		setBombFaceNu(face,value);
	}
	else if(type== CardType::THREE)
	{
		setThreeFaceNu(face,value);
	}
	else if(type == CardType::PAIR) 
	{
		setPairFaceNu(face,value);
	}
	else if(type == CardType::SINGLE)
	{
		setSingleFaceNu(face,value);
	}

	assert(false);
}


int TypeFaceExistMap::getNoSerialTypeFaceNu(int type,int face)
{
	if(type == CardType::BOMB) 
	{
		return getBombFaceNu(face);
	}
	else if(type ==CardType::THREE) 
	{
		return getThreeFaceNu(face);
	}
	else if(type == CardType::PAIR) 
	{
		return getPairFaceNu(face);
	}
	else if (type == CardType::SINGLE)
	{
		return getSingleFaceNu(face);
	}


	assert(false);
	return -1;
}


void TypeFaceExistMap::setSerialTypeFaceNu(int type,int serial,int face,int value)
{
	if(type == CardType::SERIAL_SINGLE)
	{
		setSerialSingleFaceNu(serial,face,value);
	}
	else if (type == CardType::SERIAL_PAIR) 
	{
		setSerialPairFaceNu(serial,face,value);
	}
	else if(type ==CardType::SERIAL_THREE)
	{
		setSerialThreeFaceNu(serial,face,value);
	}

	assert(false);
}

int TypeFaceExistMap::getSerialTypeFaceNu(int type,int serial,int face)
{

	if(type ==CardType::SERIAL_SINGLE)
	{
		return getSerialSingleFaceNu(serial,face);
	}
	else if (type ==CardType::SERIAL_PAIR) 
	{
		return getSerialPairFaceNu(serial,face);
	}
	else if (type == CardType::SERIAL_THREE) 
	{
		return getSerialThreeFaceNu(serial,face);
	}

	assert(false);
	return -1;
}

void TypeFaceExistMap::setSerialThreeFaceNu(int serial,int face,int value)
{
	m_serialThrees[face][serial]=value;
}

int TypeFaceExistMap::getSerialThreeFaceNu(int serial,int face)
{
	return m_serialThrees[face][serial];
}


void TypeFaceExistMap::setSerialPairFaceNu(int serial,int face,int value)
{
	m_serialPairs[face][serial]=value;
}

int TypeFaceExistMap::getSerialPairFaceNu(int serial,int face)
{
	return m_serialPairs[face][serial];
}


void TypeFaceExistMap::setSerialSingleFaceNu(int serial,int face,int value)
{
	m_serialSingles[face][serial]=value;
}


int TypeFaceExistMap::getSerialSingleFaceNu(int serial,int face)
{
	return m_serialSingles[face][serial];
}


int TypeFaceExistMap::getBiggerEqCardNu(int type,int serial,int face)
{
	int bigger_nu= getBiggerCardNu(type,serial,face);
	int eq_nu = getTypeFaceNu(type,serial,face);

	return bigger_nu+eq_nu;
}

int TypeFaceExistMap::getBiggerCardNu(int type,int serial,int face)
{
	if(type == CardType::ROCKET)
	{
		return 0;
	}

	if(type == CardType::THREE_SINGLE)
	{
		if(m_lysCards.getBiggerFaceNu(0)<2 )
		{
			return 0;
		}
	}


	if(type == CardType::THREE_PAIR)
	{
		if (m_lysCards.getBiggerFaceNu(1) < 2 ) 
		{
			return 0;
		}
	}

	if(type == CardType::SERIAL_THREE_SINGLE)
	{
		if(m_lysCards.getBiggerFaceNu(0) < serial* 2 ) 
		{
			return 0;
		}
	}

	if(type == CardType::SERIAL_THREE_PAIR)
	{
		if(m_lysCards.getBiggerFaceNu(1)< serial* 2 )
		{
			return 0;
		}
	}

	if(type == CardType::FOUR_SINGLE2)
	{
		if(m_lysCards.getBiggerFaceNu(0) < 3 )
		{
			return 0;
		}
	}

	if( type== CardType::FOUR_PAIR2)
	{
		if(m_lysCards.getBiggerFaceNu(1) < 3 )
		{
			return 0;
		}
	}
	
	static const std::map<int, int>  card_type_cast_map = {
		{1, 1},
		{2, 2},
		{3, 3},
		{4, 3},
		{5, 3},
		{6, 6},
		{7, 7},
		{8, 13},
		{9, 13},
		{10, 12},
		{11, 12},
		{12, 12},
		{13, 13},
		{14, 14},
		{15, 15},
	};

	auto iter = card_type_cast_map.find(type);
	type = iter->second;




	if(serial> 1 ) 
	{
		int max_face=DdzCard::Ace;
		std::map<int,int>* type_info=NULL;
		if(type == CardType::SERIAL_SINGLE)
		{
			type_info= m_serialSingles;
		}
		else if(type == CardType::SERIAL_PAIR) 
		{
			type_info= m_serialPairs;
		}
		else if(type == CardType::SERIAL_THREE) 
		{
			type_info= m_serialThrees;
		}

		int bigger_nu=0;
		for(int i=face+1;i<=max_face;i++)
		{
			int value =type_info[i][serial]; 
			if(value > 0) 
			{
				bigger_nu++;
			}
		}

		return bigger_nu;
	}

	int* type_info=NULL;
	if(type == CardType::BOMB) 
	{
		type_info=m_bombs;
	}
	else if(type == CardType::THREE) 
	{
		type_info= m_threes;
	}
	else if(type == CardType::PAIR)
	{
		type_info= m_pairs;
	}
	else if(type == CardType::SINGLE) 
	{
		type_info = m_singles;
	}

	//printf("type = %d,serial=%d\n",type,serial);
	int max_face=DdzCard::B_Wang;

	int bigger_nu=0;
	for(int i=face+1;i<=max_face;i++)
	{
		int type_nu = type_info[i];
		if(type_nu>0)
		{
			bigger_nu++;
		}
	}

	if(type ==CardType::BOMB) 
	{
		if(m_rocketNu > 0 )
		{
			bigger_nu++;
		}
	}

	return bigger_nu;
}

void TypeFaceExistMap::setCards(LysCard& cards)
{
	m_lysCards= cards;

	/* serial */
	for(int face= DdzCard::Three;face<=DdzCard::Ace; face++)
	{
		/* serial three */
		for(int serial=2;serial<=6;serial++)
		{
			int type_nu = m_lysCards.getSerialThree(serial,face);
			setSerialThreeFaceNu(serial,face,type_nu);
		}

		/* serial pair */
		for(int serial=3;serial<=10;serial++)
		{
			int type_nu=m_lysCards.getSerialPair(serial,face);
			setSerialPairFaceNu(serial,face,type_nu);
		}

		/* serial single */
		for(int serial=5;serial<=12;serial++)
		{
			int type_nu = m_lysCards.getSerialSingle(serial,face);
			setSerialSingleFaceNu(serial,face,type_nu);
		}
	}


	/* no serial */
	for(int face=DdzCard::Three;face<=DdzCard::B_Wang;face++)
	{
		int bomb_nu =m_lysCards.getBomb(face);
		if(face == DdzCard::B_Wang) 
		{
			setRocketNu(bomb_nu);
		}
		else 
		{
			setBombFaceNu(face,bomb_nu);
		}

		int three_nu=m_lysCards.getThree(face);
		setThreeFaceNu(face,three_nu);

		int pair_nu=m_lysCards.getPair(face);
		setPairFaceNu(face,pair_nu);

		int single_nu=m_lysCards.getSingle(face);
		setSingleFaceNu(face,single_nu);
	}
}

void TypeFaceExistMap::merge(TypeFaceExistMap* query_map)
{

	/* serial */
	for(int face= DdzCard::Three; face <=DdzCard::Ace; face++)
	{
		/* serial three */
		for(int serial=2;serial<=6;serial++)
		{
			setSerialThreeFaceNu(serial, face,getSerialThreeFaceNu(serial, face)+query_map->getSerialThreeFaceNu(serial,face));
		}

		/* serial pair */
		for(int serial=3;serial<=10;serial++)
		{
			setSerialPairFaceNu(serial, face,getSerialPairFaceNu(serial, face)+query_map->getSerialPairFaceNu(serial, face));
		}

		/* serial single */
		for(int serial=5;serial<=12;serial++)
		{
			setSerialSingleFaceNu(serial, face,getSerialSingleFaceNu(serial, face)+query_map->getSerialSingleFaceNu(serial, face));
		}
	}


	for(int face=DdzCard::Three;face<=DdzCard::B_Wang;face++)
	{
		if(face == DdzCard::B_Wang) 
		{
			setRocketNu(getRocketNu()+query_map->getRocketNu());
		}
		else 
		{
			setBombFaceNu(face,getBombFaceNu(face)+query_map->getBombFaceNu(face));
		}

		setThreeFaceNu(face,getThreeFaceNu(face)+query_map->getThreeFaceNu(face));
		setPairFaceNu(face,getPairFaceNu(face)+query_map->getPairFaceNu(face));
		setSingleFaceNu(face,getSingleFaceNu(face)+query_map->getSingleFaceNu(face));
	}

	m_lysCards.merge(query_map->m_lysCards);
}


void TypeFaceExistMap::setBombFaceNu(int face,int value)
{
	m_bombs[face]=value;
}


int TypeFaceExistMap::getBombFaceNu(int face)
{
	return m_bombs[face];
}

void TypeFaceExistMap::setThreeFaceNu(int face,int value)
{
	m_threes[face]=value;
}

int TypeFaceExistMap::getThreeFaceNu(int face)
{
	return m_threes[face];
}

void TypeFaceExistMap::setPairFaceNu(int face,int value)
{
	m_pairs[face]=value;
}

int TypeFaceExistMap::getPairFaceNu(int face)
{
	return m_pairs[face];
}

void TypeFaceExistMap::setSingleFaceNu(int face,int value)
{
	m_singles[face]=value;
}

int TypeFaceExistMap::getSingleFaceNu(int face)
{
	return m_singles[face];
}

void TypeFaceExistMap::setRocketNu(int value)
{
	m_rocketNu=value;
}

int TypeFaceExistMap::getRocketNu()
{
	return m_rocketNu;
}

