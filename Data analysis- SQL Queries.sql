-- Codebasics SQL Challenge

-- Request 1: Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT DISTINCT market 
FROM dim_customer
WHERE customer = 'Atliq Exclusive' 
  AND region = 'APAC';

-- Request 2: Calculate the percentage of unique product increase in 2021 vs. 2020.
WITH unique_product_in_2020 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2020
    FROM fact_sales_monthly 
    WHERE fiscal_year = 2020
),
unique_product_in_2021 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2021
    FROM fact_sales_monthly 
    WHERE fiscal_year = 2021
)
SELECT
    unique_products_2020,
    unique_products_2021,
    ROUND((unique_products_2021 - unique_products_2020) * 100.0 / unique_products_2020, 2) AS percentage_chg
FROM unique_product_in_2020 
JOIN unique_product_in_2021;

-- Request 3: Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
SELECT
    dim_product.segment, 
    COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- Request 4: Which segment had the most increase in unique products in 2021 vs 2020?
WITH product_in_2020 AS (
    SELECT 
        a.segment,
        COUNT(DISTINCT a.product_code) AS product_count_2020
    FROM dim_product a
    JOIN fact_sales_monthly b 
        ON a.product_code = b.product_code
    WHERE fiscal_year = 2020
    GROUP BY segment
),
product_in_2021 AS (
    SELECT 
        a.segment,
        COUNT(DISTINCT a.product_code) AS product_count_2021
    FROM dim_product a
    JOIN fact_sales_monthly b 
        ON a.product_code = b.product_code
    WHERE fiscal_year = 2021
    GROUP BY segment
)
SELECT
    product_in_2021.segment,
    product_count_2020,
    product_count_2021,
    product_count_2021 - product_count_2020 AS difference
FROM product_in_2021 
JOIN product_in_2020 
    ON product_in_2021.segment = product_in_2020.segment
ORDER BY difference DESC;

-- Request 5: Get the products that have the highest and lowest manufacturing costs.
SELECT 
    a.product_code,
    a.product,
    b.manufacturing_cost 
FROM dim_product a
JOIN fact_manufacturing_cost b USING(product_code)
WHERE
    b.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost) 
    OR
    b.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
ORDER BY b.manufacturing_cost DESC;

-- Request 6: Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
SELECT 
    a.customer_code,
    a.customer,
    AVG(b.pre_invoice_discount_pct) AS average_discount_percentage
FROM dim_customer a
JOIN fact_pre_invoice_deductions b USING (customer_code)
WHERE a.market = 'India' 
  AND b.fiscal_year = 2021
GROUP BY 
    a.customer_code,
    a.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

-- Request 7: Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.
SELECT 
    MONTHNAME(a.date) AS month,
    a.fiscal_year AS year,
    ROUND(SUM(a.sold_quantity * b.gross_price), 2) AS gross_sales_amount
FROM fact_sales_monthly a
JOIN fact_gross_price b USING(product_code)
JOIN dim_customer c USING (customer_code)
WHERE c.customer = 'Atliq Exclusive'
GROUP BY 
    year, month
ORDER BY gross_sales_amount DESC;

-- Request 8: In which quarter of 2020, got the maximum total_sold_quantity?
SELECT 
    CASE
        WHEN MONTH(a.date) IN (9,10,11) THEN 'Q1'
        WHEN MONTH(a.date) IN (12,1,2) THEN 'Q2'
        WHEN MONTH(a.date) IN (3,4,5) THEN 'Q3'
        ELSE 'Q4'
    END AS quarter,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly a
WHERE fiscal_year = 2020
GROUP BY quarter
ORDER BY total_sold_quantity DESC;

-- Request 9: Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
WITH cte AS (
    SELECT 
        c.channel, 
        ROUND(SUM((a.sold_quantity * b.gross_price) / 1000000), 2) AS gross_sales_mln 
    FROM fact_sales_monthly a 
    JOIN fact_gross_price b USING(product_code) 
    JOIN dim_customer c USING(customer_code) 
    WHERE a.fiscal_year = 2021 
    GROUP BY c.channel
    ORDER BY gross_sales_mln DESC
) 
SELECT 
    cte.channel,
    cte.gross_sales_mln,
    ROUND((cte.gross_sales_mln * 100 / SUM(cte.gross_sales_mln) OVER()), 2) AS percentage_contribution 
FROM cte
ORDER BY percentage_contribution DESC;

-- Request 10: Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021.
WITH cte AS (
    SELECT 
        a.division, 
        a.product, 
        a.product_code, 
        SUM(b.sold_quantity) AS total_sold 
    FROM dim_product a 
    JOIN fact_sales_monthly b USING(product_code) 
    WHERE fiscal_year = 2021
    GROUP BY 
        a.division, 
        a.product, 
        a.product_code 
    ORDER BY total_sold DESC
), 
rank_cte AS (
    SELECT 
        cte.*, 
        ROW_NUMBER() OVER (PARTITION BY cte.division ORDER BY total_sold DESC) AS rank_order 
    FROM cte
) 
SELECT 
    division,
    product_code,
    product,
    total_sold AS total_sold_quantity,
    rank_order
FROM rank_cte 
WHERE rank_order <= 3;
