--запрос 1: Посчитать кол-во женщин в каждом департаменте (вывод: id департамента, название департамента, кол-во женщин)

select department.id as dep_id, department.name as Dep_name, count(Employee.id) as count_female
from Employee
join Department
on Department.id=Employee.department_id
group by department.id, employee.gender
having employee.gender = 'f';

--запрос 2: Усложняем запрос1 - добавим поле с общим кол-вом работников в департаменте и долей женщин 
--(вывод: id департамента, название департамента, кол-во женщин, всего работников, доля женщин)

with ht1
as
(select department.id, department.name, count(Employee.id) as count_female
from Employee
join Department
on Department.id=Employee.department_id
group by department.id, employee.gender
having employee.gender = 'f')
select ht1.id, ht1.name as Dep_name,  ht1.count_female, count(Employee.id) as count_employee, ht1.count_female/count(Employee.id) ::real as part_fem
from Employee
join ht1
on ht1.id=Employee.department_id
group by ht1.id, ht1.name, ht1.count_female
order by ht1.id asc;

-- запрос 3 вывести id, имена,  названия департаментов,  даты рождения и возраст для всех ассистентов, сортировать от самых старших к самым младшим

select employee.id, employee.name, department.name as Dep_name, employee.date_bitrh, date_part('year', age(Employee.date_bitrh)) as age
from Employee
join Department
on Department.id=Employee.department_id
where employee.position='assistant'
order by age desc;

-- запрос 4 найти самого возрастного работника в каждом департаменте (вывод: департамент, ид и имя работника, возраст)

with ht1
as
(select department.name as Dep_name, employee.id, employee.name, employee.position, date_part('year', age(Employee.date_bitrh)) as age,
max(date_part('year', age(Employee.date_bitrh))) over (partition by Employee.department_id) as max_age
from Department
join Employee
on  Department.id=Employee.department_id
order by Department.id asc)
select ht1.Dep_name, ht1.id, ht1.name, ht1.position, ht1.max_age as age
from ht1
where ht1.age=ht1.max_age;

-- запрос 5 вывести кол-во публикаций по работникам: id, имя работника, департамент, кол-во пуликаций
-- если у публикации > 1 автора, то она засчитывается всем авторам

with ht1
as
(select employee.id, employee.name, employee.department_id, count(PubAuthor.id_pub) as count_pub
from Employee
join PubAuthor
on employee.id=PubAuthor.id_e
group by employee.id)
select ht1.id, ht1.name, department.name, ht1.count_pub
from ht1
join Department
on ht1.department_id=department.id
order by count_pub desc;

-- запрос 6 вывести количество публикаций по годам

select date_part('year', Publication.date_pub) as year_, count(Publication.id) as count_pub
from Publication
group by date_part('year', Publication.date_pub)
order by year_ asc;

-- запрос 7 вывести кол-во публикаций для авторов мужчин и женщин в 2012 году
--если у публикации > 1 автора, то она засчитывается всем авторам

with ht1
as
(select publication.id, PubAuthor.id_e
from Publication
join PubAuthor
on publication.id=PubAuthor.id_pub
where date_part('year', Publication.date_pub) = '2012')
select Employee.gender, count(ht1.id) as count_pub
from ht1
join Employee
on employee.id=ht1.id_e
group by Employee.gender;

-- запрос 8 расчитать отклонение кол-ва страниц в каждой публикации от среднего для каждого автора

select PubAuthor.id_e, Publication.id as id_pub, Publication.num_pages,
(avg(Publication.num_pages) over (partition by PubAuthor.id_e)) :: integer as Employee_avg_pages,
(Publication.num_pages-avg(Publication.num_pages) over (partition by PubAuthor.id_e)) :: integer as Employee_dev_pages
from Publication
join PubAuthor
on publication.id=PubAuthor.id_pub;

-- запрос 9 вывести информацию о структуре каждого департамента с кол-вом штатных должностей + учесть главных врачей 
--(департамент, кол-во главных врачей в департаменте, должности, кол-во штатных единиц)

with ht1
as
(select ChiefDoc.department_id, count(ChiefDoc.id) as count_chiefDoc
from ChiefDoc
group by ChiefDoc.department_id),
ht2 as
(select Department.id, Department.name, Employee.position, count(Employee.position) as staff_list
from Department
join Employee
on Department.id=Employee.department_id
group by Department.id, Department.name, Employee.position)
select ht2.name, ht1.count_chiefDoc, ht2.position, ht2.staff_list 
from ht2
join ht1
on ht2.id=ht1.department_id
order by ht2.name, ht2.position;

-- запрос 10 вывести автора с максимальным объемом страниц для всех публикаций (имя, ид, ид департамента, сумма страниц)

with ht1
as
(select PubAuthor.id_e, 
sum(Publication.num_pages) over (partition by PubAuthor.id_e) as sum_pages
from Publication
join PubAuthor
on PubAuthor.id_pub=Publication.id)
select ht1.id_e, Employee.department_id, Employee.name, ht1.sum_pages
from ht1
join Employee
on ht1.id_e=Employee.id
group by ht1.id_e, Employee.name, ht1.sum_pages, Employee.department_id
having ht1.sum_pages in (select max(ht1.sum_pages) from ht1);

-- запрос 11 вывести работников (ид, имя и должность), у кого нет публикаций (ид, имя, позиция)

select Employee.id, Employee.name, Employee.position, PubAuthor.id_pub
from Employee
left join PubAuthor
on Employee.id=PubAuthor.id_e
where PubAuthor.id_e is null;


