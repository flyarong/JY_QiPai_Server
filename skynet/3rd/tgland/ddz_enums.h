#ifndef _DDZ_ENUMS_H_
#define _DDZ_ENUMS_H_


#define DDZ_MAX_SEAT_NU 3

#define SEAT_L2C(seat_id) (seat_id) 
#define SEAT_C2L(seat_id) (seat_id)

#define SZ_START_PAI 3 
#define SZ_END_PAI 14 
#define UNKOWN_PAI_TYPE_SCORE  -10000


class DdzCard
{
	public:
		enum {
			Three=3,
			Four=4,
			Five=5,
			Six=6,
			Seven=7,
			Eight=8,
			Nine=9,
			Ten=10,
			Jack=11,
			Queen=12,
			King=13,
			Ace=14,

			Two=15, 
			L_Wang=16,
			B_Wang=17,

			FirstFace = Three,
			LastFace =Ace,
			MaxFaceNu=18
		};
};


class CardType 
{
	public:
		enum
		{
			GIVEUP=0,

			SINGLE=1, 
			PAIR=2,
			THREE=3,

			THREE_SINGLE=4,
			THREE_PAIR=5,

			SERIAL_SINGLE=6,

			SERIAL_PAIR=7,


			FOUR_SINGLE2=8,
			FOUR_PAIR2=9, 

			SERIAL_THREE_SINGLE=10,
			SERIAL_THREE_PAIR=11,

			SERIAL_THREE=12,

			BOMB=13,
			ROCKET=14,
			SOFT_BOMB=15,
			MAX_NU=16,
		};
};



#endif /*_DDZ_ENUMS_H_*/

