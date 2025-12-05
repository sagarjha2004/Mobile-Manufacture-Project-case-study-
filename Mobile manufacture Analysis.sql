
--1 . List all the states in which we have customers who have bought cellphones  
--from 2005 till today.

select distinct IDCustomer, [State],IDModel  from FACT_TRANSACTIONS as T,
DIM_LOCATION as L 
where t.IDLocation= L.IDLocation
and 
Date > '2005-01-01'

--2 . What state in the US is buying the most 'Samsung' cell phones?   
select  top 1Country,State,Model_Name , Count(IDManufacturer)  as Count_phones 
from FACT_TRANSACTIONS as T
inner join DIM_LOCATION as L
on T.IDLocation=L.IDLocation
inner join DIM_MODEL as M
on T.IDModel=M.IDModel
where IDManufacturer=12
and 
Country = 'US'
group by Country,State,Model_Name
order by Count_phones desc


--3 . Show the number of transactions for each model per zip code per state.  

select IDModel,ZipCode,State,count(IDCustomer) as [No.of_trans] 
from FACT_TRANSACTIONS as T, DIM_LOCATION as L
where T.IDLocation= L.IDLocation
group by IDModel,ZipCode,State

--4 . Show the cheapest cellphone (Output should contain the price also) 

select top 1*
from DIM_MODEL
order by Unit_price

--5 . Find out the average price for each model in the top5 manufacturers in  
--terms of sales quantity and order by average price.   

select T.IDModel, Model_name,sum(Quantity) as Tot_qty ,Avg(unit_price) as Avg_price 
from DIM_MODEL as M
inner join FACT_TRANSACTIONS as T
on M.IDModel=T.IDModel
join DIM_MANUFACTURER as t2
on M.IDManufacturer=t2.IDManufacturer
where manufacturer_name in (select  top 5 manufacturer_name 
                               From DIM_MANUFACTURER as M
                               join DIM_MODEL as M2
                               on M.IDManufacturer=M2.IDManufacturer
                               join FACT_TRANSACTIONS as T 
                               on M2.IDModel=T.IDModel
                               group by manufacturer_name
                               order by Sum(TotalPrice)desc
                               )
group by T.IDModel, Model_name
order by Avg_price desc 

--6 . List the names of the customers and the average amount spent in 2009,  
-- where the average is higher than 500  

select Customer_Name,avg(TotalPrice) as Avg_Spent,[Date] from DIM_CUSTOMER as D
join FACT_TRANSACTIONS as T
on D.IDCustomer=T.IDCustomer
where year(date)= 2009
group by Customer_Name,[Date]
having avg(TotalPrice) >500


-- 7 . List if there is any model that was in the top 5 in terms of quantity,  
--simultaneously in 2008, 2009 and 2010 
select * from (

                 select top 5 IDModel
                 from FACT_TRANSACTIONS
                 where year(date)=2008
                 group by IDModel,year(Date)
                 order by sum(Quantity) desc
                  ) as A

intersect

select * from (
                 select top 5 IDModel 
                 from FACT_TRANSACTIONS
                 where year(date)=2009
                 group by IDModel,year(Date)
                 order by sum(Quantity) desc
               ) as B

intersect 

select * from (
                 select top 5 IDModel from FACT_TRANSACTIONS
                 where year(date)=2010
                 group by IDModel,year(Date)
                 order by sum(Quantity) desc
               ) as C

--8 . Show the manufacturer with the 2nd top sales in the year of 2009 and the  
-- manufacturer with the 2nd top sales in the year of 2010.
select * from(
         select top 1 * from(
                   select top 2  Manufacturer_Name,sum(TotalPrice) as Sales ,date 
                   from FACT_TRANSACTIONS as T 
                   join DIM_MODEL as t1
                   on T.IDModel=t1.IDModel
                   join DIM_MANUFACTURER as t2
                   on t1.IDManufacturer=t2.IDManufacturer
                   where year(date)=2009
                   group by Manufacturer_Name,date
                   order by Sales desc
                    ) as S
                   order by sales asc) as T
union
select * from (
        select   top 1 * from(
                   select top 2  Manufacturer_Name,sum(TotalPrice) as Sales,date 
                   from FACT_TRANSACTIONS as T 
                   join DIM_MODEL as t1
                   on T.IDModel=t1.IDModel
                   join DIM_MANUFACTURER as t2
                   on t1.IDManufacturer=t2.IDManufacturer
                   where year(date)=2010
                   group by Manufacturer_Name,date
                   order by Sales desc
                   ) as S
                   order by sales asc) as T

-- 9. Show the manufacturers that sold cellphones in 2010 but did not in 2009.   

     select  Manufacturer_Name from (
                select Manufacturer_Name,sum(TotalPrice) as Sold from FACT_TRANSACTIONS as T
                join DIM_MODEL as M
                on T.IDModel=M.IDModel
                join DIM_MANUFACTURER as M1
                on M.IDManufacturer=M1.IDManufacturer
                where YEAR(Date)=2010
                group by Manufacturer_Name
                ) as A
               
except
      select Manufacturer_Name from (
                select Manufacturer_Name,sum(TotalPrice) as Sold from FACT_TRANSACTIONS as T
                join DIM_MODEL as M
                on T.IDModel=M.IDModel
                join DIM_MANUFACTURER as M1
                on M.IDManufacturer=M1.IDManufacturer
                where YEAR(Date)=2009
                group by Manufacturer_Name
                ) as B
     
--10. Find top 10 customers and their average spend, average quantity by each  
-- year. Also find the percentage of change in their spend. 

select *,((Avg_spend-Prev_values)/Prev_values) as percent_Values from (

 select *,lag(Avg_spend,1) over(partition by idcustomer order by year) as Prev_values 
 from(
                     select IDCustomer,sum(Quantity)as Avg_Qty
                     ,year(Date) as year ,avg(TotalPrice) as Avg_spend
                     from FACT_TRANSACTIONS
                     where IDCustomer in(select  top 10 IDCustomer from FACT_TRANSACTIONS
                                          group by IDCustomer
                                          order by sum(TotalPrice) desc)
                                          group by IDCustomer,year(Date)
                                         ) as C 

                                               ) as D
