use major_baseball
    
-- PART I: SCHOOL ANALYSIS

-- 1. View the schools and school details tables
SELECT * FROM schools;
SELECT * FROM school_details;

-- 2. In each decade, how many schools were there that produced players?
SELECT FLOOR(yearID/10)*10 AS decade, COUNT(DISTINCT schoolID) AS num_schools
FROM schools
GROUP BY decade
ORDER BY decade;

-- 3. What are the names of the top 5 schools that produced the most players?
WITH cte AS (
    SELECT sd.name_full AS school_name,
           COUNT(DISTINCT s.playerID) AS num_players,
           RANK() OVER (ORDER BY COUNT(DISTINCT s.playerID) DESC) AS rnk
    FROM schools s
    LEFT JOIN school_details sd ON s.schoolID = sd.schoolID
    GROUP BY school_name
)
SELECT * FROM cte WHERE rnk <= 5;

-- 4. For each decade, what were the names of the top 3 schools that produced the most players?
WITH ds AS (
    SELECT FLOOR(yearID/10)*10 AS decade, sd.name_full AS school_name,
           COUNT(DISTINCT playerID) AS num_players
    FROM schools s
    LEFT JOIN school_details sd ON s.schoolID = sd.schoolID
    GROUP BY decade, school_name
),
rn AS (
    SELECT decade, school_name, num_players,
           ROW_NUMBER() OVER(PARTITION BY decade ORDER BY num_players DESC) AS row_num
    FROM ds
)
SELECT decade, school_name, num_players FROM rn
WHERE row_num <= 3
ORDER BY decade DESC, row_num;


    
-- PART II: SALARY ANALYSIS

-- 1. View the salaries table
SELECT * FROM salaries;

-- 2. Return the top 20% of teams in terms of average annual spending
WITH ts AS (
    SELECT yearID, teamID, SUM(salary) AS total_spend
    FROM salaries
    GROUP BY yearID, teamID
),
nt AS (
    SELECT teamID, AVG(total_spend) AS avg_spend,
           NTILE(5) OVER (ORDER BY AVG(total_spend) DESC) AS pct
    FROM ts
    GROUP BY teamID
)
SELECT teamID, ROUND(avg_spend / 1000000, 1) AS avg_spend_millions
FROM nt
WHERE pct = 1;

-- 3. For each team, show the cumulative sum of spending over the years
WITH ts AS (
    SELECT yearID, teamID, SUM(salary) AS total_spend
    FROM salaries
    GROUP BY yearID, teamID
)
SELECT yearID, teamID, total_spend,
       ROUND(SUM(total_spend) OVER(PARTITION BY teamID ORDER BY yearID) / 1000000, 1) AS cumulative_sum_millions
FROM ts;

-- 4. Return the first year that each team's cumulative spending surpassed 1 billion
WITH ts AS (
    SELECT yearID, teamID, SUM(salary) AS total_spend
    FROM salaries
    GROUP BY yearID, teamID
),
cs AS (
    SELECT yearID, teamID, total_spend,
           SUM(total_spend) OVER(PARTITION BY teamID ORDER BY yearID) AS cumulative_sum
    FROM ts
),
bn AS (
    SELECT yearID, teamID, cumulative_sum,
           ROW_NUMBER() OVER(PARTITION BY teamID ORDER BY cumulative_sum) AS rn
    FROM cs
    WHERE cumulative_sum > 1000000000
)
SELECT yearID, teamID, ROUND(cumulative_sum / 1000000000, 2) AS cumulative_sum_billions
FROM bn
WHERE rn = 1;


    
-- PART III: PLAYER CAREER ANALYSIS

-- 1. View the players table and find the number of players in the table
SELECT COUNT(*) AS num_players FROM players;

-- 2. For each player, calculate their age at debut, final game, and career length
SELECT nameGiven,
       CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS birthdate,
       TIMESTAMPDIFF(YEAR, CAST(CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS DATE), debut) AS starting_age,
       TIMESTAMPDIFF(YEAR, CAST(CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS DATE), finalGame) AS ending_age,
       TIMESTAMPDIFF(YEAR, debut, finalGame) AS career_length
FROM players
ORDER BY career_length DESC;

-- 3. What team did each player play on for their starting and ending years?
SELECT p.playerID, p.nameGiven, p.debut, p.finalGame,
       s.yearID AS starting_year, s.teamID AS starting_team,
       e.yearID AS ending_year, e.teamID AS ending_team
FROM players p
JOIN salaries s ON p.playerID = s.playerID AND YEAR(p.debut) = s.yearID
JOIN salaries e ON p.playerID = e.playerID AND YEAR(p.finalGame) = e.yearID;

-- 4. How many players started and ended on the same team and played over a decade?
SELECT p.playerID, p.nameGiven, p.debut, p.finalGame,
       s.teamID AS starting_team, e.teamID AS ending_team
FROM players p
JOIN salaries s ON p.playerID = s.playerID AND YEAR(p.debut) = s.yearID
JOIN salaries e ON p.playerID = e.playerID AND YEAR(p.finalGame) = e.yearID
WHERE s.teamID = e.teamID AND e.yearID - s.yearID > 10;


    
-- PART IV: PLAYER COMPARISON ANALYSIS

-- 1. Players with the same birthday between 1980 and 1990
WITH bd AS (
    SELECT CAST(CONCAT(birthYear,'-',birthMonth,'-',birthDay) AS DATE) AS birthdate,
           nameGiven
    FROM players
)
SELECT birthdate, GROUP_CONCAT(nameGiven SEPARATOR ', ') AS players, COUNT(nameGiven)
FROM bd
WHERE YEAR(birthdate) BETWEEN 1980 AND 1990
GROUP BY birthdate
ORDER BY birthdate;

-- 2. Summary table showing % of bats: right, left, both per team
SELECT s.teamID,
       ROUND(SUM(CASE WHEN p.bats = 'R' THEN 1 ELSE 0 END) / COUNT(s.playerID) * 100, 1) AS right_bats,
       ROUND(SUM(CASE WHEN p.bats = 'L' THEN 1 ELSE 0 END) / COUNT(s.playerID) * 100, 1) AS left_bats,
       ROUND(SUM(CASE WHEN p.bats = 'B' THEN 1 ELSE 0 END) / COUNT(s.playerID) * 100, 1) AS switch_bats
FROM salaries s
LEFT JOIN players p ON s.playerID = p.playerID
GROUP BY s.teamID;

-- 3. Decade-over-decade difference in average height and weight at debut
WITH hw AS (
    SELECT FLOOR(YEAR(debut)/10)*10 AS decade,
           ROUND(AVG(height), 2) AS avg_height,
           ROUND(AVG(weight), 2) AS avg_weight
    FROM players
    GROUP BY decade
)
SELECT decade,
       avg_height - LAG(avg_height) OVER(ORDER BY decade) AS height_diff,
       avg_weight - LAG(avg_weight) OVER(ORDER BY decade) AS weight_diff
FROM hw
WHERE decade IS NOT NULL;
"""
