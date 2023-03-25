SELECT *
FROM Covid.covid_death
WHERE continent is not null





-- Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid.covid_death
ORDER BY 1,2

-- Looking at total cases vs total deaths
-- shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths,(total_deaths/total_cases)*100 AS death_percentage
FROM Covid.covid_death
WHERE location LIKE "%State%"
ORDER BY 1,2

--looking at Total cases vs population
-- Shows what percentage of population got Covid
SELECT location, date, total_cases, population,(total_cases/population)*100 AS cases_percentage
FROM Covid.covid_death
--WHERE location LIKE "%State%"
ORDER BY 1,2

--Looking at Countries with highest infection rates compared with population
SELECT location, MAX(total_cases) AS Highest_Infection_count, population,MAX((total_cases/population))*100 AS Percent_population_infected
FROM Covid.covid_death
GROUP BY population, location
--WHERE location LIKE "%State%"
ORDER BY 4 DESC

--Showing Countries with the highest death count per population
SELECT location,MAX(total_deaths) AS TotalDeathCount
FROM Covid.covid_death
--WHERE location LIKE "%State%"
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--lets break things down by continent
SELECT continent,MAX(total_deaths) AS TotalDeathCount
FROM Covid.covid_death
--WHERE location LIKE "%State%"
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Showing continents with highest death count per population
SELECT continent,MAX(total_deaths) AS TotalDeathCount
FROM Covid.covid_death
--WHERE location LIKE "%State%"
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--GLOBAL NUMBERS
SELECT SUM(new_cases) AS Totalnewcases, SUM(new_deaths)AS Totalnewdeath, SAFE_DIVIDE(SUM(new_deaths),SUM(new_cases))*100 AS death_percentage
FROM Covid.covid_death
--WHERE location LIKE "%State%"
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2   DESC

--Looking at total population vs vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM Covid.covid_death AS dea
JOIN Covid.covid_vaccination AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2 DESC

--USE Common Table expression
WITH popvsvac AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM Covid.covid_death AS dea
JOIN Covid.covid_vaccination AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
)
SELECT *, (Rolling_People_Vaccinated/population) *100
FROM popvsvac


--TEMP TABLE

CREATE TEMP TABLE Percent_Population_Vaccinated
(
  continent STRING(1024),
  location STRING(1024),
  date date,
  population INT64,
  new_Vaccinations INT64,
  Rolling_People_Vaccinated INT64
);


INSERT INTO Percent_Population_Vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM Covid.covid_death AS dea
JOIN Covid.covid_vaccination AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

SELECT *, (Rolling_People_Vaccinated/population) *100
FROM Percent_Population_Vaccinated;

-- Creating View to store data for later Vizualisations
CREATE VIEW Percent_Population_Vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, 
dea.date) AS Rolling_People_Vaccinated
FROM covid.covid_death AS dea
JOIN covid.covid_vaccination AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;