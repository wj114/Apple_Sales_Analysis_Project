# To improve query performance
#

#time : 0.3529 sec

Explain Analyze
SELECT *
FROM sales
where store_id = 'ST-31';

create index sales_store_id on sales(store_id(50));
#after indexing time: 0.02802 sec

#Optimization on sale_date column
create index sales_sale_date on sales(sale_date(50));

#-----------BUSINESS PROBLEM---------------------------

# 1. FInd the number of stores in each contry.
select country, count(*) as total_stores
from stores
group by country 
order by total_stores desc;

# 2. Calculate the total number of untis sold in each stores.
select s1.store_id, s2.store_name, sum(quantity) as total_units
from sales as s1
left join stores s2
	on s1.store_id = s2.store_id
group by 1,2
order by 3 desc;

# 3. How many sales occurred in December 2023?
select year(str_to_date(sale_date, '%Y-%m-%d')) as year_2023, count(*)
from sales
where year(str_to_date(sale_date, '%Y-%m-%d'))='2023'
group by 1;

# 4. How many stores have never had a warranty claim filed against any of their products?
select count(distinct store_id)
from stores
where store_id not in (
	select distinct s.store_id 
	from warranty w
	inner join sales s
		on w.sale_id=s.sale_id);

# 5. What percentage of warranty claims are marked as "Warranty Void"?
select ((select count(*) from warranty where repair_status='Warranty Void') *100 / count(*)) as percentage_warranty
from warranty
where repair_status<>'repair_status';

#6. Which store had the highest total units sold in the last year (year 2023)?
select s.store_id, s2.store_name, sum(s.quantity) as total_sales
from sales s
left join stores s2
	on s.store_id = s2.store_id
where year(str_to_date(sale_date,'%Y-%m-%d'))='2023'
group by s.store_id, s2.store_name
order by 3 desc
limit 1;

# 7. Count the number of unique products sold in the last year (2023).
select count(distinct product_id)
from sales
where year(str_to_date(sale_date,'%Y-%m-%d'))='2023';

# 8. What is the average price of products in each category?
select c.category_name, p.category_id, avg(price)
from products p
left join category c
	on p.category_id=c.category_id
group by 1,2
order by 3 desc;

# 9. How many warranty claims were filed in 2020?
select count(*)
from warranty
where year(str_to_date(claim_date,'%Y-%m-%d'))='2020';

# 10. Identify each store and best selling day based on highest qty sold.
with cte as 
(select store_id, dayname(sale_date) as day_of_week, sum(quantity) as total_quantity_sold,
	rank() over (partition by store_id order by sum(quantity) desc ) as rnk
from sales
group by store_id, dayname(sale_date))

select store_id, day_of_week, total_quantity_sold
from cte
where rnk=1;

# 11. Identify least selling product of each country for each year based on total unit sold.
with cte as
(select st.country, s.product_id,sum(quantity) as total_sold,
	rank()over(partition by st.country order by sum(quantity)) as rnk
from sales s
left join stores st
	on s.store_id = st.store_id
group by st.country, s.product_id)

select country, c.product_id, p.product_name, total_sold
from cte c
left join products p
   on c.product_id =p.product_id 
where rnk=1;

# 12. How many warranty claims were filed within 180 days of a product sale?
select w.sale_id, s.sale_date, w.claim_date, repair_status
from warranty w
left join sales s
	on w.sale_id=s.sale_id
where datediff(claim_date, sale_date)<=180;   #all the warranty claims within 180 days

select count(*)
from warranty w
left join sales s
	on w.sale_id=s.sale_id
where datediff(claim_date, sale_date)<=180; # the total claims within 180 days

# 13. How many warranty claims have been filed for products launched in the last two years?
select * #total list
from warranty
where claim_date between curdate()- interval 2 year and curdate()
order by claim_date;

select count(*) #total count
from warranty
where claim_date between curdate()- interval 2 year and curdate()
order by claim_date; 

# 14. List the months in the last 3 years where sales exceeded 5000 units from usa.
select  month(str_to_date(sale_date,'%Y-%m-%d')) as each_month ,sum(s.quantity) as total_sold
from sales s
left join stores s2
	on s.store_id = s2.store_id
where s.sale_date between curdate()- interval 3 year and curdate() and s2.country= 'USA'
group by 1
having sum(quantity)>=5000;

# 15. Which product category had the most warranty claims filed in the last 2 years (2022-2023)?
select c.category_name, count(*) 
from warranty w
left join sales s
	on w.sale_id=s.sale_id
left join products p
	on s.product_id =p.product_id
left join category c
	on p.category_id = c.category_id
where claim_date between curdate()-interval 2 year and curdate()
group by c.category_name
order by 2 desc;


# 16. Determine the percentage chance of receiving claims after each purchase for each country.
select s2.country, sum(s.quantity) as total_unit_sold ,count(w.claim_id) as total_claim, 
	(count(w.claim_id) *100 /sum(s.quantity)) as percentage_claim
from sales s
left join stores s2
	on s.store_id = s2.store_id
left join warranty w
	on s.sale_id = w.sale_id
group by 1
order by 3 desc;


# 17. Analyze each stores year by year growth ratio
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

#18. What is the correlation between product price and warranty claims for products sold in the last five years? (Segment based on diff price)

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
group by 1;

# 19. Identify the store with the highest percentage of "Paid Repaired" claims in relation to total claims filed.
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
	on c1.store_id = st.store_id;
    
# 20. Write SQL query to calculate the monthly running total (cumulative) of sales for each store over the past four years 
#     and compare the trends across this period?
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

# 21. Analyze sales trends of product over time, segmented into key time periods: 
#     from launch to 6 months, 6-12 months, 12-18 months, and beyond 18 months?

select  p.product_name, 
	case 
		when s.sale_date between p.launch_date and p.launch_date + interval 6 month then '0-6 Month'
        when s.sale_date between p.launch_date + interval 6 month and p.launch_date + interval 12 month then '6-12 Month'
        when s.sale_date between p.launch_date + interval 12 month and p.launch_date + interval 18 month then '12-18 Month'
        else 'Beyond 18 Month'
	end as time_periods,
    sum(s.quantity) as total_quantity_sale
    
from sales s
left join products p
	on s.product_id = p.product_id
group by 1,2
order by 1,2


