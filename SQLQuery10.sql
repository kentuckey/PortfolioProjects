--COVID PROJECT

--**Select data we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

--**To check total cases vs total deaths(Check percentage of infected people that are actually dying)
SELECT location, date, total_cases, total_deaths,
CASE WHEN total_cases <= 0
THEN  0
ELSE (total_deaths/total_cases)*100
END AS percent_death
FROM CovidDeaths
ORDER BY 1,2

--**You can edit the code to view specific locations; eg, for the united states
SELECT location, date, total_cases, total_deaths,
CASE WHEN total_cases <= 0
THEN  0
ELSE (total_deaths/total_cases)*100
END AS percent_death
FROM CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

--***Measuring total cases with population
SELECT location, date, population, total_cases, (total_cases/population)*100 AS percent_infected
FROM CovidDeaths
WHERE location like '%Nigeria%'
ORDER BY 1,2


--***To see the location with the highest percent-infected (highest infection rate compared to population)
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX(total_cases/population)*100 AS percent_infected
FROM CovidDeaths
GROUP BY location, population
order by 4 DESC


--*****Countries with highest death count per population
SELECT location, population, MAX(total_deaths) AS death_count, MAX(total_deaths/population)*100 AS percent_death
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC



--******Lets work with continents
--Deaths based on continents(date is the most recent in the database, so it has the most updated death count) 
SELECT continent, SUM(total_deaths) AS death_count FROM CovidDeaths
WHERE continent is not null AND date='2024-07-21 00:00:00.000'
GROUP BY continent
ORDER BY death_count DESC


SELECT location, MAX(total_deaths) AS death_count FROM CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY death_count DESC


SELECT continent, SUM(MaxDeaths) AS SumOfMaxDeathsPerCountry
FROM (
    SELECT location, continent, MAX(total_deaths) AS MaxDeaths
    FROM CovidDeaths
	WHERE continent IS NOT NULL
    GROUP BY location, continent
) AS subquery 
GROUP BY continent 
ORDER BY SumOfMaxDeathsPerCountry DESC


--****Continents with highest death count per population
SELECT location, MAX(total_deaths) AS death_count, MAX(total_deaths/population)*100 AS percent_death
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY percent_death DESC



--******Obtaining global numbers
--Death percentage based on total cases
SELECT 
    continent, 
    date, 
    SUM(total_cases) AS cases, 
    SUM(total_deaths) AS deaths, 
    SUM(population) AS population, 
    (SUM(total_deaths) / SUM(total_cases))*100 AS percent_death
FROM 
    CovidDeaths
WHERE 
    continent IS NOT NULL 
    AND date = '2024-07-21 00:00:00.000'
GROUP BY 
    continent, 
    date
ORDER BY percent_death DESC



--*******************TO GET THE NUMBER OF CASES AND DEATHS GLOBALLY EVERYDAY SINCE THE PANDEMIC STARTED
SELECT SUM(total_cases) AS cases, SUM(total_deaths) AS deaths, (SUM(total_deaths) / SUM(total_cases))*100 AS percent_death
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--**********TO GET SAME RESULT GROUPED BY DATE
SELECT date, SUM(total_cases) AS cases, SUM(total_deaths) AS deaths, (SUM(total_deaths) / SUM(total_cases))*100 AS percent_death
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


--***************In exploring dataset, we realize there are some records where total deaths recorded are more than total cases recorded.
--**********This shows a discrepancy in the data, so we can eliminate such records
DELETE FROM CovidDeaths
WHERE total_deaths > total_cases



--************LETS INTRODUCE THE SECOND TABLE, COVIDVACCINATIONS
--FOR REFRESHER ON WHAT IT CONTAINS
SELECT * FROM CovidVaccinations

--************JOIN BOTH TABLES
SELECT * FROM CovidDeaths AS Dea
JOIN CovidVaccinations AS Vac
ON Dea.location = Vac.location AND Dea.date = Vac.date


--*************CHECK TOTAL AMOUNT AND PERCENT OF PEOPLE IN THE WORLD THAT HAS BEEN VACCINATED FOR EACH COUNTRY
SELECT Dea.location, MAX(population) AS population, MAX(total_vaccinations) AS vaccination,
(MAX(total_vaccinations)/MAX(population))*100 AS percent_vaccinated
FROM CovidDeaths AS Dea JOIN CovidVaccinations AS Vac
ON Dea.location = Vac.location
WHERE Dea.continent IS NOT NULL
GROUP BY Dea.location


--**************TO CHECK NEW VACCINATIONS ADMINISTERED EVERYDAY IN EACH COUNTRY
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3



--**************WE CAN CREATE A NEW COLUMN INTO THE SCRIPT THAT ADDS THE NUMBER OF NEW_VACCINATIONS FOR EVERY COUNTRY AT EACH DATE {ROLLING COUNT}
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


--***********WE CAN ALSO USE THE ROLLING COUNT ABOVE TO GET THE PERCENT VACCINATED IN EACH COUNTRY (USING CTE OR TEMP TABLE)
--****ULTIMATELY, THE END OF THE ROLLING COUNT GIVES THE TOTAL VACCINATION NUMBER FOR EACH COUNTRY
--****BUT SINCE ROLLINGCOUNT COLUMN IS JUST CREATED, WE CANT USE IT IN THE QUERY AGAIN ((ROLLINGCOUNT/POPULATION)*100)
--****FIRST WITH CTE NAMED popvsvac USING SAME QUERY AS ABOVE

WITH popvsvac (continent, location, date, population, new_vaccinations, rollingcount) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingcount
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT location, population, rollingcount, (rollingcount/population)*100 AS percent_vaccinated
FROM popvsvac


--*****************However, with the data, some countries have over 100% percent_vaccinated which would imply the rolling count is greater than the population.
--We go through the documentation and figure out that the new_vaccination column used for our rollingcount refers to number of doses not people
--To get the percent_vaccinated accurately, we have to use the people_vaccinated or people_fully_vaccinated column.

--To get percent of people that has gotten atleast one dose
WITH popvsvacs (location, population, total_vaccination) AS
(
SELECT dea.location, dea.population, MAX(CAST(vac.people_vaccinated AS bigint)) AS total_vaccination
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.date = vac.date AND dea.location = vac.location
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.population
--order by location
)
SELECT location, population, total_vaccination, (total_vaccination/population)*100  AS percent_vaccinated
FROM popvsvacs
where location = 'United States'

--(FYI, we use cast to get the right value for MAX people_vaccinated)


--**********For percent of people that have been fully vaccinated
WITH popvsvacs (location, population, total_vaccination) AS
(
SELECT dea.location, dea.population, MAX(CAST(vac.people_fully_vaccinated AS bigint)) AS total_vaccination
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.date = vac.date AND dea.location = vac.location
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.population
--order by location
)
SELECT location, population, total_vaccination, (total_vaccination/population)*100  AS percent_vaccinated
FROM popvsvacs



--**************LETS USE A TEMP TABLE FOR THE SAME EXAMPLE
CREATE TABLE #percent_vaccinated
(
location nvarchar(255), population numeric, total_vaccination bigint)

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

--**********LIMITATION OF TEMP TABLE, you have to define every column you'll need when creating the temp table because it'll be difficult to alter it later
--For instance, we defined people_vaccinated in the temp table, but if we want to find out percent of people_fully_vaccinated, it will be difficult because we did not define the column
--IN SUCH CASE, ADD THE CODE LINE "DROP TABLE IF EXISTS TABLE_NAME" JUST BEFORE CREATING THE TEMP TABLE AGAIN WITH THE NEW ALTERATION.
--FOR INSTANCE, WE WANT TO CHECK FOR people_fully_vaccinated INSTEAD OF people_vaccinated

DROP TABLE IF EXISTS #percent_vaccinated
CREATE TABLE #percent_vaccinated
(
location nvarchar(255), population numeric, total_vaccination bigint)

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




--***************CREATING A VIEW TO STORE DATA FOR VISUALIZATION
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