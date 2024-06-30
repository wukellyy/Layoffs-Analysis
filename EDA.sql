-- Exploratory Data Analysis

SELECT *
FROM layoffs_data_working;

-- Look at the min layoff and max layoff there was in a day
SELECT MIN(Laid_Off_Count), MAX(Laid_Off_Count)
FROM layoffs_data_working;

-- The company that had the most layoff in a single day
SELECT *
FROM layoffs_data_working
WHERE Laid_Off_Count = (SELECT MAX(Laid_Off_Count)
						FROM layoffs_data_working);

-- The total amount of employees laid off for each company
SELECT Company, SUM(Laid_Off_Count)
FROM layoffs_data_working
GROUP BY Company
ORDER BY SUM(Laid_Off_Count) DESC;

-- The total amount of employees laid off for each industry
SELECT Industry, SUM(Laid_Off_Count)
FROM layoffs_data_working
GROUP BY Industry
ORDER BY SUM(Laid_Off_Count) DESC;

-- The total amount of employees laid off for each stage
SELECT Stage, SUM(Laid_Off_Count)
FROM layoffs_data_working
GROUP BY Stage
ORDER BY SUM(Laid_Off_Count) DESC;

-- The total amount of employees laid off for each country
WITH total_country_layoffs AS
(
SELECT 
	Country, 
    SUM(Laid_Off_Count) AS Total_Laid_Off
FROM layoffs_data_working
GROUP BY Country
ORDER BY SUM(Laid_Off_Count) DESC
)

-- Rank these country to most to least layoffs
SELECT
	DENSE_RANK() OVER(ORDER BY Total_Laid_Off DESC) AS Rank_Num,
	Country,
    Total_Laid_Off
FROM total_country_layoffs;
-- The United States had by far the most layoffs over the past four years.
-- Almost eight times more than the country with the second-highest number of layoffs.

-- Let's look at the date range of this dataset
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_data_working;
-- 2020-03-11 to 2024-06-05
-- Seems like the dataset has info from the start of COVID-19 to almost present day

-- Total layoffs for the past 4 years
SELECT
	EXTRACT(YEAR FROM `date`) AS `Year`,
    SUM(Laid_Off_Count)
FROM layoffs_data_working
GROUP BY EXTRACT(YEAR FROM `date`)
ORDER BY 1;

-- Let's look at it in months, as well
SELECT
	SUBSTRING(`date`, 1, 7) AS `Month`,
    SUM(Laid_Off_Count) AS Number_Of_Layoffs
FROM layoffs_data_working
GROUP BY SUBSTRING(`date`, 1, 7)
ORDER BY 1;

-- Top 3 companies that laid off the most people for each year
-- Step 1: Calculate the total amount of layoffs for each company per year
WITH Company_Total_Laid_Off_Year AS
(
SELECT
	EXTRACT(YEAR FROM `date`) AS `Year`,
    Company,
    SUM(Laid_Off_Count) AS Total_Laid_Off
FROM layoffs_data_working
GROUP BY EXTRACT(YEAR FROM `date`), Company
),
-- Step 2: Rank each company based on the total number of layoffs in each year
Layoff_Year_Rank AS
(
SELECT
	DENSE_RANK() OVER(PARTITION BY `Year` ORDER BY Total_Laid_Off DESC) AS Rank_Num,
    `Year`,
    Company,
    Total_Laid_Off
FROM Company_Total_Laid_Off_Year
)
-- Step 3: Filter to get only the top 3 companies with the highest layoffs for each year
SELECT
	`Year`,
    Rank_Num,
    Company,
    Total_Laid_Off
FROM Layoff_Year_Rank
WHERE Rank_Num <= 3
ORDER BY 'Year';

-- Let's do the same with industry now
-- Step 1: Calculate the total amount of layoffs for each industry per year
WITH Industry_Total_Laid_Off_Year AS
(
SELECT
	EXTRACT(YEAR FROM `date`) AS `Year`,
    Industry,
    SUM(Laid_Off_Count) AS Total_Laid_Off
FROM layoffs_data_working
GROUP BY EXTRACT(YEAR FROM `date`), Industry
),
-- Step 2: Rank each company based on the total number of layoffs in each year
Industry_Layoff_Year_Rank AS
(
SELECT
	DENSE_RANK() OVER(PARTITION BY `Year` ORDER BY Total_Laid_Off DESC) AS Rank_Num,
    `Year`,
    Industry,
    Total_Laid_Off
FROM Industry_Total_Laid_Off_Year
)
-- Step 3: Filter to get only the top 3 industries with the highest layoffs for each year
SELECT
	`Year`,
    Rank_Num,
    Industry,
    Total_Laid_Off
FROM Industry_Layoff_Year_Rank
WHERE Rank_Num <= 3
ORDER BY 'Year';
-- Noticing a lot of retail and consumer