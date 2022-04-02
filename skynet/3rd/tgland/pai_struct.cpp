#include <stdio.h>
#include <assert.h>
#include "pai_struct.h"


int pai_struct_get_type(const PaiStruct& pai)
{
	return pai.type ;
}


int pai_struct_get_serial(const PaiStruct& pai)
{
	if (pai.type == 6 || pai.type == 7 || pai.type == 10 || pai.type == 11 || pai.type == 12)
	{
		int serial=pai.pai[1]-pai.pai[0]+1;

		//printf("serial=%d,pai[1]=%d,pai[0]=%d\n",serial,pai.pai[1],pai.pai[0]);
		//assert(serial>1);
	
		return serial;
	}
	return 1;
}

int pai_struct_get_face(const PaiStruct& pai)
{
	if(pai.type == 6 || pai.type == 7 || pai.type == 10 || pai.type == 11 || pai.type == 12 )
	{
		return pai.pai[1];
	}

	return pai.pai[0];
}

int pai_struct_get_face_from(const PaiStruct& pai)
{
	return pai.pai[0];
}

int pai_struct_get_face_to(const PaiStruct& pai)
{
	if(pai.type == 6 || pai.type == 7 || pai.type == 10 || pai.type == 11 || pai.type == 12 )
	{
		return pai.pai[1];
	}
	return pai.pai[0];
}

int pai_struct_get_card_nu(const PaiStruct& pai)
{
	int pai_type =pai.type;
	int pai_serial=pai_struct_get_serial(pai);

	if(pai_type == 1)
	{
		return 1 ;
	}


	if(pai_type == 2 )
	{
		return 2 ;
	}

	if(pai_type == 3 )
	{
		return 3 ;
	}

	if(pai_type ==4 )
	{
		return 4 ;
	}


	if(pai_type == 5)
	{
		return 5 ;
	}


	if(pai_type == 6)
	{
		return pai_serial;
	}


	if(pai_type == 7 )
	{
		return (pai_serial)*2;
	}

	if(pai_type == 8)
	{
		return 6 ;
	}

	if(pai_type == 9)
	{
		return 8 ;
	}


	if(pai_type == 10 )
	{
		return (pai_serial)*4;
	}

	if(pai_type == 11)
	{
		return (pai_serial)*5;
	}

	if(pai_type == 12)
	{
		return (pai_serial)*3;
	}

	if(pai_type == 13 )
	{
		return 4 ;
	}

	if(pai_type == 14 )
	{
		return 2 ;
	}
	return 0;

}










