use zomato;

drop table if exists gold_members;
CREATE TABLE gold_members(userid int,gold_signup_date date); 

INSERT INTO gold_members(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid int,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid int,created_date date,product_id int); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);

drop table if exists product;
CREATE TABLE product(product_id int,product_name text,price int); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

select * from sales;
select * from users;
select * from gold_members;
select * from product;

--1. What is total amount each customer spent on zomato?

select s.userid as "User ID",sum(p.price) as "Total amount spent" from sales s join product p on s.product_id=p.product_id group by s.userid;

--2. How many days each customer visited zomato?

select userid as "User ID",count(distinct created_date) as "Number of distinct days visited" from sales group by userid;

--3. What was the first product purchased by the each customer?

select t.userid as "User Id",t.created_date as "First Order date",t.product_id as "Product ID" from (select *,rank() over(partition by userid order by created_date) as order_rank from sales) as t where t.order_rank=1;

--4. What is the most purchased item and how many times it was purchased by all the customers?

select * from sales where product_id = (select TOP 1 t.product_id from (select product_id,count(product_id) over (partition by product_id) as cnt from sales)as t order by t.cnt desc);

select userid,count(product_id) as "Count" from sales where product_id = (select TOP 1 product_id from sales group by product_id order by count(product_id) desc) group by userid;

--5. Which item was most popular for each of the customer?

select t1.userid,t1.product_id from (select *,dense_rank() over(partition by t.userid order by t.cnt desc) as rnk from (select userid,product_id,count(product_id) as cnt from sales group by userid,product_id)as t)as t1 where t1.rnk=1;

--6. Which item was purchased first by customer after they became a member?

select * from (select *,rank() over(partition by t.userid order by t.created_date) as rnk from (select s.userid,created_date,product_id,gold_signup_date from sales s join gold_members g on s.userid=g.userid where created_date>=gold_signup_date) as t)as t1 where t1.rnk=1;

--7. Which item was purchased just before the customer has became a member?

select * from (select *,rank() over(partition by userid order by created_date desc) as rnk from (select s.userid,created_date,product_id,gold_signup_date from sales s join gold_members g on s.userid=g.userid where created_date<=gold_signup_date) as t) as t1 where t1.rnk=1;

--8. What is total orders and amount spent for each memeber before they became a memeber?

select t.userid,count(t.userid) as "Orders Purchased",sum(p.price) as "Total Amount Spent" from (select s.userid,product_id,created_date,gold_signup_date from sales s join gold_members g on s.userid=g.userid where created_date<=gold_signup_date) as t join product p on t.product_id=p.product_id group by t.userid order by userid;

--9. If buying each product generates points for example 5 rupees = 2 zomato points and each product has different purchasing points for eg for P1 5 rupees=1 zomato point, for P2 10 rupees=5 zomato points for P3 5 rupeees=1 zomato point

--Calculate points collected by each customer and for which product most points have been given till now.

select x.*,
case 
when x.product_id=1 then x.amount/5 
when x.product_id=2 then (x.amount/10)*2
else x.amount/5 
end as points 
from (select t.userid,t.product_id,sum(t.price) as amount from (select a.*,b.price from sales a join product b on a.product_id=b.product_id) as t group by t.userid,t.product_id) as x;


select * from (select *,rank() over(order by points desc) rnk from (select x.product_id,
case 
when x.product_id=1 then sum(x.amount/5)
when x.product_id=2 then sum((x.amount/10)*2)
else sum(x.amount/5 )
end as points
from (select t.userid,t.product_id,sum(t.price) as amount from (select a.*,b.price from sales a join product b on a.product_id=b.product_id) as t group by t.userid,t.product_id) as x group by x.product_id) y) z where rnk=1;

--10. In first one year after a customer joins the gold program (including their join date) irrespective of what the customer has purchased they earn  5 zomato points fro every 10 rupees spent who earned more 1 or 3 and what was their oints earnings in the first year?

--1 zomato point=2 rupees
--0.5 zomato point=1 rupee

--11. rank all the transactions of the customers.

select *,dense_rank() over(partition by userid order by created_date) rnk from sales;

--12. rank all the transaction for each member whenever they are zomato gold member for every non gold member transactions mark as na

select c.*,(case when gold_signup_date is null then 'NA' else cast(rank() over(partition by userid order by created_date desc) as varchar) end) as rnk from (select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a left join gold_members b on a.userid=b.userid and a.created_date>=b.gold_signup_date) c;