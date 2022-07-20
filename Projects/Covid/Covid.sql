-- 1) Exploration of the two databases (CovidDeath and CovidVaccinations)

SELECT * 
FROM CovidDeaths$
ORDER BY 3, 4

SELECT * 
FROM CovidVaccinations$
ORDER BY 3, 4

-- 2) Select the especific data we are going to select

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths$
ORDER BY 1, 2

-- 3) Analyzing Total Cases vs Total Deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercent
FROM CovidDeaths$
ORDER BY 1, 2

-- 4) Analyzing Total Cases vs Total Deaths in the case of Spain

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercent
FROM CovidDeaths$
WHERE location = 'Spain'
ORDER BY 1, 2

-- 5) Analyzing Total Cases vs Population

SELECT location, date, population, total_cases, (total_cases/population)*100 as CasesPercent
FROM CovidDeaths$
WHERE location = 'Spain'
ORDER BY 1, 2


-- 6) Countries with highest infection rate relative to its population
SELECT location, population, MAX(total_cases) as HighestInfectionRate, Max((total_cases/population))*100 as CasesPercent
FROM CovidDeaths$
GROUP BY location, population
ORDER BY CasesPercent DESC

-- 7) Countries with highest death rate relative to its population
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths$
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- 8) Highest death count ordered by continent

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- 9) Total cases, deaths and lethality percent

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercent
From CovidDeaths$
WHERE continent is not null
ORDER BY 1, 2

-- 10) Analyzing total population vs vaccination rate

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(cast(v.new_vaccinations as int)) OVER (Partition by d.location ORDER BY d.location, d.date)
FROM CovidDeaths$ d
JOIN CovidVaccinations$ v 
	ON d.location = v.location
	and d.date = v.date
WHERE d.continent is not null
ORDER BY 2, 3

-- 11) Analyzing total population vs vaccination rate evolution

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
From CovidDeaths$ d
Join CovidVaccinations$ v
	On d.location = v.location
	and d.date = v.date
where d.continent is not null 
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- 12) Creating a Table

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths$ dea
Join CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating a view

Create View PercentPopulationVaccinated as
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
From CovidDeaths$ d
Join CovidVaccinations$ v
	On d.location = v.location
	and d.date = v.date
where d.continent is not null 
