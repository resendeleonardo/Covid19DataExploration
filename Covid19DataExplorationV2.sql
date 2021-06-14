/*

Basic SQL Data Exploration with Covid19 Dataset 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


SELECT *
FROM Covid19DataExploration..CovidDeaths
WHERE continent IS NOT NULL
--ORDER BY 3,4
ORDER BY location, date


-- Selecting the data we are going to be working with
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid19DataExploration..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date


-- TOTAL CASES VS TOTAL DEATHS
-- Death Percentage if someone contracts Covid19 in Brazil
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM Covid19DataExploration..CovidDeaths
WHERE location like 'Brazil'
ORDER BY location, date


-- TOTAL CASES VS POPULATION
-- Percentage of Brazil's population who got Covid19
SELECT location, date, total_cases, population, (total_cases/population)*100 AS PercentPopulationInfected
FROM Covid19DataExploration..CovidDeaths
WHERE location like 'Brazil'
ORDER BY location, date


-- HIGHEST INFECTION RATES
-- Countries with Highest Infection Rates when compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM Covid19DataExploration..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- HIGHEST DEATH COUNT (COUNTRIES)
-- Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM Covid19DataExploration..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- HIGHEST DEATH COUNT (CONTINENTS)
-- Highest Death Count per Population by Continent
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM Covid19DataExploration..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- COVID19 GLOBAL NUMBERS
SELECT date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM Covid19DataExploration..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, TotalCases


-- TOTAL COVID19 GLOBAL NUMBERS
-- Total Cases, Total Deaths and Death Percentage
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM Covid19DataExploration..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY TotalCases, TotalDeaths


-- TOTAL POPULATION VS VACCINATIONS
-- How many people have been vaccinated from Covid19 in the world?
SET dateformat ymd
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
		PARTITION BY dea.location ORDER BY dea.location, CAST(dea.date AS DATETIME)
		) AS RollingPeopleVaccinatedCount
FROM Covid19DataExploration..CovidDeaths dea
JOIN Covid19DataExploration..CovidVaccinations vac 
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date


-- Common Table Expression (CTE)
WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinatedCount) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
		PARTITION BY dea.location ORDER BY dea.location, CAST(dea.date AS DATETIME)
		) AS RollingPeopleVaccinatedCount
FROM Covid19DataExploration..CovidDeaths dea
JOIN Covid19DataExploration..CovidVaccinations vac 
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinatedCount/population)*100
FROM PopVsVac


-- TEMPORARY TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinatedCount numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
		PARTITION BY dea.location ORDER BY dea.location, CAST(dea.date AS DATETIME)
		) AS RollingPeopleVaccinatedCount
FROM Covid19DataExploration..CovidDeaths dea
JOIN Covid19DataExploration..CovidVaccinations vac 
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
SELECT *, (RollingPeopleVaccinatedCount/population)*100
FROM #PercentPopulationVaccinated


-- VIEWS
-- Creating view to store data for later visualizations in Tableau
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
		PARTITION BY dea.location ORDER BY dea.location, CAST(dea.date AS DATETIME)
		) AS RollingPeopleVaccinatedCount
FROM Covid19DataExploration..CovidDeaths dea
JOIN Covid19DataExploration..CovidVaccinations vac 
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL