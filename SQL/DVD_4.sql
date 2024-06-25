--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате платежа
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате платежа
--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по размеру платежа от наименьшей к большей
--Пронумеруйте платежи для каждого покупателя по размеру платежа от наибольшего к
--меньшему так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.

select payment_id, payment_date,
       row_number () over (order by payment_date) as w
from payment

select customer_id, payment_id, payment_date,
       row_number () over (partition by customer_id order by payment_date) as w
from payment

select customer_id, payment_id, payment_date,
       sum(amount) over (partition by customer_id order by payment_date, amount) as w
from payment

select customer_id, payment_id, payment_date, amount,       
       dense_rank () over (partition by customer_id order by amount desc) as w4
from payment 
 

--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате платежа.

select customer_id, payment_id, payment_date, amount,
       coalesce (lag(amount) over (partition by customer_id order by payment_date), 0.) as "Предыдущий платёж"
from payment 


--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.

select customer_id, payment_id, payment_date, amount,
       amount - lead (amount) over (partition by customer_id order by payment_date) as "Разница между текущим и следующим"
from payment p 


--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.

     
select customer_id, payment_id, payment_date, amount
from (
       select customer_id, payment_id, payment_date, amount, 
       row_number () over (partition by customer_id order by payment_date desc)
       from payment)
where row_number = 1


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.


select staff_id, payment_date::date, sum(amount) as "По дате",
	sum(sum(amount)) over (partition by staff_id order by payment_date::date) as "По сотруднику"
from payment 
where date_trunc('month', payment_date) = '01.08.2005'
group by 1, 2


--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку


with cte1 as (
     select customer_id, payment_date, row_number () over (order by payment_date) as "Номер платежа"
     from payment
     where payment_date::date = '2005-08-20')
select customer_id, payment_date, "Номер платежа" 
from cte1
where mod("Номер платежа",100) = 0 


--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм

with cte1 as (
          select c.country_id, c.country, c3.customer_id, concat(c3.last_name, ' ', c3.first_name) as "Покупатель", r.rental_id, p.amount, p.payment_date 
          from country c
          left join city c2 on c.country_id = c2.country_id 
          left join address a on c2.city_id = a.city_id 
          left join customer c3 on a.address_id = c3.address_id
          left join rental r on r.customer_id = c3.customer_id
          left join payment p on p.rental_id = r.rental_id),
cte2 as (
     select *, count(rental_id) over (partition by customer_id) as "Кол-во аренд",
     sum(amount) over (partition by customer_id) as "Сумма аренд"
     from cte1),
cte3 as (
     select country_id, country, "Покупатель", "Кол-во аренд", "Сумма аренд", payment_date, 
     max("Кол-во аренд") over (partition by country) as "Max_Count",
     max("Сумма аренд") over (partition by country) as "Max_Sum",
     row_number () over (partition by country order by payment_date desc) as "Number"
     from cte2
     order by country, "Покупатель")
select t.country_id, t.country, t."Последняя аренда", t2."Наибольшая сумма", t3."Наибольшое кол-во"
from 
    (select country_id, country, "Покупатель" as "Последняя аренда"
     from cte3
     where "Number" = 1) t
left join 
  (select distinct country_id, country, "Покупатель" as "Наибольшая сумма"
   from cte3
   where "Сумма аренд" = "Max_Sum") t2 on t.country_id = t2.country_id
left join 
  (select distinct country_id, country, "Покупатель" as "Наибольшое кол-во"
   from cte3
where "Кол-во аренд" = "Max_Count") t3 on t.country_id = t3.country_id


-- Альтернативное решение

with cte1 as (
	select p.customer_id, count, sum, max
	from (
		select customer_id, sum(amount)
		from payment 
		group by 1) p
	join (
		select customer_id, count(i.film_id), max(r.rental_date)
		from rental r 
		join inventory i on i.inventory_id = r.inventory_id
		group by 1) r on p.customer_id = r.customer_id), 
cte2 as (
	select c2.country_id, 
		case when count = max(count) over (partition by c2.country_id) then concat(c.last_name, ' ', c.first_name) end cc,
		case when sum = max(sum) over (partition by c2.country_id) then concat(c.last_name, ' ', c.first_name) end cs,
		case when max = max(max) over (partition by c2.country_id) then concat(c.last_name, ' ', c.first_name) end cm
	from customer c
	join address a on c.address_id = a.address_id
	join city c2 on a.city_id = c2.city_id
	join cte1 on c.customer_id = cte1.customer_id)
select c.country, string_agg(cc, ', '), string_agg(cs, ', '), string_agg(cm, ', ')
from country c
left join cte2 on cte2.country_id = c.country_id
group by c.country_id
