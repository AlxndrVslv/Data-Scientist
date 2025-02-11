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

SELECT	customer_id, payment_id, payment_date,
		row_number() over(order by payment_date) as column_1,
		row_number() over(partition by customer_id order by payment_date) as column_2,
		sum(amount) over(partition by customer_id order by payment_date, amount) as column_3,
		dense_rank() over(partition by customer_id order by amount desc) as column_4
FROM	payment;


--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате платежа.

select 	c.customer_id,
		p.payment_id, p.payment_date,
		p.amount,
		lag(p.amount, 1, 0.) over(partition by p.customer_id order by p.payment_date) as last_amount
from 	customer c 
left join	payment p on c.customer_id = p.customer_id;



--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.

select 	c.customer_id,
		p.payment_id, p.payment_date,
		p.amount,
		lead(p.amount, 1, 0.) over(partition by p.customer_id order by p.payment_date) - coalesce(p.amount, 0) as difference
from 	customer c 
left join	payment p on c.customer_id = p.customer_id;



--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.

select 	customer_id, 
		payment_id, payment_date, amount
from	(
			select 	c.customer_id, 
					p.payment_id, p.payment_date, p.amount,
					row_number() over(partition by p.customer_id order by p.payment_date desc) as rn 
			from 	customer c 
			left join	payment p  on	c.customer_id = p.customer_id
		) cp
where 	rn = 1;



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.

select 	s.staff_id,
		p.payment_date::date as payment_date,
		sum(p.amount) as sum_amount,
		sum(sum(p.amount)) over(partition by s.staff_id order by p.payment_date::date)
from 	staff s 
left join	payment p 	on	s.staff_id = p.staff_id 
where 	date_trunc('month', p.payment_date) = to_date('2005-08-01', 'YYYY-MM-DD')
group by s.staff_id, p.payment_date::date;


--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку

select 	customer_id, payment_date, rn as payment_number
from	(
			select 	p.customer_id, p.payment_date,
					row_number() over(order by p.payment_date) as rn
			from 	payment p 
			where 	payment_date::date = to_date('2005-08-20', 'YYYY-MM-DD')
		) p
where 	p.rn%100 = 0;


--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм

explain analyze	--	7866 - 53
select 	distinct
		country as "Страна",
		first_value(customer_name) over(partition by country order by film_cnt desc) as "Покупатель, арендовавший наибольшее количество фильмов",
		first_value(customer_name) over(partition by country order by rent_sum desc) as "Покупатель, арендовавший фильмов на самую большую сумму",
		first_value(customer_name) over(partition by country order by max_rent_date desc) as "Покупатель, который последним арендовал фильм"
from 	(
			select 	c3.country, 
					c.customer_id, concat_ws(' ', c.first_name, c.last_name) as customer_name,
					count(distinct i.film_id) as film_cnt, 
					sum(p.rent_sum) as rent_sum, 
					max(r.rental_date) as max_rent_date		
			from 	customer c 
			join	address a 	on	c.address_id = a.address_id 
			join 	city c2 	on	a.city_id = c2.city_id 
			join 	country c3 	on	c2.country_id = c3.country_id
			join 	rental r 	on	c.customer_id = r.customer_id
			join 	inventory i on	r.inventory_id = i.inventory_id
			join	(
						select	rental_id, sum(amount) as rent_sum
						from	payment 
						group by rental_id
					) p 	on	r.rental_id = p.rental_id 
			group by 	c3.country_id,
						c.customer_id
		) t;