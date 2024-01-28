-- Analysis: displaying the 2 databases

select * from ptf_project.CovidDeaths
order by 3,4;

select * from ptf_project.CovidVaccinations
order by 3,4;

-- Selecting data for the use

select Location, date, total_cases, new_cases, total_deaths, population
from ptf_project.CovidDeaths
order by 1,2;

-- total cases vs total deaths: understand the % of deaths over people who got the covid - spotting italy ordered by higher %

select Location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100,6) as DeathPercentage
from ptf_project.CovidDeaths
where location like 'Italy' 
order by 2 desc;

-- checking for duplicated rows

select date, count(date) from (select * from ptf_project.CovidDeaths where location = 'Italy') as sub1
group by 1
having 2 >1;

-- 1) Getting incidence of death over people who contracted the virus
select Location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100,5) as DeathPercentage from ptf_project.CovidDeaths
where location = 'Italy'
order by 5 desc; -- result higher & is 2020-06-20 

-- 2) Getting incidence of death over people who contracted the virus
select Location, date, total_cases, population, round((total_cases/population)*100,6) as cases_over_population from ptf_project.CovidDeaths
where location = 'Italy'
order by 2 asc;

-- 2.1) getting unique value as top
select Location, date, total_cases, population, round((total_cases/population)*100,6) as cases_over_population from ptf_project.CovidDeaths
group by 1,2,3,4
having location = 'Italy'
order by 5 desc
limit 1; -- 2021-04-30 was considered the peak of the pandemic with 6.65% of the population affected

-- 3) looking at country with Highest infection rate VS population 
select Location, population, max(total_cases) as Highest_infe_count, population, round(max(total_cases/population)*100,6) as cases_over_population 
from ptf_project.CovidDeaths
group by 1,2
having max(total_cases) is not null
order by 5 desc; -- small population could have high % cases, on the other hand USA almost 10%

-- 4) showing Countries with highest death count per population

select location, max(total_deaths) as Total_death_count
from ptf_project.CovidDeaths
where continent is not null -- the dataset has continent showed as country so i am filtering out just to get the countries
group by 1
order by 2 desc;

-- 5) exploting data by Continent 

select location, max(total_deaths) as Total_death_count
from ptf_project.CovidDeaths
where continent is null
group by 1
order by 2 desc;

-- 6) applying aggregate funtion
	-- getting daily new global cases

with cte_data as (
	select Location, date, total_cases, total_deaths, new_cases, population
    from ptf_project.CovidDeaths
	group by 1,2,3,4,5,6
)
select date , sum(new_cases) as daily_new_cases 
from cte_data
group by date
having sum(new_cases) is not null
order by 2 asc;

-- getting historical global cases and percentage over total population
select sum(new_cases) as total_cases, sum(new_deaths) as total_death, concat(round(sum(new_deaths)/Sum(new_cases)*100,2), '%') as DeathPercentage
from (select location, date, total_cases, total_deaths, new_cases, population, new_deaths, continent
    from ptf_project.CovidDeaths
	group by 1,2,3,4,5,6,7,8)sub1
where continent is not null;

-- ----------------------------------------------------------------ADDING NEW TABLE----------------------------------------------------------------
-- getting number of daily vaccinations per country

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from ptf_project.CovidDeaths dea
join ptf_project.CovidDeaths vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and vac.new_vaccinations is not null
order by 2,3;

-- getting incremental vaccination using partition

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location , dea.date) as rolling_vaccination
from ptf_project.CovidDeaths dea
join ptf_project.CovidDeaths vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and vac.new_vaccinations is not null
order by 2,3;

-- applying CTE to get more insight 

with cte_POPvsVAC (continent, location, date, population, new_vaccination, rolling_vaccination)
as (
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location , dea.date) as rolling_vaccination
	from ptf_project.CovidDeaths dea
	join ptf_project.CovidDeaths vac
		on dea.location = vac.location
		and dea.date = vac.date
	where dea.continent is not null and vac.new_vaccinations is not null
	order by 2,3)
select *, round(rolling_vaccination/population*100,4)
from cte_POPvsVAC;
    
-- getting max for each country 
use ptf_project;
DROP TABLE if exists percentpopulationVaccinated
CREATE TABLE percentpopulationVaccinated 
( 
	continent  nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccination numeric,
	rolling_vaccination numeric
)
insert into percentpopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location , dea.date) as rolling_vaccination
	from ptf_project.CovidDeaths dea
	join ptf_project.CovidDeaths vac
		on dea.location = vac.location
		and dea.date = vac.date
	where dea.continent is not null and vac.new_vaccinations is not null
	order by 2,3)
select *, round(rolling_vaccination/population*100,4)
from percentpopulationVaccinated;

-- Creating view to store data
use ptf_project;
create view percentpopulationVaccinated as
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		sum(vac.new_vaccinations) over (partition by dea.location order by dea.location , dea.date) as rolling_vaccination
		from ptf_project.CovidDeaths dea
		join ptf_project.CovidDeaths vac
		on dea.location = vac.location
		and dea.date = vac.date
		where dea.continent is not null and vac.new_vaccinations is not null;

-- calling a view table to check 
select * from percentpopulationVaccinated;



