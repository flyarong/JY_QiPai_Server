-- 创建时间:2019-02-25

local gobang_robot_ai = {}

local m_level = "初级"
local attackGradeList = {}
local defenseGradeList = {}

local chessboard
local chessW
local chessH
local chess_color

local chess = {}

local count
local left
local right
local NOTHINGFLAG = 0
local colorleft
local colorright
local hiscolor
local mycolor
-- 可能的最大长度
local maxcount = 1

local bufPos = {
{{ -4, 0 }, { -3, 0 }, { -2, 0 }, { -1, 0 }, { 0, 0 }, { 1, 0 }, { 2, 0 }, { 3, 0 }, { 4, 0 }},
{{ 0, -4 }, { 0, -3 }, { 0, -2 }, { 0, -1 }, { 0, 0 }, { 0, 1 }, { 0, 2 }, { 0, 3 }, { 0, 4 }},
{{ -4, -4 }, { -3, -3 }, { -2, -2 }, { -1, -1 }, { 0, 0 }, { 1, 1 }, { 2, 2 }, { 3, 3 }, { 4, 4 }},
{{ -4, 4 }, { -3, 3 }, { -2, 2 }, { -1, 1 }, { 0, 0 }, { 1, -1 }, { 2, -2 }, { 3, -3 }, { 4, -4 }},
}
local LevelOne = 100000
local Leveltwo = 10000
local Levelthree = 5000
local Levelfour = 1000
local Levelfive = 500
local Levelsix = 400
local Levelseven = 100
local LevelEight = 90
local LevelNight = 50
local LevelTen = 10
local LevelEleven = 9
local LevelTwelve = 5
local LevelThirteen = 2
local LevelFourteen = 1


local function getChessData(x, y)
    if x >= 1 and x <= chessW and y >= 1 and y <= chessH then
        return chessboard[x][y] or 0
    end
    return 0
end
local function check_operation(x, y)
    if chessboard[x][y] == 0 then
        return true
    end
end
-- 棋局的情况
local function InitSituation()
    local situation = {}
    situation.win5 = 0--赢5
    situation.alive4 = 0--活4
    situation.die4 = 0--死4
    situation.alive3 = 0--活3
    situation.lowalive3 = 0--低级活3
    situation.die3 = 0--死3
    situation.alive2 = 0--活2
    situation.lowalive2 = 0--低级活2
    situation.die2 = 0--死2
    situation.NOTHREAT = 0--没有威胁
    return situation
end
local function InitGradeData()
    local data = {}
    data.situation = {}
    data.grade = 0
    data.x = 1
    data.y = 1
    return data
end

local function calc()
    local x = 1
    local y = 1
    mycolor = chess_color
    if chess_color == 1 then
        hiscolor = 2
    else
        hiscolor = 1
    end
    for i = 1, chessW do
        for j = 1, chessH do
            if check_operation(i, j) then
                local situation = InitSituation()
                chess[5] = mycolor
                for k = 1, 4 do
                    gobang_robot_ai.setBufChess(k, i, j)
                    gobang_robot_ai.chessType(situation)
                end
                local grade = gobang_robot_ai.getGrade(situation)
                local data = InitGradeData()
                data.situation = situation
                data.grade = grade
                data.x = i
                data.y = j
                attackGradeList[#attackGradeList + 1] = data
            end
        end
    end
    
    hiscolor = chess_color
    if chess_color == 1 then
        mycolor = 2
    else
        mycolor = 1
    end
    for i = 1, chessW do
        for j = 1, chessH do
            if check_operation(i, j) then
                local situation = InitSituation()
                chess[5] = mycolor
                for k = 1, 4 do
                    gobang_robot_ai.setBufChess(k, i, j)
                    gobang_robot_ai.chessType(situation)
                end
                local grade = gobang_robot_ai.getGrade(situation)
                local data = InitGradeData()
                data.situation = situation
                data.grade = grade
                data.x = i
                data.y = j
                defenseGradeList[#defenseGradeList + 1] = data
            end
        end
    end

    return gobang_robot_ai.Level1()
end

--[[**********************************
    执行五子棋AI
**********************************]]
-- 棋盘chessboard：chessW * chessH的数组
function gobang_robot_ai.runAI(c, W, H, color)
    attackGradeList = {}
    defenseGradeList = {}
    chessboard = c
    chessW = W
    chessH = H
    chess_color = color
    chess = {0,0,0,0,0,0,0,0,0}
    return calc()
end

function gobang_robot_ai.setBufChess(index, x, y)
    for i = 1, 9 do
        local x1 = x + bufPos[index][i][1]
        local y1 = y + bufPos[index][i][2]
        if i ~= 5 then
            if x1 > 0 and x1 <= chessW and y1 > 0 and y1 <= chessH then
                chess[i] = getChessData(x1, y1)
            else
                chess[i] = hiscolor
            end
        end
    end
end

-- 棋型：连五，活四，冲四，活三，眠三，活二，眠二
function gobang_robot_ai.chessType(situation)
    maxcount = 1
    count = 1
    left = 4
    right = 6
    local b = true
    for i = 4, 1, -1 do
        if b and mycolor == chess[i] then
            left = i - 1
            count = count + 1
            maxcount = maxcount + 1
        elseif hiscolor == chess[i] then
            break
        else
            b = false
            maxcount = maxcount + 1
        end
    end
    b = true
    for i = 6, 9 do
        if b and mycolor == chess[i] then
            right = i + 1
            count = count + 1
            maxcount = maxcount + 1
        elseif hiscolor == chess[i] then
            break
        else
            b = false
            maxcount = maxcount + 1
        end
    end
    if left > 0 then
        colorleft = chess[left]
    end
    if right <= 9 then
        colorright = chess[right]
    end
    gobang_robot_ai.setSituation(situation)
end

function gobang_robot_ai.setSituation(situation)
    if maxcount < 5 then
        situation.NOTHREAT = situation.NOTHREAT + 1 --没有威胁
        return
    else
        if count >= 5 then--中心线5连
            situation.win5 = situation.win5 + 1--5连珠
            return
        elseif count == 4 then--中心线4连
            if colorleft == NOTHINGFLAG and colorright == NOTHINGFLAG then--两边断开位置均空
                situation.alive4 = situation.alive4 + 1--活四
                return
            elseif colorleft == NOTHINGFLAG or colorright == NOTHINGFLAG then--两边断开位置只有一个空
                situation.die4 = situation.die4 + 1--死四
                return
            end
        elseif count == 3 then
            local colorleft1 = chess[left - 1]
            local colorright1 = chess[right + 1]

            if colorleft == NOTHINGFLAG and colorright == NOTHINGFLAG then--两边断开位置均空
                if colorleft1 == hiscolor and colorright1 == hiscolor then--均为对手棋子
                    situation.die3 = situation.die3 + 1
                    return
                elseif colorleft1 == NOTHINGFLAG and colorright1 == NOTHINGFLAG then--均空
                    situation.alive3 = situation.alive3 + 1
                    return
                elseif colorleft1 == mycolor and colorright1 == mycolor then--均为自己的棋子
                    situation.alive4 = situation.alive4 + 1
                    return
                elseif (colorleft1 == mycolor or colorright1 == mycolor) and (colorleft1 == hiscolor or colorright1 == hiscolor) then --一个是自己的一个是别人的
                    situation.die4 = situation.die4 + 1
                    return
                elseif (colorleft1 == mycolor or colorright1 == mycolor) and (colorleft1 == NOTHINGFLAG or colorright1 == NOTHINGFLAG) then--一个是自己的一个是空
                    situation.alive3 = situation.alive3 + 1
                    return
                elseif (colorleft1 == hiscolor or colorright1 == hiscolor) and (colorleft1 == NOTHINGFLAG or colorright1 == NOTHINGFLAG) then--一个是别人的一个是空
                    situation.alive3 = situation.alive3 + 1
                    return
                end
            elseif colorleft == NOTHINGFLAG or colorright == NOTHINGFLAG then--两边断开位置只有一个空
                if colorleft == hiscolor then--左边被对方堵住
                    if colorright1 == NOTHINGFLAG then--右边均空
                        situation.die3 = situation.die3 + 1
                        return
                    end
                    if colorright1 == mycolor then
                        situation.die4 = situation.die4 + 1
                        return
                    end
                end
                if colorright == hiscolor then--右边被对方堵住
                    if colorleft1 == NOTHINGFLAG then--左边均空
                        situation.die3 = situation.die3 + 1
                        return
                    end
                    if colorleft1 == mycolor then--左边还有自己的棋子
                        situation.die4 = situation.die4 + 1
                        return
                    end
                end
            end
        elseif count == 2 then
            local colorleft1 = chess[left - 1]
            local colorright1 = chess[right + 1]
            local colorleft2 = chess[left - 2]
            local colorright2 = chess[right + 2]

            if colorleft == NOTHINGFLAG and colorright == NOTHINGFLAG then--两边断开位置均空
                if colorleft1 == mycolor and colorright1 == mycolor and colorleft2 == mycolor and colorright2 == mycolor then
                    situation.alive4 = situation.alive4 + 1--活4
                    return
                elseif colorleft1 == NOTHINGFLAG and colorright1 == NOTHINGFLAG then
                    situation.alive2 = situation.alive2 + 1
                    return
                elseif (colorleft1 == hiscolor and colorright1 == NOTHINGFLAG and colorright2 == NOTHINGFLAG) or
                    (colorright1 == hiscolor and colorleft1 == NOTHINGFLAG and colorleft2 == NOTHINGFLAG) then
                    situation.alive2 = situation.alive2 + 1--活2
                    return
                elseif (colorright1 == mycolor and colorright2 == NOTHINGFLAG) or
                    (colorleft1 == mycolor and colorleft2 == NOTHINGFLAG) then
                    situation.lowalive2 = situation.lowalive2 + 1--低级活2
                    return
                elseif (colorright1 == NOTHINGFLAG and colorright2 == mycolor) or
                    (colorleft1 == NOTHINGFLAG and colorleft2 == mycolor) then
                    situation.die3 = situation.die3 + 1--死3
                    return
                elseif (colorright1 == mycolor and colorright2 == hiscolor) or
                    (colorleft1 == mycolor and colorleft2 == hiscolor) then
                    situation.die3 = situation.die3 + 1--死3
                    return
                elseif (colorright1 == mycolor and colorright2 == mycolor) or
                    (colorleft1 == mycolor and colorleft2 == mycolor) then
                    situation.die4 = situation.die4 + 1--死4
                    return
                else
                    situation.die2 = situation.die2 + 1--死2
                    return
                end
            elseif colorleft == NOTHINGFLAG or colorright == NOTHINGFLAG then--两边断开位置只有一个空
                if colorleft == hiscolor then--左边被对方堵住
                    if colorright1 == NOTHINGFLAG and colorright2 == NOTHINGFLAG then
                        situation.die2 = situation.die2 + 1--死2
                        return
                    elseif colorright1 == mycolor and colorright2 == mycolor then
                        situation.die4 = situation.die4 + 1--死4
                    elseif colorright1 == mycolor or colorright2 == mycolor then
                        situation.die3 = situation.die3 + 1--死3
                        return
                    end
                end
                if colorright == hiscolor then
                    if colorleft1 == NOTHINGFLAG and colorleft2 == NOTHINGFLAG then
                        situation.die2 = situation.die2 + 1--死2
                        return
                    elseif colorleft1 == mycolor and colorleft2 == mycolor then
                        situation.die4 = situation.die4 + 1--死4
                        return
                    elseif colorleft1 == mycolor or colorleft2 == mycolor then
                        situation.die3 = situation.die3 + 1--死3
                        return
                    end
                end
            end
        elseif count == 1 then
            local colorleft1 = chess[left - 1]
            local colorright1 = chess[right + 1]
            local colorleft2 = chess[left - 2]
            local colorright2 = chess[right + 2]
            local colorleft3 = chess[left - 3]
            local colorright3 = chess[right + 3]

            if colorleft == NOTHINGFLAG and colorright == NOTHINGFLAG and 
                colorleft1 == mycolor and colorleft2 == mycolor and colorleft3 == mycolor and
                colorright1 == mycolor and colorright2 == mycolor and colorright3 == mycolor then
                situation.alive4 = situation.alive4 + 1
                return
            elseif colorleft == NOTHINGFLAG and colorright == hiscolor and colorleft1 == mycolor and colorleft2 == mycolor and colorleft3 == mycolor then
                situation.die4 = situation.die4 + 1
                return
            elseif colorright == NOTHINGFLAG and colorleft == hiscolor and colorright1 == mycolor and colorright2 == mycolor and colorright3 == mycolor then
                situation.die4 = situation.die4 + 1
                return
            elseif colorleft == NOTHINGFLAG and colorleft1 == mycolor and colorleft2 == mycolor and colorleft3 == NOTHINGFLAG and colorright == NOTHINGFLAG then
                situation.lowalive3 = situation.lowalive3 + 1
                return
            elseif colorright == NOTHINGFLAG and colorright1 == mycolor and colorright2 == mycolor and colorright3 == NOTHINGFLAG and colorleft == NOTHINGFLAG then
                situation.lowalive3 = situation.lowalive3 + 1
                return
            elseif colorleft == NOTHINGFLAG and colorleft1 == mycolor and colorleft2 == mycolor and colorleft3 == hiscolor and colorright == NOTHINGFLAG then
                situation.die3 = situation.die3 + 1
                return
            elseif colorright == NOTHINGFLAG and colorright1 == mycolor and colorright2 == mycolor and colorright3 == hiscolor and colorleft == NOTHINGFLAG then
                situation.die3 = situation.die3 + 1
                return
            elseif colorleft == NOTHINGFLAG and colorleft1 == NOTHINGFLAG and colorleft2 == mycolor and colorleft3 == mycolor then
                situation.die3 = situation.die3 + 1
                return
            elseif colorright == NOTHINGFLAG and colorright1 == NOTHINGFLAG and colorright2 == mycolor and colorright3 == mycolor then
                situation.die3 = situation.die3 + 1
                return
            elseif colorleft == NOTHINGFLAG and colorleft1 == mycolor and colorleft2 == NOTHINGFLAG and colorleft3 == mycolor then
                situation.die3 = situation.die3 + 1
                return
            elseif colorright == NOTHINGFLAG and colorright1 == mycolor and colorright2 == NOTHINGFLAG and colorright3 == mycolor then
                situation.die3 = situation.die3 + 1
                return
            elseif colorleft == NOTHINGFLAG and colorleft1 == mycolor and colorleft2 == NOTHINGFLAG and colorleft3 == NOTHINGFLAG and colorright == NOTHINGFLAG then
                situation.lowalive2 = situation.lowalive2 + 1
                return
            elseif colorright == NOTHINGFLAG and colorright1 == mycolor and colorright2 == NOTHINGFLAG and colorright3 == NOTHINGFLAG and colorleft == NOTHINGFLAG then
                situation.lowalive2 = situation.lowalive2 + 1
                return
            elseif colorleft == NOTHINGFLAG and colorleft1 == NOTHINGFLAG and colorleft2 == mycolor and colorleft3 == NOTHINGFLAG and colorright == NOTHINGFLAG then
                situation.lowalive2 = situation.lowalive2 + 1
                return
            elseif colorright == NOTHINGFLAG and colorright1 == NOTHINGFLAG and colorright2 == mycolor and colorright3 == NOTHINGFLAG and colorleft == NOTHINGFLAG then
                situation.lowalive2 = situation.lowalive2 + 1
                return
            end
        end
    end
    situation.NOTHREAT = situation.NOTHREAT + 1
end

function gobang_robot_ai.getGrade(situation)
    if situation.win5 >= 1 then
        return LevelOne--赢5
    end
    if situation.alive4 >= 1 or situation.die4 >= 2 or (situation.die4 >= 1 and situation.alive3 >= 1) then
        return Leveltwo--活4 双死4 死4活3
    end
    if situation.alive3 >= 2 then
        return Levelthree--双活3
    end
    if situation.die3 >= 1 and situation.alive3 >= 1 then
        return Levelfour--死3活3
    end
    if situation.die4 >= 1 then
        return Levelfive--高级死4
    end
    if situation.alive3 >= 1 then
        return Levelseven--单活3
    end
    if situation.lowalive3 >= 1 then
        return LevelEight--低级活3
    end
    if situation.alive2 >= 2 then
        return LevelNight--双活2
    end
    if situation.alive2 >= 1 then
        return LevelTen--活2
    end
    if situation.lowalive2 >= 1 then
        return LevelEleven--低级活2
    end
    if situation.die3 >= 1 then
        return LevelTwelve--死3
    end
    if situation.die2 >= 1 then
        return LevelThirteen--死2
    end
    return LevelFourteen--没有威胁
end


-- 排序
local function CompareCall(d1, d2)
    if d1.grade > d2.grade then
        return true
    elseif d1.grade < d2.grade then
        return false
    else
        local x1 = d1.x
        local y1 = d1.y
        local x2 = d2.x
        local y2 = d2.y
        local x3 = chessW / 2
        local y3 = chessH / 2

        if math.abs(math.abs(x1 - x3) + math.abs(y1 - y3)) < math.abs(math.abs(x2 - x3) + math.abs(y2 - y3)) then
            return true
        else
            return false
        end
    end
end

-- 初级难度：攻击低级活3即以上,防守双活3即以上,随机在5个中选择一个攻击点
function gobang_robot_ai.Level1()
    local x = 1
    local y = 1
    table.sort(attackGradeList, CompareCall)
    table.sort(defenseGradeList, CompareCall)
    --优先攻击
    if attackGradeList[1].grade > LevelEight and attackGradeList[1].grade >= defenseGradeList[1].grade then--攻击低级活3即以上
        x = attackGradeList[1].x
        y = attackGradeList[1].y
    elseif attackGradeList[1].grade >= Levelseven and defenseGradeList[1].grade <= Levelthree then
        x = attackGradeList[1].x
        y = attackGradeList[1].y
    elseif attackGradeList[1].grade < defenseGradeList[1].grade and defenseGradeList[1].grade >= Levelthree then--防守双活3即以上
        x = defenseGradeList[1].x
        y = defenseGradeList[1].y
    else--否则随机在5个中选择一个攻击点
        local fr = #attackGradeList
        if fr > 5 then
            fr = 5
        end
        local fi = math.random( 1, fr )
        x = attackGradeList[fi].x
        y = attackGradeList[fi].y
    end
    return x, y
end

return gobang_robot_ai