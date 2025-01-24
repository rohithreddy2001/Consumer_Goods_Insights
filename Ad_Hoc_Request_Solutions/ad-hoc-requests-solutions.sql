
-- Business Request - 1

SELECT DISTINCT
    market
FROM
    dim_customer
WHERE
    customer = 'Atliq Exclusive'
        AND region = 'APAC';
        
-- Business Request - 2

WITH cte AS (select
(SELECT 
    COUNT(product_code)
FROM
    fact_manufacturing_cost
WHERE
    cost_year = 2020) as unique_products_2020,
(SELECT 
    COUNT(product_code)
FROM
    fact_manufacturing_cost
WHERE
    cost_year = 2021) as unique_products_2021
)

SELECT 
    unique_products_2020,
    unique_products_2021,
    ROUND(((unique_products_2021 - unique_products_2020) / unique_products_2020) * 100, 2) AS percentage_change
FROM
    cte;
    
-- Business Request - 3

SELECT 
    segment, COUNT(product_code) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY COUNT(product_code) DESC;

-- Business Request - 4

WITH cte AS (
SELECT 
    segment,
    SUM(CASE
        WHEN cost_year = 2020 THEN 1
        ELSE 0
    END) AS product_count_2020,
    SUM(CASE
        WHEN cost_year = 2021 THEN 1
        ELSE 0
    END) AS product_count_2021
FROM
    dim_product dp
        INNER JOIN
    fact_manufacturing_cost fmc ON dp.product_code = fmc.product_code
GROUP BY segment
)

SELECT 
    segment,
    product_count_2020,
    product_count_2021,
    ROUND(((product_count_2021 - product_count_2020) / product_count_2020) * 100, 2) AS difference
FROM
    cte;
    
-- Business Request - 5

SELECT 
    fmc.product_code, dp.product, fmc.manufacturing_cost
FROM
    fact_manufacturing_cost fmc
        INNER JOIN
    dim_product dp ON fmc.product_code = dp.product_code
WHERE
    fmc.manufacturing_cost = (SELECT 
            MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
        OR fmc.manufacturing_cost = (SELECT 
            MIN(manufacturing_cost)
        FROM
            fact_manufacturing_cost);
            
-- Business Request - 6

SELECT 
    fpid.customer_code,
    dc.customer,
    AVG(fpid.pre_invoice_discount_pct) AS average_discount_percentage
FROM
    fact_pre_invoice_deductions fpid
        INNER JOIN
    dim_customer dc ON fpid.customer_code = dc.customer_code
WHERE
    fiscal_year = 2021
        AND dc.market = 'India'
GROUP BY fpid.customer_code , dc.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

-- Business Request - 7

SELECT 
    MONTH(fsm.date) AS month,
    YEAR(fsm.date) AS year,
    ROUND(SUM(fsm.sold_quantity * fgp.gross_price), 2) AS gross_sales_amount
FROM
    fact_sales_monthly fsm
        INNER JOIN
    fact_gross_price fgp ON fsm.product_code = fgp.product_code
        INNER JOIN
    dim_customer dc ON fsm.customer_code = dc.customer_code
WHERE
    dc.customer = 'Atliq Exclusive'
GROUP BY MONTH(fsm.date) , YEAR(fsm.date)
ORDER BY month , year;
    
-- Business Request - 8

SELECT 
    CASE
        WHEN
            MONTH(date) = 9 OR MONTH(date) = 10 OR MONTH(date) = 11
        THEN 1
        WHEN
            MONTH(date) = 12 OR MONTH(date) = 1 OR MONTH(date) = 2
        THEN 2
        WHEN
            MONTH(date) = 3 OR MONTH(date) = 4 OR MONTH(date) = 5
        THEN 3
        ELSE 4
    END AS quarter,
    SUM(sold_quantity) AS total_sold_quantity
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020
GROUP BY quarter
ORDER BY total_sold_quantity DESC;

-- Business Request - 9

WITH gross_sales AS (
SELECT 
    dc.channel,
    SUM(fsm.sold_quantity * fgp.gross_price) AS gross_sales_mln,
    DENSE_RANK() OVER(ORDER BY SUM(fsm.sold_quantity * fgp.gross_price) DESC) AS ranking
FROM
    dim_customer dc
        INNER JOIN
    fact_sales_monthly fsm ON fsm.customer_code = dc.customer_code
        INNER JOIN
    fact_gross_price fgp ON fgp.product_code = fsm.product_code
WHERE
    fsm.fiscal_year = 2021
GROUP BY dc.channel
ORDER BY gross_sales_mln DESC
), total_sales AS (
SELECT 
    SUM(gross_sales_mln) AS total
FROM
    gross_sales
)

SELECT 
    channel,
    ROUND(gross_sales_mln, 2) as gross_sales_mln,
    ROUND((gross_sales_mln / ts.total) * 100.0, 2) AS percentage_contribution
FROM
    gross_sales gs,
    total_sales ts
WHERE gs.ranking = 1;

-- Business Request - 10

WITH cte AS (
SELECT 
	dp.division, 
    dp.product_code, 
    dp.product, 
    SUM(fsm.sold_quantity) AS total_sold_quantity,
	DENSE_RANK() OVER(PARTITION BY dp.division ORDER BY SUM(fsm.sold_quantity) DESC) AS rank_order
FROM 
	dim_product dp 
INNER JOIN 
	fact_sales_monthly fsm ON fsm.product_code = dp.product_code
WHERE 
	fsm.fiscal_year = 2021
GROUP BY dp.division, dp.product_code, dp.product
)

SELECT 
    division,
    product_code,
    product,
    total_sold_quantity,
    rank_order
FROM
    cte
WHERE
    rank_order <= 3;


