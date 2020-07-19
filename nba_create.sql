use nba;

DROP TABLE IF EXISTS players;

CREATE TABLE IF NOT EXISTS players(
    player_id varchar(8) primary key,
    player_name TEXT not null
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/player.csv' INTO table players FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 rows;

DROP TABLE IF EXISTS teams;

CREATE TABLE IF NOT EXISTS teams(
    team_id varchar(11) primary key,
    team_name TEXT not null,
    team_abbrevitation char(3),
    team_city text not null
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/team.csv' INTO table teams FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 rows;

DROP TABLE IF EXISTS games;

CREATE TABLE IF NOT EXISTS games(
    game_date date,
    game_sequence int,
    game_id varchar(11),
    home_team_id varchar(11),
    visitor_team_id varchar(11),
    season year,
    primary key (game_id),
    FOREIGN KEY (home_team_id) REFERENCES teams (team_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    FOREIGN KEY (visitor_team_id) REFERENCES teams (team_id) ON UPDATE RESTRICT ON DELETE CASCADE
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/games.csv' INTO table games FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 rows;

DROP TABLE IF EXISTS actions;

CREATE TABLE IF NOT EXISTS actions(
    game_id varchar(11),
    team_id varchar(11),
    player_id varchar(8),
    min time,
    FGM int,
    FGA int,
    FG3M int,
    FG3A int,
    FTM int,
    FTA int,
    OREB int,
    DREB int,
    REB int,
    AST int,
    STL int,
    BLK int,
    TURN_OVER int,
    PF int,
    PTS int,
    PLUS_MINUS int,
    primary key (game_id, team_id, player_id),
    FOREIGN KEY (game_id) REFERENCES games (game_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    FOREIGN KEY (team_id) REFERENCES teams (team_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    FOREIGN KEY (player_id) REFERENCES players (player_id) ON UPDATE RESTRICT ON DELETE CASCADE
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/actions.csv' INTO table actions FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 rows;