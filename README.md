# 🧹 Layoffs Data Cleaning & Analysis — SQL Project

A complete end-to-end SQL project that takes raw, messy layoff data and transforms it into a clean, analysis-ready dataset using MySQL. Covers deduplication, standardization, null handling, and exploratory analysis.

---

## 📁 Project Structure

```
layoffs-sql-cleaning/
├── layoffs_cleaning.sql     # Full SQL script (cleaning + analysis)
├── layoffs.csv              # Raw source data
└── README.md
```

---

## 🎯 Objectives

- Remove duplicate records using window functions
- Standardize inconsistent text values (industry names, whitespace)
- Handle NULL and blank values appropriately
- Convert date strings to proper `DATE` format
- Run exploratory analysis queries on the cleaned dataset

---

## 🔄 Workflow

### 1. Staging Table
A staging table (`layoffs_stage`) is created as a safe copy of the raw data — the original is never modified.

### 2. Duplicate Detection & Removal
Duplicates are identified using `ROW_NUMBER()` with `PARTITION BY` across key columns:

```sql
ROW_NUMBER() OVER(
    PARTITION BY company, industry, total_laid_off,
                 percentage_laid_off, date, stage, country, funds_raised_millions
) AS row_num
```

Only rows where `row_num = 1` are kept in the final `layoffs_cleaned` table.

### 3. Standardization
- `TRIM()` applied to company names
- Industry values like `'Crypto Currency'`, `'CryptoCurrency'` normalized to `'Crypto'`
- Date column converted from `TEXT` (`MM/DD/YYYY`) to `DATE` type using `STR_TO_DATE()`

### 4. Null Handling

| Column | Strategy |
|---|---|
| `industry` | Self-join to fill from matching company rows; remaining NULLs → `'Unknown'` |
| `total_laid_off` | NULLs → `0` |
| `percentage_laid_off` | NULLs → `0` |
| `funds_raised_millions` | NULLs → `0` |

### 5. Final Quality Check
```sql
SELECT COUNT(*) AS total_rows,
    SUM(company IS NULL)   AS company_nulls,
    SUM(location IS NULL)  AS location_nulls,
    SUM(industry IS NULL)  AS industry_nulls,
    SUM(date IS NULL)      AS date_nulls
FROM layoffs_cleaned;
```

---

## 📊 Analysis Queries

| Query | Description |
|---|---|
| Total layoffs by company | Which companies laid off the most workers |
| Total layoffs by industry | Hardest-hit sectors |
| Total layoffs by country | Geographic distribution |
| Monthly layoff trend | Layoffs over time (month-by-month) |
| Top 5 companies per year | `DENSE_RANK()` to rank within each year |
| Companies with highest funding | Cross-reference with `funds_raised_millions` |
| Top countries by affected companies | `COUNT(DISTINCT company)` per country |
| First & last layoff dates | Dataset date range |

---

## 🛠️ Tech Stack

- **Database**: MySQL 8.0+
- **Key SQL Features Used**:
  - Window functions (`ROW_NUMBER()`, `DENSE_RANK()`)
  - CTEs (`WITH` clause)
  - `STR_TO_DATE()`, `DATE_FORMAT()`
  - Self-joins for NULL imputation
  - `ALTER TABLE`, `UPDATE`, `DROP COLUMN`

---

## 🚀 How to Run

1. Import the raw `layoffs.csv` into a MySQL database as the `layoffs` table.
2. Open `layoffs_cleaning.sql` in MySQL Workbench (or any MySQL client).
3. Run the script top to bottom — it handles table creation, cleaning, and analysis in sequence.

> ⚠️ The script uses `SET SQL_SAFE_UPDATES = 0` to allow bulk updates. Re-enable after running if needed.

---

## 💡 Key Learnings

- Using CTEs + window functions is the safest way to identify and remove duplicates without losing data
- A staging table pattern protects raw data integrity throughout the cleaning process
- Self-joins are effective for filling NULLs when the same company appears in multiple rows
- Always run a final null audit before moving to analysis

---

## 📌 Sample Insight

```sql
-- Top 5 companies with most layoffs each year
WITH company_year AS (
    SELECT company, YEAR(date) AS year_name, SUM(total_laid_off) AS total_laid_off
    FROM layoffs_cleaned
    WHERE date IS NOT NULL
    GROUP BY company, YEAR(date)
),
company_rank AS (
    SELECT *, DENSE_RANK() OVER(PARTITION BY year_name ORDER BY total_laid_off DESC) AS ranking
    FROM company_year
)
SELECT * FROM company_rank WHERE ranking <= 5;
```

---

## 🙌 Acknowledgements

Dataset sourced from publicly available global tech layoff records (2020–2023).
