# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT
	market,
	customer,
    region
FROM 
	dim_customer c
WHERE 
	customer LIKE "%Atliq Exclusive%"
AND
	region="APAC";

# 2. What is the percentage of unique product increase in 2021 vs. 2020?

WITH unique_products_2020 AS (SELECT 
	COUNT(DISTINCT p.product_code) AS unique_products_2020
	FROM fact_sales_monthly s
	join dim_product p
		on s.product_code=p.product_code
where fiscal_year=2020), unique_products_2021 AS (SELECT 
	COUNT(DISTINCT p.product_code) AS unique_products_2021
	FROM fact_sales_monthly s
	join dim_product p
		on s.product_code=p.product_code
where fiscal_year=2021
)
SELECT 
  unique_products_2020, 
  unique_products_2021, 
  ROUND((unique_products_2021 - unique_products_2020)/unique_products_2020*100,2) AS percentage_chg
FROM 
	unique_products_2020, 
	unique_products_2021;

# 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.

SELECT 
	p.segment as segment,
	COUNT(distinct(p.product_code)) as product_count
FROM 
	dim_product p
GROUP BY 
	segment
ORDER BY 
	product_count desc;

# 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?

with product_count_2020 as (SELECT 
		p.segment as segment,
		COUNT(distinct(p.product_code)) as product_count_2020
		FROM dim_product p
		join fact_sales_monthly s
			on p.product_code=s.product_code
		where fiscal_year=2020
group by segment), product_count_2021 as (SELECT 
		p.segment as segment,
		COUNT(distinct(p.product_code)) as product_count_2021
		FROM dim_product p
		join fact_sales_monthly s
			on p.product_code=s.product_code
		where fiscal_year=2021
group by segment)

SELECT 
	product_count_2020.segment,
	product_count_2020,
	product_count_2021,
	(product_count_2021.product_count_2021-product_count_2020.product_count_2020) as Difference
FROM product_count_2020
JOIN product_count_2021
	ON product_count_2020.segment=product_count_2021.segment
ORDER BY Difference desc;

# 5. Get the products that have the highest and lowest manufacturing costs.

SELECT 
	p.product_code,
    p.product,
    manufacturing_cost
FROM dim_product p
join fact_manufacturing_cost c
	on c.product_code=p.product_code
where manufacturing_cost in (    
	(select max(manufacturing_cost) from fact_manufacturing_cost),
	(select min(manufacturing_cost) from fact_manufacturing_cost))
order by manufacturing_cost desc;

# 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.

SELECT 
	d.customer_code,
    c.customer,
    ROUND(avg(pre_invoice_discount_pct*100),2) as avg_discount_pct
FROM fact_pre_invoice_deductions d
JOIN dim_customer c 
	ON c.customer_code=d.customer_code
WHERE fiscal_year=2021 
AND market="India"
group by customer
order by avg_discount_pct desc
LIMIT 5;

# 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.

SELECT 
	MONTHNAME(s.date) as Month,
	YEAR(s.date) AS Year,
    round(sum(sold_quantity*gross_price)/1000000,2) as gross_sales_mln
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON 
	g.product_code=s.product_code
JOIN dim_customer c
ON 
	c.customer_code=s.customer_code
where customer="Atliq Exclusive"
group by Month, Year
order by Year;

# 8.  In which quarter of 2020, got the maximum total_sold_quantity?

SELECT 
	CASE
			WHEN month(date) in (9,10,11) THEN "Q1"
			WHEN month(date) in (12,1,2) THEN "Q2"
			WHEN month(date) in (3,4,5) THEN "Q3"
			ELSE "Q4"
	END as Quarter,
Round(sum(sold_quantity)/1000000,2) as total_sold_quantity_mln
FROM fact_sales_monthly
WHERE fiscal_year=2020
GROUP BY Quarter
ORDER BY total_sold_quantity_mln desc;

# 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 

with cte1 as (SELECT
	c.channel,
    ROUND(sum(fs.sold_quantity*g.gross_price)/1000000,2) as gross_sales_mln
FROM 
	dim_customer c
JOIN 
	fact_sales_monthly fs
ON 
	fs.customer_code=c.customer_code
JOIN
	fact_gross_price g
ON 
	g.product_code=fs.product_code
WHERE 
	fs.fiscal_year=2021
GROUP BY
	channel
ORDER BY
	gross_sales_mln desc)
    
SELECT 
	channel,
    gross_sales_mln,
    ROUND(gross_sales_mln*100/sum(gross_sales_mln) over(),2) as percentage
FROM 
	cte1;
    
# 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?

with cte1 as (SELECT 
	p.division,
	p.product_code,
    p.product,
    sum(s.sold_quantity) as total_sold_quantity
FROM 
	dim_product p
JOIN
	fact_sales_monthly s
ON 
	s.product_code=p.product_code
WHERE s.fiscal_year=2021
GROUP BY division,product,product_code),
    
cte2 as (SELECT*,
	    dense_rank() over(partition by division ORDER BY Total_sold_quantity desc) as drnk
FROM cte1)

SELECT
	*
FROM cte2
WHERE drnk<=3;