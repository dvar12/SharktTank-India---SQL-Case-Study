truncate sharktank;

select * from sharktank;

-- loading the dataset --
load data infile 'C:\\sharktank.csv'
into table sharktank
fields terminated by ','
optionally enclosed by  '"'
lines terminated by '\r\n'
ignore 1 rows;

select * from sharktank;
-- 1.You Team must promote shark Tank India season 4, The senior come up with the idea to show highest funding domain wise 
-- so that new startups can be attracted, and you were assigned the task to show the same.
select 
	Industry, MAX(Total_Deal_Amount_in_lakhs) as "max_funding"
from sharktank
group by Industry;

-- 2. You have been assigned the role of finding the domain where female as pitchers have female to male pitcher ratio >70%
select 
	Industry, (females/males)*100 as "ratio" 
    from 
(select 
	Industry, sum(Male_Presenters) as "males", sum(Female_Presenters) as "females"
from sharktank
group by Industry
having sum(Male_Presenters)>0 and sum(Female_Presenters)>0)  t
where (females/males)*100 >70;


-- 3.You are working at marketing firm of Shark Tank India, you have got the task to determine volume of per season sale pitch made, 
-- pitches who received offer and pitches that were converted. 
-- Also show the percentage of pitches converted and percentage of pitches entertained.
select a.Season_Number, a.total, b.received, c.accepted ,(b.received/a.total)*100 as "entertained_%", 
(c.accepted/a.total)*100 as "converted_%" from 
(select Season_Number,count(Pitch_Number) as "total" from sharktank
group by Season_Number) a
join
(select Season_Number,count(Pitch_Number) as "received" from sharktank
where Received_Offer="Yes"
group by Season_Number) b
on a.Season_Number=b.Season_Number
join
(select Season_Number,count(Pitch_Number) as "accepted" from sharktank
where Accepted_Offer="Yes"
group by Season_Number) c
on b.season_number=c.season_number;

-- 4.As a venture capital firm specializing in investing in startups featured on a renowned entrepreneurship TV show, 
-- you are determining the season with the highest average monthly sales and identify the top 5 industries 
-- with the highest average monthly sales during that season to optimize investment decisions?


set @season =(select Season_Number
from sharktank
group by 1
order by round(avg(Monthly_Sales_in_lakhs),2) desc
limit 1);
select Industry, round(avg(Monthly_Sales_in_lakhs),2) as "avg_monthly" from sharktank
where Season_Number=@season
group by Industry
order by round(avg(Monthly_Sales_in_lakhs),2) desc
limit 5;

-- 5.As a data scientist at our firm, your role involves solving real-world challenges like identifying industries 
-- with consistent increases in funds raised over multiple seasons. This requires focusing on industries where data is available across all three seasons. 
-- Once these industries are pinpointed, your task is to delve into the specifics, analyzing the number of pitches made, 
-- offers received, and offers converted per season within each industry.


with cte as (select Industry,
max(case when Season_Number=1 then Total_Deal_Amount_in_lakhs else null end) as "Season_1",
max(case when Season_Number=2 then Total_Deal_Amount_in_lakhs else null end) as "Season_2",
max(case when Season_Number=3 then Total_Deal_Amount_in_lakhs else null end) as "Season_3"
from sharktank
group by Industry
having Season_2>Season_1 and Season_3>Season_2 and Season_1!=0)


select  Industry,season_number ,count(Pitch_Number) as "pitches_made" ,
sum(case when Received_Offer="Yes" then 1 else 0 end) as "offer_received",
sum(case when Accepted_Offer="Yes" then 1 else 0 end) as "offer_accepted" from sharktank
where Industry in (select Industry from cte)
group by 1,2
order by 1,2;

-- 6. Every shark wants to know in how much year their investment will be returned, so you must create a system for them, 
-- where shark will enter the name of the startup’s and the based on the total deal and equity given in how many years their 
-- principal amount will be returned and make their investment decisions.
select * from sharktank;

-- creating the stored procedure --
CREATE DEFINER=`root`@`localhost` PROCEDURE `TOT`(IN startup VARCHAR(255))
BEGIN
	DELIMITER //
    CASE
        WHEN (SELECT Accepted_offer = 'Not Received' FROM sharktank WHERE Startup_Name = startup) THEN
            SELECT 'Unable to fetch TOT. Offer not accepted.';
        WHEN (SELECT Accepted_offer = 'Yes' AND Yearly_Revenue_in_lakhs = 'Not Mentioned' 
        FROM sharktank WHERE Startup_Name = startup) THEN
            SELECT 'Unable to fetch TOT. Yearly_Revenue not mentioned.';
        ELSE
            SELECT `Startup_Name`, 
                   `Yearly_Revenue_in_lakhs`, 
                   `Total_Deal_Amount_in_lakhs`, 
                   `Total_Deal_Equity_in_%`, 
                   `Total_Deal_Amount_in_lakhs` / (`Total_Deal_Equity_in_%` * `Yearly_Revenue_in_lakhs`) AS 'TOT'
                   FROM sharktank
            WHERE Startup_Name = startup;

    END CASE;
    DELIMITER //
    

CALL TOT('BluePineFoods');

-- 7.In the world of startup investing, we're curious to know which big-name investor, 
-- often referred to as "sharks," tends to put the most money into each deal on average. 
-- This comparison helps us see who's the most generous with their investments and how they measure up against their fellow investors.
select 
	avg(case when Namita_Investment_Amount_in_lakhs>0 then Namita_Investment_Amount_in_lakhs else null end ) as "Avg_Namita",
    avg(case when Vineeta_Investment_Amount_in_lakhs>0 then Vineeta_Investment_Amount_in_lakhs else null end ) as "Avg_Vineeta",
    avg(case when Aman_Investment_Amount_in_lakhs>0 then Aman_Investment_Amount_in_lakhs else null end ) as "Avg_Aman" ,
    avg(case when Anupam_Investment_Amount_in_lakhs>0 then Anupam_Investment_Amount_in_lakhs else null end ) as "Avg_Anupam", 
    avg(case when Peyush_Investment_Amount_in_lakhs>0 then Peyush_Investment_Amount_in_lakhs else null end ) as "Avg_Peyush",
    avg(case when Ashneer_Investment_Amount_in_lakhs>0 then Ashneer_Investment_Amount_in_lakhs else null end ) as "Avg_Ashneer",
    avg(case when Amit_Investment_Amount_in_lakhs>0 then Amit_Investment_Amount_in_lakhs else null end ) as "Avg_Amit"from sharktank
where Received_Offer="Yes" ;

-- 8.Develop a stored procedure that accepts inputs for the season number and the name of a shark. 
-- The procedure will then provide detailed insights into the total investment made by that specific shark across different industries during the specified season. 
-- Additionally, it will calculate the percentage of their investment in each sector relative to the total investment in that year, 
-- giving a comprehensive understanding of the shark's investment distribution and impact.

select * from sharktank;

-- creating a stored procedure --

CREATE DEFINER=`root`@`localhost` PROCEDURE `shark_season_report`(in season INT, in name VARCHAR(50))
BEGIN
	
	CASE 
		WHEN name="Namita" THEN 
        set @total_namita=(SELECT SUM(Namita_Investment_Amount_in_lakhs) FROM sharktank WHERE Season_Number=season);
        (SELECT Industry, SUM(Namita_Investment_Amount_in_lakhs) AS "Namita's_investment_in_lakhs",
        SUM(Namita_Investment_Amount_in_lakhs)*100/@total_namita AS "%_investment_share"
        FROM sharktank 
        WHERE Namita_Investment_Amount_in_lakhs>0 AND Season_Number=season
        GROUP BY 1);
        
        WHEN name="Vineeta" THEN 
        set @total_vineeta=(SELECT SUM(Vineeta_Investment_Amount_in_lakhs) FROM sharktank WHERE Season_Number=season);
        (SELECT Industry, SUM(Vineeta_Investment_Amount_in_lakhs) AS "Vineeta's_investment_in_lakhs",
        SUM(Vineeta_Investment_Amount_in_lakhs)*100/ @total_vineeta AS "%_investment_share"
        FROM sharktank 
        WHERE Vineeta_Investment_Amount_in_lakhs>0 AND Season_Number=season
        GROUP BY 1);
        
        WHEN name="Aman" THEN 
        set @total_aman=(SELECT SUM(Aman_Investment_Amount_in_lakhs) FROM sharktank WHERE Season_Number=season);
        (SELECT Industry, SUM(Aman_Investment_Amount_in_lakhs) AS "Aman's_investment_in_lakhs" ,
        SUM(Aman_Investment_Amount_in_lakhs)*100/@total_aman AS "%_investment_share"
        FROM sharktank 
        WHERE Aman_Investment_Amount_in_lakhs>0 AND Season_Number=season
        GROUP BY 1);
        
        WHEN name="Anupam" THEN 
        set @total_anupam= (SELECT SUM(Anupam_Investment_Amount_in_lakhs) FROM sharktank WHERE Season_Number=season);
        (SELECT Industry, SUM(Anupam_Investment_Amount_in_lakhs) AS "Anupam's_investment_in_lakhs" ,
        SUM(Anupam_Investment_Amount_in_lakhs)*100/@total_peyush AS "%_investment_share"
        FROM sharktank 
        WHERE Anupam_Investment_Amount_in_lakhs>0 AND Season_Number=season
        GROUP BY 1);
        
        WHEN name="Ashneer" THEN 
        set @total_ashneer=(SELECT SUM(Ashneer_Investment_Amount_in_lakhs) FROM sharktank WHERE Season_Number=season);
        (SELECT Industry, SUM(Ashneer_Investment_Amount_in_lakhs) AS "Ashneer's_investment_in_lakhs" ,
        SUM(Ashneer_Investment_Amount_in_lakhs)*100/@total_ashneer AS "%_investment_share"
        FROM sharktank 
        WHERE Ashneer_Investment_Amount_in_lakhs>0 AND Season_Number=season
        GROUP BY 1);
        
        WHEN name="Amit" THEN 
        set @total_amit=(SELECT SUM(Amit_Investment_Amount_in_lakhs) FROM sharktank WHERE Season_Number=season);
        (SELECT Industry, SUM(Amit_Investment_Amount_in_lakhs) AS "Amit's_investment_in_lakhs" ,
        SUM(Amit_Investment_Amount_in_lakhs)*100/@total_ashneer AS "%_investment_share"
        FROM sharktank 
        WHERE Amit_Investment_Amount_in_lakhs>0 AND Season_Number=season
        GROUP BY 1);
        
        WHEN name="Peyush" THEN 
        set @total_peyush=(SELECT SUM(Peyush_Investment_Amount_in_lakhs) FROM sharktank WHERE Season_Number=season);
        (SELECT Industry, SUM(Peyush_Investment_Amount_in_lakhs) AS "Peyush's_investment_in_lakhs" ,
        SUM(Peyush_Investment_Amount_in_lakhs)*100/@total_peyush AS "%_investment_share"
        FROM sharktank 
        WHERE Peyush_Investment_Amount_in_lakhs>0 AND Season_Number=season
        GROUP BY 1);
      ELSE
        (SELECT "Not a shark");
     END CASE;   

END

call shark_season_report(2,"Namita");

-- 9.In the realm of venture capital, we're exploring which shark possesses the most diversified investment portfolio across various industries. 
-- By examining their investment patterns and preferences, 
-- we aim to uncover any discernible trends or strategies that may shed light on their decision-making processes and investment philosophies.

with cte AS (SELECT
            'Namita' AS sharkname, Industry
        FROM
            sharktank
        WHERE
            Namita_Investment_Amount_in_lakhs > 0

        UNION ALL

        SELECT
            'Vineeta' AS sharkname, Industry
        FROM
            sharktank
        WHERE
            Vineeta_Investment_Amount_in_lakhs > 0

        UNION ALL

        SELECT
            'Anupam' AS sharkname, Industry
        FROM
            sharktank
        WHERE
            Anupam_Investment_Amount_in_lakhs > 0

        UNION ALL

        SELECT
            'Aman' AS sharkname, Industry
        FROM
            sharktank
        WHERE
            Aman_Investment_Amount_in_lakhs > 0

        UNION ALL

        SELECT
            'Peyush' AS sharkname, Industry
        FROM
            sharktank
        WHERE
            Peyush_Investment_Amount_in_lakhs > 0

        UNION ALL

        SELECT
            'Amit' AS sharkname, Industry
        FROM
            sharktank
        WHERE
            Amit_Investment_Amount_in_lakhs > 0

        UNION ALL

        SELECT
            'Ashneer' AS sharkname, Industry
        FROM
            sharktank
        WHERE
            Ashneer_Investment_Amount_in_lakhs > 0)
select *, dense_rank() over(order by num_unique_industries desc) as "diversification_rank" from 
(select sharkname,count(distinct Industry) as "num_Unique_industries"
 from cte
group by sharkname) t;

select * from sharktank
limit 1

    
