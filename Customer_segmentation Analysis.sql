select * from sales_fact;


with months as (
select date_format(max(order_date), '%Y-%m-01') as current_month,
	 date_sub(date_format(max(order_date), '%Y-%m-01'), interval 1 month ) as last_month,
     date_sub(date_format(max(order_date), '%Y-%m-01'), interval 2 month ) as before_last_month
     from sales_fact),
     
customer_order as (
select customer_id, date_format(order_date,'%Y-%m-01') as month
from sales_fact
group by 1,2),

customer_segmentation as (
select c.customer_id,
	max(case when c.month = m.current_month then 1 else 0 end) as current_flag,
    max(case when c.month = m.last_month then 1 else 0 end) as last_flag,
    max(case when c.month < m.last_month then 1 else 0 end) as before_last_flag
 from customer_order c
 cross join months m
 group by 1 
 order by 1
 ),
 
 final_segment as (
 select c.* ,
		case when current_flag =1 and last_flag =1 and before_last_flag =1 then "Retained"
			when current_flag =1 and last_flag =0 and before_last_flag =1 then "Returning"
            when current_flag =1 and last_flag =0 and before_last_flag =0 then "New"
            when current_flag =0 and last_flag =1 and before_last_flag =0 then "Churned"
			when current_flag =0 and last_flag =0 and before_last_flag =0 then "Retained"
            else "others" end as customer_segment
from customer_segmentation c
)
select f.customer_segment, 
		count(*)/(select count(*) from final_segment f)*100 as percent_count
from final_segment f
group by customer_segment
order by percent_count;

 
 -- %of Customer Satisfaction
 
 with cte as (
 select customer_id,delivery_proposed_date,delivery_date,
		timestampdiff(day,delivery_proposed_date,delivery_date) as lead_day
 from sales_fact),

cte1 as (
 select * ,
     case when lead_day <=0 then "satisfied" else "desatisfied" end as satisfaction_categeory
 from cte)
 
 select satisfaction_categeory, count(*) as Total_customer,
		round(count(*)/(select count(*) from cte),1)*100 as percentage
 from cte1 
 group by 1
 
 
 
 
 
 