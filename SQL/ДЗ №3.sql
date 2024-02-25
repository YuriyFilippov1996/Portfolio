--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.

select concat(c.last_name, ' ', c.first_name) as "Name", a.address, c2.city, c3.country 
from customer c 
left join address a on a.address_id = c.address_id 
join city c2 on c2.city_id  = a.city_id 
join country c3 on c3.country_id = c2.country_id
order by c.customer_id 


--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

select store_id, count(*) 
from customer  
group by store_id


--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.

select store_id, count(*) 
from customer  
group by store_id
having count(*) > 300


-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.


select c.store_id, count(*), c2.city, concat(s2.last_name, ' ', s2.first_name) as Staff_Name  
from customer c
join store s on c.store_id = s.store_id 
join address a on a.address_id = s.address_id
join city c2 on c2.city_id = a.city_id 
join staff s2 on s2.store_id = s.store_id
group by c.store_id, s2.staff_id, c2.city_id  
having count(*) > 300


--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов

select concat(c.last_name, ' ', c.first_name) as "Name", count(rental_id) as "Count"
from customer c
join rental r on c.customer_id = r.customer_id 
group by c.customer_id
order by count(rental_id) desc
limit 5


--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма

select concat(c.last_name, ' ', c.first_name) as "Name", 
       count(r.rental_id) as "Count",
       round(sum(p.amount)) as "Sum",
       min(p.amount) as "MIN", 
       max (p.amount) as "MAX"
from customer c
join rental r on c.customer_id = r.customer_id 
join payment p on p.rental_id = r.rental_id 
group by c.customer_id



--ЗАДАНИЕ №5
--Используя данные из таблицы городов, составьте все возможные пары городов так, чтобы 
--в результате не было пар с одинаковыми названиями городов. Решение должно быть через Декартово произведение.
 
select distinct c.city as "city 1", c2.city as "city 2"
from city c 
cross join city c2
where c.city < c2.city
order by c.city



--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и 
--дате возврата (поле return_date), вычислите для каждого покупателя среднее количество 
--дней, за которые он возвращает фильмы. В результате должны быть дробные значения, а не интервал.
 
select customer_id, round(avg(return_date::date - rental_date::date), 2)
from rental
group by customer_id
order by customer_id



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.

select f.title, l."name", string_agg, count(r.rental_id), sum(p.amount)
from film f
left join inventory i on f.film_id = i.film_id
left join rental r on r.inventory_id = i.inventory_id
left join payment p on p.rental_id = r.rental_id
join "language" l on f.language_id = l.language_id
join (
	select fc.film_id, string_agg(c.name, ', ')
	from film_category fc 
	join category c on c.category_id = fc.category_id
	group by fc.film_id) fc on fc.film_id = f.film_id
group by f.film_id, l.language_id, string_agg


--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, которые отсутствуют на dvd дисках.

select f.title, l."name", string_agg, count(r.rental_id), sum(p.amount)
from film f
left join inventory i on f.film_id = i.film_id
left join rental r on r.inventory_id = i.inventory_id
left join payment p on p.rental_id = r.rental_id
join "language" l on f.language_id = l.language_id
join (
	select fc.film_id, string_agg(c.name, ', ')
	from film_category fc 
	join category c on c.category_id = fc.category_id
	group by fc.film_id) fc on fc.film_id = f.film_id
where i.film_id is null
group by f.film_id, l.language_id, string_agg


--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".

select concat(s.last_name, ' ', s.first_name), count (*),
  case 
  	when count (*) > 7300 then 'Да'
  	else 'Нет'
  end as "Премия"
from staff s 
left join payment p on p.staff_id = s.staff_id 
group by s.staff_id 





