

# 高级合伙人接口
## 得到高级合伙人信息

    * sczd/get_gjhhr_achievements_data?player_id=1011196
    * 参数：
        player_id 玩家 id
返回值说明：
```
{
    "result": "0",
    "gjhhr_status": "nor",
    
    "jicha_cash": 0  -- 可提现金额

    "all_percentage": 2.5, -- 总的提成比例
    "all_achievements": 0, -- 总业绩
    "all_income": 0, -- 总收入

    "my_achievements": 0, -- 我的团队业绩
    "my_percentage": 0, -- 我的团队提成比例
    "my_income": 0, -- 我的团队收入

    "other_achievements": 0, -- 其它下级 高级合伙人 业绩 和 收入： 直接孩子以下
    "other_income": 0, -- 其它下级 高级合伙人 收入 和 收入： 直接孩子以下

    "today_achievements": 0,-- 今天的总业绩

    "other_xj_gjhhr_ids": {},

    -- 直接孩子 高级合伙人 id 列表： xxx 团队
    "children_gjhhr_ids": [
        "105795",
        "105794"
    ],

     -- 直接孩子 高级合伙人数据： xxx 团队
    "son_data": [
        {
            "all_achievements": 0,
            "name": "105795团队",
            "income": 0,
            "percentage": 2.5,
            "id": "105795"
        },
        {
            "all_achievements": 0,
            "name": "105794团队",
            "income": 0,
            "percentage": 2.5,
            "id": "105794"
        }
    ],
}
```