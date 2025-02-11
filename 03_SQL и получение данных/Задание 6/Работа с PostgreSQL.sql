--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".

select 	film_id, title, special_features
from	(
			SELECT	film_id, title, special_features, unnest(special_features) as sf
			FROM	film
		) f
where 	sf = 'Behind the Scenes';


--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.

select 	film_id, title, special_features
from	film f 
where 	array['Behind the Scenes'] <@ special_features;

select 	film_id, title, special_features 
from	film f
where 	array_position(special_features, 'Behind the Scenes') is not null;


--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.

with
film as (
select 	film_id, title, special_features
from	(
			SELECT	film_id, title, special_features, unnest(special_features) as sf
			FROM	film
		) f
where 	sf = 'Behind the Scenes'
)
select 	c.customer_id, count(f.film_id) as film_count
from 	customer c
left join	rental r 	on	c.customer_id = r.customer_id  
left join 	inventory i on	r.inventory_id = i.inventory_id
left join 	film f		on	i.film_id = f.film_id
group by c.customer_id;



--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.

select 	c.customer_id, count(f.film_id) as film_count
from 	customer c
left join	rental r 	on	c.customer_id = r.customer_id  
left join 	inventory i on	r.inventory_id = i.inventory_id
left join 	(
				select 	film_id, title, special_features
				from	(
							SELECT	film_id, title, special_features, unnest(special_features) as sf
							FROM	film
						) f
				where 	sf = 'Behind the Scenes'
			) f	on	i.film_id = f.film_id
group by c.customer_id;



--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

create materialized view cust_films as
select 	c.customer_id, count(f.film_id) as film_count
from 	customer c
left join	rental r 	on	c.customer_id = r.customer_id  
left join 	inventory i on	r.inventory_id = i.inventory_id
left join 	(
				select 	film_id, title, special_features
				from	(
							SELECT	film_id, title, special_features, unnest(special_features) as sf
							FROM	film
						) f
				where 	sf = 'Behind the Scenes'
			) f	on	i.film_id = f.film_id
group by c.customer_id
with no data;

refresh materialized view cust_films; 

select 	* from cust_films;

--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ стоимости выполнения запросов из предыдущих заданий и ответьте на вопросы:
--1. с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания: 
--поиск значения в массиве затрачивает меньше ресурсов системы;
--2. какой вариант вычислений затрачивает меньше ресурсов системы: 
--с использованием CTE или с использованием подзапроса.

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

explain analyze	-- 247.50	/ 	0.7
select 	film_id, title, special_features
from	(
			SELECT	film_id, title, special_features, unnest(special_features) as sf
			FROM	film
		) f
where 	sf = 'Behind the Scenes';


explain analyze	-- 67.5		/	0.3
select 	film_id, title, special_features
from	film f 
where 	array['Behind the Scenes'] <@ special_features;


explain analyze	-- 67.5		/	0.4
select 	film_id, title, special_features 
from	film f
where 	array_position(special_features, 'Behind the Scenes') is not null;

-- Вывод: 
--	При использовании оператора "<@" и функции "array_position" поиск элемента в массиве занимает меньше ресурсов и времени, чем при использовании функции "unnest".
--  Между "<@" и "array_position" разницы в затраченных ресурсах и времени практически нет.


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

explain analyze	--	1016	/	 12
with
film as (
select 	film_id, title, special_features
from	(
			SELECT	film_id, title, special_features, unnest(special_features) as sf
			FROM	film
		) f
where 	sf = 'Behind the Scenes'
)
select 	c.customer_id, count(f.film_id) as film_count
from 	customer c
left join	rental r 	on	c.customer_id = r.customer_id  
left join 	inventory i on	r.inventory_id = i.inventory_id
left join 	film f		on	i.film_id = f.film_id
group by c.customer_id;

explain analyze	--	1016	/	 12
select 	c.customer_id, count(f.film_id) as film_count
from 	customer c
left join	rental r 	on	c.customer_id = r.customer_id  
left join 	inventory i on	r.inventory_id = i.inventory_id
left join 	(
				select 	film_id, title, special_features
				from	(
							SELECT	film_id, title, special_features, unnest(special_features) as sf
							FROM	film
						) f
				where 	sf = 'Behind the Scenes'
			) f	on	i.film_id = f.film_id
group by c.customer_id;

-- Вывод:
--	Использование CTE или подзапроса никак не влияет на план запроса, его стоимость и время выполнения.


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии

explain analyze
select distinct cu.first_name  || ' ' || cu.last_name as name, 
	count(ren.iid) over (partition by cu.customer_id)
from customer cu
full outer join 
	(select *, r.inventory_id as iid, inv.sf_string as sfs, r.customer_id as cid
	from rental r 
	full outer join 
		(select *, unnest(f.special_features) as sf_string
		from inventory i
		full outer join film f on f.film_id = i.film_id) as inv 
		on r.inventory_id = inv.inventory_id) as ren 
	on ren.cid = cu.customer_id 
where ren.sfs like '%Behind the Scenes%'
order by count desc

/*

        Sort Method: quicksort  Memory: 1058kB
        ->  WindowAgg  (cost=1091.99..1092.10 rows=5 width=44) (actual time=42.254..47.436 rows=8632 loops=1)														--	9.	Группировка полученного в п.7 набора данных
              ->  Sort  (cost=1091.99..1092.00 rows=5 width=21) (actual time=42.215..43.537 rows=8632 loops=1)														--	8.	Сортировка полученного в п.7 набора данных
                    Sort Key: cu.customer_id
                    Sort Method: quicksort  Memory: 1057kB
                    ->  Nested Loop Left Join  (cost=82.09..1091.93 rows=5 width=21) (actual time=0.432..39.548 rows=8632 loops=1)									--  7.  Соединение наборов данных из п. 6а и 6б простым перебором
                          ->  Nested Loop Left Join  (cost=81.82..1090.45 rows=5 width=6) (actual time=0.416..29.791 rows=8632 loops=1)								--	6а. Соединение наборов данных из п. 5а и 5б простым перебором
                                ->  Subquery Scan on inv  (cost=77.50..996.42 rows=5 width=4) (actual time=0.395..5.212 rows=2494 loops=1)							--	5а. Сканирование полученного набора и наложение фильтра
                                      Filter: (inv.sf_string ~~ '%Behind the Scenes%'::text)
                                      Rows Removed by Filter: 7274
                                      ->  ProjectSet  (cost=77.50..423.80 rows=45810 width=712) (actual time=0.385..4.290 rows=9768 loops=1)						--	4а. Формирование набора данных по функции
                                            ->  Hash Full Join  (cost=77.50..160.39 rows=4581 width=63) (actual time=0.382..1.773 rows=4623 loops=1)				--	3.  Быстрое соединение по хэшу таблиц inventory и film
                                                  Hash Cond: (i.film_id = f.film_id)
                                                  ->  Seq Scan on inventory i  (cost=0.00..70.81 rows=4581 width=6) (actual time=0.011..0.287 rows=4581 loops=1)	-- 	2б. Последовательное сканирование всей таблицы inventory
                                                  ->  Hash  (cost=65.00..65.00 rows=1000 width=63) (actual time=0.360..0.361 rows=1000 loops=1)						--	2а. Создание хэша на диске
                                                        Buckets: 1024  Batches: 1  Memory Usage: 104kB
                                                        ->  Seq Scan on film f  (cost=0.00..65.00 rows=1000 width=63) (actual time=0.012..0.222 rows=1000 loops=1)	-- 	1.  Последовательное сканирование всей таблицы film
                                ->  Bitmap Heap Scan on rental r  (cost=4.32..18.77 rows=4 width=6) (actual time=0.003..0.004 rows=3 loops=2494)					--	5б. Сканирование таблицы rental по индексу 
                                      Recheck Cond: (inventory_id = inv.inventory_id)
                                      Heap Blocks: exact=8605
                                      ->  Bitmap Index Scan on idx_fk_inventory_id  (cost=0.00..4.32 rows=4 width=0) (actual time=0.002..0.002 rows=3 loops=2494)	--	4б. Сканирование таблицы rental по индексу 
                                            Index Cond: (inventory_id = inv.inventory_id)
                          ->  Index Scan using customer_pkey on customer cu  (cost=0.28..0.30 rows=1 width=17) (actual time=0.001..0.001 rows=1 loops=8632)			--	6б. Сканирование таблицы customer по индексу
                                Index Cond: (customer_id = r.customer_id)

*/

-- Узкие места:
-- 1. Много ресурсов занимает формирование набора данных для Unnest функции в п. 4а. Возможно заменить на оператор поиска в массиве;
-- 2. Не оптимальное соединение простым перебором всей таблицы rental с набором данных, которое получено в результате соединения таблицы inventory и film.
-- 3. Не оптимальное соединение простым перебором всей таблицы customer с набором данных, которое получено в прошлом пункте.  


-- В основном запросе также лучше отказаться от использования фукнции Unnest в пользу операторов поиска в массиве.

--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.

--explain analyze	--	2635	/	15
with
staff_paym as (
select 	staff_id,
		amount,
		payment_date,
		rental_id
from	(
			select	s.staff_id, 
					p.amount, p.payment_date, p.rental_id,
					row_number() over(partition by s.staff_id order by p.payment_date) as rn
			from 	staff s 
			join 	payment p 	on	s.staff_id = p.staff_id
		) sp
where 	rn = 1
)
,
staff_rent as (
select 	sp.*,
		r.inventory_id, r.customer_id
from 	staff_paym sp
join	rental r 	on	sp.rental_id = r.rental_id
)
select 	s.staff_id,
		f.film_id, f.title,
		sr.amount, sr.payment_date,
		c.last_name as customer_last_name, c.first_name as customer_first_name
from 	staff s
left join	staff_rent sr	on	s.staff_id = sr.staff_id
left join 	customer c 		on	sr.customer_id = c.customer_id
left join 	inventory i		on	sr.inventory_id = i.inventory_id
left join 	film f 			on	i.film_id = f.film_id;


--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день

--explain analyze		--	5416	/	25
select 	s.store_id as "ID магазина",
		s1.rental_date as "День, в который арендовали больше всего фильмов",
		s1.film_cnt as "Количество фильмов, взятых в аренду в этот день",
		s2.payment_date as "День, в который продали фильмов на наименьшую сумму",
		s2.sum_pymt as "Сумма продажи в этот день"
from 	store s 
left join
		(
			select 	store_id,
					rental_date,
					film_cnt
			from	(
						select 	s.store_id,
								count(i.film_id) as film_cnt,
								r.rental_date::date as rental_date,
								row_number() over(partition by s.store_id order by count(i.film_id) desc) as rn
						from 	store s 
						join	customer c 	on	s.store_id = c.store_id 
						join 	rental r 	on	c.customer_id = r.customer_id 
						join 	inventory i on	r.inventory_id = i.inventory_id
						group by s.store_id, r.rental_date::date
					) sf
			where 	sf.rn = 1
		) s1	on	s.store_id = s1.store_id
left join 
		(
			select 	store_id,
					payment_date,
					sum_pymt
			from	(
						select 	s.store_id, 
								p.payment_date::date as payment_date,
								sum(p.amount) as sum_pymt,
								row_number() over(partition by s.store_id order by sum(p.amount)) as rn
						from 	store s 
						join	customer c 	on	s.store_id = c.store_id 
						join 	payment p 	on	c.customer_id = p.customer_id 
						group by s.store_id, p.payment_date::date
					) sp
			where 	sp.rn = 1
		) s2	on	s.store_id = s2.store_id;