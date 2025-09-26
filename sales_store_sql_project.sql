create table sales_store(
transaction_id varchar(15),
customer_id varchar(15),
customer_name varchar(30),
customer_age int,
gender varchar(15),
product_id varchar(15),
product_name varchar(15),
product_category varchar(15),
quantiy int,
prce float,
payment_mode varchar(15),
purchase_date date,
time_of_purchase time,
status varchar(15)
);                           -- imorting data STEP -2
bulk insert sales_store
from 'C:\Users\JESUS\OneDrive\Desktop\code\sql_project1.csv'
	with (
		rowterminator='\n',
		fieldterminator=',',
		firstrow=2
		);
select * from sales_store;
--Now Data Cleaning STEP -3
-- first copy the data into new table
select * into sales_pt from sales_store;
select * from sales_pt;
select * from sales_store;
-- STEP 1: Finding Duplicates
select transaction_id,count(*) from sales_pt
group by transaction_id
having count(transaction_id)>1;
with cte as (
select *,row_number() over(partition by transaction_id 
order by transaction_id) as rownum 
from sales_pt
)
SELECT * FROM CTE WHERE TRANSACTION_ID IN('TXN240646',
'TXN342128',
'TXN855235',
'TXN981773');
-- delete from cte where rownum=2;
select * from cte 
where rownum>1;

-- STEP 2: Correction oh Headers
exec sp_rename 'sales_pt.prce','price','column';
exec sp_rename 'sales_pt.quantiy','quantity','column';
select * from sales_pt;

-- Check Datatype
select column_name,data_type from information_schema.columns
where table_name='sales_pt'

-- Step 4: Checking Null Values
DECLARE @sales_pt NVARCHAR(128) = 'sales_pt';
DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql = @sql + 
    'SELECT ''' + COLUMN_NAME + ''' AS ColumnName, COUNT(*) - COUNT([' + COLUMN_NAME + ']) AS NullCount FROM ' + @sales_pt + ' UNION ALL '
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @sales_pt;

-- Remove last 'UNION ALL'
SET @sql = LEFT(@sql, LEN(@sql) - 10);

EXEC sp_executesql @sql;

-- part 2: Treating Null Values
select * from sales_pt
where transaction_id is null
or customer_id is null
or customer_name is null
or customer_age is null
or product_id is null
or product_name is null
or product_category is null
or quantity is null
or price is null 
or payment_mode is null
or purchase_date is null
or time_of_purchase is null
or status is null;

delete from sales_pt where transaction_id is null

select * from sales_pt 
where customer_name='damini raju'

update sales_pt
set customer_id='CUST1401'
WHERE customer_name='damini raju';

select * from sales_pt 
where customer_id='cust1003'

update sales_pt
set customer_name='mahika saini',customer_age=35,gender='male'
WHERE customer_id='cust1003';

select * from sales_pt;

-- Step 3: Data Cleaning
-- for gender and payment_mode
select distinct gender from sales_pt;
update sales_pt
set gender='M'
where gender='male';

update sales_pt
set gender='F'
where gender='Female'

select distinct payment_mode from sales_pt

update sales_pt
set payment_mode='Credit Card'
where payment_mode='cc'

select * from sales_pt;

-- Step 4: Data Analysis
-- Solving Bussiness Insights Questions
-- Q1. what are the top 5 most selling products by quantity?
select product_name,sum(quantity) as total_quantity_sold
from sales_pt
group by product_name 

select distinct status from sales_pt

select top 5 product_name,sum(quantity) as total_quantity_sold
from sales_pt
where status='delivered'
group by product_name 
order by total_quantity_sold desc

-- Bussiness Problem: We don't which products have most in demand.

-- Bussiness Impact: Helps Prioritize stock and boost sales through targeted promotions.

----------------------------------------------------------------------------------------------------------------------
-- Q2. Which products are most frequently cancelled?
select top 5 product_name,count(*) as total_cancelled from sales_pt
where status='cancelled'
group by product_name
order by total_cancelled desc

-- Bussiness Problem: Frequent cancellation revenue and customer trust.

-- Bussiness Impact: Identify poor_performing products to improve quality or remove from catalog.

----------------------------------------------------------------------------------------------------------------------------
-- Q3. What time of the day has the highest number of purchases?
select * from sales_pt

select 
	case
		when datepart(hour,time_of_purchase) between 0 and 5 then 'Night'
		when datepart(hour,time_of_purchase) between 6 and 11 then 'Morning'
		when datepart(hour,time_of_purchase) between 12 and 17 then 'Afternoon'
		when datepart(hour,time_of_purchase) between 18 and 23 then 'Evening'
        end as time_of_day,
		count(*) as total_orders 
		from sales_pt
		group by 
		case
		when datepart(hour,time_of_purchase) between 0 and 5 then 'Night'
		when datepart(hour,time_of_purchase) between 6 and 11 then 'Morning'
		when datepart(hour,time_of_purchase) between 12 and 17 then 'Afternoon'
		when datepart(hour,time_of_purchase) between 18 and 23 then 'Evening'
        end
order by total_orders desc

-- Bussiness Problem: Find peak sales time.

-- Bussiness Impact: Optimize staffing, Promotion and Server loads.

------------------------------------------------------------------------

-- Q4.Who are the top 5 highest spending customers.
select * from sales_pt 

select top 5 customer_name,
format(sum(price*quantity),'c0','en-in') as total_spending --N=number format  0=no decimal space
from sales_pt             -- c= currrency
group by customer_name
order by sum(price*quantity) desc 

-- Bussiness Problem: Identify VIP Customers

-- Bussiness Impact: Personalized Offers,loyality Rewards and rentention.
 
 ----------------------------------------------------------------------------------------

 -- Q5. Which product categories generate highest revenue?
 select * from sales_pt

 select product_category,format(sum(price*quantity),'c0','en-in')
 as revenue
 from sales_pt
 group by product_category
 order by sum(price*quantity) desc;

 -- Bussiness Problem: Identify top-performing product categories.

 -- Bussiness impact: Refine about strategy,supply chain and promotions.
 -- allowing the bussiness to invest more in higher margin or high demand categories.

 -----------------------------------------------------------------------------------------------------------
 -- Q6.What is the return/cancellation rate per product category?
 select * from sales_pt 
 -- cancelation
 select product_category,
 format(count(case when status='cancelled' then 1 end)*100.0/count(*),'n3')+' %' as total_cancelled
 from sales_pt
 group by product_category
 order by total_cancelled desc

 -- returned
 select product_category,
 format(count(case when status='returned' then 1 end)*100.0/count(*),'n3')+' %' as total_returned
 from sales_pt
 group by product_category
 order by total_returned desc

-- Business Problem: Monitor dissatisfaction trends per category

-- Business Impact: reduce returns,improve product descriptions/expectations.
-- Helps identity and fix product or logistics issues.

-- Q7.What is the most preferred payment mode?
select payment_mode,count(payment_mode) as preferred_mode from sales_pt
group by payment_mode
order by preferred_mode desc

-- Business Problem: Know which payment options customers prefer.

-- Bussiness Impact: Streamline payment processing,priortize popular payment modes.

-----------------------------------------------------------------------------------------------------
-- Q8. How does age group affect purchasing behaviour?
select * from sales_pt
select max(customer_age) as max_age,min(customer_age) as min_age from sales_pt;
select 
	case
		when customer_age between 18 and 25 then '18-25'
		when customer_age between 26 and 35 then '26-35'
		when customer_age between 36 and 50 then '36-50'
		else '51+'
		end as customer_age,
	format(sum(price*quantity),'c0','en-in') as total_purchase
from sales_pt
group by case
		when customer_age between 18 and 25 then '18-25'
		when customer_age between 26 and 35 then '26-35'
		when customer_age between 36 and 50 then '36-50'
		else '51+'
		end
order by sum(price*quantity) desc

-- Bussiness Problem: Understand customer demographics.

-- Bussiness Impact: Targeted Marketing and recommendations by age group.

--------------------------------------------------------------------------------------
-- Q9. What's the monthly sales trend?
select * from sales_pt
-- Method 1
select format(purchase_date,'yyyy-MM') as month_year,
format(sum(price*quantity),'c0','en-in') as total_sales,
sum(quantity) as total_quantity
from sales_pt
group by format(purchase_date,'yyyy-MM')

-- Method 2
select --year(purchase_date) as Years,	
	   month(purchase_date) as months,
	   format(sum(price*quantity),'c0','en-in') as total_sales,
	   sum(quantity) as total_quantity
	   from sales_pt
	   group by /*year(purchase_date),*/month(purchase_date)
	   order by months
-- 2023 46,28,608
-- 2024 3,39,442
select(4628608+339442);

-- Bussiness Problem: Sales fluctuations go unnoticed.

-- Bussiness Impact: Plan inventory and marketing according to seasonal trends.

------------------------------------------------------------------------------------------------------------
-- Q10.Are certain genders buying more specific product categories?
select * from sales_pt

-- Method 1
select gender, product_category,count(product_category)
from sales_pt
group by gender, product_category
order by gender

-- Method 2
select * from
(
  select gender,product_category from sales_pt
) as sales
pivot(
	count(gender)
	for gender in ([M],[F])
	) as pivot_table
order by product_category

-- Bussiness Problem: Gender based product preferences.

-- Bussiness Impact: Personalized adds, gender focused campaigns.