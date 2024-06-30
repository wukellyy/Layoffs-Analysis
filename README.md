# Layoffs Analysis: Data Cleaning, EDA, and Visualization

The goal of this project is to analyze layoffs trends across companies and industries from 2020-2024, leveraging **data cleaning** techniques with SQL to ensure data quality, conducting **exploratory data analysis (EDA)** to uncover insights, and **visualizing key findings** in a Tableau dashboard.

**Dataset**: https://www.kaggle.com/datasets/theakhilb/layoffs-data-2022/data

## Data Cleaning 🧹

Before diving into our analysis, it's crucial to ensure the integrity of our data so that our insights are based on accurate and complete information. This involves several key steps:

### Checking for Duplicates

Identifying and removing any duplicate records to maintain data consistency and accuracy.

```sql
WITH row_num_cte AS
(
SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY Company, Location_HQ, Industry, Laid_Off_Count, `Date`, `Source`, Funds_Raised,
								   Stage, Date_Added, Country, Percentage, List_of_Employees_Laid_Off) AS row_num
FROM layoffs_data_working
)
```

In this query:
- We are partitioning by specific columns (**\`Company\`**, **\`Location_HQ\`**, etc.) to group identical records.
- The **ROW_NUMBER()** function assigns a sequential number to each row within its partition.

By theory, if `row_num` is greater than 1, the record is identified as a duplicate. We can remove these duplicate rows with the following query:

```sql
DELETE 
FROM layoffs_data_working
WHERE (Company, Location_HQ, Industry, Laid_Off_Count, `Date`, `Source`, Funds_Raised,
       Stage, Date_Added, Country, Percentage, List_of_Employees_Laid_Off) 
       IN (
           SELECT Company, Location_HQ, Industry, Laid_Off_Count, `Date`, `Source`, Funds_Raised,
                  Stage, Date_Added, Country, Percentage, List_of_Employees_Laid_Off
           FROM row_num_cte
           WHERE row_num > 1
       );
```

**Note:** In SQL, you cannot directly update or delete from a CTE. The CTE is a temporary result set and does not support modification operations like `DELETE` or `UPDATE` directly.

### Standardizing Data

Addressing formatting issues and ensuring consistency in data types across the dataset.

1. **Fixing Text Formatting Issues**

    ```sql
    UPDATE layoffs_data_working
    SET Company = TRIM(Company);
    ```

    I noticed there was a company with an extra space in the front of the name. We can fix the text formatting issues using the `TRIM()` function, which removes any leading or trailing spaces from a text, ensuring uniform formatting.

2. **Converting Data Types**

    ```sql
    -- Convert the `date` column from text to date format
    UPDATE layoffs_data_working
    SET `date` = STR_TO_DATE(`date`, '%Y-%m-%d');

    -- Alter table to modify the data type of the `date` column to DATE
    ALTER TABLE layoffs_data_working
    MODIFY COLUMN `date` DATE;
    ```

    Converting data types not only makes the dataset more logical but also improves compatibility and efficiency in SQL operations. This will be helpful for our exploratory data analysis.

### Managing NULL/Empty Values

Updating empty values to NULL establishes a consistent representation of missing or undefined data across the dataset. This uniformity makes it easier to interpret and analyze data consistently.

```sql
-- Selecting all records where Laid_Off_Count is NULL or empty
SELECT *
FROM layoffs_data_working
WHERE Laid_Off_Count IS NULL OR Laid_Off_Count = '';

-- Updating all records where Laid_Off_Count is empty to NULL
UPDATE layoffs_data_working
SET Laid_Off_Count = NULL
WHERE Laid_Off_Count = '';
```

Using NULL values in our dataset also allows us to potentially populate them with existing data from within the dataset. For instance, if a record has a NULL value for the industry field but another record exists with the same company name and location, and it has a non-NULL value for the industry, we can use that second record to fill in the NULL value in the first record. This approach helps maintain data completeness and ensures that information gaps are effectively filled using available data within the dataset.

### Removing Unnecessary Columns/Rows

Streamlining the dataset by removing irrelevant or redundant columns and rows, focusing on data that is essential for our analysis.

Given that **`Laid_Off_Count`** is crucial for my analysis, retaining rows with NULL values in this column seems unnecessary. The presence of NULL implies uncertainty about whether layoffs occurred, and without a total employee count column, Laid_Off_Percentage cannot reliably infer Laid_Off_Count. Therefore, rows where both Laid_Off_Count and Laid_Off_Percentage are NULL will be removed to maintain data integrity and relevance for analysis.

```sql
DELETE
FROM layoffs_data_working
WHERE Laid_Off_Count IS NULL AND Laid_Off_Percentage IS NULL;
```

### Full SQL Script

For a comprehensive overview of the entire data cleaning process, refer to the complete SQL script [here](Data_Cleaning.sql).

## Exploratory Data Analysis 🔍

With the data now cleaned, we can explore and analyze it to uncover trends and patterns, providing valuable insights into the layoffs through various SQL queries.

Let's start by looking at the total amount of employees laid off for each company.

```sql
SELECT Company, SUM(Laid_Off_Count)
FROM layoffs_data_working
GROUP BY Company
ORDER BY SUM(Laid_Off_Count) DESC;
```

**Output:**

| Company   | SUM(Laid_Off_Count) |
|-----------|---------------------|
| Amazon    | 27840               |
| Meta      | 21000               |
| Tesla     | 14500               |
| Microsoft | 14058               |
| Google    | 13472               |
| ...       | ...                 |

We can see from the output that the top five companies with the highest layoffs are primarily tech giants.

How about the total amount of employees laid off for each industry?

```sql
SELECT Industry, SUM(Laid_Off_Count)
FROM layoffs_data_working
GROUP BY Industry
ORDER BY SUM(Laid_Off_Count) DESC;
```

**Output:**

| Industry          | SUM(Laid_Off_Count) |
|-------------------|---------------------|
| Retail            | 67368               |
| Consumer          | 63814               |
| Transportation    | 57913               |
| Other             | 55864               |
| Food              | 42365               |
| ...               | ...                 |

Looks like retail and consumer got hit really hard these past four years.

These queries so far have provided valuable insights, yet understanding the underlying reasons behind the layoffs requires examining their timeline. This step is crucial for identifying trends and patterns that could reveal the factors influencing these workforce reductions.

```sql
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_data_working;
```

**Output:**

| MIN(\`date\`) | MAX(\`date\`) |
|---------------|---------------|
| 2020-03-11    | 2024-06-05    |

It appears that the dataset covers layoffs from early in the COVID-19 pandemic to relatively recent dates.

Now, we can dive in even more to see total layoffs for the past four years.

```sql
SELECT
	EXTRACT(YEAR FROM `date`) AS `Year`,
    SUM(Laid_Off_Count)
FROM layoffs_data_working
GROUP BY EXTRACT(YEAR FROM `date`)
ORDER BY 1;
```

**Output:**

| Year | SUM(Laid_Off_Count) |
|------|---------------------|
| 2020 | 70755               |
| 2021 | 15810               |
| 2022 | 151657              |
| 2023 | 212585              |
| 2024 | 77194               |

Just looking at these numbers, you can see there is a significant spike in layoffs in 2022 and 2023. This is surprising, as I initially thought 2020 would have the most layoffs due to the pandemic.

Let's continue analyzing these trends on a monthly basis.

```sql
SELECT
	SUBSTRING(`date`, 1, 7) AS `Month`,
    SUM(Laid_Off_Count) AS Number_Of_Layoffs
FROM layoffs_data_working
GROUP BY SUBSTRING(`date`, 1, 7)
ORDER BY 1;
```

**Output:**

| Month   | Number_of_Layoffs |
|---------|-------------------|
| 2020-03 | 8981              |
| 2020-04 | 25271             |
| 2020-05 | 22699             |
| ...     | ...               |
| 2022-11 | 52390             |
| 2022-12 | 8697              |
| 2023-01 | 70935             |
| ...     | ...               |
| 2024-05 | 5019              |
| 2024-06 | 1410              |

Analyzing layoffs on a monthly basis reveals distinct trends over time. Initially, there was a notable spike in layoffs during the early stages of the pandemic, gradually decreasing through 2021. However, from late 2022 to early 2023, there was a significant resurgence in layoffs, as indicated by the data.

To enhance our earlier queries in this exploratory data analysis, let's identify the top three companies that laid off the most employees each year. This process can be broken down into three steps:

1. **Calculate the total layoffs for each company per year:**

    ```sql
    WITH Company_Total_Laid_Off_Year AS
    (
    SELECT
        EXTRACT(YEAR FROM `date`) AS `Year`,
        Company,
        SUM(Laid_Off_Count) AS Total_Laid_Off
    FROM layoffs_data_working
    GROUP BY EXTRACT(YEAR FROM `date`), Company
    )
    ```

2. **Rank each company based on their total layoffs in each year:**

    ```sql
    WITH Layoff_Year_Rank AS
    (
    SELECT
        DENSE_RANK() OVER(PARTITION BY `Year` ORDER BY Total_Laid_Off DESC) AS Rank_Num,
        `Year`,
        Company
    FROM Company_Total_Laid_Off_Year
    )
    ```

3. **Filter to retrieve the top 3 companies with the highest layoffs for each year:**

    ```sql
    SELECT
        `Year`,
        Rank_Num,
        Company
    FROM Layoff_Year_Rank
    WHERE Rank_Num <= 3
    ORDER BY 'Year';
    ```

**Output:**

| Year | Rank | Company   |
|------|------|-----------|
| 2020 | 1    | Uber      |
| 2020 | 2    | Groupon   |
| 2020 | 3    | Swiggy    |
| 2021 | 1    | Bytedance |
| 2021 | 2    | Katerra   |
| 2021 | 3    | Zillow    |
| 2022 | 1    | Meta      |
| 2022 | 2    | Amazon    |
| 2022 | 3    | Cisco     |
| 2023 | 1    | Amazon    |
| 2023 | 2    | Google    |
| 2023 | 3    | Microsoft |
| 2024 | 1    | Tesla     |
| 2024 | 2    | SAP       |
| 2024 | 3    | Cisco     |

Looking at this year-by-year snapshot, a clear trend emerges with tech companies consistently leading in layoffs. Companies like Meta and Amazon stand out during pivotal yearshighlighting their significant impact on employment trends amidst economic and industry challenges.

### Full SQL Script

For a comprehensive overview of the entire exploratory data analysis process, refer to the complete SQL script [here](EDA.sql).

## Visualization 📊

Key insights and trends identified from EDA were visualized in Tableau, providing interactive dashboards for deeper exploration.

Explore the full dashboard [here](https://public.tableau.com/app/profile/kelly.wu4441/viz/Layoffs2024Dashboard/Dashboard1?publish=yes).