-- ## Lahman Baseball Database Exercise
-- - this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
-- - you can find a data dictionary [here](http://www.seanlahman.com/files/database/readme2016.txt)

-- ### Use SQL queries to find answers to the *Initial Questions*. If time permits, choose one (or more) of the *Open-Ended Questions*. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the *Open-Ended Questions*.



-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 

		-- SELECT COUNT(DISTINCT yearid)
		-- FROM appearances -- 146

		-- SELECT COUNT(DISTINCT yearid)
		-- FROM teams -- 146

		-- SELECT COUNT(DISTINCT year)
		-- FROM homegames -- 146

SELECT CONCAT(MIN(yearid),' - ',MAX(yearid)) as year_range
FROM appearances -- 1871 - 2016

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
 
SELECT DISTINCT CONCAT(namefirst, ' ', namelast), 
 		CONCAT(CAST(FLOOR(height::numeric / 12) AS varchar(10)) , ' ft ', CAST((MOD(height::numeric,12)) AS varchar(10)) , ' in') as height,
		 CASE WHEN g_all = '1' THEN CONCAT(g_all,' game played for the ',name, ' in ', sub.yearid)
												  	ELSE CONCAT(g_all,' games played for the ',name, 
																' in ', sub.yearid) END as games_played, 
			CASE WHEN (SELECT SUM(g_all)
					FROM appearances as a
					WHERE a.playerid=sub.playerid) ='1' THEN CONCAT((SELECT SUM(g_all)
																	FROM appearances as a
																	WHERE a.playerid=sub.playerid), 
																	' total game played')
					ELSE CONCAT((SELECT SUM(g_all)
								FROM appearances as a
								WHERE a.playerid=sub.playerid), ' total games played') 
								END AS total_games
	   
FROM people
INNER JOIN (SELECT playerid, teamid, g_all, yearid
		   FROM appearances
		   WHERE playerid=(SELECT playerid
						  FROM people
						  WHERE height IN (SELECT MIN(height)
										 FROM people))) as sub
	USING (playerid)
INNER JOIN teams
USING (teamid)

SELECT DISTINCT CONCAT(namefirst, ' ', namelast), 
 		CONCAT(CAST(FLOOR(height::numeric / 12) AS varchar(10)) , ' ft ', CAST((MOD(height::numeric,12)) AS varchar(10)) , ' in') as height,
		 CASE WHEN g_all = '1' THEN CONCAT(g_all,' game played for the ',name, ' in ', sub.yearid)
												  	ELSE CONCAT(g_all,' games played for the ',name, ' in ', sub.yearid) END as games_played, 
		CASE WHEN (SELECT SUM(g_all)
					FROM appearances as a
					WHERE a.playerid=sub.playerid) ='1' THEN CONCAT((SELECT SUM(g_all)
																	FROM appearances as a
																	WHERE a.playerid=sub.playerid), ' total game played')
				ELSE CONCAT((SELECT SUM(g_all)
							FROM appearances as a
							WHERE a.playerid=sub.playerid), ' total games played') END AS total_games, games_by_team
	   
FROM people
INNER JOIN (SELECT playerid, teamid, g_all, yearid
		   FROM appearances
		   WHERE playerid IN (SELECT playerid
						  FROM people
						  WHERE playerid LIKE 'aaron%')
		   ORDER BY yearid) as sub
	USING (playerid)
INNER JOIN teams
USING (teamid)
INNER JOIN (SELECT playerid, teamid, yearid, SUM(g_all) as games_by_team
		   FROM appearances
		   GROUP BY teamid, playerid, yearid) as ap
USING(playerid)




SELECT namelast
from people


SELECT *
		   FROM appearances
		   ORDER BY playerid, yearid
		   
WITH cte AS (
	SELECT playerid, 
		   namefirst, 
	       namelast, 
	       height, 
	       teamid,
	       SUM(g_all) AS games_by_team
	FROM people
	LEFT JOIN appearances
	USING(playerid)
	WHERE playerid LIKE '%roberri%'
	GROUP BY teamid,
	         playerid, 
	         namefirst, 
	         namelast, 
	         height
	)
	
SELECT cte.namefirst, 
       cte.namelast, 
	   cte.height, 
	   cte.teamid,
	   games_by_team,
	   total_player_games
FROM cte
LEFT JOIN (
	SELECT playerid, SUM(g_all) AS total_player_games
	FROM appearances
	GROUP BY playerid) AS total
USING(playerid)
ORDER BY playerid, teamid

-- Eddie Gaedel, 3ft7in, 1 game played for the St. Louis Browns

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT DISTINCT CONCAT(namefirst, ' ', namelast), 
	MONEY(SUM(salary::numeric) OVER (PARTITION BY playerid)) as lifetime_salary
FROM (SELECT *
	 FROM people
	 WHERE playerid IN (SELECT playerid
					   FROM collegeplaying
					   WHERE schoolid = 'vandy')) as vandy
INNER JOIN salaries
USING(playerid)
ORDER BY lifetime_salary DESC;

-- David Price made the most money with over 81 million bucks

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT 
	CASE WHEN pos IN ('LF','RF','CF') THEN 'Outfield'
		WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
		WHEN pos IN ('P','C') THEN 'Battery'
		ELSE 'Not listed' END AS position_group, 
	SUM(po) as total_putouts
FROM fieldingpost
WHERE yearid = '2016'
GROUP BY position_group
ORDER BY total_putouts DESC;

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

-- I keep fucking up how I'm counting games. Not sure why my older approach wasn't working. This isn't a perfect count of games played, but good enough for now. Consider revisiting. can also link to teams table to get an actual count of the games played per season by team. sum of games from teams table

WITH games as ( 
			SELECT DISTINCT yearid, MAX(g) as max_games, 
			MAX(g) * COUNT(DISTINCT teamid)/2 as total_games, 
			COUNT(distinct teamid) as teams, SUM(so) as so_total, 
			CONCAT(FLOOR(yearID/10)*10,'s') as decade, 
			SUM(hr) as hr_total
			FROM batting
			GROUP BY yearid)
			
SELECT decade, ROUND(SUM(so_total)/SUM(total_games),2) as so_per_game, ROUND(SUM(hr_total)/SUM(total_games),2) as hr_per_game
FROM games
WHERE yearid>= '1920'
GROUP BY decade
ORDER BY decade

-- Positive correlation between home-runs and strike-outs


					-- SELECT yearID, sum(so)/2430 -- estimate of games per season
					-- FROM Batting 
					-- GROUP BY yearid -- 24,000 so in 1991

					-- SELECT * 
					-- FROM batting 


-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT CONCAT(namefirst, ' ', namelast), sb, cs, 
	CONCAT(ROUND(100*ROUND((sb::float/(cs + sb)::float)::numeric,3),1),'%') as steal_success
FROM batting
JOIN people
	USING(playerid)
WHERE yearid = '2016' 
	AND (sb+cs) > 20
ORDER BY steal_success DESC
LIMIT 1;

-- Chris Owings


-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?


SELECT name, yearid, w, WSwin
FROM teams
WHERE WSwin = 'N' AND yearid BETWEEN '1970' AND '2016' AND 
	w = (SELECT MAX(w)
		  FROM teams as sub
		  WHERE WSwin = 'N' AND yearid BETWEEN '1970' AND '2016')

-- Seattle Mariners in 2001 won 116 games and didn't win WS.

SELECT name, yearid, w, WSwin
FROM teams
WHERE WSwin = 'Y' AND yearid BETWEEN '1970' AND '2016' AND w = (SELECT MIN(w)
		  FROM teams
		  WHERE WSwin = 'Y' AND yearid BETWEEN '1970' AND '2016')

-- LA Dodgers in 1981 won the WS and 63 games. Season shortened due to strike. 

SELECT name, yearid, w, WSwin
FROM teams
WHERE WSwin = 'Y' AND (yearid BETWEEN '1970' AND '1980' OR yearid BETWEEN '1982' AND '2016') AND w = (SELECT MIN(w)
		  FROM teams
		  WHERE WSwin = 'Y' AND (yearid BETWEEN '1970' AND '1980' OR yearid BETWEEN '1982' AND '2016'))

		  
-- St. Louis Cardinals in 2006 with 83 wins.

WITH cte as (SELECT name, yearid, w, WSwin
				FROM teams
				WHERE w IN (SELECT MAX(w) OVER (PARTITION BY yearid) as w
							FROM teams as sub
							WHERE (yearid BETWEEN '1970' AND '1980' OR yearid BETWEEN '1982' AND '2016') 
							AND teams.yearid = sub.yearid))
			 
SELECT 
	COUNT(*) as best_team_ws, 
	CONCAT(ROUND((100 * COUNT(*)::float / (SELECT COUNT( DISTINCT yearid)
											FROM teams
											WHERE (yearid BETWEEN '1970' AND '1980' 
												   OR yearid BETWEEN '1982' AND '2016'))::float)::numeric, 1),'%') 
											as pct_ws_highest_w
FROM cte
WHERE wswin = 'Y'

-- Team with most wins has won the WS 12 times over this range, or 26.1% of the time


-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

SELECT teams.park, name, homegames.attendance/homegames.games as avg_attd
FROM homegames
JOIN teams
ON homegames.team = teams.teamid AND homegames.year = teams.yearid
WHERE year = '2016' AND games >= 10
ORDER BY avg_attd DESC 
LIMIT 5; -- Top 5


SELECT teams.park, name, homegames.attendance/homegames.games as avg_attd
FROM homegames
JOIN teams
ON homegames.team = teams.teamid AND homegames.year = teams.yearid
WHERE year = '2016' AND games >= 10
ORDER BY avg_attd  
LIMIT 5; -- Bottom 5


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

SELECT playerid, count(distinct lgid)
FROM awardsmanagers
WHERE awardid LIKE 'TSN%' 
GROUP BY playerid
HAVING count(distinct lgid) > 1
ORDER BY count(distinct lgid) DESC -- this doesn't work bc TSN doesn't distinguish league before 1985

SELECT a.yearid, CONCAT(p.namefirst, ' ', p.namelast), t.name, m.lgid
FROM (SELECT playerid, yearid
	  FROM awardsmanagers
	  WHERE awardid LIKE 'TSN%') as a
INNER JOIN managers as m
ON a.playerid = m.playerid AND a.yearid = m.yearid
INNER JOIN people as p
ON p.playerid = a.playerid
INNER JOIN teams as t
ON m.teamid = t.teamid AND t.yearid=a.yearid
WHERE a.playerid IN (SELECT playerid
				  FROM awardsmanagers
					 WHERE awardid LIKE 'TSN%'
				  GROUP BY playerid
				  HAVING COUNT(playerid)> 1)
GROUP BY a.yearid, CONCAT(p.namefirst, ' ', p.namelast), t.name, m.lgid
ORDER BY CONCAT(p.namefirst, ' ', p.namelast), yearid -- this gives all repeats for TSN winning managers. 54 rows

SELECT CONCAT(p.namefirst, ' ', p.namelast), COUNT (distinct m.lgid)
FROM (SELECT playerid, yearid
	  FROM awardsmanagers
	  WHERE awardid LIKE 'TSN%') as a
INNER JOIN managers as m
ON a.playerid = m.playerid AND a.yearid = m.yearid
INNER JOIN people as p
ON p.playerid = a.playerid
INNER JOIN teams as t
ON m.teamid = t.teamid AND t.yearid=a.yearid
WHERE a.playerid IN (SELECT playerid
				  FROM awardsmanagers
					 WHERE awardid LIKE 'TSN%'
				  GROUP BY playerid
				  HAVING COUNT(playerid)> 1)
GROUP BY CONCAT(p.namefirst, ' ', p.namelast)
HAVING COUNT(distinct m.lgid) >1
ORDER BY CONCAT(p.namefirst, ' ', p.namelast) -- This give all TSN winning managers from 2 leagues. Now how do I combine? 

SELECT * 
FROM people
WHERE namelast = 'Cox'

SELECT *
FROM awardsmanagers
WHERE awardid LIKE 'TSN%' -- so in 1986 TSN switched to awarding for each league 


SELECT sub.name, year, team_name, sub.playerid, league
FROM (SELECT playerid, yearid as year, CONCAT(p.namefirst, ' ', p.namelast) as name, awardid, COUNT(playerid) OVER (PARTITION BY playerid) as tsn_count
		FROM awardsmanagers as a
	  	LEFT JOIN people as p
	  	USING (playerid)
	  WHERE awardid LIKE 'TSN%') as sub
LEFT JOIN (SELECT playerid, t.teamid, m.yearid, t.name as team_name, m.lgid as league
		  FROM managers as m
		  INNER JOIN teams as t
		  ON m.teamid = t.teamid AND m.yearid = t.yearid) as tsub
	ON sub.playerid = tsub.playerid AND sub.year = tsub.yearid
WHERE tsn_count > 1
ORDER BY sub.name, year


WITH cte as(
			SELECT sub.name as name, year, team_name, league
		FROM (SELECT playerid, yearid as year, CONCAT(p.namefirst, ' ', p.namelast) as name, awardid, COUNT(playerid) OVER (PARTITION BY 			playerid) as tsn_count
				FROM awardsmanagers as a
				LEFT JOIN people as p
				USING (playerid)
			  WHERE awardid LIKE 'TSN%') as sub
		LEFT JOIN (SELECT playerid, t.teamid, m.yearid, t.name as team_name, m.lgid as league
				  FROM managers as m
				  INNER JOIN teams as t
				  ON m.teamid = t.teamid AND m.yearid = t.yearid
				  GROUP BY playerid, m.yearid, t.teamid, t.name, m.lgid) as tsub
			ON sub.playerid = tsub.playerid AND sub.year = tsub.yearid
		WHERE tsn_count > 1) 
		
SELECT name, year, team_name, league
FROM CTE					
WHERE (SELECT COUNT(distinct league)
		FROM cte as sub
		WHERE cte.name = sub.name) > 1
ORDER BY name, year -- this one works

--consider playing around with ROLLUP here

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

  

