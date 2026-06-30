# Task-1	Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT DISTINCT 
    market
FROM 
    dim_customer
WHERE 
    region = 'APAC'
    AND customer = 'Atliq Exclusive';
    
# Task-2 What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg
    
WITH CTE1 AS (
    SELECT DISTINCT 
        COUNT(p.product) AS unique_products_2020p 
    FROM 
        dim_product p
    JOIN 
        fact_gross_price g ON p.product_code = g.product_code
    WHERE 
        g.fiscal_year = 2020
),

CTE2 AS (
    SELECT DISTINCT 
        COUNT(p.product) AS unique_products_2021p 
    FROM 
        dim_product p
    JOIN 
        fact_gross_price g ON p.product_code = g.product_code
    WHERE 
        g.fiscal_year = 2021
)

SELECT 
    c1.unique_products_2020p AS unique_products_2020, 
    c2.unique_products_2021p AS unique_products_2021, 
    ROUND(((c2.unique_products_2021p - c1.unique_products_2020p) * 100 / c1.unique_products_2020p), 2) AS percentage_chg
FROM 
    CTE1 AS c1
CROSS JOIN 
    CTE2 AS c2;

SELECT 
    c1.unique_products_2020p AS unique_products_2020, 
    c2.unique_products_2021p AS unique_products_2021, 
    ROUND(((c2.unique_products_2021p - c1.unique_products_2020p) * 100.0 / c1.unique_products_2020p), 2) AS percentage_chg
FROM 
    CTE1 AS c1
CROSS JOIN 
    CTE2 AS c2;
    
# Task-3 Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields, segment product_count
    
    SELECT 
    segment, 
    COUNT(*) AS product_count
FROM 
    dim_product
GROUP BY 
    segment
ORDER BY 
    product_count DESC;
    
# Task-4 Which segment had the most increase in unique products in 2021 vs 2020? Expected Output:
# segment
# product_count_2020
# product_count_2021
# difference

SELECT
    p.segment,

    COUNT(
        DISTINCT CASE
            WHEN f.fiscal_year = 2020
            THEN p.product_code
        END
    ) AS product_count_2020,

    COUNT(
        DISTINCT CASE
            WHEN f.fiscal_year = 2021
            THEN p.product_code
        END
    ) AS product_count_2021,

    COUNT(
        DISTINCT CASE
            WHEN f.fiscal_year = 2021
            THEN p.product_code
        END
    )
    -
    COUNT(
        DISTINCT CASE
            WHEN f.fiscal_year = 2020
            THEN p.product_code
        END
    ) AS difference

FROM dim_product AS p

JOIN fact_gross_price AS f
    ON p.product_code = f.product_code

WHERE f.fiscal_year IN (2020, 2021)

GROUP BY
    p.segment

ORDER BY
    difference DESC;
    
#Task-5 Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code product manufacturing_cost
    
WITH CTE1 AS (
    SELECT 
        m.product_code, 
        p.product, 
        ROUND(m.manufacturing_cost, 2) AS manufacturing_cost
    FROM 
        fact_manufacturing_cost m
    JOIN 
        dim_product p ON m.product_code = p.product_code
    WHERE 
        m.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
),
CTE2 AS (
    SELECT 
        m.product_code, 
        p.product, 
        ROUND(m.manufacturing_cost, 2) AS manufacturing_cost
    FROM 
        fact_manufacturing_cost m
    JOIN 
        dim_product p ON m.product_code = p.product_code
    WHERE 
        m.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
)

SELECT * FROM CTE1
UNION ALL
SELECT * FROM CTE2;

#Task-6 Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
# The final output contains these fields, customer_code customer average_discount_percentage

SELECT DISTINCT 
    p.customer_code, 
    c.customer, 
    ROUND((AVG(p.pre_invoice_discount_pct) OVER(PARTITION BY p.customer_code)) * 100, 2) AS average_discount_percentage 
FROM 
    fact_pre_invoice_deductions p 
JOIN 
    dim_customer c ON c.customer_code = p.customer_code
WHERE 
    p.fiscal_year = 2021 
    AND c.market = 'India'
ORDER BY 
    average_discount_percentage DESC
LIMIT 5;

#Task-7 Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
#The final report contains these columns: Month Year Gross sales Amount

SELECT CONCAT(MONTHNAME(FS.date), ' (', YEAR(FS.date), ')') AS 'Month', FS.fiscal_year,
       ROUND(SUM(G.gross_price*FS.sold_quantity), 2) AS Gross_sales_Amount
FROM fact_sales_monthly FS JOIN dim_customer C ON FS.customer_code = C.customer_code
						   JOIN fact_gross_price G ON FS.product_code = G.product_code
WHERE C.customer = 'Atliq Exclusive'
GROUP BY  Month, FS.fiscal_year 
ORDER BY FS.fiscal_year;

#Task-8 In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity

WITH cte AS (
    SELECT 
        CASE 
            WHEN MONTH(date) IN (9, 10, 11) THEN "Q1"
            WHEN MONTH(date) IN (12, 1, 2)  THEN "Q2"
            WHEN MONTH(date) IN (3, 4, 5)   THEN "Q3"
            WHEN MONTH(date) IN (6, 7, 8)   THEN "Q4"
        END AS quarter, 
        sold_quantity AS sold 
    FROM 
        fact_sales_monthly
    WHERE 
        fiscal_year = 2020
)

SELECT DISTINCT 
    c.quarter, 
    SUM(c.sold) OVER(PARTITION BY quarter) AS total_sold_quantity 
FROM 
    cte c; 
#Task-9 Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields, channel gross_sales_mln percentage

WITH cte AS (
    SELECT 
        c.channel, 
        ROUND((SUM(g.gross_price * s.sold_quantity) / 1000000), 2) AS total_sales
    FROM 
        fact_sales_monthly s 
    JOIN 
        fact_gross_price g ON s.product_code = g.product_code
    JOIN 
        dim_customer c ON c.customer_code = s.customer_code
    WHERE 
        s.fiscal_year = 2021
    GROUP BY 
        c.channel
)

SELECT 
    c.channel, 
    c.total_sales AS total_sales_mln, 
    ROUND((c.total_sales / (SUM(c.total_sales) OVER())) * 100, 2) AS percentage
FROM 
    cte c
ORDER BY 
    percentage DESC;
    
#Task-10 Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields, division product_code 
#product total_sold_quantity rank_order

WITH cte AS (
    SELECT 
        p.division, 
        s.product_code, 
        p.product, 
        SUM(sold_quantity) AS total_sold_quantity
    FROM 
        fact_sales_monthly s 
    JOIN 
        dim_product p ON p.product_code = s.product_code
    WHERE 
        s.fiscal_year = 2021
    GROUP BY 
        p.division,
        s.product_code,
        p.product
),

cte1 AS (
    SELECT 
        c.*, 
        DENSE_RANK() OVER(PARTITION BY c.division ORDER BY total_sold_quantity DESC) AS rank_order 
    FROM 
        cte c
)

SELECT 
    c1.* 
FROM 
    cte1 c1
WHERE 
    rank_order < 4;

    

    


    
    
    
  

    
    