SELECT *
FROM [Bloomerang Logistics ]

---create profit categories
ALTER TABLE dbo.bloomerang_logistics
ADD profit_category VARCHAR(20)
---set conditions for profit category
UPDATE bloomerang_logistics
SET profit_category =
    CASE 
        WHEN profit < -1000 THEN 'Major loss'
        WHEN profit < 0 THEN 'Minor loss'
        WHEN profit = 0 THEN 'Break even'
        WHEN profit <= 500 THEN 'Low profit'
        WHEN profit <= 2000 THEN 'Medium profit'
        ELSE 'High profit'
    END
   ---clean columns with date and convert to DATE type
   ---ADD new columns orederdate_clean and shipdate_clean
   ALTER TABLE dbo.bloomerang_logistics
   ADD orderdate_clean DATE
   ALTER TABLE bloomerang_logistics
   ADD shipdate_clean DATE

   UPDATE [Bloomerang_Logistics ]     SET
    orderdate_clean = CAST((order_date) AS DATE),
    shipdate_clean = CAST((Ship_date) AS DATE)
    ---Add new column for date difference AS shipping_durartion
    ALTER TABLE bloomerang_logistics
    ADD shipping_duration INT
    UPDATE [Bloomerang_Logistics ]
         SET shipping_duration= DATEDIFF(DAY,orderdate_clean, shipdate_clean)
    ---Check for name inconsistencies
    SELECT customer_name, COUNT (*) AS frequency
    FROM [Bloomerang_Logistics ]
    GROUP BY customer_name
    ORDER BY frequency DESC
    ---Fill NULLS values in product base margin with category average
    ALTER TABLE bloomerang_logistics
    ADD product_base_marginclean DECIMAL(10,4)
     UPDATE [Bloomerang_Logistics ]
         SET  
         product_base_marginclean= 
         COALESCE((Product_Base_Margin), 
              (SELECT AVG((Product_Base_Margin))
              FROM Bloomerang_Logistics AS b2
              WHERE b2.product_category= Bloomerang_Logistics.(product_category)
              AND (Product_Base_Margin) IS NOT NULL)
              )
         ---Check inconsistencies on postal code column
         SELECT postal_code, LEN(postal_code) AS length, COUNT(*) AS count
         FROM bloomerang_logistics
         GROUP BY postal_code, LEN(postal_code)
         ORDER BY length, count DESC
         ---Standardize postal code to 5- digit format
         ALTER TABLE bloomerang_logistics
         ADD postalcode_clean VARCHAR(10)

         UPDATE bloomerang_logistics
         SET postalcode_clean 
            = LTRIM(RTRIM(postal_code))
            WHERE postal_code IS NOT NULL

            UPDATE [Bloomerang_Logistics ]
            SET postalcode_clean =
               CASE WHEN LEN(postalcode_clean) = 4 THEN '0' + postalcode_clean
                    ELSE postalcode_clean 
          END
---Replace special characters in product name column
ALTER TABLE bloomerang_logistics
ADD productname_clean NVARCHAR(255)

UPDATE [Bloomerang_Logistics ]
SET productname_clean =
    REPLACE(product_name, '™', '')
    UPDATE [Bloomerang_Logistics ]
SET productname_clean =
    REPLACE(product_name, '®', '')
    UPDATE [Bloomerang_Logistics ]
SET productname_clean =                     
    REPLACE(product_name, '_', '-')
    UPDATE [Bloomerang_Logistics ]
SET productname_clean =
    REPLACE(product_name, '”', '"')

    ---SALES AND PROFIT ANALYSIS OVERVIEW
    CREATE VIEW vw_salesprofitanalysis AS
    SELECT
          ---per year and month
          YEAR(orderdate_clean) AS Orderyear,
          MONTH(orderdate_clean) AS Ordermonth,
          DATENAME(MONTH, orderdate_clean) AS MonthName,
          FORMAT(orderdate_clean, 'yyyy-MM') AS YearMonth,

         --- per geographic location
          Region,
          State_or_province AS State,
          City,
          postalcode_clean AS postalcode,

          --- per business dimensions and category
          customer_segment,
          product_category,
          product_sub_category,
          Ship_mode,
          order_priority,

          ---per metrics
          COUNT(*) AS Ordercount,
          SUM(quantity_ordered_new) AS Totalquantity,
          SUM(sales) AS Totalsales,
          SUM(profit) AS Totalprofit,
              CASE
                  WHEN SUM(sales) = 0 THEN 0
                  ELSE (SUM(profit) / SUM(sales)) * 100
              END AS profitmarginpercent,
              AVG(profit) AS Avgprofitperorder,
              SUM(shipping_cost) AS Total_shippingcost

    FROM bloomerang_logistics
    WHERE orderdate_clean IS NOT NULL
    GROUP BY 
           YEAR(orderdate_clean),
           MONTH(orderdate_clean),
           DATENAME(MONTH, orderdate_clean),
           FORMAT(orderdate_clean, 'yyyy-MM'),
           Region,
           (state_or_province),
           City,
           postalcode_clean,
           customer_segment,
           product_category,
           product_sub_category,
           ship_mode,
           order_priority

---SALES ANALYSIS PER REGION PERFORMANCE
CREATE VIEW vw_regionalperformance AS 
SELECT
     Region,
     (state_or_province) AS State,
     City,
     COUNT(*) AS ordercount,
     SUM(Sales) AS Totalsales,
     SUM(profit) AS TOtalprofit,
     CASE
         WHEN SUM(Sales) = 0 THEN 0
         ELSE (SUM(profit) / SUM(sales)) * 100
    END AS profitmarginpercent,
    SUM([Shipping_cost]) AS Totalshippingcost,
    AVG(Shipping_duration) AS Shippingdurationdays,

    ---metrics per customer by region
    COUNT(DISTINCT(customer_ID)) AS uniquecustomers,
    ---metrics per products by region
    COUNT(DISTINCT(productname_clean))AS uniqueproducts

FROM bloomerang_logistics
GROUP BY 
     Region,
     State_or_province,
     city

     ---Product sales performance
CREATE VIEW vw_productperformance AS
SELECT 
     (product_category),
     (product_sub_category),
     productname_clean AS productname,
     product_container,

     ---Sales metrics per product performance
     COUNT(*) AS ordercount,
     SUM((quantity_ordered_new)) AS Totalquantitysold,
     SUM(Sales) AS Totalsales,
     SUM(profit) AS totalprofit,

     ---profitability per product performance
     CASE 
         WHEN SUM(sales) =0 THEN 0
         ELSE (SUM(profit) / SUM(sales)) * 100
     END AS profitbasemargin,
     AVG(profit) AS Avgprofitperorder,

     ---pricing and discount analysis per product performance
     AVG(unit_price) AS Avgunitprice,
     AVG(Discount) AS Avgdiscount,
     AVG(product_base_marginclean) AS Avgproductmargin,

     --- shipping analysis performance
     AVG(shipping_cost) AS Avgshippingcost, ship_mode

     FROM [Bloomerang_Logistics ]
     GROUP BY 
            product_category,
            product_sub_category,
            productname_clean,
            product_container,
            ship_mode

---Customer performance analysis
CREATE VIEW vw_customerperformance AS
SELECT
    customer_ID,
    customer_name,
    customer_segment,

--- order per customer
COUNT([Order_ID]) AS Totalorders,
SUM(sales ) AS lifetimevalue,
SUM(profit) AS Totalprofit,

---order ID per average
AVG(sales) AS Avgordervalue,
AVG(profit) AS Avgprofitperorder,

--- Time based performance metrics
MIN(orderdate_clean) AS Firstorderdate,
MAX(orderdate_clean) AS Lastorderdate,
DATEDIFF(DAY, MIN(orderdate_clean), MAX(orderdate_clean))AS Customerlifetimedays,

---geographic performance by orders info
region,
state_or_province AS State,
 city

FROM bloomerang_logistics
GROUP BY
      customer_ID,
      Customer_name,
      Customer_segment,
      region,
      state_or_province,
      city

---Monthly trends view
CREATE VIEW vw_monthlytrends AS
SELECT 
      Year(OrderDate_clean) AS OrderYear,
      Month(OrderDate_clean) AS Ordermonth,
      FORMAT(OrderDate_clean, 'yyyy-MM') AS YearMonth,
      DATENAME(MONTH, OrderDate_clean) AS MonthName,

      ---Monthly metrics of sales
      COUNT(*) AS Monthlyordercount,
      SUM(sales) AS monthlysales,
      SUM(profit) AS monthlyprofit,
      CASE 
         WHEN SUM(Sales)=0 THEN 0
         ELSE(SUM(profit) / SUM(Sales)) * 100
      END AS monthlyprofitmargin,

      ---Comparison metrics for months
      LAG(SUM(Sales), 1) OVER (ORDER BY YEAR(OrderDate_clean), MONTH(OrderDate_clean))AS Previousmonthsales,
      LAG(SUM(Profit), 1) OVER (ORDER BY YEAR(OrderDate_clean), MONTH(OrderDate_clean))AS Previousmonthprofit,

      SUM(quantity_ordered_new) AS Monthlyquantity,
      AVG(shipping_cost) AS Avgmonthlyshippingcost

      FROM [Bloomerang_Logistics ]
      WHERE OrderDate_clean IS NOT NULL
      GROUP BY
            YEAR(OrderDate_clean),
            MONTH(OrderDate_clean),
            FORMAT(OrderDate_clean, 'yyyy-MM'),
            DATENAME(MONTH, OrderDate_clean

    ---Shipping Analysis
CREATE VIEW vw_shippinganalysis AS
SELECT 
     (ship_mode),
     COUNT(*) AS ordercount,
     SUM(Sales) AS Totalsales,
     SUM(profit) AS Totalprofit,
     AVG(profit) AS Avgprofit,
     AVG(shipping_cost) AS Avgshippingcost,
     CASE
         WHEN SUM(sales)=0 THEN 0
         ELSE SUM(profit)/SUM(sales) * 100
    END AS profitmarginpercent
FROM bloomerang_logistics
GROUP BY ship_mode

CREATE VIEW vw_customerlifetimevalue AS
SELECT
     customer_ID,
     customer_name,
     customer_segment,
     COUNT(DISTINCT(order_id))AS Totalorders,
     SUM(sales) AS lifetimevalue,
     SUM(profit) AS Totalprofit,
     MIN(orderdate_clean) AS Firstorderdate,
     MAX(orderdate_clean) AS Lastorderdate,
     DATEDIFF(Day, MIN(orderdate_clean), MAX(orderdate_clean)) AS customerlifetimedays,
     CASE
         WHEN DATEDIFF(DAY, MIN(orderdate_clean), MAX(orderdate_clean)) = 0 THEN SUM(Sales)
         ELSE SUM(sales) / DATEDIFF(DAY, MIN(orderdate_clean), MAX(orderdate_clean))
     END AS Dailyvaluerate
     FROM bloomerang_logistics
     GROUP BY customer_id, customer_name, customer_segment

CREATE VIEW vw_productprotfolio AS
SELECT 
      product_category,
      product_sub_category,
      productname_clean AS ProductName,
      COUNT(*) AS Order_count,
      SUM(quantity_ordered_new) AS Totalquantity,
      SUM(Sales) AS Totalsales,
      SUM(profit) AS Totalprofit,
      AVG(product_base_marginclean) AS AvgBasemargin,
      AVG(Discount) AS AvgDiscount,

      CASE 
         WHEN SUM(sales) > (SELECT AVG(Totalsales) FROM vw_productperformance)
         AND (SUM(profit) / SUM(Sales)) > 0.15 THEN 'Star'
         WHEN SUM(Sales) > (SELECT AVG(Totalsales) FROM vw_productperformance)
         AND (SUM(profit) / SUM(Sales)) <= 0.15 THEN 'Cash cow'
         WHEN SUM(Sales) <=  (SELECT AVG(Totalsales) FROM vw_productperformance)
         AND  (SUM(profit) / SUM(Sales)) > 0.15 THEN 'Question Mark'
         ELSE 'Dog'
     END AS ProductType
FROM [Bloomerang_Logistics ]
GROUP BY product_category,
         product_sub_category,
         productname_clean

---SEASONAL TRENDS FOR PRODUCT
CREATE VIEW vw_seasonaltrends AS
SELECT
      Year(orderdate_clean) AS OrderYear,
      MONTH(orderdate_clean) AS OrderMonth,
      DATENAME(MONTH, orderdate_clean) AS Monthname,
      product_category,
      customer_segment,
      Region,

      COUNT(*) AS ordercount,
      SUM(Sales) AS Monthlysales,
      SUM(profit) AS Monthlyprofit,
      SUM(quantity_ordered_new) AS MonthlyQuantity,
      LAG(SUM(Sales), 12) OVER (PARTITION BY(product_category), Region ORDER BY YEAR(orderdate_clean), MONTH(orderdate_clean)) AS previousyearsales
FROM [Bloomerang_Logistics ]
WHERE orderdate_clean IS NOT NULL
GROUP BY
       YEAR(orderdate_clean),
       MONTH(orderdate_clean),
       DATENAME(MONTH, orderdate_clean),
       product_category,
       customer_segment,
       region


       

 SELECT productname_clean
 FROM [Bloomerang_Logistics]