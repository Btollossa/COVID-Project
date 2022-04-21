use PortfolioProject

--Select a subset of the data to get familiar with everything. 

SELECT TOP(5000) *
FROM	PortfolioProject..COVIDDeaths
WHERE	continent is not null

SELECT TOP(5000) *
FROM	PortfolioProject..COVIDVVax$

--Select the data that we are going to be using 
SELECT  Location, date, total_cases, new_cases, total_deaths, population
FROM	COVIDDeaths
WHERE	continent is not null

--Looking at Total Cases vs Total Deaths
--Shows the likelihood of dying if you contract COVID in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM	COVIDDeaths
WHERE location = 'United States'
	AND
		continent is not null

--Looking at Total Cases vs Population 
--Shows the population size vs total_cases and deathpercentage						*Get in the habit of exploring your data and all the things its telling. Ask questions from your data
SELECT location, date, population, total_cases, (total_cases/population)* 100 as PercentOfPopulationInfected
FROM	COVIDDeaths
WHERE location = 'United States'
	AND
	total_deaths != 'NULL'
	AND
	continent is not null

--Looking at Countries w/Highest Infection Rates Compared to Population
--Shows the Highest Infection Count of a location and the percent of pop infected as well as deceased  
SELECT	location, population, MAX(total_cases) as HighestInfectionCount, 
		MAX((total_cases)/(population))*100 PercentOfPopulationInfected
FROM	COVIDDeaths
WHERE	continent is not null 
GROUP BY location, population
ORDER BY PercentOfPopulationInfected DESC

--Looking at Countries w/Highest Death Count Per Population
SELECT	location, MAX(Cast(total_deaths as int)) HighestDeathCount   --we cast this as an integer because the data type on the design was nvarchar. This messed with how the numbers came back in our
FROM	COVIDDeaths			--our query so we cast it to get more accurate numbers. 
WHERE	continent is not null
GROUP BY location, population 
ORDER BY HighestDeathCount DESC


--Showing the continents with the Highest Death count 
SELECT	continent, MAX(Cast(total_deaths as int)) HighestDeathCount  
FROM	COVIDDeaths			
WHERE	continent is not null
GROUP BY continent
ORDER BY HighestDeathCount DESC

--Showing global numbers 
SELECT SUM(new_cases) TotalNewCases, SUM(CAST(new_deaths as INT)) TotalNewDeaths, SUM(CAST(New_deaths as INT))/SUM(New_Cases)*100 as DeathPercentage
FROM	COVIDDeaths
WHERE continent is not null

ORDER BY 1,2

--Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations			--this shows us the amount of new vaccinations 
	  ,SUM(CONVERT(bigint,vax.new_vaccinations)) OVER (partition by dea.location ORDER BY dea.location, dea.date) TotalRollingVax
FROM	COVIDVVax$ VAX
JOIN  COVIDDEATHS DEA
	on VAX.location = DEA.location
	AND
		VAX.date = DEA. date
WHERE	dea.continent is not NULL
	AND
		vax.new_vaccinations is not NULL
ORDER BY 1,2,3

--Creating a CTE too look at the Rolling population in relation to the vaccination
With POPvsVAX	(continent, location, date, population, TotalRollingVax, new_vaccinations)
as
(
	SELECT dea.continent, dea.location, dea.date, population, vax.new_vaccinations,
	SUM(cast(vax.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) TotalRollingVax
	FROM COVIDVVax$ VAX
	JOIN COVIDDeaths DEA
		on VAX.location = DEA.location
		AND
			VAX.date = DEA.date
	WHERE dea.continent is not null
)

SELECT *, (TotalRollingVax/population)*100 PercentageofPopVax
FROM POPvsVAX

--Creating a #TEMPTABLE to look at the same thing above
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population numeric,
New_Vaccinations numeric,
TotalRollingVax numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, population, vax.new_vaccinations,
	SUM(convert(bigint, vax.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) TotalRollingVax
FROM COVIDVVax$ VAX
JOIN COVIDDeaths DEA
	on VAX.location = DEA.location
	AND
		VAX.date = DEA.date
WHERE dea.continent is not null

SELECT *, (TotalRollingVax/Population)*100
FROM	#PercentPopulationVaccinated


--Creating View to store data for later visualizations
CREATE VIEW vw_PercentPopulationVaccinated
AS
SELECT dea.continent, dea.location, dea.date, dea.population,vax.new_vaccinations,
		SUM(CONVERT(INT,vax.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
		dea.date) as TotalRollingVax
FROM	COVIDVVax$ VAX
JOIN	COVIDDeaths DEA
	on  Vax.location = dea.location
	AND
		vax.date = dea.date
WHERE	dea.continent is not null