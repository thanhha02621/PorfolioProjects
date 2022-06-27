﻿/*
Data Exploration
*/

--------------------------------------------------------------------------------------------------------------------------

SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT * 
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

--------------------------------------------------------------------------------------------------------------------------

--Select Data 


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2 -- See that the first day of deaths was March 22 and since then it has increased a lot

--------------------------------------------------------------------------------------------------------------------------

--Looking at Total Cases vs Total Deaths 


SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%viet%'
AND continent IS NOT NULL
ORDER BY 1,2

--------------------------------------------------------------------------------------------------------------------------

--Looking at Total Cases vs Population
-- Show what percentage of population got Covid


SELECT location, date, population, total_cases, (total_deaths/total_cases)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%viet%'
WHERE continent IS NOT NULL
ORDER BY 1,2

--------------------------------------------------------------------------------------------------------------------------

--Looking at Countries with Highest Infection Rate compared to Population


SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%viet%'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--------------------------------------------------------------------------------------------------------------------------

--Showing Countries with Highest Death Count per Population


SELECT location, MAX(CAST(total_deaths AS int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%viet%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--------------------------------------------------------------------------------------------------------------------------

--BREAK THINGS DOWN BY CONTINENT


SELECT continent, MAX(CAST(total_deaths AS int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%viet%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--------------------------------------------------------------------------------------------------------------------------

--Looking at Total Population vs Vaccinations


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVacccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2,3

--------------------------------------------------------------------------------------------------------------------------

--TEMP TABLE


DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
( 
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric, 
new_vaccinations numeric,
RollingPeopleVacccinated numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVacccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVacccinated/population)*100
FROM #PercentPopulationVaccinated

--------------------------------------------------------------------------------------------------------------------------

--Creating View to store data for later visualizations


USE [PortfolioProject] GO
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVacccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated

--==================================================================================================================================================
/*
Queries used for Tableau Project
*/

--------------------------------------------------------------------------------------------------------------------------

-- 1.
--Rolling People Vaccinated

Select dea.continent, dea.location, dea.date, dea.population
, MAX(vac.total_vaccinations) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
group by dea.continent, dea.location, dea.date, dea.population
order by 1,2,3

--------------------------------------------------------------------------------------------------------------------------

-- 2.
-- DeathPercentage, Total Cases, Total Deaths

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

--------------------------------------------------------------------------------------------------------------------------

-- 3.
-- Total Death Count

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc

--------------------------------------------------------------------------------------------------------------------------

-- 4.
-- Percent Population Infected


Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

--------------------------------------------------------------------------------------------------------------------------

-- 5.
--added population


Select Location, date, population, total_cases, total_deaths
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
order by 1,2

--------------------------------------------------------------------------------------------------------------------------

-- 6. 


With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
From PopvsVac

--------------------------------------------------------------------------------------------------------------------------

-- 7. 
-- Percent Population Infected

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc

--------------------------------------------------------------------------------------------------------------------------


















