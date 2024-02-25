--Задание №1
--Выведите название самолетов, которые имеют менее 50 посадочных мест

select a.model, count(s.seat_no) as "Кол-во мест" 
from aircrafts a 
join seats s on s.aircraft_code = a.aircraft_code
group by a.aircraft_code
having count(s.seat_no) < 50

--Задание №2
--Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых.
	
select *, round((("Сумма брони" - "Сумма брони за прошлый мес")/"Сумма брони за прошлый мес")*100, 2) as "Изменение суммы в %"
from (
	select date_trunc('month', book_date::date)::date as "Месяц", sum (total_amount) as "Сумма брони", 
	lag(sum (total_amount)) over(order by date_trunc('month', book_date::date)) as "Сумма брони за прошлый мес"
	from bookings
	group by date_trunc('month', book_date::date)
	order by "Месяц")
	
--Задание №3
--Выведите названия самолетов не имеющих бизнес - класс. Решение должно быть через функцию array_agg.
	
select model
from (
	select a.model, array_agg(s.fare_conditions) as "Классы обслуживания" 
	from aircrafts a 
	join seats s on s.aircraft_code = a.aircraft_code 
	group by a.aircraft_code)
where array_position("Классы обслуживания", 'Business')is null 

--Задание №4
--Вывести накопительный итог количества мест в самолетах по каждому аэропорту на каждый день, учитывая только те самолеты, 
--которые летали пустыми и только те дни, где из одного аэропорта таких самолетов вылетало более одного.
--В результате должны быть код аэропорта, дата, количество пустых мест в самолете и накопительный итог.

	
select *, sum (c1) over (partition by airport_code order by actual_departure::date)
from (
	select t.airport_code, t.actual_departure::date, count (s.seat_no) as c1
	from
		(select a.aircraft_code, a1.airport_code, f.actual_departure::date,
		count(a.aircraft_code) over (partition by a1.airport_code, f.actual_departure::date) 
		from aircrafts a
		left join flights f on a.aircraft_code = f.aircraft_code
		left join airports a1 on a1.airport_code = f.departure_airport
		left join ticket_flights tf on f.flight_id = tf.flight_id
		left join boarding_passes bp on f.flight_id = bp.flight_id
		where bp.flight_id is null and f.actual_departure is not null) t
	join seats s on t.aircraft_code = s.aircraft_code
	where count > 1
	group by t.actual_departure::date, t.airport_code)
	
--Эталонное решение
	
with c as (
	select departure_airport, actual_departure, actual_departure::date ad_date, c_s
	from flights f
	join (
		select aircraft_code, count(*) c_s
		from seats
		group by aircraft_code) s on s.aircraft_code = f.aircraft_code
	left join boarding_passes bp on bp.flight_id = f.flight_id
	where actual_departure is not null and bp.flight_id is null)
select departure_airport, ad_date, c_s, sum(c_s) over (partition by departure_airport, ad_date order by actual_departure)
from c 
where (departure_airport, ad_date) in (
	select departure_airport, ad_date
	from c 
	group by 1,2 
	having count(*) > 1)
		
	
--Задание №5
--Найдите процентное соотношение перелетов по маршрутам от общего количества перелетов.
--Выведите в результат названия аэропортов и процентное отношение.
--Решение должно быть через оконную функцию.


select "Маршрут", c1 as "Кол-во по маршруту", c2 as "Кол-во всего", round((c1::numeric /c2)*100, 2) as "Percent"
from (
	select f.flight_id, concat (a1.airport_name, ' - ', a2.airport_name) as "Маршрут", f.departure_airport, f.arrival_airport,
	count (flight_id) over (partition by a1.airport_name, a2.airport_name) c1, count (*) over () c2
	from flights f
	join airports a1 on a1.airport_code = f.departure_airport
	join airports a2 on a2.airport_code = f.arrival_airport)
order by "Маршрут"

--Задание №6
--Выведите количество пассажиров по каждому коду сотового оператора, 
--если учесть, что код оператора - это три символа после +7
 
select count (passenger_id), phone_code
from (
	select passenger_id, right(left((contact_data ->> 'phone'), 5), -2) as phone_code
	from tickets)
group by phone_code

--Задание №7
--Классифицируйте финансовые обороты (сумма стоимости перелетов) по маршрутам:
--До 50 млн - low
--От 50 млн включительно до 150 млн - middle
--От 150 млн включительно - high
--Выведите в результат количество маршрутов в каждом полученном классе

select "Классификация", count(*)
from (
	select "Маршрут", sum, 
		case 
			when sum < 50000000 then 'low'
			when sum >= 50000000 and sum < 150000000 then 'middle'
			when sum >= 150000000 then 'high'
			else 'No_flights'
		end as "Классификация"
	from (
		select concat(f.departure_airport, ' - ', f.arrival_airport) as "Маршрут", sum(amount)
		from ticket_flights tf 
		join flights f on tf.flight_id = f.flight_id
		group by f.departure_airport, f.arrival_airport))
group by "Классификация"
order by count

--Задание №8
--Вычислите медиану стоимости перелетов, медиану размера бронирования и 
--отношение медианы бронирования к медиане стоимости перелетов, округленной до сотых

	
select t1.pc1, t2.pc2, round((pc1/pc2)::numeric, 2)
from (select percentile_cont(0.5) within group (order by total_amount) as pc1 from bookings) t1
cross join (select percentile_cont(0.5) within group (order by amount) as pc2 from ticket_flights) t2

	
--Задание №9
--Найдите значение минимальной стоимости полета 1 км для пассажиров. 
--То есть нужно найти расстояние между аэропортами и с учетом стоимости перелетов получить искомый результат
--Для поиска расстояния между двумя точками на поверхности Земли используется модуль earthdistance.
--Для работы модуля earthdistance необходимо предварительно установить модуль cube.
--Установка модулей происходит через команду: create extension название_модуля

create extension cube

create extension earthdistance

select round(min (amount/"range")::numeric, 2)
from (
	select distinct a1.airport_name, a2.airport_name, tf.amount,
	(earth_distance(ll_to_earth (a1.latitude, a1.longitude), ll_to_earth (a2.latitude, a2.longitude)))/1000 as range
	from flights f
	join airports a1 on a1.airport_code = f.departure_airport
	join airports a2 on a2.airport_code = f.arrival_airport
	join ticket_flights tf on tf.flight_id = f.flight_id) 

	
