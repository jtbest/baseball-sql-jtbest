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
	CASE WHEN pos IN ('LF','RF','CF','OF') THEN 'Outfield'
		WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
		WHEN pos IN ('P','C') THEN 'Battery'
		ELSE 'Not listed' END AS position_group, 
	SUM(po) as total_putouts
FROM fielding
WHERE yearid = '2016'
GROUP BY position_group
ORDER BY total_putouts DESC;

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

-- I keep screwing up how I'm counting games. Not sure why my older approach wasn't working. This isn't a perfect count of games played, but good enough for now. Consider revisiting. can also link to teams table to get an actual count of the games played per season by team. sum of games from teams table

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

(SELECT teams.park, name, homegames.attendance/homegames.games as avg_attd, 'high' as class
FROM homegames
JOIN teams
ON homegames.team = teams.teamid AND homegames.year = teams.yearid
WHERE year = '2016' AND games >= 10
ORDER BY avg_attd DESC 
LIMIT 5)

UNION

(SELECT teams.park, name, homegames.attendance/homegames.games as avg_attd, 'low' as class
FROM homegames
JOIN teams
ON homegames.team = teams.teamid AND homegames.year = teams.yearid
WHERE year = '2016' AND games >= 10
ORDER BY avg_attd  
LIMIT 5) -- Bottom 5
ORDER BY class

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
		FROM (SELECT playerid, yearid as year, CONCAT(p.namefirst, ' ', p.namelast) as name, awardid, COUNT(playerid) OVER (PARTITION BY playerid) as tsn_count
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

SELECT *
FROM batting
WHERE yearid = '2016' AND hr > 0


SELECT playerid, max_hr, yearid
FROM (SELECT distinct playerid, MAX(hr) OVER (PARTITION BY playerid) as max_hr, yearid
		FROM batting as sub
	  Where playerid = 'abreujo02'
		GROUP by playerid, yearid, hr
		HAVING MAX(hr) = SELECT( MAX(hr) OVER (PARTITION BY playerid)
	 FROM BATTING)) as hrs
ORDER BY playerid


SELECT playerid, yearid, MAX(hr)
FROM batting
Where playerid LIKE 'cano%'
GROUP BY playerid, yearid

-- Find what year was each player's max hr output
SELECT playerid, yearid, hr
FROM batting as b
WHERE hr in (SELECT MAX(hr) OVER (PARTITION BY playerid)
			FROM batting as sub
			WHERE b.playerid = sub.playerid ) AND hr > 1
			
-- Use this as a cte to give all players with their max hr in 2016

WITH cte as (SELECT playerid, yearid, hr
FROM batting as b
WHERE hr in (SELECT MAX(hr) OVER (PARTITION BY playerid)
			FROM batting as sub
			WHERE b.playerid = sub.playerid ) 
	AND hr >= 1
	AND playerid IN (SELECT playerid
					FROM batting
					GROUP BY playerid
					HAVING COUNT( DISTINCT yearid) >= 10))
			
SELECT CONCAT(p.namefirst, ' ', p.namelast), hr
FROM cte
INNER JOIN people as p
USING (playerid)
WHERE yearid = '2016'
ORDER BY hr DESC -- this doesn't accunt for mid-season trades

SELECT *
FROM batting
WHERE playerid = 'colonba01'
-- Find how many seasons each player has played. added above in cte
SELECT playerid, COUNT(yearid)
FROM batting
GROUP BY playerid
HAVING COUNT(yearid) >= 10
--
WITH cte as (SELECT playerid, yearid, hrs
			FROM (SELECT playerid, yearid, SUM(hr) as hrs
						FROM batting
						GROUP BY playerid, yearid) as sub
			WHERE hrs in (SELECT MAX(hrs) OVER (PARTITION BY playerid)
								FROM (SELECT playerid, yearid, 
									  SUM(hr) as hrs
										FROM batting as bb
										GROUP BY playerid, yearid) as bsub
								WHERE bsub.playerid = sub.playerid ) 
				AND hrs >= 1
				AND playerid IN (SELECT playerid
									FROM batting
									GROUP BY playerid
									HAVING COUNT( DISTINCT yearid) >= 10))
			
SELECT CONCAT(p.namefirst, ' ', p.namelast), hrs
FROM cte
INNER JOIN people as p
USING (playerid)
WHERE yearid = '2016'
ORDER BY hrs DESC -- this one
--
SELECT playerid, yearid, SUM(hr) as hrs
FROM batting
GROUP BY playerid, yearid
--


-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.


WITH s as (SELECT s.yearid, s.teamid, SUM(s.salary) as total_sal
				FROM salaries as s
		  		GROUP BY s.teamid,s.yearid)

SELECT s.yearid, s.teamid, total_sal,
	ROUND(((total_sal-AVG(total_sal) OVER (Partition by s.yearid)::numeric)/AVG(total_sal) OVER (Partition by s.yearid))::numeric,2) as salary_pct_diff,
	t.w as wins, 
	RANK() OVER (PARTITION BY s.yearid order by total_sal DESC ) as sal_rank, 
	RANK() OVER (PARTITION BY t.yearid ORDER BY t.w DESC) as win_rank
FROM s
LEFT JOIN teams as t
	ON t.teamid=s.teamid AND s.yearid=t.yearid
WHERE s.yearid >= '2000'
ORDER BY yearid DESC, win_rank

-- consider finding the avg or median sal_ranking for top 10 teams 

WITH ranks as (
				SELECT s.yearid, s.teamid, total_sal,
			ROUND(((total_sal-AVG(total_sal) OVER (Partition by s.yearid)::numeric)/AVG(total_sal) OVER (Partition by s.yearid))::numeric,2) as salary_pct_diff,
			t.w as wins, 
			RANK() OVER (PARTITION BY s.yearid order by total_sal DESC ) as sal_rank, 
			RANK() OVER (PARTITION BY t.yearid ORDER BY t.w DESC) as win_rank
		FROM (SELECT s.yearid, s.teamid, SUM(s.salary) as total_sal
						FROM salaries as s
						GROUP BY s.teamid,s.yearid) as s
		LEFT JOIN teams as t
			ON t.teamid=s.teamid AND s.yearid=t.yearid
		ORDER BY yearid DESC, win_rank)

SELECT win_rank, ROUND(AVG(sal_rank),2) as avg_sal_rank
FROM ranks
WHERE ranks.yearid >= '2000'
GROUP BY win_rank
ORDER BY win_rank -- gives avg salary ranking for each win ranking
--

WITH ranks as (
				SELECT s.yearid, s.teamid, total_sal,
			ROUND(((total_sal-AVG(total_sal) OVER (Partition by s.yearid)::numeric)/AVG(total_sal) OVER (Partition by s.yearid))::numeric,2) as salary_pct_diff,
			t.w as wins, 
			RANK() OVER (PARTITION BY s.yearid order by total_sal DESC ) as sal_rank, 
			RANK() OVER (PARTITION BY t.yearid ORDER BY t.w DESC) as win_rank
		FROM (SELECT s.yearid, s.teamid, SUM(s.salary) as total_sal
						FROM salaries as s
						GROUP BY s.teamid,s.yearid) as s
		LEFT JOIN teams as t
			ON t.teamid=s.teamid AND s.yearid=t.yearid
		ORDER BY yearid DESC, win_rank)

SELECT sal_rank, ROUND(AVG(win_rank),2) as avg_win_rank
FROM ranks
WHERE ranks.yearid >= '2000'
GROUP BY sal_rank
ORDER BY sal_rank -- gives avg win ranking each salary ranking

--

WITH ranks as (
				SELECT s.yearid, s.teamid, total_sal,
			ROUND(((total_sal-AVG(total_sal) OVER (Partition by s.yearid)::numeric)/AVG(total_sal) OVER (Partition by s.yearid))::numeric,2) as salary_pct_diff,
			t.w as wins, 
			RANK() OVER (PARTITION BY s.yearid order by total_sal DESC ) as sal_rank, 
			RANK() OVER (PARTITION BY t.yearid ORDER BY t.w DESC) as win_rank
		FROM (SELECT s.yearid, s.teamid, SUM(s.salary) as total_sal
						FROM salaries as s
						GROUP BY s.teamid,s.yearid) as s
		LEFT JOIN teams as t
			ON t.teamid=s.teamid AND s.yearid=t.yearid
		ORDER BY yearid DESC, win_rank
										)

SELECT ROUND(CORR(sal_rank,win_rank)::numeric,2) as correlation
FROM ranks
WHERE ranks.yearid >= '2000' -- 0.39 correlation between salary rank and win rank. moderate positive correlation

--

WITH ranks as (
				SELECT s.yearid, s.teamid, total_sal,
			ROUND(((total_sal-AVG(total_sal) OVER (Partition by s.yearid)::numeric)/AVG(total_sal) OVER (Partition by s.yearid))::numeric,2) as salary_pct_diff,
			t.w as wins, 
			RANK() OVER (PARTITION BY s.yearid order by total_sal DESC ) as sal_rank, 
			RANK() OVER (PARTITION BY t.yearid ORDER BY t.w DESC) as win_rank
		FROM (SELECT s.yearid, s.teamid, SUM(s.salary) as total_sal
						FROM salaries as s
						GROUP BY s.teamid,s.yearid) as s
		LEFT JOIN teams as t
			ON t.teamid=s.teamid AND s.yearid=t.yearid
		ORDER BY yearid DESC, win_rank
										)
										
SELECT ROUND(CORR(salary_pct_diff, wins)::numeric,2) as correlation
FROM ranks
WHERE ranks.yearid >= '2000' -- 0.40 correlation with % above avg salary and wins. may be a better model

-- 12. In this question, you will explore the connection between number of wins and attendance.
--   
--      Does there appear to be any correlation between attendance at home games and number of wins? 
--     Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>

SELECT CORR(w, attendance)
FROM (SELECT yearid, teamid, w, attendance, (100*attendance - Lag(attendance) OVER (PARTITION BY teamid ORDER BY yearid))::float/Lag(attendance) OVER (PARTITION BY teamid ORDER BY 		yearid)::float as change_attn
		FROM teams
	  WHERE attendance IS NOT NULL) as sub -- correlation of 0.4

	  
SELECT CORR(w, change_attn)
FROM (SELECT yearid, teamid, w, attendance, (100*attendance - Lag(attendance) OVER (PARTITION BY teamid ORDER BY yearid))::float/Lag(attendance) OVER (PARTITION BY teamid ORDER BY 		yearid)::float as change_attn
		FROM teams
	  WHERE attendance IS NOT NULL) as sub -- correlation of 0.11 with change in attendance
--

SELECT yearid, 
	teamid,
	wswin='Y' as ws_win,
	divwin='Y' OR wcwin = 'Y' as playoffs,
	LAG(w) OVER (Partition by teamid ORDER BY yearid) as last_year_w, attendance, 
	CONCAT((ROUND(((100*attendance - Lag(attendance) OVER (PARTITION BY teamid ORDER BY yearid))::float/Lag(attendance) OVER (PARTITION BY teamid ORDER BY yearid)::float)::numeric, 
	1))::varchar, '%') as change_attn
FROM teams
WHERE attendance IS NOT NULL
Order by teamid, yearid
--

With attd as (
			SELECT yearid, 
			teamid,
			wswin='Y' as ws_win,
			divwin='Y' OR wcwin = 'Y' as playoffs,
			LAG(w) OVER (Partition by teamid ORDER BY yearid) as last_year_w, attendance, 
			(attendance - Lag(attendance) OVER (PARTITION BY teamid ORDER BY yearid))::float/
						   Lag(attendance) OVER (PARTITION BY teamid ORDER BY yearid)::float as change_attn
		FROM teams
		WHERE attendance IS NOT NULL
		Order by teamid, yearid
								)
SELECT ws_win, ROUND(100*AVG(change_attn::numeric),1)
FROM attd
WHERE ws_win IS NOT NULL
GROUP BY ws_win -- 14.4% increase after WS win. 7% for all others
--
With attd as (
			SELECT yearid, 
			teamid,
			wswin='Y' as ws_win,
			divwin='Y' OR wcwin = 'Y' as playoffs,
			LAG(w) OVER (Partition by teamid ORDER BY yearid) as last_year_w, attendance, 
			(attendance - Lag(attendance) OVER (PARTITION BY teamid ORDER BY yearid))::float/
						   Lag(attendance) OVER (PARTITION BY teamid ORDER BY yearid)::float as change_attn
		FROM teams
		WHERE attendance IS NOT NULL
		Order by teamid, yearid
								)
SELECT playoffs, ROUND(100*AVG(change_attn::numeric),1)
FROM attd
WHERE playoffs IS NOT NULL
GROUP BY playoffs -- 13.7% bump after making playoffs, 6% if not

-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

With pitchers as (
	SELECT distinct pi.playerid, throws
	FROM pitching as pi
	INNER JOIN people as po
	USING (playerid)
	WHERE throws IS NOT NULL)

SELECT throws, COUNT(*)::float/(SELECT COUNT(*)
				FROM pitchers)::float as throw_pct, COUNT(*)
FROM pitchers
WHERE throws <> 'S'
GROUP BY throws -- 72% R, 28% L. Only 10% of overall pop is L
--

With pitchers as (
	SELECT Distinct pi.playerid, throws, inducted, awardid
	FROM pitching as pi
	INNER JOIN people as po
	USING (playerid)
	LEFT JOIN awardsplayers
	USING(playerid)
	LEFT JOIN halloffame
	USING(playerid)
	WHERE throws IS NOT NULL)

SELECT throws, (SELECT COUNT(*)
			   FROM pitchers as psub
			   WHERE awardid LIKE 'Cy%' AND psub.throws = pitchers.throws ) as cy_count,
		(SELECT COUNT(*)
			   FROM pitchers as psub
			   WHERE awardid LIKE 'Cy%' AND psub.throws = pitchers.throws )::float/(SELECT COUNT(*)
			   FROM pitchers as psub
			   WHERE psub.throws = pitchers.throws )::float as pct_cy, (SELECT COUNT(*)
			   FROM pitchers as psub
			   WHERE awardid LIKE 'Cy%' AND psub.throws = pitchers.throws )::float/(86) as share_of_cy
FROM pitchers
WHERE throws <> 'S'
GROUP BY throws -- 30% of Cy Young winners are L, compared to 28% in MLB and 10% in general pop
--

With pitchers as (
	SELECT Distinct pi.playerid, throws, inducted, awardid
	FROM pitching as pi
	INNER JOIN people as po
	USING (playerid)
	LEFT JOIN awardsplayers
	USING(playerid)
	LEFT JOIN halloffame
	USING(playerid)
	WHERE throws IS NOT NULL)

SELECT throws, (SELECT COUNT(*)
			   FROM pitchers as psub
			   WHERE inducted = 'Y' AND psub.throws = pitchers.throws ) as cy_count,
		(SELECT COUNT(*)
			   FROM pitchers as psub
			   WHERE inducted = 'Y' AND psub.throws = pitchers.throws )::float/(SELECT COUNT(*)
			   FROM pitchers as psub
			   WHERE psub.throws = pitchers.throws )::float as pct_hf,(SELECT COUNT(*)
			   FROM pitchers as psub
			   WHERE inducted = 'Y' AND psub.throws = pitchers.throws )::float/(SELECT COUNT(*)
			   FROM pitchers as psub
			   WHERE inducted = 'Y')as share_of_hf
FROM pitchers
WHERE throws <> 'S'
GROUP BY throws -- figure out why some of my numbers aren't adding up


SELECT  playerid, yearid
FROM awardsplayers
WHErE awardid LIKE 'Cy%'
ORDER BY yearid

SELECT pi.playerid, throws, inducted, awardid
	FROM pitching as pi
	INNER JOIN people as po
	USING (playerid)
	LEFT JOIN awardsplayers
	USING(playerid)
	LEFT JOIN halloffame
	USING(playerid)
	WHERE throws IS NOT NULL AND awardid LIKE 'Cy%'
	
	
-- ## Question 1: Rankings
-- #### Question 1a: Warmup Question
-- Write a query which retrieves each teamid and number of wins (w) for the 2016 season. Apply three window functions to the number of wins (ordered in descending order) - ROW_NUMBER, RANK, AND DENSE_RANK. Compare the output from these three functions. What do you notice?




-- ​
-- #### Question 1b: 
-- Which team has finished in last place in its division (i.e. with the least number of wins) the most number of times? A team's division is indicated by the divid column in the teams table.
-- ​
-- ## Question 2: Cumulative Sums
-- #### Question 2a: 
-- Barry Bonds has the record for the highest career home runs, with 762. Write a query which returns, for each season of Bonds' career the total number of seasons he had played and his total career home runs at the end of that season. (Barry Bonds' playerid is bondsba01.)
-- ​
-- #### Question 2b:
-- How many players at the end of the 2016 season were on pace to beat Barry Bonds' record? For this question, we will consider a player to be on pace to beat Bonds' record if they have more home runs than Barry Bonds had the same number of seasons into his career. 
-- ​
-- #### Question 2c: 
-- Were there any players who 20 years into their career who had hit more home runs at that point into their career than Barry Bonds had hit 20 years into his career? 
-- ​
-- ## Question 3: Anomalous Seasons
-- Find the player who had the most anomalous season in terms of number of home runs hit. To do this, find the player who has the largest gap between the number of home runs hit in a season and the 5-year moving average number of home runs if we consider the 5-year window centered at that year (the window should include that year, the two years prior and the two years after).
-- ​
-- ## Question 4: Players Playing for one Team
-- For this question, we'll just consider players that appear in the batting table.
-- #### Question 4a: 
-- Warmup: How many players played at least 10 years in the league and played for exactly one team? (For this question, exclude any players who played in the 2016 season). Who had the longest career with a single team? (You can probably answer this question without needing to use a window function.)
-- ​
-- #### Question 4b: 
-- Some players start and end their careers with the same team but play for other teams in between. For example, Barry Zito started his career with the Oakland Athletics, moved to the San Francisco Giants for 7 seasons before returning to the Oakland Athletics for his final season. How many players played at least 10 years in the league and start and end their careers with the same team but played for at least one other team during their career? For this question, exclude any players who played in the 2016 season.
-- ​
-- ## Question 5: Streaks
-- #### Question 5a: 
-- How many times did a team win the World Series in consecutive years?
-- ​
-- #### Question 5b: 
-- What is the longest steak of a team winning the World Series? Write a query that produces this result rather than scanning the output of your previous answer.
-- ​
-- #### Question 5c: 
-- A team made the playoffs in a year if either divwin, wcwin, or lgwin will are equal to 'Y'. Which team has the longest streak of making the playoffs? 
-- ​
-- #### Question 5d: 
-- The 1994 season was shortened due to a strike. If we don't count a streak as being broken by this season, does this change your answer for the previous part?
-- ​
-- ## Question 6: Manager Effectiveness
-- Which manager had the most positive effect on a team's winning percentage? To determine this, calculate the average winning percentage in the three years before the manager's first full season and compare it to the average winning percentage for that manager's 2nd through 4th full season. Consider only managers who managed at least 4 full years at the new team and teams that had been in existence for at least 3 years prior to the manager's first full season.
