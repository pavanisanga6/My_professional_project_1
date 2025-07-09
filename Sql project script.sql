create database Zomotoproject;
use zomotoproject;
##load main,calendar,country,currency tables
##truncate main;
##select @@secure_file_priv;
load data infile "C:/Main.csv" into table main
fields terminated by ','
ignore 1 lines;

##1. data cleaning
select * from main;
select * from calendar;
select * from country;
select * from currency;
alter table main rename column ï»¿RestaurantID to Restaurant;
alter table main rename column Restaurant to RestaurantID;
alter table country rename column ï»¿CountryID to CountryID;
alter table calendar rename column ï»¿RestaurantID to RestaurantID;
alter table currency rename column ï»¿Currency to Currency;
## joins 
select * from main join currency on main.Currency=Currency.Currency;
select * from main join country on main.CountryCode=Country.CountryID;
select * from main left join calendar on main.date=Calendar.datekey 
                    union all
                    select * from main right join calendar on main.date=Calendar.datekey; 
                    
## 2. Creating Calendar table columns
select DateKey, year(DateKey) as Year, month(DateKey) as monthno,monthname(DateKey) as monthfullname,
                  (concat("Q",quarter(DateKey)))as Quarter, (concat(year(DateKey),"-",month(DateKey))) as Yearmonth,
                   weekday(DateKey) as weekdayno,dayname(DateKey) as weekdayname,
                   case when month(DateKey)<=3 then (concat("FM",(month(DateKey)+9)))
						else (concat("FM",(month(DateKey)-3)))
						end as FinancialMonth,
				   case when month(DateKey) in(4,5,6) Then "FQ-1"
					    when month(DateKey) in(7,8,9) Then "FQ-2"
                        when month(DateKey) in(10,11,12) Then "FQ-3"
                        when month(DateKey) in(1,2,3) Then "FQ-4" 
					    end as financialquarter from calendar;
                                  
## 3. Convert the Average cost for 2 column into USD dollars (currently the Average cost for 2 in local currencies)
select (main.Average_Cost_for_two * currency.USD_Rate) as Average_cost_for_two_in_USD from main
											join currency on main.Currency=Currency.Currency;

## 4. Find the Numbers of Resturants based on City and Country.
select country.Countryname, main.city, count(main.restaurantID)as no_of_restaurants from main 
											join country on main.CountryCode=Country.CountryID  
                                            group by country.countryname , main.city
                                            order by country.countryname , main.city;
										
## 5.Numbers of Resturants opening based on Year , Quarter , Month
select year(date) as year, Quarter(date)as quarter, monthname(date) as Month, count(restaurantID) as no_of_restaurants from main 
                                           group by year(date), Quarter(date),monthname(date)
                                           order by year(date), Quarter(date),monthname(date);
                                           
## 6. Count of Resturants based on Average Ratings
select case when rating <=2 then "0-2" 
            when rating <=3 then "2-3"
            when rating <=4 then "3-4"
            when rating <=5 then "4-5"
            end  as Rating_range, count(restaurantID) as no_of_restaurants from main group by Rating_range order by Rating_range;
            
## 7. Create buckets based on Average Price of reasonable size and find out how many resturants falls in each buckets
select case when (main.Average_Cost_for_two * currency.USD_Rate)<=5 then "0-5"
            when (main.Average_Cost_for_two * currency.USD_Rate)<=10 then "6-10"
            when (main.Average_Cost_for_two * currency.USD_Rate)<=20 then "11-20"
            when (main.Average_Cost_for_two * currency.USD_Rate)<=50 then "21-50"
            when (main.Average_Cost_for_two * currency.USD_Rate)<=100 then "51-100"
            else "101-500"
            end as Average_price_bucket, count(main.restaurantID) as no_of_restaurants from main join currency on main.Currency=Currency.Currency
            group by  Average_price_bucket;

## 8.Percentage of Resturants based on "Has_Table_booking"									
select Has_Table_booking, count(restaurantID) as no_of_restaurant, 
                          concat(round(((count(restaurantID)/(select count(*) from main))*100),1),"%") as Percentage 
                          from main group by Has_Table_booking;  
                          
## 9.Percentage of Resturants based on "Has_Online_delivery"
select Has_Online_delivery, count(restaurantID) as no_of_restaurant, 
                          concat(round(((count(restaurantID)/(select count(*) from main))*100),1),"%") as Percentage 
                          from main group by Has_Online_delivery; 