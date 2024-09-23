--DATA EXPLORATION ON COVID DATASET
--Dataset contains global information relevant to COVID deaths and vaccinations from January 2020 to May 2024
--This exploration focuses on COVID deaths, so we've already selected and saved columns relevant to COVID deaths while loading the dataset


--View data in the dataset "CovidDeaths"
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

	
--Dataset contains seveeral rows, includidng 'location', 'date', 'total_cases', 'new_cases', 'total_deaths', 'population'
	
--Let's check total_cases vs total_deaths (Show the percentage of infected people that actually died)
SELECT location, date, total_cases, total_deaths,
CASE WHEN total_cases <= 0
THEN  0
ELSE (total_deaths/total_cases)*100
END AS percent_death
FROM CovidDeaths
ORDER BY 1,2

	

--Since it's a global dataset, this shows 'percent_death' for different countries from 2020 to 2024
--We can also view specific locations; like the united states
SELECT location, date, total_cases, total_deaths,
CASE WHEN total_cases <= 0
THEN  0
ELSE (total_deaths/total_cases)*100
END AS percent_death
FROM CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2


	
--We then evaluate the total cases with population for Nigeria (Highest infection rate based on population)
SELECT location, date, population, total_cases, (total_cases/population)*100 AS percent_infected
FROM CovidDeaths
WHERE location like '%Nigeria%'
ORDER BY 1,2

	

--Next, we can identify the location with the highest percent_infected (Highest infection rate compared to population)
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX(total_cases/population)*100 AS percent_infected
FROM CovidDeaths
GROUP BY location, population
order by 4 DESC


	
--Now, to the death count; Let's identify countries with highest death count per population (Percentage death based on population)
SELECT location, population, MAX(total_deaths) AS death_count, MAX(total_deaths/population)*100 AS percent_death
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

	

--The dataset also presents continental information. Let's explore these information
--Deaths based on continents as at the latest date in the dataset '2024-07-21 00:00:00.000'
SELECT continent, SUM(total_deaths) AS death_count FROM CovidDeaths
WHERE continent is not null AND date='2024-07-21 00:00:00.000'
GROUP BY continent
ORDER BY death_count DESC


	
--Aside from the continent column, the dataset also features continents in the location column 
--But the corresponding value in the continent column is NULL. So, alternatively:
SELECT location, MAX(total_deaths) AS death_count FROM CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY death_count DESC


	
--We can also identify the total number of deaths for each continent
SELECT continent, SUM(MaxDeaths) AS SumOfMaxDeathsPerCountry
FROM (
    SELECT location, continent, MAX(total_deaths) AS MaxDeaths
    FROM CovidDeaths
	WHERE continent IS NOT NULL
    GROUP BY location, continent
) AS subquery 
GROUP BY continent 
ORDER BY SumOfMaxDeathsPerCountry DESC

	

--Next, continents with highest death count per population (Percentage death based on continent's population)
SELECT location, MAX(total_deaths) AS death_count, MAX(total_deaths/population)*100 AS percent_death
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY percent_death DESC



--Let's work with global numbers
--Global death percentage based on total cases
SELECT continent, date, SUM(total_cases) AS cases, SUM(total_deaths) AS deaths, SUM(population) AS population, 
    (SUM(total_deaths) / SUM(total_cases))*100 AS percent_death
FROM CovidDeaths
WHERE continent IS NOT NULL AND date = '2024-07-21 00:00:00.000'
GROUP BY continent, date
ORDER BY percent_death DESC

	

--We can aggregate the data to get the number of cases and deaths globally eveeryday since the pandemic started
SELECT SUM(total_cases) AS cases, SUM(total_deaths) AS deaths, (SUM(total_deaths) / SUM(total_cases))*100 AS percent_death
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


	
--To get the same result grouped by date
SELECT date, SUM(total_cases) AS cases, SUM(total_deaths) AS deaths, (SUM(total_deaths) / SUM(total_cases))*100 AS percent_death
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


	
--In exploring the dataset, we realize there are some records where total deaths recorded are more than total cases recorded.
--This shows a discrepancy in the data, so we can eliminate such records
DELETE FROM CovidDeaths
WHERE total_deaths > total_cases



--Let's introduce a second table 'CovidVaccinations' that contains data relevant to global vaccination numbers
--View columns present in the CovidVaccination table
SELECT * FROM CovidVaccinations

	
--Join both tables
SELECT * FROM CovidDeaths AS Dea
JOIN CovidVaccinations AS Vac
ON Dea.location = Vac.location AND Dea.date = Vac.date


--Let's uncover the total number and percent of people tht has been vaccinated based on country
SELECT Dea.location, MAX(population) AS population, MAX(total_vaccinations) AS vaccination,
(MAX(total_vaccinations)/MAX(population))*100 AS percent_vaccinated
FROM CovidDeaths AS Dea JOIN CovidVaccinations AS Vac
ON Dea.location = Vac.location
WHERE Dea.continent IS NOT NULL
GROUP BY Dea.location


--We can choose to discover the rate at which new vaccinations are administered daily, based on country
--From the dataset's documentation, new_vaccination refers to number of doses administered.
--For the number of vaccination, we use either the 'people_vaccinated' column for people with atleast one dose or 'people_fully_vaccinated' column for over one dose
SELECT dea.continent, dea.location, dea.date, dea.population, vac.people_vaccinated
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


--Alternatively, we can create a rolling count that adds the number of new vaccinations for each country at each date.
SELECT dea.continent, dea.location, dea.date, dea.population, vac.people_vaccinated,
SUM(cast(vac.people_vaccinated as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

	
--The end of the rolling count at the most recent date gives the total number of vaccination for each country
--So, we can use this count to get the percent vaccinated in each country
--First, using a CTE to get percent of people that has gotten atleast one dose (people_vaccinated)
WITH popvsvacs (location, population, total_vaccination) AS
(
SELECT dea.location, dea.population, MAX(CAST(vac.people_vaccinated AS bigint)) AS total_vaccination
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.date = vac.date AND dea.location = vac.location
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.population
)
SELECT location, population, total_vaccination, (total_vaccination/population)*100  AS percent_vaccinated
FROM popvsvacs
where location = 'United States'

--FYI, we use cast to get the right value for MAX people_vaccinated
--For percent of people that have been fully vaccinated (people_fully_vaccinated)
WITH popvsvacs (location, population, total_vaccination) AS
(
SELECT dea.location, dea.population, MAX(CAST(vac.people_fully_vaccinated AS bigint)) AS total_vaccination
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.date = vac.date AND dea.location = vac.location
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.population
)
SELECT location, population, total_vaccination, (total_vaccination/population)*100  AS percent_vaccinated
FROM popvsvacs


--Let's use a TEMP table for the same analysis
CREATE TABLE #percent_vaccinated
(location nvarchar(255), population numeric, total_vaccination bigint)
	
INSERT INTO #percent_vaccinated
SELECT dea.location, dea.population, MAX(CAST(vac.people_vaccinated AS bigint)) AS total_vaccination
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.date = vac.date AND dea.location = vac.location
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.population

SELECT location, population, total_vaccination, (total_vaccination/population)*100  AS percent_vaccinated
FROM #percent_vaccinated
ORDER BY location

	
--LIMITATION OF TEMP TABLE: always have to drop table to carry our different exploration
--For instance, we defined people_vaccinated in the temp table, but if we want to find out percent of people_fully_vaccinated, it will be difficult because the column was not defined
--In such case, add the code line "DROP TABLE IF EXISTS TABLE_NAME" just before creating the TEMP table again with the new alteration
--For instance, let's checck for people_fully_vaccinated instead of people_vaccinated
	
DROP TABLE IF EXISTS #percent_vaccinated
CREATE TABLE #percent_vaccinated
(location nvarchar(255), population numeric, total_vaccination bigint)

INSERT INTO #percent_vaccinated
SELECT dea.location, dea.population, MAX(CAST(vac.people_fully_vaccinated AS bigint)) AS total_vaccination
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.date = vac.date AND dea.location = vac.location
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.population

SELECT location, population, total_vaccination, (total_vaccination/population)*100  AS percent_vaccinated
FROM #percent_vaccinated
where location = 'United States'
ORDER BY location




--Let's create a view to store the data for visualization (Project was done on SQL Server)
CREATE VIEW percent_vaccinated AS
SELECT dea.location, dea.population, MAX(CAST(vac.people_fully_vaccinated AS bigint)) AS total_vaccination
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.date = vac.date AND dea.location = vac.location
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.population

SELECT location, population, total_vaccination, (total_vaccination/population)*100  AS percent_vaccinated
FROM percent_vaccinated
where location = 'Nigeria'
ORDER BY location
