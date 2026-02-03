# Bloomerang Logistics: Strategic SQL Analysis 🚚📊
## 📌 Project Overview
**From raw data to business strategy.** This project transforms a raw logistics sales dataset into actionable business intelligence. Using **SQL (T-SQL)**, I built an end-to-end pipeline that cleans dirty data, calculates key performance indicators (KPIs), and categorizes products using the **BCG Matrix** framework.
**Medium Article:**(https://medium.com/@olasogbamayowa2018/from-excel-to-sql-unlocking-strategic-value-in-logistics-sales-data-4021fd3649f8)
## 📂 File Structure
* `logistics_analysis_pipeline.sql`: The complete source code containing data cleaning steps, view creations, and analytical queries.
## 🛠️ Key Techniques Used
* **Data Cleaning:** Implemented `COALESCE` for smart imputation of missing values and `LTRIM`/`REPLACE` for string normalization.
* **Feature Engineering:** Created new metrics like `Shipping_Duration` and `Profit_Category`.
* **Strategic Logic:** Built a **BCG Matrix** (Stars, Cash Cows, etc.) using complex `CASE` statements to guide inventory strategy.
* **Trend Analysis:** Used Window Functions (`LAG`, `LEAD`) to calculate Month-over-Month growth and identify seasonality.

## 📊 Sample Insights
* **Product Portfolio:** Classified products into "Stars" (High Growth/High Share) and "Dogs" (Low Growth/Low Share) to recommend discontinuation candidates.
* **Operational Lag:** Identified a correlation between specific ship modes and increased shipping delays.

---
*Author:Olasogba Mayowa
*Tools: SQL Server
