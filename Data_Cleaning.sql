SELECT *
FROM layoffs_data;

-- Create a copy of the raw table to work with
CREATE TABLE layoffs_data_working
LIKE layoffs_data;

INSERT INTO layoffs_data_working
SELECT * FROM layoffs_data;

-- Data Cleaning

-- ================ 1. Check for duplicates (remove if any) ================
WITH row_num_cte AS
(
SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY Company, Location_HQ, Industry, Laid_Off_Count, `Date`, `Source`, Funds_Raised,
								   Stage, Date_Added, Country, Percentage, List_of_Employees_Laid_Off) AS row_num
FROM layoffs_data_working
)

SELECT *
FROM row_num_cte
WHERE row_num > 1;
-- It seems like we don't have any duplicate rows!

-- ================ 2. Standardize data ================

SELECT *
FROM layoffs_data_working;

SELECT DISTINCT Company, TRIM(Company)
FROM layoffs_data_working
ORDER BY 1;
-- I noticed there was a company with an extra space in the front of the name

-- Fix text format issues
UPDATE layoffs_data_working
SET Company = TRIM(Company);

SELECT DISTINCT Location_HQ
FROM layoffs_data_working
ORDER BY 1;

SELECT DISTINCT Industry
FROM layoffs_data_working
ORDER BY 1;

SELECT DISTINCT Country
FROM layoffs_data_working
ORDER BY 1;

-- Change data types for columns
SELECT *
FROM layoffs_data_working;

UPDATE layoffs_data_working
SET `date` = STR_TO_DATE(`date`, '%Y-%m-%d');
-- Convert the text from data column into a data format

ALTER TABLE layoffs_data_working
MODIFY COLUMN `date` DATE;

-- Change Laid_Off_Count data type to integer
ALTER TABLE layoffs_data_working
MODIFY COLUMN Laid_Off_Count INT;

SELECT Percentage
FROM layoffs_data_working;

SELECT MIN(Percentage), MAX(Percentage)
FROM layoffs_data_working;
-- Seems like the percentage values range from 0.0 to 1.0 (this this accurate!)

-- Change Percentage data type to decimal
ALTER TABLE layoffs_data_working
MODIFY COLUMN Percentage DECIMAL(2, 1);

-- Rename this column to be more clearer
ALTER TABLE layoffs_data_working
RENAME COLUMN Percentage TO Laid_Off_Percentage;

-- ================ 3. Look into null/empty values ================

-- Any empty values should be turned into null values
SELECT *
FROM layoffs_data_working
WHERE Laid_Off_Count IS NULL OR Laid_Off_Count = '';

UPDATE layoffs_data_working
SET Laid_Off_Count = NULL
WHERE Laid_Off_Count = '';

SELECT *
FROM layoffs_data_working
WHERE Funds_Raised IS NULL OR Funds_Raised = '';

SELECT *
FROM layoffs_data_working
WHERE Percentage IS NULL OR Percentage = '';

UPDATE layoffs_data_working
SET Percentage = NULL
WHERE Percentage = '';

-- ================ 4. Remove unnecessary columns/rows ================

SELECT *
FROM layoffs_data_working;

SELECT *
FROM layoffs_data_working
WHERE Laid_Off_Count IS NULL AND Laid_Off_Percentage IS NULL;

-- Since I plan to use the Laid_Off_Count for most of my analysis, I don't see the point of keeping a null value of it.
-- It implies there has been a layoff, but I don't know for sure.
-- Plus, there isn't a total amount of employees column for me to use Laid_Off_Percentage to find Laid_Off_Count.
-- If both Laid_Off_Count and Laid_Off_Percentage are null, just delete the row...
DELETE
FROM layoffs_data_working
WHERE Laid_Off_Count IS NULL AND Laid_Off_Percentage IS NULL;

SELECT *
FROM layoffs_data_working;

-- I won't be using this Source column for my analysis
ALTER TABLE layoffs_data_working
DROP COLUMN `Source`;

-- As well as this Date_Added column (it's just an author's note)
ALTER TABLE layoffs_data_working
DROP COLUMN Date_Added;

SELECT COUNT(*)
FROM layoffs_data_working
WHERE List_of_Employees_Laid_Off = 'Unknown';
-- It seems like ~90% of List_of_Employees_Laid_Off is 'Unknown'... and also the column is pretty irrelevant

ALTER TABLE layoffs_data_working
DROP COLUMN List_of_Employees_Laid_Off;

SELECT COUNT(*)
FROM layoffs_data_working;