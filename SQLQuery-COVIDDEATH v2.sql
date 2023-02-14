--SELECT *
--FROM PortfolioProject.dbo.CovidDeaths
--ORDER BY 3,4;

--SELECT *
--FROM PortfolioProject.dbo.CovidVaccinations
--ORDER BY 3,4;

--select data that I am going to be using
--SELECT LOCATION
--	 , DATE
--	 , TOTAL_CASES
--	 , NEW_CASES
--	 , TOTAL_DEATHS
--	 , POPULATION
--FROM PortfolioProject.DBO.CovidDeaths
--ORDER BY 1,2;

-- looking total cases vs total death
-- shows likelihood of dying if you contract COVID in your country

--SELECT LOCATION
--	 , DATE
--	 , TOTAL_CASES
--	 , TOTAL_DEATHS
--	 , (TOTAL_DEATHS/TOTAL_CASES)*100 AS DEATHPERCENTAGE
--FROM PortfolioProject.DBO.CovidDeaths
--WHERE LOCATION LIKE '%state%'
--ORDER BY 1,2;

-- looking at total cases vs total population
-- shows what percentage of population got COVID
----SELECT LOCATION
----	 , DATE
----	 , TOTAL_CASES
----	 , POPULATION
----	 , (TOTAL_CASES/POPULATION)*100 AS CASEPERCENTAGE
----FROM PortfolioProject.DBO.CovidDeaths
------WHERE LOCATION LIKE '%states%'
----ORDER BY 1,2;

--looking at countries with the highest infection rate compared to population

--SELECT LOCATION
--	 , MAX(TOTAL_CASES) AS HIGHEST_INFECTION_COUNT
--	 , MAX((TOTAL_CASES/POPULATION))*100 AS INFECTED_PERCENTAGE
--FROM PortfolioProject.DBO.CovidDeaths
--GROUP BY LOCATION, POPULATION
--ORDER BY INFECTED_PERCENTAGE DESC;

--Showing countries with highest death count per population

--SELECT LOCATION
--	 , MAX(CAST(total_deaths AS INT)) AS TOTAL_DEATH_COUNT
--	-- , MAX((TOTAL_CASES/POPULATION))*100 AS INFECTED_PERCENTAGE
--FROM PortfolioProject.DBO.CovidDeaths
--WHERE CONTINENT IS NOT NULL
--GROUP BY LOCATION
--ORDER BY TOTAL_DEATH_COUNT DESC;

----Let's break things down by continent

--SELECT LOCATION
--	 , MAX(TOTAL_DEATHS) AS TOTALDEATHCOUNT
--FROM PortfolioProject.DBO.CovidDeaths
--WHERE CONTINENT IS NULL
--GROUP BY LOCATION
--ORDER BY TOTALDEATHCOUNT DESC;

--Global numbers

--SELECT DATE
--	 , SUM(NEW_CASES) AS TOTAL_NEW_CASES
--	 , SUM(NEW_DEATHS) AS TOTAL_NEW_DEATHS
--	 , SUM(NEW_DEATHS)/SUM(NEW_CASES)*100 AS NEW_DEATH_BY_CASES
--FROM PortfolioProject.DBO.CovidDeaths
--WHERE CONTINENT IS NOT NULL /*THIS IS TO EXCLUDE CONTINENT VALUE */
--GROUP BY DATE
--ORDER BY 1;

--looking at total population vs vaccinations
--SELECT DEA.continent
--	 , DEA.location
--	 , DEA.date
--	 , DEA.population
--	 , VAC.NEW_VACCINATIONS
--	 , SUM(CONVERT(INT,VAC.NEW_VACCINATIONS)) 
--	   OVER (
--			PARTITION BY DEA.location 
--			ORDER BY DEA.location
--		  , DEA.date 
--			) 
--			AS RollingPeopleVacc
--			/* OVER PARTITION BY is a ROLLING SUM comment.  
--			It AGGREGATES DAILY new vaccinations by DEA.location and date. */
--	 --, (RollingPeopleVacc/population)*100	  
--FROM PortfolioProject..CovidDeaths AS DEA
--JOIN PortfolioProject..CovidVaccinations AS VAC
--	ON DEA.location = VAC.location
--	AND DEA.date = VAC.date
--WHERE DEA.continent IS NOT NULL
--AND DEA.location = 'Albania'
--ORDER BY DEA.location
--	 , DEA.date;

--Use CTE
--WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVacc)
--AS
--	(
--	SELECT DEA.continent
--	 , DEA.location
--	 , DEA.date
--	 , DEA.population
--	 , VAC.NEW_VACCINATIONS
--	 , SUM(CONVERT(INT,VAC.NEW_VACCINATIONS)) 
--	   OVER (
--			PARTITION BY DEA.location 
--			ORDER BY DEA.location
--		  , DEA.date 
--			) 
--			AS RollingPeopleVacc
--			/* OVER PARTITION BY is a ROLLING SUM comment.  
--			It AGGREGATES DAILY new vaccinations by DEA.location and date. */
--		--, (RollingPeopleVacc/population)*100	  
--FROM PortfolioProject..CovidDeaths AS DEA
--JOIN PortfolioProject..CovidVaccinations AS VAC
--	ON DEA.location = VAC.location
--	AND DEA.date = VAC.date
--WHERE DEA.continent IS NOT NULL
--AND DEA.location = 'Albania'
----ORDER BY DEA.location
--	 --, DEA.date
--	 	)
--SELECT * 
--	 , (
--	 RollingPeopleVacc/population
--	    )*100 
--	 AS RollingPeopleVaccByPopulation
--FROM PopvsVac;


--Temp table
DROP Table if exists #PercentPopulationVaccinated
/*Always include Drop Table if plan on making alternations 
or running temp table multiple times, makes it easy
to maintain */

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255)
, Location nvarchar(255)
, Date datetime
, Population numeric
, New_vaccinations numeric
, RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT DEA.continent
	 , DEA.location
	 , DEA.date
	 , DEA.population
	 , VAC.NEW_VACCINATIONS
	 , SUM(CONVERT(INT,VAC.NEW_VACCINATIONS)) 
	   OVER (
			PARTITION BY DEA.location 
			ORDER BY DEA.location
		  , DEA.date 
			) 
			AS RollingPeopleVacc
			/* OVER PARTITION BY is a ROLLING SUM comment.  
			It AGGREGATES DAILY new vaccinations by DEA.location and date. */
		--, (RollingPeopleVacc/population)*100	  
FROM PortfolioProject..CovidDeaths AS DEA
JOIN PortfolioProject..CovidVaccinations AS VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
--WHERE DEA.continent IS NOT NULL
WHERE DEA.location = 'Albania'
--ORDER BY DEA.location
	 --, DEA.date
SELECT * 
	 , (
	 RollingPeopleVaccinated/population
	    )*100 
	 AS RollingPeopleVaccByPopulation
FROM #PercentPopulationVaccinated;	

--Creating view to store data for later visualization

CREATE VIEW PercentPopulationVaccinated AS

SELECT DEA.continent
	 , DEA.location
	 , DEA.date
	 , DEA.population
	 , VAC.NEW_VACCINATIONS
	 , SUM(CONVERT(INT,VAC.NEW_VACCINATIONS)) 
	   OVER (
			PARTITION BY DEA.location 
			ORDER BY DEA.location
		  , DEA.date 
			) 
			AS RollingPeopleVacc
			/* OVER PARTITION BY is a ROLLING SUM comment.  
			It AGGREGATES DAILY new vaccinations by DEA.location and date. */
		--, (RollingPeopleVacc/population)*100	  
FROM PortfolioProject..CovidDeaths AS DEA
JOIN PortfolioProject..CovidVaccinations AS VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
--ORDER BY DEA.location
	-- , DEA.date


SELECT *
FROM PercentPopulationVaccinated;

