# Apple_Sales_Analysis_Project

## Project Overview
This project is being designed to showcase advanced SQL querying techniques through the analysis of over 1 million rows of Apple retail sales data. The dataset is being analyzed to include information about products, stores, sales transactions, and warranty claims across various Apple retail locations globally. A variety of questions, from basic to complex, are being tackled to demonstrate the ability to write sophisticated SQL queries that extract valuable insights from large datasets.

## Project Focus

This project primarily focuses on developing and showcasing the following SQL skills:
- **Complex SQL joins and aggregations:** The ability to perform complex SQL joins and aggregate data meaningfully is being demonstrated.
- **Window Functions:** Advanced window functions are being used for calculating running totals, conducting growth analysis, and performing time-based queries.
- **Data Segmentation:** Data is being analyzed across different time frames to gain insights into product performance.
- **Correlation Analysis:** Relationships between key variables, such as pricing and warranty claims, are being explored using SQL functions.
- **Real-World Problem Solving:** Business challenges resembling real-world data analyst tasks are being addressed through practical SQL applications.


## Entity Relationship Diagram (ERD)

![ERD](https://github.com/najirh/Apple-Retail-Sales-SQL-Project---Analyzing-Millions-of-Sales-Rows/blob/main/erd.png)

## Dataset

- **Size**: 1 million+ rows of sales data.
- **Period Covered**: The data spans multiple years, allowing for long-term trend analysis.
- **Geographical Coverage**: Sales data from Apple stores across various countries.

## Buisness Questions

The project is divided into three levels of questions, each designed to assess SQL skills of increasing complexity. SQL queries addressing complex business problems are presented to demonstrate the capability to solve challenging issues.

### Easy to Medium (10 Questions)

1. Find the number of stores in each country.
2. Calculate the total number of units sold by each store.
3. Identify how many sales occurred in December 2023.
4. Determine how many stores have never had a warranty claim filed.
5. Calculate the percentage of warranty claims marked as "Warranty Void".
6. Identify which store had the highest total units sold in the last year.
7. Count the number of unique products sold in the last year.
8. Find the average price of products in each category.
9. How many warranty claims were filed in 2020?
10. For each store, identify the best-selling day based on highest quantity sold.

### Medium to Hard (5 Questions)

11. Identify the least selling product in each country for each year based on total units sold.
12. Calculate how many warranty claims were filed within 180 days of a product sale.
13. Determine how many warranty claims were filed for products launched in the last two years.
14. List the months in the last three years where sales exceeded 5,000 units in the USA.
15. Identify the product category with the most warranty claims filed in the last two years.

### Complex (6 Questions)

16. Determine the percentage chance of receiving warranty claims after each purchase for each country.
``` sql
select s2.country, sum(s.quantity) as total_unit_sold ,count(w.claim_id) as total_claim, 
	(count(w.claim_id) *100 /sum(s.quantity)) as percentage_claim
from sales s
left join stores s2
	on s.store_id = s2.store_id
left join warranty w
	on s.sale_id = w.sale_id
group by 1
order by 3 desc;
```
17. Analyze the year-by-year growth ratio for each store.
```sql
with cte as
(select  s.store_id, st.store_name ,year(str_to_date(sale_date,'%Y-%m-%d'))as extracted_year,sum(s.quantity * p.price) as total_price
from sales s
left join products p
	on s.product_id = p.product_id
left join stores st
	on s.store_id =st.store_id
group by 1,2,3
order by 2,3),

cte2 as
(select store_name,extracted_year , 
	lag(total_price,1) over (partition by store_name order by extracted_year) as previous_year_sales,
    total_price as current_year_sales
from cte)

select store_name,extracted_year, previous_year_sales,current_year_sales, 
	((current_year_sales-previous_year_sales)*100/previous_year_sales) as growth_ratio
from cte2
where previous_year_sales is not null;
```
18. Calculate the correlation between product price and warranty claims for products sold in the last five years, segmented by price range.
```sql
select 
	case
		when p.price < 500 then "Less Expensive Product"
		when p.price between 500 and 1000 then ' Mid Range Product'
        else 'Expensive Prouct'
	end as price_segment,
	count(w.claim_id) as total_claim
from warranty w
left join sales s
	on w.sale_id=s.sale_id
left join products p
	on p.product_id = s.product_id
where claim_date between curdate() - interval 5 year and curdate()
```
19. Identify the store with the highest percentage of "Paid Repaired" claims relative to total claims filed.
```sql
with cte as
(select s.store_id,count(distinct claim_id) as total_paid_repaired
from warranty w
left join sales s
	on s.sale_id = w.sale_id
where repair_status='Paid Repaired'
group by 1),

cte2 as
(select s.store_id,count(distinct claim_id) as total_repaired
from warranty w
left join sales s
	on s.sale_id = w.sale_id
group by 1)

select c1.store_id, st.store_name, c1.total_paid_repaired, c2.total_repaired, (c1.total_paid_repaired *100/ c2.total_repaired) as paid_ratio
from cte c1
left join cte2 c2
	on c1.store_id = c2.store_id
left join stores st
```

20. Write a query to calculate the monthly running total (cumulative) of sales for each store over the past four years and compare trends during this period.
```sql
with cte as
(select s.store_id, year(str_to_date(s.sale_date, '%Y-%m-%d')) as sale_year, month(str_to_date(s.sale_date, '%Y-%m-%d')) as sale_month, sum(s.quantity * p.price) as total
from sales s
left join products p
	on s.product_id = p.product_id
group by 1,2,3
order by 1,2,3)

select *,
	sum(total) over(partition by store_id order by sale_year, sale_month) as running_total
from cte;
```
21. Analyze product sales trends over time, segmented into key periods: from launch to 6 months, 6-12 months, 12-18 months, and beyond 18 months.
```sql
select  p.product_name, 
	case 
		when s.sale_date between p.launch_date and p.launch_date + interval 6 month then '0-6 Month'
        when s.sale_date between p.launch_date + interval 6 month and p.launch_date + interval 12 month then '6-12 Month'
        when s.sale_date between p.launch_date + interval 12 month and p.launch_date + interval 18 month then '12-18 Month'
        else 'Beyong 18 Month'
	end as time_periods,
    sum(s.quantity) as total_quantity_sale
    
from sales s
left join products p
	on s.product_id = p.product_id
group by 1,2
order by 1,2
```
## Conclusion

By completing this project, I have developed advanced SQL querying skills, enhanced my ability to manage large datasets, and gained practical experience in solving complex data analysis challenges essential for informed business decision-making.
