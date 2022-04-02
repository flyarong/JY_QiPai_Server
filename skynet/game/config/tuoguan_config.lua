--
-- Author: lyx
-- Date: 2018/10/9
-- Time: 15:14
-- 说明：托管 配置
--

return 
{
    -- 托管场次等级。注意：不关服动态修改 不支持 增减，只能改参数
    tuoguan_games = 
    {
        {
            money={3000,20000},
            games = 
            {
                {model="freestyle_game",game_id=1},
			    {model="freestyle_game",game_id=17},
              
            }
        },
		{
            money={3000,50000},
            games = 
            {
                {model="freestyle_game",game_id=21},
              
            }
        },
		{
            money={5000,100000},
            games = 
            {
            {model="freestyle_game",game_id=33},
		              
            }
        },
        {
            money={10000,100000},
            games = 
            {
			{model="freestyle_game",game_id=13},

            }
        },
		{
            money={20000,400000},
            games = 
            {
			{model="freestyle_game",game_id=18},	
			
            }
        },
		 {
            money={20000,100000},
            games = 
            {			
			{model="match_game",game_id=2},    
            }
        },
		 {
            money={50000,400000},
            games = 
            {
			{model="freestyle_game",game_id=22},
			{model="freestyle_game",game_id=6},
            }
        },
		 {
            money={100000,500000},
            games = 
            {
			{model="freestyle_game",game_id=14},
			{model="freestyle_game",game_id=3},
            }
        },
		{
            money={100000,1000000},
            games = 
            {
			{model="freestyle_game",game_id=34},
            }
        },
		{
            money={400000,1000000},
            games = 
            {
			{model="freestyle_game",game_id=19},
            }
        },
		{
            money={500000,2000000},
            games = 
            {
			{model="freestyle_game",game_id=15},
		    {model="freestyle_game",game_id=4},
		    {model="freestyle_game",game_id=7},
            }
        },	
		{
            money={400000,2000000},
            games = 
            {
			{model="freestyle_game",game_id=23},
            }
        },	
		{
            money={1000000,5000000},
            games = 
            {
			{model="freestyle_game",game_id=35},
		    {model="freestyle_game",game_id=20},
            }
        },	
		{
            money={2000000,5000000},
            games = 
            {
			{model="freestyle_game",game_id=16},
		    {model="freestyle_game",game_id=24},
		    {model="freestyle_game",game_id=8},
            }
        },	
		{
            money={5000000,7000000},
            games = 
            {
			{model="freestyle_game",game_id=36},
            }
        },	
		{
            money={5000,50000},
            games = 
            {
			{model="freestyle_game",game_id=5},
            }
        },			
    }
}