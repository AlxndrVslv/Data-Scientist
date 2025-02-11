--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.


select 	concat_ws(' ', c.last_name, c.first_name) as "Customer name",
		a.address, c2.city, c3.country
from 	customer c 
join	address a 	on	c.address_id = a.address_id
join 	city c2 	on	a.city_id = c2.city_id 
join 	country c3 	on	c2.country_id = c3.country_id;


--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

select 	s.store_id as "ID магазина",
		count(c.customer_id) as "Количество покупателей"
from 	store s 
join	customer c 	on	s.store_id = c.store_id
group by s.store_id;



--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.

select 	s.store_id as "ID магазина",
		count(c.customer_id) as "Количество покупателей"
from 	store s 
join	customer c 	on	s.store_id = c.store_id
group by s.store_id
having 	count(c.customer_id) > 300;



-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.

select 	s.store_id as "ID магазина",		
		count(c.customer_id) as "Количество покупателей",
		c2.city as "Город",
		concat_ws(' ', s2.last_name, s2.first_name) as "Имя сотрудника" 
from 	store s 
join	customer c 	on	s.store_id = c.store_id
join 	address a 	on	s.address_id = a.address_id 
join 	city c2 	on	a.city_id = c2.city_id 
join 	staff s2 	on	s.manager_staff_id = s2.staff_id 
group by 	s.store_id,
			c2.city_id,
			s2.staff_id
having 	count(c.customer_id) > 300;



--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов

select 	concat_ws(' ', c.last_name, c.first_name) as "Фамилия и имя покупателя",
		count(r.rental_id) as "Количество фильмов"
from 	customer c 
join	rental r 	on	c.customer_id = r.customer_id 
group by	c.customer_id 
order by 	count(r.rental_id) desc
limit 5;



--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма

select	concat_ws(' ', c.last_name, c.first_name) as "Фамилия и имя покупателя",
		count(distinct r.inventory_id) as "Количество фильмов",
		round(sum(p.amount)) as "Общая стоимость платежей",
		min(p.amount) as "Минимальная стоимость платежа",
		max(p.amount) as "Максимальная стоимость платежа"
from 	customer c 
join	rental r	on	c.customer_id = r.customer_id 
join	payment p	on	r.rental_id = p.rental_id 
group by c.customer_id;

--ЗАДАНИЕ №5
--Используя данные из таблицы городов, составьте все возможные пары городов так, чтобы 
--в результате не было пар с одинаковыми названиями городов. Решение должно быть через Декартово произведение.
 
select 	distinct
		c.city as "Город 1",
		c2.city as "Город 2"
from 	city c 
cross join city c2 
where c.city < c2.city;


--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и 
--дате возврата (поле return_date), вычислите для каждого покупателя среднее количество 
--дней, за которые он возвращает фильмы. В результате должны быть дробные значения, а не интервал.
 

select 	c.customer_id as "ID покупателя",		
		round(avg(r.return_date::date - r.rental_date::date), 2) as "Среднее количество дней на возврат"
from 	customer c 
join	rental r 	on	c.customer_id = r.customer_id 
where 	r.return_date is not null	-- Исключим аренды, по которым еще не было возврата
group by c.customer_id ;



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.

select 	f.title as "Название фильма", 
		f.rating as "Рейтинг",
		c."name" as "Жанр",
		f.release_year as "Год выпуска",
		l."name" as "Язык",
		count(r.rental_id) as "Количество аренд",
		sum(p.amount) as "Общая стоимость аренды"
from 	film f  
join	(
			select	distinct 	-- В БД DVD_rental для таблицы inventory не соблюдается ограничение PK на столбце inventory_id
					film_id, 	-- Поэтому пришлось добавлять distinct
					inventory_id
			from	inventory i 
		) i 	on	f.film_id = i.film_id 
join 	rental r 		on	i.inventory_id = r.inventory_id 
join 	payment p 		on	r.rental_id = p.rental_id 
join 	film_category fc 	on	f.film_id = fc.film_id
join 	category c 		on	fc.category_id = c.category_id
join 	"language" l 	on	f.language_id = l.language_id 
group by f.film_id, c.category_id, l.language_id;



--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, которые отсутствуют на dvd дисках.


select 	f.title as "Название фильма", 
		f.rating as "Рейтинг",
		c."name" as "Жанр",
		f.release_year as "Год выпуска",
		l."name" as "Язык",
		count(r.rental_id) as "Количество аренд",
		sum(p.amount) as "Общая стоимость аренды"
from 	film f  
left join	(
				select	distinct 	-- В БД DVD_rental для таблицы inventory не соблюдается ограничение PK на столбце inventory_id
						film_id, 	-- Поэтому пришлось добавлять distinct
						inventory_id
				from	inventory i 
			) i 	on	f.film_id = i.film_id 
left join 	rental r 		on	i.inventory_id = r.inventory_id 
left join 	payment p 		on	r.rental_id = p.rental_id 
join 	film_category fc 	on	f.film_id = fc.film_id
join 	category c 		on	fc.category_id = c.category_id
join 	"language" l 	on	f.language_id = l.language_id 
where 	i.inventory_id is null
group by f.film_id, c.category_id, l.language_id;



--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".

select 	staff_id ,
		cnt_rent as "Количество продаж",
		case 
			when cnt_rent > 7300 then 'Да'
			else 'Нет'
		end as "Премия"
from	(
			select 	s.staff_id,
					count(p.payment_id) as cnt_rent
			from 	staff s 
			join	payment p 	on	s.staff_id = p.staff_id  
			group by s.staff_id 
		) sp;


