Question 1

-- Selecting country ISO code, country name, and total sales

SELECT 
    c.COUNTRY_ISO_CODE AS "Country ISO code",
    c.COUNTRY_NAME AS "Country Name",
    SUM(s.AMOUNT_SOLD) AS "Sales"
FROM 
    SH.COUNTRIES c
JOIN 
    SH.CUSTOMERS cu ON c.COUNTRY_ID = cu.COUNTRY_ID
JOIN 
    SH.SALES s ON cu.CUST_ID = s.CUST_ID
GROUP BY 
    c.COUNTRY_ISO_CODE, c.COUNTRY_NAME          -- Grouping by country ISO code and name
ORDER BY 
    SUM(s.AMOUNT_SOLD) DESC            -- Sorting total sales in descending order
FETCH FIRST 3 ROWS ONLY;              -- Limiting the result to the top 3 rows


---------------------------------------------------------------------------------
Question 2


-- Using CTEs to calculate total quantity sold for each product in the US per year
WITH US_SALES AS (
    SELECT
        EXTRACT(YEAR FROM T.TIME_ID) AS Calendar_Year,
        P.PROD_NAME AS Prod_name,
        SUM(S.QUANTITY_SOLD) AS Total_Quantity
    FROM
        SH.COUNTRIES C
    JOIN
        SH.CUSTOMERS CS ON C.COUNTRY_ID = CS.COUNTRY_ID
    JOIN
        SH.SALES S ON CS.CUST_ID = S.CUST_ID
    JOIN
        SH.PRODUCTS P ON S.PROD_ID = P.PROD_ID
    JOIN
        SH.TIMES T ON S.TIME_ID = T.TIME_ID
    WHERE
        C.COUNTRY_ISO_CODE = 'US'
        AND EXTRACT(YEAR FROM T.TIME_ID) BETWEEN 1998 AND 2001
    GROUP BY
        EXTRACT(YEAR FROM T.TIME_ID), P.PROD_NAME  ),-- Grouping by year and product name

RANKED_PRODUCTS AS (
    SELECT
        Calendar_Year,
        Prod_name,
        Total_Quantity,
        ROW_NUMBER() OVER (PARTITION BY Calendar_Year ORDER BY Total_Quantity DESC) AS Rank
    FROM
        US_SALES -- Ranking products by total quantity sold within each year
)
SELECT
    Calendar_Year,
    Prod_name,
    Total_Quantity
FROM
    RANKED_PRODUCTS
WHERE
    Rank = 1; -- Selecting the most sold product for each year



--------------------------------------------------------------------------
question 3


-------retrieving the product id of the highest sales in 2001------

SELECT 
  S.PROD_ID,
  SUM(S.AMOUNT_SOLD) AS Total_Revenue
FROM 
  SH.SALES S
JOIN 
  SH.TIMES T ON S.TIME_ID = T.TIME_ID
WHERE 
  TO_CHAR(T.CALENDAR_YEAR) = '2001'
GROUP BY 
  S.PROD_ID
ORDER BY 
  Total_Revenue DESC
FETCH FIRST 1 ROW ONLY;  -- Fetching only the top row (highest revenue)


-------putting product id=18 retrieved from above code------
-- This query retrieves detailed sales information for the product with Product ID 18 in the year 2001.

SELECT 
  S.PROD_ID,
  S.CHANNEL_ID,
  C.CHANNEL_DESC,
  COUNT(*) AS NUM_TRANS,
  SUM(S.QUANTITY_SOLD) AS TOTAL_QUANTITY   -- Calculating the total quantity sold

FROM 
  SH.SALES S
JOIN 
  SH.TIMES T ON S.TIME_ID = T.TIME_ID
JOIN 
  SH.CHANNELS C ON S.CHANNEL_ID = C.CHANNEL_ID
WHERE 
  TO_CHAR(T.CALENDAR_YEAR) = '2001'
  AND S.PROD_ID = 18
GROUP BY 
  S.PROD_ID, S.CHANNEL_ID, C.CHANNEL_DESC;

  

---------------------------------------------------------------------------------
question 4

-- Selecting country ISO code, country name, and total sales with COALESCE to handle NULL values
SELECT 
  C.COUNTRY_ISO_CODE,
  C.COUNTRY_NAME,
  COALESCE(SUM(S.AMOUNT_SOLD), 0) AS SALES
FROM 
  SH.COUNTRIES C
LEFT JOIN 
  SH.CUSTOMERS CU ON C.COUNTRY_ID = CU.COUNTRY_ID
LEFT JOIN 
  SH.SALES S ON CU.CUST_ID = S.CUST_ID
LEFT JOIN 
  SH.TIMES T ON S.TIME_ID = T.TIME_ID
WHERE 
  TO_CHAR(T.CALENDAR_YEAR) = '1998'
GROUP BY 
  C.COUNTRY_ISO_CODE, C.COUNTRY_NAME -- Grouping by country ISO code and name
ORDER BY 
  SALES -- Sorting by total sales
FETCH FIRST 3 ROWS ONLY; -- Limiting the result to the bottom 3 countries in terms of sales


---------------------------------------------------------------------------------

question 5 


-- Creating a materialized view to aggregate sales data by promotion and product
CREATE MATERIALIZED VIEW Promotion_Analysis_mv
AS
SELECT
  S.PROMO_ID,
  S.PROD_ID,
  SUM(S.AMOUNT_SOLD) AS TOTAL_SALES
FROM
  SH.SALES S
GROUP BY
  S.PROMO_ID, S.PROD_ID;

-- Querying to display created materialized view
Select * from Promotion_Analysis_mv;

--------------------------------------------------------------------------------
question 6
-----using ROLLUP to find aggregated sales data by promotion and product, with 'Total' for overall summary---

SELECT
  NVL(TO_CHAR(S.PROMO_ID), 'Total') AS PROMO_ID,
  NVL(TO_CHAR(S.PROD_ID), 'Total') AS PROD_ID,
  NVL(TO_CHAR(SUM(S.TOTAL_SALES)), '0') AS TOTAL_SALES
FROM
  Promotion_Analysis_mv S   -- Using the materialized view Promotion_Analysis_mv

GROUP BY
  ROLLUP (S.PROMO_ID, S.PROD_ID)  -- Applying ROLLUP for aggregation with promotion and product
ORDER BY
  S.PROMO_ID NULLS FIRST, S.PROD_ID NULLS FIRST;     -- Ordering results with 'Total' first, then by promotion and product




----------------------------------------------------------------------------------

question 7

---Promotion Impact on Sales:
-- Calculating the total sales for each combination of product subcategory and promotion

SELECT
    PROD_SUBCATEGORY,
    PROMO_ID,
    -- Calculating the total sales for each combination of product subcategory and promotion
    SUM(DOLLARS) AS Total_Sales
FROM
    SH.FWEEK_PSCAT_SALES_MV   
GROUP BY
    PROD_SUBCATEGORY, PROMO_ID
ORDER BY
    PROD_SUBCATEGORY, Total_Sales DESC;   -- Ordering by product subcategory and total sales in descending order



-------Channelwise Sales for Product Subcategories:
-- This query calculates the total sales for product subcategories across different channels.

SELECT
    PROD_SUBCATEGORY,
    CHANNEL_ID,
    SUM(DOLLARS) AS Total_Sales  -- Calculating the total sales for each combination of product subcategory and channel
FROM
    SH.FWEEK_PSCAT_SALES_MV
GROUP BY
    PROD_SUBCATEGORY, CHANNEL_ID
ORDER BY
    PROD_SUBCATEGORY, Total_Sales DESC;





