use nba;

-- 1 Đưa ra các trận đấu trong ngày x-y-z
select
    game_date as Date,
    h.team_name as "Home",
    v.team_name as Visitor
from
    games as g
    join teams as h on g.home_team_id = h.team_id
    join teams as v on g.visitor_team_id = v.team_id
where
    g.game_date = "2012-10-30";

-- 2 Đưa ra tổng số trận đội a trong mùa x
select
    count(game_id)
from
    games
where
    (
        home_team_id in (
            select
                team_id as t
            from
                teams
            where
                team_name = "Celtics"
        )
        or visitor_team_id in (
            select
                team_id as t
            from
                teams
            where
                team_name = "Celtics"
        )
    )
    and season = 2018;

-- 3 Đưa ra trung bình điểm mỗi trận của mỗi đội mùa x
select
    team_name,
    TrungBinh
from
    (
        select
            sum(PTS) / count(distinct(a.game_id)) as TrungBinh,
            a.team_id as id
        from
            actions as a
            join games as g on a.game_id = g.game_id
        where
            g.season = 2018
        group by
            team_id
    ) as x
    join teams as t on x.id = t.team_id;

-- 4 Đưa ra top 10 đội tỉ lệ số điểm ghi được bằng ném 3 nhiều nhất mùa x
select
    team_name,
    TrungBinh
from
    (
        select
            sum(FG3M) * 3 / sum(PTS) as TrungBinh,
            a.team_id as id
        from
            actions as a
            join games as g on a.game_id = g.game_id
        where
            g.season = 2018
        group by
            team_id
    ) as x
    join teams as t on x.id = t.team_id
order by
    TrungBinh desc
limit
    10;

-- 5 Đưa ra cầu thủ ghi trung bình điểm mỗi trận cao nhất mùa x
select
    player_name,
    TrungBinh
from
    (
        select
            sum(PTS) / count(distinct(a.game_id)) as TrungBinh,
            a.player_id as id
        from
            actions as a
            join games as g on a.game_id = g.game_id
        where
            g.season = 2018
        group by
            a.player_id
    ) as x
    join players as p on x.id = p.player_id
order by
    TrungBinh desc
limit
    1;

-- 6 Đưa ra top 10 cầu thủ có tỉ lệ ném ba tốt nhất mùa x (ném ít nhất 20 quả)
select
    player_name,
    TrungBinh
from
    (
        select
            sum(FG3M) / sum(FG3A) as TrungBinh,
            a.player_id as id
        from
            actions as a
            join players as p on a.player_id = p.player_id
            join games as g on a.game_id = g.game_id
        where
            g.season = 2018
        group by
            a.player_id
        having
            sum(FG3A) > 20
    ) as x
    join players as p on x.id = p.player_id
order by
    TrungBinh desc
limit
    10;

-- 7 Đưa ra top 10 cầu thủ có nhiều Triple Double nhất mùa x
drop function if exists TripleDouble;

DELIMITER $$ 
CREATE FUNCTION TripleDouble(
    REB int,
    AST int,
    STL int,
    BLK int,
    PTS int
) RETURNS int DETERMINISTIC BEGIN DECLARE result int;

SET
    result = 0;

IF REB > 9 THEN
SET
    result = result + 1;

END IF;

IF AST > 9 THEN
SET
    result = result + 1;

END IF;

IF BLK > 9 THEN
SET
    result = result + 1;

END IF;

IF STL > 9 THEN
SET
    result = result + 1;

END IF;

IF PTS > 9 THEN
SET
    result = result + 1;

END IF;

RETURN (result);

END $$ 
DELIMITER ;

select
    player_name,
    TB
from
    (
        select
            count(
                if(
                    TripleDouble(a.REB, a.AST, a.BLK, a.STL, a.PTS) > 2,
                    3,
                    NULL
                )
            ) as TB,
            a.player_id as id
        from
            actions as a
            join players as p on a.player_id = p.player_id
            join games as g on a.game_id = g.game_id
        where
            g.season = 2018
        group by
            a.player_id
    ) as x
    join players as p on x.id = p.player_id
order by
    TB desc
limit
    10;

-- 8 Đưa ra top 10 đội bóng có tỉ lệ FG(FGM/FGA) nhất mùa x
select
    team_name,
    TrungBinh
from
    (
        select
            sum(FGM) / sum(FGA) as TrungBinh,
            a.team_id as id
        from
            actions as a
            join games as g on a.game_id = g.game_id
        where
            g.season = 2018
        group by
            team_id
    ) as x
    join teams as t on x.id = t.team_id
order by
    TrungBinh desc
limit
    10;

-- 9 Đưa ra top 10 đội bóng có hàng phòng ngự tốt nhất mùa x (Đội bị ghi ít điểm nhất)
with temp as (
    select
        a.team_id,
        a.game_id,
        sum(PTS) as points
    from
        actions as a
        join games as g on a.game_id = g.game_id
    where
        season = 2018
    group by
        team_id,
        game_id
),
temp2 as (
    select
        t1.team_id as team_id,
        t1.game_id as game_id,
        t2.points as Lpoints
    from
        temp as t1
        join temp as t2 on (
            t1.game_id = t2.game_id
            and t1.team_id != t2.team_id
        )
)
select
    concat(team_city, ' ', team_name) as Team,
    Lpoints / 82 as "PPG Allow"
from
    (
        select
            team_id,
            sum(Lpoints) as Lpoints
        from
            temp2
        group by
            team_id
        order by
            sum(Lpoints)
        limit
            10
    ) as t
    join teams as te on t.team_id = te.team_id;

-- 10 Đưa ra thống kê đối đầu giữa 2 đội trong mùa x
drop procedure if exists TwoTem;

DELIMITER // 
CREATE PROCEDURE TwoTem(
    IN team1name VARCHAR(60),
    in team2name varchar(60),
    in inputseason year
) BEGIN declare team1id,
team2id varchar(11);

select
    team_id
from
    teams
where
    team_name = team1name into team1id;

select
    team_id
from
    teams
where
    team_name = team2name into team2id;

with temp as (
    select
        game_id
    from
        games
    where
        (
            (
                (
                    home_team_id = team1id
                    and visitor_team_id = team2id
                )
                or(
                    home_team_id = team2id
                    and visitor_team_id = team1id
                )
            )
            and season = inputseason
        )
),
temp2 as (
    select
        a.game_id,
        sum(PTS) as t1PTS
    from
        actions as a
        join temp as t on a.game_id = t.game_id
    where
        a.team_id = team1id
    group by
        game_id,
        team_id
),
temp3 as (
    select
        a.game_id,
        sum(PTS) as t2PTS
    from
        actions as a
        join temp as t on a.game_id = t.game_id
    where
        a.team_id = team2id
    group by
        game_id,
        team_id
),
temp4 as (
    select
        temp2.game_id,
        t1PTS,
        t2PTS
    from
        temp2
        join temp3 on temp2.game_id = temp3.game_id
)
select
    concat(team1name, '-', team2name) as teams,
    concat(
        count(if(t1PTS > t2PTS, 1, NULL)),
        '-',
        count(if(t2PTS > t1PTS, 1, NULL))
    ) as result
from
    temp4;

END // 
DELIMITER ;

call TwoTem("Celtics", "Hawks", 2018);

-- 11 Đưa ra kết quả của một đội trong mùa x->y
drop procedure if exists OneTem;

DELIMITER // 
CREATE PROCEDURE OneTem(
    IN teamname VARCHAR(60),
    in startseason year,
    in endseason year
) BEGIN declare teamid varchar(11);

select
    team_id
from
    teams
where
    team_name = teamname into teamid;

with temp as (
    select
        game_id
    from
        games
    where
        (
            (
                (home_team_id = teamid)
                or(visitor_team_id = teamid)
            )
            and season <= endseason
            and season >= startseason
        )
),
temp2 as (
    select
        a.game_id,
        sum(PTS) as t1PTS
    from
        actions as a
        join temp as t on a.game_id = t.game_id
    where
        a.team_id = teamid
    group by
        game_id,
        team_id
),
temp3 as (
    select
        a.game_id,
        sum(PTS) as t2PTS
    from
        actions as a
        join temp as t on a.game_id = t.game_id
    where
        a.team_id != teamid
    group by
        game_id,
        team_id
),
temp4 as (
    select
        temp2.game_id,
        t1PTS,
        t2PTS
    from
        temp2
        join temp3 on temp2.game_id = temp3.game_id
)
select
    teamname as team,
    concat(
        count(if(t1PTS > t2PTS, 1, NULL)),
        '-',
        count(if(t2PTS > t1PTS, 1, NULL))
    ) as result
from
    temp4;

END //
DELIMITER ;

call OneTem("Celtics", 2013, 2018);

-- 12 Đưa ra top 10 đội bóng có thành tích tốt nhất mùa x
with temp as (
    select
        a.team_id,
        a.game_id,
        sum(PTS) as PTS
    from
        actions as a
        join games as g on a.game_id = g.game_id
    where
        season = 2018
    group by
        a.game_id,
        a.team_id
),
temp2 as (
    select
        g.game_id,
        t1.team_id as hid,
        t1.PTS as hpoints,
        t2.team_id as vid,
        t2.PTS as vpoints
    from
        (
            games as g
            join temp as t1 on g.game_id = t1.game_id
            and g.home_team_id = t1.team_id
        )
        join temp as t2 on g.game_id = t2.game_id
        and g.visitor_team_id = t2.team_id
),
temp3 as (
    select
        hid,
        count(if(hpoints > vpoints, 1, NULL)) as hwin,
        count(if(hpoints < vpoints, 1, NULL)) as hlose
    from
        temp2
    group by
        hid
),
temp4 as (
    select
        vid,
        count(if(vpoints > hpoints, 1, NULL)) as vwin,
        count(if(vpoints < hpoints, 1, NULL)) as vlose
    from
        temp2
    group by
        vid
)
select
    team_name,
    hwin + vwin as wins,
    hlose + vlose as lose
from
    temp3
    join temp4 on hid = vid
    join teams on hid = team_id
order by
    wins - lose desc
limit
    10;

-- 13 Đưa ra top 10 cầu thủ có điểm đánh giá với công thức gamescore trung bình trong mùa x tốt nhất
drop function if exists gamescore;

DELIMITER $$ 
CREATE FUNCTION gamescore(
    FGM int,
    FGA int,
    FG3M int,
    FG3A int,
    FTM int,
    FTA int,
    OREB int,
    DREB int,
    AST int,
    STL int,
    BLK int,
    TURN_OVER int,
    PF int,
    PTS int
) RETURNS int DETERMINISTIC BEGIN DECLARE result int;

SET
    result = PTS + (0.4 * FGM) - (0.7 * FGA) - (0.4 * (FTA - FTM)) + (0.7 * OREB) + (0.3 * DREB) + STL + (0.7 * AST) + (0.7 * BLK) - (0.4 * PF) - TURN_OVER;

RETURN (result);

END $$ 
DELIMITER ;

select
    player_name,
    TrungBinh
from
    (
        select
            avg(
                gamescore(
                    FGM,
                    FGA,
                    FG3M,
                    FG3A,
                    FTM,
                    FTA,
                    OREB,
                    DREB,
                    AST,
                    STL,
                    BLK,
                    TURN_OVER,
                    PF,
                    PTS
                )
            ) as TrungBinh,
            a.player_id as id
        from
            actions as a
            join players as p on a.player_id = p.player_id
            join games as g on a.game_id = g.game_id
        where
            g.season = 2018
        group by
            a.player_id
    ) as x
    join players as p on x.id = p.player_id
order by
    TrungBinh desc
limit
    10;

-- 14 Đưa ra top 20 cầu thủ bị turn over nhiều nhất
select
    player_name,
    turn_over
from
    (
        select
            sum(TURN_OVER) as turn_over,
            a.player_id as id
        from
            actions as a
            join players as p on a.player_id = p.player_id
            join games as g on a.game_id = g.game_id
        where
            g.season = 2018
        group by
            a.player_id
    ) as x
    join players as p on x.id = p.player_id
order by
    turn_over desc
limit
    20;

-- 15 Đưa ra top 10 cầu thủ chơi cho nhiều đội bóng nhất từ mùa x->y
select
    player_name,
    teams
from
    (
        select
            count(distinct(team_id)) as teams,
            a.player_id as id
        from
            actions as a
            join players as p on a.player_id = p.player_id
            join games as g on a.game_id = g.game_id
        where
            g.season <= 2018
            and g.season >= 2012
        group by
            a.player_id
    ) as x
    join players as p on x.id = p.player_id
order by
    teams desc
limit
    10;

-- 16 Đưa ra chuỗi trận thắng dài nhất của một đội trong mùa x
DROP PROCEDURE IF EXISTS count_con_win;

DELIMITER // 
CREATE PROCEDURE count_con_win(
    IN teamname VARCHAR(60),
    in inputseason year,
    out c_win int
) BEGIN declare teamid varchar(11);

DECLARE mp INT;

declare lp int;

declare gdate date;

DECLARE done INT DEFAULT FALSE;

declare max int default 0;

declare curr_max int default 0;

DECLARE cursor_i CURSOR FOR with temp as (
    select
        game_id,
        game_date
    from
        games
    where
        (
            home_team_id = teamid
            or visitor_team_id = teamid
        )
        and season = inputseason
),
temp1 as (
    select
        a.game_id,
        sum(PTS) as MPTS
    from
        actions as a
        join temp as g on a.game_id = g.game_id
    where
        a.team_id = teamid
    group by
        a.game_id,
        a.team_id
),
temp2 as (
    select
        a.game_id,
        sum(PTS) as LPTS
    from
        actions as a
        join temp as g on a.game_id = g.game_id
    where
        a.team_id != teamid
    group by
        a.game_id,
        a.team_id
)
SELECT
    game_date,
    MPTS,
    LPTS
FROM
    temp as t
    join temp1 as t1 on t.game_id = t1.game_id
    join temp2 as t2 on t.game_id = t2.game_id
order by
    game_date;

DECLARE CONTINUE HANDLER FOR NOT FOUND
SET
    done = TRUE;

select
    team_id
from
    teams
where
    team_name = teamname into teamid;

OPEN cursor_i;

read_loop: LOOP FETCH cursor_i INTO gdate,
mp,
lp;

IF done THEN LEAVE read_loop;

END IF;

if mp > lp then
set
    curr_max = curr_max + 1;

else if curr_max > max then
set
    max = curr_max;

end if;

set
    curr_max = 0;

end if;

END LOOP;

CLOSE cursor_i;

set
    c_win = max;

END // 
DELIMITER ;

call count_con_win("Celtics", 2018, @con_win);

select
    @con_win;

-- 17 Đưa ra chuỗi trận thắng dài nhất của mỗi đội trong mùa x
DROP PROCEDURE IF EXISTS count_con_win_all;

DELIMITER // 
CREATE PROCEDURE count_con_win_all(in inputseason year) BEGIN declare teamid varchar(11);

declare teamname varchar(100);

DECLARE done INT DEFAULT FALSE;

declare max int default 0;

DECLARE cursor_i CURSOR FOR
select
    team_name
from
    teams;

DECLARE CONTINUE HANDLER FOR NOT FOUND
SET
    done = TRUE;

create table if not exists temp_table(team_name varchar(100), con_win int);

OPEN cursor_i;

read_loop: LOOP FETCH cursor_i INTO teamname;

IF done THEN LEAVE read_loop;

END IF;

call count_con_win(teamname, inputseason, max);

insert into
    temp_table(team_name, con_win)
values
(teamname, max);

END LOOP;

CLOSE cursor_i;

select
    *
from
    temp_table;

drop table temp_table;

END // 
DELIMITER ;

call count_con_win_all(2018);

-- 18 Tìm ra top 10 cầu thủ ghi nhiều điểm trên sân khách nhất
select
    sum(PTS),
    player_name
from
    actions as a
    join games as g on (
        a.game_id = g.game_id
        and a.team_id != g.home_team_id
    )
    join players as p on a.player_id = p.player_id
where
    (season = 2018)
group by
    a.player_id
order by
    sum(PTS) desc
limit
    10;

-- 19 Đưa ra cầu thủ ghi nhiều điểm nhất của mỗi đội trong trận x
with temp as (
    select
        home_team_id as hid,
        visitor_team_id as vid,
        game_id as gid
    from
        games
    where
        game_id = 21200018
),
temp1 as (
    select
        team_name,
        a.player_id,
        PTS,
        hid,
        t.gid as gid,
        player_name
    from
        actions as a
        join temp as t on a.game_id = t.gid
        and t.hid = a.team_id
        join teams as te on t.hid = te.team_id
        join players as p on p.player_id = a.player_id
    group by
        player_id
    order by
        PTS desc
    limit
        1
), temp2 as (
    select
        team_name,
        a.player_id,
        PTS,
        vid,
        t.gid as gid,
        player_name
    from
        actions as a
        join temp as t on a.game_id = t.gid
        and t.vid = a.team_id
        join teams as te on t.vid = te.team_id
        join players as p on p.player_id = a.player_id
    group by
        player_id
    order by
        PTS desc
    limit
        1
)
select
    temp1.team_name,
    temp1.player_name,
    temp1.PTS,
    temp2.team_name,
    temp2.player_name,
    temp2.PTS,
    temp1.gid
from
    temp1
    join temp2 on temp1.gid = temp2.gid;

-- 20 Đưa ra danh sách các cầu thủ thi đấu cho đội x trong mùa x
select
    player_name
from
    actions as a
    join players as p on a.player_id = p.player_id
    join games as g on a.game_id = g.game_id
    join teams as t on a.team_id = t.team_id
where
    season = 2018
    and team_name = "Celtics";

-- 21 Tìm ra cầu thủ có tên bắt đầu bằng k kết thuc bằng g
select
    player_name
from
    players
where
    player_name like "k%g";

-- 22 Liệt kê đội bóng của mỗi thành phố
select
    team_city,
    group_concat(team_name) as Teams
from
    teams
group by
    team_city;

-- 23 Top 10 cầu thủ thi đấu nhiều nhất mùa x (Tính theo phút)
select
    player_name,
    FLOOR(MIN + SEC / 60) as MIN
from
    (
        select
            sum(minute(MIN)) as MIN,
            sum(second(MIN)) as SEC,
            a.player_id as id
        from
            actions as a
            join players as p on a.player_id = p.player_id
            join games as g on a.game_id = g.game_id
        where
            g.season = 2018
        group by
            a.player_id
    ) as x
    join players as p on x.id = p.player_id
order by
    (MIN * 60 + SEC) desc
limit
    10;

-- 24 Tìm trận đấu có chênh lệch điểm số lớn nhất mùa x
with temp as (
    select
        a.game_id,
        a.team_id,
        sum(PTS) as pts
    from
        actions as a
        join games as g on a.game_id = g.game_id
    where
        season = 2018
    group by
        a.game_id,
        a.team_id
)
select
    g.game_id,
    abs(t1.pts - t2.pts) as pDiff
from
    games as g
    join temp as t1 on (
        g.game_id = t1.game_id
        and g.home_team_id = t1.team_id
    )
    join temp as t2 on (
        g.game_id = t2.game_id
        and g.visitor_team_id = t2.team_id
    )
group by
    g.game_id
order by
    abs(t1.pts - t2.pts) desc
limit
    1;

-- 25 Tìm ra các đội mà cầu thủ a chơi
select
    distinct(team_name)
from
    actions as a
    join teams as t on a.team_id = t.team_id
    join players as p on a.player_id = p.player_id
where
    player_name like "%Jeremy Lin%";

-- 26 Đưa ra kết quả của các trận đấu mà đội a tham gia trong mùa x
with temp1 as (
    select
        a.team_id as tid,
        a.game_id as gid,
        sum(PTS) as Lpoints
    from
        actions as a
        join games as g on a.game_id = g.game_id
    where
        season = 2018
        and a.team_id not in (
            select
                team_id as t
            from
                teams
            where
                team_name = "Celtics"
        )
    group by
        a.team_id,
        a.game_id
),
temp2 as (
    select
        a.team_id as tid,
        a.game_id as gid,
        sum(PTS) as Mpoints
    from
        actions as a
        join games as g on a.game_id = g.game_id
    where
        season = 2018
        and a.team_id in (
            select
                team_id as t
            from
                teams
            where
                team_name = "Celtics"
        )
    group by
        a.team_id,
        a.game_id
)
select
    temp1.gid,
    team_name,
    Lpoints,
    Mpoints
from
    (
        select
            game_id
        from
            games
        where
            home_team_id in (
                select
                    team_id as t
                from
                    teams
                where
                    team_name = "Celtics"
            )
            or visitor_team_id in (
                select
                    team_id as t
                from
                    teams
                where
                    team_name = "Celtics"
            )
    ) as g
    join temp1 on g.game_id = temp1.gid
    join temp2 on g.game_id = temp2.gid
    join teams on temp1.tid = teams.team_id;

-- 27 Đưa ra các cầu thủ thi đấu trong 2017 mà không thi đấu trong 2018
select
    distinct player_name
from
    actions as a
    join games as g on a.game_id = g.game_id
    join players as p on a.player_id = p.player_id
where
    season = 2017
    and a.player_id not in (
        select
            player_id
        from
            actions as a
            join games as g on a.game_id = g.game_id
        where
            season = 2018
    );

-- 28 Tìm ra cầu thủ có tên dài nhất
select
    player_name
from
    players
order by
    length(player_name) desc
limit
    1;

-- 29 Tìm ra rank các cầu thủ (xếp theo điểm của các cầu thủ trong một trận đấu)
SELECT
    player_name,
    PTS,
    RANK() OVER (
        ORDER BY
            PTS DESc
    ) pts_rank
FROM
    actions as a
    join players as p on a.player_id = p.player_id
where
    game_id = 21200018;

-- 30 In ra các cầu thủ và điểm ghi được của cầu thủ đó của đội x và phân loại nếu điểm >200 thì là KP, nếu 100<điểm<200 thì là RP1, nếu 50<điểm<100 thì là RP2, dưới 50 là Rookie.
with temp as (
    select
        count(pts) as points,
        player_id
    from
        actions as a
        join (
            select
                team_id
            from
                teams
            where
                team_name = "Celtics"
        ) as t on a.team_id = t.team_id
    group by
        player_id
    order by
        points desc
)
select
    player_name,
    t.points as points,
    CASE
        WHEN t.points >= 200 THEN "Key Player"
        WHEN (
            t.points > 100
            and t.points < 200
        ) THEN "Reserve Player 1"
        WHEN (
            t.points > 50
            and t.points < 100
        ) THEN "Reserve Player 2"
        ELSE "Rookie"
    END as CLASS
from
    temp as t
    join players as p on t.player_id = p.player_id
order by
    points desc;
