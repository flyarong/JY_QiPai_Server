#include <stdio.h>
#include <time.h>
#include "lys_card.hpp"
#include "ddz_ai_util.hpp"



int test_card_analysis()
{
	const char* pai_str = "Ww2222AKQJT777666555543";

	std::map<int, int> pai_map = str_to_pai_map(pai_str);


	std::map<int, std::vector<struct pai_struct> >::iterator iter;


	std::map<int, int> kaiguan;
	kaiguan[CardType::THREE_PAIR] = 1;
	kaiguan[CardType::THREE_SINGLE] = 1;
	kaiguan[CardType::THREE] = 1;

	std::map<int, std::vector<struct pai_struct> > pai_enum = lys_get_pai_enum(pai_map, kaiguan);

	for(iter=pai_enum.begin(); iter!=pai_enum.end(); ++iter)
	{
		//("type_%d{",iter->first);

		const std::vector<struct pai_struct>& pais=iter->second;

		for(unsigned int i=0;i<pais.size();i++)
		{
			printf("%s ",pai_struct_tostring(pais[i]).c_str());
		}
		printf("}\n");

	}
	printf("\n");


	return 0;
}



void test_fenpai_forall(FenpaiData* data)
{
	std::map<int, int> kaiguan;
	for(int i=1;i<=14;i++)
	{
		kaiguan[i]=1;
	}

	/*
	std::vector<const char*> pais = {
		"7778888999TTTJQQK",
		"5555666644443333W2A7",
		"w222AAAKKKQQJJJT9",
	};
	*/

	std::vector<const char*> pais = {
		"Q6",
		"22QJJJJ765",
	};


	std::map<int, std::map<int, int>>  all_pais;

	for(unsigned int i=0;i<pais.size();i++)
	{
		all_pais[i+1]= str_to_pai_map(pais[i]);
	}
	std::map<int, int> sz_min= { { 1,5 },{ 2,3 },{ 3,2 } };
	std::map<int, int> sz_max = { { 1,12 },{ 2,10 },{ 3,6 } };

	fenpai_for_all(data, all_pais, sz_min, sz_max, kaiguan,2,2,2);

}

int main()
{

	printf("start_time: %lld\n", time(NULL));
	for (int i = 0; i < 0; i++)
	{

		FenpaiData data;
		test_fenpai_forall(&data);
	}
	printf("end_time: %lld\n ", time(NULL));



	FenpaiData data;
	test_fenpai_forall(&data);

	for(auto& iter:data.fen_pai)
	{
		printf("seat id:%d (score=%d,shoushu=%d,bomb_count=%d,xiajiao=%d,no_xiajiao_score=%d){ ",iter.first,iter.second.score,iter.second.shoushu,iter.second.bomb_count,iter.second.xiajiao,iter.second.no_xiajiao_score);


		for(auto& type_pai: iter.second.pai)
		{
			for(auto& pai:type_pai.second)
			{
				std::string str_pai=pai_struct_tostring(pai);
				printf(" %s(%d)", str_pai.c_str(),pai.score);
			}
		}
		printf("}\n");
	}


	return 0;
}




