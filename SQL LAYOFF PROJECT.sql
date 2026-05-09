-- =========================
-- DATA CLEANING PROJECT
-- =========================

-- 0. View original data
SELECT * FROM layoffs;

-- =========================
-- 1. CREATE STAGING TABLE
-- =========================
DROP TABLE IF EXISTS layoffs_stage;

CREATE TABLE layoffs_stage LIKE layoffs;

INSERT INTO layoffs_stage
SELECT * FROM layoffs;

SELECT * FROM layoffs_stage;

-- Convert TEXT date to DATE
UPDATE layoffs_stage
SET date = STR_TO_DATE(date, '%m/%d/%Y');

ALTER TABLE layoffs_stage
MODIFY COLUMN date DATE;

-- =========================
-- 3. FIND DUPLICATES
-- =========================

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, date
ORDER BY company
) AS row_num
FROM layoffs_stage;

-- 4. VIEW ONLY DUPLICATES
WITH duplicate_cte AS (
    SELECT *,
    ROW_NUMBER() OVER(
    PARTITION BY company, industry, total_laid_off, percentage_laid_off, date
    ORDER BY company
    ) AS row_num
    FROM layoffs_stage
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- =========================
-- 5. REMOVE DUPLICATES
-- =========================

DROP TABLE IF EXISTS layoffs_cleaned;

CREATE TABLE layoffs_cleaned AS
SELECT *
FROM (
    SELECT *,
    ROW_NUMBER() OVER(
    PARTITION BY company, industry, total_laid_off, percentage_laid_off, date
    ORDER BY company
    ) AS row_num
    FROM layoffs_stage
) t
WHERE row_num = 1;


SELECT * FROM layoffs_cleaned;

SELECT * FROM layoffs_cleaned WHERE company = "Oda";
SELECT * FROM layoffs_cleaned where company = "Casper";

WITH duplicate_cte AS (
    SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY company, industry, total_laid_off,
        percentage_laid_off, date,
        stage, country, funds_raised_millions
    ) AS row_num
    FROM layoffs_stage
)

SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Remove Duplicate --


select * 
from(
select *,row_number() OVER(
PARTITION BY company,industry,total_laid_off,percentage_laid_off,date
) as row_num from layoffs_stage )t where row_num = 1;

UPDATE layoffs_cleaned set company = trim(company);

UPDATE layoffs_cleaned set industry = "crypto" where industry
like 'crypto%';
 
 SELECT * FROM layoffs_cleaned where industry IS NULL or industry
 ='';
 
 UPDATE layoffs_cleaned t1 join layoffs_cleaned t2 
 on t1.company = t2.company set t1.industry = t2.industry
 where t1.industry is null and t2.industry is not null;

select 
sum(company is null) as company_nulls,
sum(location is null) as location_nulls,
sum(industry is null) as industry_nulls,
sum(total_laid_off is null) as total_laid_off_nulls,
sum(percentage_laid_off is null) as percentage_nulls,
sum(date is null) as date_null,
sum(stage is null) as stage_null,
sum(country is null) as country_nulls,
sum(funds_raised_millions is null) as funds_nulls
from layoffs_cleaned;
 
select * from layoffs_cleaned where industry is null;
select *
from layoffs_cleaned where industry is null or total_laid_off
is null or country is null;

UPDATE layoffs_cleaned set industry = "Unknown" where industry
is null;

select * from layoffs_cleaned;

SELECT COUNT(*)
FROM layoffs_cleaned
WHERE total_laid_off IS NULL;

SET SQL_SAFE_UPDATES = 0;
UPDATE layoffs_cleaned
SET total_laid_off = 0
WHERE total_laid_off IS NULL;

SELECT COUNT(*)
FROM layoffs_cleaned
WHERE total_laid_off IS NULL;

select * from layoffs_cleaned;

select * from  layoffs_cleaned where percentage_laid_off is null;
select count(*) from layoffs_cleaned where percentage_laid_off;

select * from layoffs_cleaned;

UPDATE layoffs_cleaned set percentage_laid_off = 0 
where  percentage_laid_off is null;

select count(*) from layoffs_cleaned where total_laid_off is null;
select * from layoffs_cleaned; 

select count(*) from layoffs_cleaned where funds_raised_millions
is null;

UPDATE layoffs_cleaned set funds_raised_millions = 0
where funds_raised_millions is null;

select count(*) from layoffs_cleaned where funds_raised_millions
is null;

select * from layoffs_stage;
select * from layoffs_cleaned;

-- TOTAL LAYOFFS BY COMPANY--
SELECT company,sum(total_laid_off) as total_layoffs
from layoffs_cleaned group by company order by total_layoffs desc;

-- TOTAL LAYOFFS BY INDUSTRY -- 
SELECT industry, sum(total_laid_off) as total_layoffs
from layoffs_cleaned group by industry order by total_layoffs desc;

-- TOTAL LAYOFFS BY COUNTRY--
SELECT country, sum(total_laid_off) as total_layoffs
from layoffs_cleaned group by country order by total_layoffs desc;

-- MONTHLY LAYOFF TREND --
SELECT substring(date,1,7) as months, sum(total_laid_off) as 
total_layoffs from layoffs_cleaned group by months order by 
months desc;

-- TOP 5 COMPANIES WITH MOST LAYOFFS EACH YEAR --
WITH company_year AS
(
    SELECT 
        company,
        YEAR(date) AS year_name,
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_cleaned
    WHERE date IS NOT NULL
    GROUP BY company, YEAR(date)
),

company_rank AS
(
    SELECT *,
    DENSE_RANK() OVER(
        PARTITION BY year_name
        ORDER BY total_laid_off DESC
    ) AS ranking
    FROM company_year
)

SELECT *
FROM company_rank
WHERE ranking <= 5;

select * from layoffs_cleaned;

select count(*) from layoffs_cleaned;

-- FIND VERY OLD DATES --
SELECT * FROM layoffs_cleaned where year(date) < 2000;

-- FIND EXTRA WHITESPACES --
SELECT * FROM layoffs_cleaned where 
company != TRIM(company);

-- STANDARDIZE INDUSTRY VALUES --
UPDATE layoffs_cleaned set industry = 'Crypto' 
where industry like 'crypto%';

select * from layoffs_cleaned;

-- COUNT DISTINCT COMPANIES --
SELECT COUNT(distinct company) from layoffs_cleaned;

-- CHECK NULL PERCENTAGE --
SELECT ROUND(
SUM(industry is null) *100/count(*),2
) as industry_null_percentage from layoffs_cleaned;

-- COMPANY WITH HIGHEST FUNDING --
SELECT * FROM layoffs_cleaned order by funds_raised_millions desc
limit 10;

-- TOP COUNTRIES WITH MOST COMPANIES AFFECTED --
SELECT country, COUNT(DISTINCT company) as affected_companies
from layoffs_cleaned group by country order by affected_companies desc;


-- MONTHLY TREND -- 
SELECT date_format(date, '%y-%m') as months,
sum(total_laid_off) as total_layoffs from layoffs_cleaned
group by months order by months;

-- FIRST AND LAST LAYOFF DATE --
SELECT MIN(DATE) AS first_layoff,
MAX(DATE) AS last_layoffs from layoffs_cleaned;

-- REMOVE UNUSED COLUMNS --
ALTER TABLE layoffs_cleaned DROP COLUMN row_num;

-- FINAL DATA QUALITY CHECK ---
SELECT count(*) AS total_rows,

SUM(company is null) as company_nulls,
SUM(location is null) as location_nulls,
sum(industry is null) as industry_nulls,
sum(date is null) as date_nulls

from layoffs_cleaned;

SELECT * FROM layoffs_cleaned;


