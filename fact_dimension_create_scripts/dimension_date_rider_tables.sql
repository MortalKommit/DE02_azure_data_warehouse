-- Creates a dateDimension Table dimDate. 
-- Modified Code from https://gist.github.com/mlongoria/5a4f58b148d75f5a440a6c0961b0b792
-- StartDate and EndDate values are pre-computed below to save effort. CutOffDate Has been increased by
-- 1 day to save time


-- DECLARE @StartDate datetime = (SELECT TOP 1 MIN(MinDate) FROM (
-- 						SELECT MIN([date]) as MinDate FROM [dbo].[staging_payment]
-- 						UNION SELECT MIN(account_start_date) as MinDate FROM [dbo].[staging_rider] 
-- 						UNION SELECT MIN(account_end_date) as MinDate FROM [dbo].[staging_rider]
-- 						UNION SELECT MIN(start_at) as MinDate FROM [dbo].[staging_trip]
-- 						UNION SELECT MIN(ended_at)  as MinDate FROM [dbo].[staging_trip]) As minDatesAll);

-- DECLARE @CutOffDate datetime = (SELECT TOP 1 MAX(MinDate) FROM (
-- 						SELECT MAX([date]) as MinDate FROM [dbo].[staging_payment]
-- 						UNION SELECT MAX(account_start_date) as MinDate FROM [dbo].[staging_rider] 
-- 						UNION SELECT MAX(account_end_date) as MinDate FROM [dbo].[staging_rider]
-- 						UNION SELECT MAX(start_at) as MinDate FROM [dbo].[staging_trip]
-- 						UNION SELECT MAX(ended_at)  as MinDate FROM [dbo].[staging_trip]) As minDatesAll);

-- Add 1 day to account for the full day (00:00 to 23:00) of the last timestamp
-- SET @CutOffDate = DATEADD(DAY, 1, @CutOffDate);

DECLARE @StartDate datetime = '2013-01-31';
DECLARE @CutOffDate datetime = '2022-02-13';

CREATE TABLE #dimdate
(
  [datetime]   datetime,
  [date]       date, 
  [day]        tinyint,
  [month]      tinyint,
  FirstOfMonth date,
  [MonthName]  varchar(12),
  [week]       tinyint,
  [ISOweek]    tinyint,
  [DayOfWeek]  tinyint,
  [quarter]    tinyint,
  [year]       smallint,
  Style112     char(8)
);


--prevent set or regional settings from interfering with 
-- interpretation of dates / literals
-- Month starts on Monday
SET DATEFIRST 1;

-- this is just a holding table for intermediate calculations:

-- use the catalog views to generate as many rows as we need

INSERT #dimdate([datetime]) 
SELECT d
FROM
(
  SELECT d = DATEADD(HOUR, rn - 1, @StartDate)
  FROM 
  (
    SELECT TOP (DATEDIFF(HOUR, @StartDate, @CutoffDate)) 
      rn = ROW_NUMBER() OVER (ORDER BY s1.[object_id])
    FROM sys.all_objects AS s1
    CROSS JOIN sys.all_objects AS s2
    -- on my system this would support > 5 million days
    ORDER BY s1.[object_id]
  ) AS x
) AS y;


UPDATE #dimdate 
set 
  [date]      =  CAST([datetime] AS date),
  [day]        = DATEPART(DAY,      [datetime]),
  [month]      = DATEPART(MONTH,    [datetime]),
  FirstOfMonth = CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, [date]), 0)),
  [MonthName]  = DATENAME(MONTH,    [datetime]),
  [week]       = DATEPART(WEEK,     [datetime]),
  [ISOweek]    = DATEPART(ISO_WEEK, [datetime]),
  [DayOfWeek]  = DATEPART(WEEKDAY,  [datetime]),
  [quarter]    = DATEPART(QUARTER,  [datetime]),
  [year]       = DATEPART(YEAR,     [datetime]),
  Style112     = CONVERT(CHAR(8),   [datetime], 112)
;


CREATE TABLE [dbo].[dimDate]
WITH
(
    DISTRIBUTION = ROUND_ROBIN
) AS
SELECT
  [DatetimeKey]     = CAST(FORMAT([datetime], 'yyyyMMddHH') AS BIGINT),
  [DatetimeActual]  = [datetime],
  [DateKey]         = CAST(FORMAT([datetime], 'yyyyMMdd') AS int),
  [DateActual]      = [date],
  [Day]             = CONVERT(TINYINT, [day]),
  [DayName]         = CONVERT(VARCHAR(10), DATENAME(WEEKDAY, [date])),
  [DaySuffix]       =  CONVERT(CHAR(2), CASE WHEN [day] / 10 = 1 THEN 'th' ELSE 
                       CASE RIGHT([day], 1) WHEN '1' THEN 'st' WHEN '2' THEN 'nd' 
  	                   WHEN '3' THEN 'rd' ELSE 'th' END END),
  [Hour]            = CONVERT(TINYINT, DATEPART(hour, [datetime])),
  [TimeOfDay]       =  CONVERT(VARCHAR(15), CASE WHEN FORMAT([datetime], 'HH:mm') BETWEEN '06:00' and '08:29'
                             THEN 'Early Morning'
  	                        WHEN FORMAT([datetime], 'HH:mm') BETWEEN '08:30' and '11:59'
  		                      THEN 'Late Morning'
  	                        WHEN FORMAT([datetime], 'HH:mm') BETWEEN '12:00' and '17:59'
  		                      THEN 'Noon'
  	                        WHEN FORMAT([datetime], 'HH:mm') BETWEEN '18:00' and '22:29'
  		                      THEN 'Evening'
  	                        ELSE 'Night' END),
  [DayOfWeek]       = CONVERT(TINYINT, [DayOfWeek]),
  [DayOfYear]       = CONVERT(SMALLINT, DATEPART(DAYOFYEAR, [date])),
  [WeekOfMonth]     = CONVERT(SMALLINT, (DATEPART(day, [date]) - 1) / 7 + 1),
  [WeekOfYear]      = CONVERT(TINYINT, [week]),
  [ISOWeekOfYear]   = CONVERT(TINYINT, ISOWeek),
  [MonthName]       = CONVERT(VARCHAR(10), [MonthName]),
  [Month]           = CONVERT(TINYINT, [month]),
  [QuarterName]     = CONVERT(VARCHAR(6), CASE [quarter] WHEN 1 THEN 'First' 
                      WHEN 2 THEN 'Second' WHEN 3 THEN 'Third' WHEN 4 THEN 'Fourth' END), 
  [Quarter]         = CONVERT(TINYINT, [quarter]),
  [Year]            = [year]
FROM #dimdate;

ALTER TABLE dimDate ALTER COLUMN DatetimeKey BIGINT NOT NULL;
ALTER TABLE dimDate add CONSTRAINT dim_date_key PRIMARY KEY NONCLUSTERED (DatetimeKey) NOT ENFORCED;

CREATE INDEX dim_date_date_actual_idx ON dimDate ([DateActual]);
CREATE INDEX dim_date_quarter_idx ON dimDate ([Quarter]);
CREATE INDEX dim_date_month_idx ON dimDate ([Month]); 
CREATE INDEX dim_date_day_of_week_idx ON dimDate ([DayOfWeek]);
CREATE INDEX dim_date_time_of_day_idx ON dimDate ([TimeOfDay]);


DROP Table #dimdate;


CREATE TABLE dimRider 
WITH
(
    DISTRIBUTION = ROUND_ROBIN
) AS    
SELECT [RiderId] = [rider_id],
	   [Address] = [address],
	   [FirstName] = [first],
	   [LastName] = [last],
	   [Birthday] = [birthday],
	   [AccountStartDate] = TRY_CONVERT(DATE, [account_start_date]),
	   [AccountEndDate] = TRY_CONVERT(DATE, [account_end_date]),
	   [MemberStatus] = CONVERT(VARCHAR(15), CASE [is_member] WHEN 'True' THEN 'Member'
	   		    ELSE 'Casual Rider'
	          END)
	   FROM [dbo].[staging_rider];

ALTER TABLE dimRider ALTER COLUMN [RiderId] BIGINT NOT NULL;
ALTER TABLE dimRider add CONSTRAINT dim_rider_key PRIMARY KEY NONCLUSTERED ([RiderId]) NOT ENFORCED;

CREATE INDEX dim_rider_member_idx ON dimRider ([MemberStatus]);

