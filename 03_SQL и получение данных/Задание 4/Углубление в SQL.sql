/*
 База данных: если подключение к облачной базе, то создаёте новую схему с префиксом в виде фамилии, название должно быть на латинице в нижнем регистре и таблицы создаете в этой новой схеме, 
 если подключение к локальному серверу, то создаёте новую схему и в ней создаёте таблицы. 
 */

create schema lecture_4;

set search_path to lecture_4;

---------------------------------------- Основная часть: ----------------------------------------

/*
Задание 1. Спроектируйте базу данных, содержащую три справочника:
· язык (английский, французский и т. п.);
· народность (славяне, англосаксы и т. п.);
· страны (Россия, Германия и т. п.).
*/

drop table if exists language cascade;
drop table if exists nationality cascade;
drop table if exists country cascade;
drop table if exists nation_language;
drop table if exists country_nation;

create table language(
	language_id serial primary key,
	language_name varchar(50) not null unique
);
	
create table nationality(
	nation_id serial primary key,
	nation_name varchar(50) not null unique
);

create table country(
	country_id serial primary key,
	country_name varchar(50) not null unique
);


-- Две таблицы со связями: язык-народность и народность-страна, отношения многие ко многим. Пример таблицы со связями — film_actor. 

create table nation_language(
	nation_id int2 references nationality(nation_id),
	language_id int2 references language(language_id),
	constraint nation_language_pkey primary key (nation_id, language_id)
);

create table country_nation(
	country_id int2 references country(country_id),
	nation_id int2 references nationality(nation_id),
	constraint country_nation_pkey primary key (country_id, nation_id)
);

-- Запросы по добавлению в каждую таблицу по 5 строк с данными

insert into language (language_name) 
values
	('Английский'),
	('Французский'),
	('Испанский'),
	('Русский'),
	('Китайский');
	
insert into nationality(nation_name)
values
	('Англосаксы'),
	('Французы'),
	('Испанцы'),
	('Славяне'),
	('Китайцы');
	
insert into country(country_name)
values
	('Англия'),
	('Франция'),
	('Испания'),
	('Россия'),
	('Китай');

insert into nation_language
values
	(1, 1),
	(2, 2),
	(3, 3),
	(4, 4),
	(5, 5);

insert into country_nation
values
	(1, 1),
	(2, 2),
	(3, 3),
	(4, 4),
	(5, 5);

select 	*	from language;
select 	*	from nationality;
select 	*	from country;
select 	*	from nation_language;
select 	*	from country_nation;


---------------------------------------- Дополнительная часть: ----------------------------------------

drop table if exists film_new;

/*
Задание 1. Создайте новую таблицу film_new со следующими полями:
· film_name — название фильма — тип данных varchar(255) и ограничение not null;
· film_year — год выпуска фильма — тип данных integer, условие, что значение должно быть больше 0;
· film_rental_rate — стоимость аренды фильма — тип данных numeric(4,2), значение по умолчанию 0.99;
· film_duration — длительность фильма в минутах — тип данных integer, ограничение not null и условие, что значение должно быть больше 0.
Если работаете в облачной базе, то перед названием таблицы задайте наименование вашей схемы.
*/

create table film_new(
	film_id serial primary key,
	film_name varchar(255) not null,
	film_year int check (film_year > 0),
	film_rental_rate numeric(4, 2) default 0.99,
	film_duration int not null check (film_duration > 0)
);


-- Задание 2. Заполните таблицу film_new данными с помощью SQL-запроса, где колонкам соответствуют массивы данных

insert into film_new(film_name, film_year, film_rental_rate, film_duration)
select 	unnest(array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindler’s List']) as film_name,
		unnest(array[1994, 1999, 1985, 1994, 1993]) as film_year,
		unnest(array[2.99, 0.99, 1.99, 2.99, 3.99]) as film_rental_rate,
		unnest(array[142, 189, 116, 142, 195]) as film_duration;

select 	* from film_new fn ;

-- Задание 3. Обновите стоимость аренды фильмов в таблице film_new с учётом информации, что стоимость аренды всех фильмов поднялась на 1.41

update film_new 
	set film_rental_rate = film_rental_rate + 1.41;
	
select 	* from film_new fn ;

-- Задание 4. Фильм с названием Back to the Future был снят с аренды, удалите строку с этим фильмом из таблицы film_new

delete from film_new where film_name = 'Back to the Future';

select 	* from film_new fn ;

-- Задание 5. Добавьте в таблицу film_new запись о любом другом новом фильме

insert into film_new(film_name, film_year, film_rental_rate, film_duration)
values ('Star Wars 4', 1985, 5.99, 120);

select 	* from film_new fn ;

-- Задание 6. Напишите SQL-запрос, который выведет все колонки из таблицы film_new, а также новую вычисляемую колонку «длительность фильма в часах», округлённую до десятых

select 	film_id,
		film_name,
		film_year,
		film_rental_rate,
		film_duration,
		round(film_duration / 60., 1) as film_duration_hours
from	film_new fn ;

-- Задание 7. Удалите таблицу film_new

drop table if exists film_new;