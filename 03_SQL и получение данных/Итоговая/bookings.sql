set search_path = bookings;

-- 1. Выведите название самолетов, которые имеют менее 50 посадочных мест? 

select 	a.aircraft_code, a.model  
from 	aircrafts a 
join	seats s 	on	a.aircraft_code = s.aircraft_code 
group by a.aircraft_code 
having count(*) < 50;



-- 2. Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых.

select 	book_month::date as book_month,
		case 
			when prev_total_amount > 0 then round((total_amount / prev_total_amount - 1) * 100., 2)
			else 100
		end as total_amount_diff_prcnt
from 	(
			select 	date_trunc('month', book_date) as book_month,
					sum(total_amount) as total_amount,
					lag(sum(total_amount), 1, 0) over(order by date_trunc('month', book_date)) as prev_total_amount
			from 	bookings b 
			group by date_trunc('month', book_date)
		) bb;

	
-- 3. Выведите названия самолетов не имеющих бизнес - класс. Решение должно быть через функцию array_agg.
	
select 	aircraft_code, model
from	(
			select 	a.aircraft_code, a.model,
					array_agg(s.fare_conditions) as fare_conditions
			from 	aircrafts a 
			join	seats s 	on	a.aircraft_code = s.aircraft_code 
			group by a.aircraft_code, a.model
		) ase
where 	array_position(fare_conditions, 'Business') is null;


-- 4. Вывести накопительный итог количества мест в самолетах по каждому аэропорту на каждый день, учитывая только те самолеты, которые летали пустыми и только те дни, где из одного аэропорта таких самолетов вылетало более одного.


with
dep_airs as (	-- Находим перелеты, на которые не были проданы билеты
select 	f.flight_id, f.departure_airport, a.aircraft_code, f.actual_departure::date as departure_date
from 	flights f 
left join	ticket_flights tf on f.flight_id = tf.flight_id 
left join	aircrafts a on	f.aircraft_code = a.aircraft_code
where 	f.actual_departure is not null
group by f.flight_id, a.aircraft_code
having 	count(tf.ticket_no) = 0
)
,
air_seats as (	-- Считаем количество мест в самолетах
select 	a.aircraft_code, 
		count(s.seat_no) as seats_cnt
from 	aircrafts a 
join	seats s 	on	a.aircraft_code = s.aircraft_code 
group by a.aircraft_code
)
,
air_seats_aggr as (	-- Считаем количество мест в самолетах на перелетах без проданных билетов, где количество пустых перелетов за день было больше 1
select 	da.departure_airport, da.departure_date, sum(a.seats_cnt) as seats_cnt, count(da.flight_id)
from 	dep_airs da
join	air_seats a	on	da.aircraft_code = a.aircraft_code
group by da.departure_airport, da.departure_date
having 	count(da.flight_id) > 1
)
select 	asa.departure_airport, asa.departure_date, asa.seats_cnt,	-- Считаем накопительный итог количества мест в пустых самолетах в разрезе каждого аэропорта на каждый день
		sum(asa.seats_cnt) over(partition by asa.departure_airport order by asa.departure_date) as seats_cnt
from 	air_seats_aggr asa;


-- 5. Найдите процентное соотношение перелетов по маршрутам от общего количества перелетов.
-- Выведите в результат названия аэропортов и процентное отношение.
-- Решение должно быть через оконную функцию. 

select 	departure_airport, arrival_airport, 
		round(count(f.flight_id) / sum(count(f.flight_id)) over() * 100., 2) as route_flights_prcnt
from 	flights f 
where 	actual_departure is not null -- Берем только завершенные перелеты
	and actual_arrival is not null
group by departure_airport, arrival_airport;



-- 6. Выведите количество пассажиров по каждому коду сотового оператора, если учесть, что код оператора - это три символа после +7 

select 	substring(contact_data ->> 'phone', 3, 3) as code, count(passenger_id) as passengers_cnt
from 	tickets t
group by substring(contact_data ->> 'phone', 3, 3);


--	7. Классифицируйте финансовые обороты (сумма стоимости перелетов) по маршрутам:
--	 До 50 млн - low
--	 От 50 млн включительно до 150 млн - middle
--	 От 150 млн включительно - high
--	 Выведите в результат количество маршрутов в каждом полученном классе 

select 	case 
			when coalesce(amnt, 0) <  50  * power(10, 6) 												then 'low'
			when coalesce(amnt, 0) >= 50  * power(10, 6) and coalesce(amnt, 0) < 150 * power(10, 6) 	then 'middle'
			when coalesce(amnt, 0) >= 150 * power(10, 6) 												then 'high'
		end as cash_flows_class,
		count(*) as routes_cnt
from 	(
			select 	departure_airport, arrival_airport, 
					sum(tf.amount) as amnt
			from 	flights f 
			left join	ticket_flights tf 	on	f.flight_id = tf.flight_id
			group by departure_airport, arrival_airport
		) tfs
group by 
		case 
			when coalesce(amnt, 0) <  50  * power(10, 6) 												then 'low'
			when coalesce(amnt, 0) >= 50  * power(10, 6) and coalesce(amnt, 0) < 150 * power(10, 6) 	then 'middle'
			when coalesce(amnt, 0) >= 150 * power(10, 6) 												then 'high'
		end;
	
-- 8. Вычислите медиану стоимости перелетов, медиану размера бронирования и отношение медианы бронирования к медиане стоимости перелетов, округленной до сотых
	
select 	flights_median, books_median,
		round(cast(b.books_median / flights_median as numeric), 2) as books_flights_median_div
from	(	-- 13400
			select 	percentile_cont(0.5) within group(order by tf.amount) flights_median
			from 	flights f 
			left join	ticket_flights tf 	on	f.flight_id = tf.flight_id 
		) f
join 	(
			-- 55900
			select 	percentile_cont(0.5) within group(order by total_amount) as books_median
			from 	bookings b 
		) b 	on	1 = 1;
						

--	9. Найдите значение минимальной стоимости полета 1 км для пассажиров. То есть нужно найти расстояние между аэропортами и с учетом стоимости перелетов получить искомый результат
--	Для поиска расстояния между двумя точками на поверхности Земли используется модуль earthdistance.
--  Для работы модуля earthdistance необходимо предварительно установить модуль cube.
--  Установка модулей происходит через команду: create extension название_модуля.
	
create extension cube;
create extension earthdistance;

with 	
flight_ticket_cost as (	-- По каждому перелету посчитаем среднюю стоимость одного билета
select 	f.flight_id,
		f.departure_airport, f.arrival_airport,
		sum(tf.amount) / count(tf.ticket_no) as avg_ticket_cost
from 	flights f 
join	ticket_flights tf 	on	f.flight_id = tf.flight_id 
--where 	tf.fare_conditions = 'Economy'
group by f.flight_id
)
select 	min(
			round(
				cast(
						avg_ticket_cost / 
						(
							earth_distance(ll_to_earth(ad.latitude, ad.longitude), ll_to_earth(aa.latitude, aa.longitude)) -- Расстояние м/у аэропортами в метрах
							/ 1000.	-- Переводим в километры
						)
						as numeric
					), 2
				)
		   )
from 	flight_ticket_cost f
join 	airports ad 	on	f.departure_airport = ad.airport_code 
join 	airports aa 	on	f.arrival_airport  = aa.airport_code;
