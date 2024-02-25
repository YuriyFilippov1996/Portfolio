--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".

--explain analyze
select film_id, title, t
from (
	select film_id, title, unnest(special_features) as t 
	from film
	)
where t = 'Behind the Scenes'


--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.

--explain analyze
select film_id, title, special_features
from film
where 'Behind the Scenes' = any(special_features)

--explain analyze
select film_id, title, special_features
from film
where special_features && array['Behind the Scenes']


--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.

--explain analyze
with cte1 as
	(select film_id, title, special_features
	from film
	where 'Behind the Scenes' = any(special_features))
select c.customer_id, count(i.film_id)
from customer c
left join rental r on r.customer_id = c.customer_id 
left join inventory i on i.inventory_id = r.inventory_id 
join cte1 on cte1.film_id = i.film_id 
group by c.customer_id
order by c.customer_id


--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.

--explain analyze
select c.customer_id, count(i.film_id)
from customer c
left join rental r on r.customer_id = c.customer_id 
left join inventory i on i.inventory_id = r.inventory_id 
join (
	select film_id, title, special_features
	from film
	where 'Behind the Scenes' = any(special_features)) t on t.film_id = i.film_id
group by c.customer_id
order by c.customer_id


--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

create materialized view "Task 6" as
	select c.customer_id, count(i.film_id)
	from customer c
	left join rental r on r.customer_id = c.customer_id 
	left join inventory i on i.inventory_id = r.inventory_id 
	join (
		select film_id, title, special_features
		from film
		where 'Behind the Scenes' = any(special_features)) t on t.film_id = i.film_id
	group by c.customer_id
	order by c.customer_id
with no data --решил создать без данных

refresh materialized view "Task 6"


--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ стоимости выполнения запросов из предыдущих заданий и ответьте на вопросы:
--1. с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания: 
--поиск значения в массиве затрачивает меньше ресурсов системы;
--2. какой вариант вычислений затрачивает меньше ресурсов системы: 
--с использованием CTE или с использованием подзапроса.

--1. Функция пересечения &&
--2. Одинаково


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============


--ЗАДАНИЕ №1
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.


with cte1 as (
	select p.staff_id, f.film_id, f.title, p. amount, p.payment_date, concat(c.last_name, ' ', c.first_name),
	row_number () over (partition by p.staff_id order by p.payment_date) N
	from payment p
	join customer c on c.customer_id = p.customer_id 
	join rental r on r.rental_id = p.rental_id 
	join inventory i on i.inventory_id = r.inventory_id 
	join film f on f.film_id = i.film_id)
select *
from cte1
where N = 1


--ЗАДАНИЕ №2
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день


select p.store_id, r.rental_date, r.count, p.payment_date, p.sum
from (
	select i.store_id, rental_date::date, count(*),
	max(count(*)) over (partition by i.store_id) mc
	from rental r
	join inventory i on r.inventory_id = i.inventory_id
	group by 1, 2) r
full join (
	select i.store_id, p.payment_date::date, sum(p.amount),
	min(sum(p.amount)) over (partition by i.store_id) ms
	from payment p
	left join rental r on p.rental_id = r.rental_id
	left join inventory i on r.inventory_id = i.inventory_id
	group by 1, 2) p on r.store_id = p.store_id
where r.count = r.mc and p.sum = p.ms
