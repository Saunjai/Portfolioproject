SELECT * FROM [Portfolio Project] .. CovidDeathsCSV;
SELECT * FROM [Portfolio Project] .. CovidVaccinationsCSV;

--Had to update some of the information in the database so it would be usable
UPDATE [Portfolio Project] .. CovidDeathsCSV SET total_deaths = NULL WHERE total_deaths = 0;
UPDATE [Portfolio Project] .. CovidDeathsCSV SET total_cases = NULL WHERE total_cases = 0;
UPDATE [Portfolio Project] .. CovidDeathsCSV SET new_deaths = NULL WHERE new_deaths = 0;
UPDATE [Portfolio Project] .. CovidDeathsCSV SET new_cases = NULL WHERE new_cases = 0;
UPDATE [Portfolio Project] .. CovidVaccinationsCSV SET new_vaccinations = NULL WHERE new_vaccinations = 0;
UPDATE [Portfolio Project] .. CovidVaccinationsCSV SET total_vaccinations = NULL WHERE total_vaccinations = 0;

--Coviddeath information that i'll be using
SELECT location, date, total_cases, new_cases, total_deaths, new_deaths, population 
FROM [Portfolio Project] .. CovidDeathsCSV 
ORDER BY 1

--Total death count
SELECT location, MAX(cast(total_deaths as int)) AS total_death_count FROM [Portfolio Project]..CovidDeathsCSV
GROUP BY location
order by total_death_count desc

--Total number of cases and deaths for every location
SELECT location, SUM(cast(new_cases as int)) AS Total_Cases, SUM(cast(new_deaths as int)) AS Total_Deaths
FROM [Portfolio Project] .. CovidDeathsCSV 
GROUP BY location
ORDER BY 2 desc

--Likelihood of death if covid was contracted per location
SELECT location, SUM(cast(new_cases as float)) AS Total_Cases, SUM(cast(new_deaths as float)) AS Total_Deaths, 
(SUM(cast(new_deaths as float))/(SUM(cast(new_cases as float))))*100 AS total_death_percentage
FROM [Portfolio Project] .. CovidDeathsCSV 
GROUP BY location 
ORDER BY 2 desc

--Likelihood of death if covid was contracted per day in the USA
SELECT location, date, total_cases, total_deaths, ((cast(total_deaths as float))/(cast(total_cases as float)))* 100 AS total_death_percentage
FROM [Portfolio Project] .. CovidDeathsCSV 
WHERE location like '%state%' 
ORDER BY 1

--Percentage of population that got covid in the USA
SELECT location, date, population, total_cases, (cast(total_cases as float)/population)* 100 AS percent_infected
FROM [Portfolio Project] .. CovidDeathsCSV 
WHERE location like '%state%' 
ORDER BY 1 

--Percetage of population that died from covid in the USA
SELECT location, date, population, total_deaths, (cast(total_deaths as float)/population)*100 AS percent_dead
FROM [Portfolio Project] .. CovidDeathsCSV 
WHERE location like '%state%' 
ORDER BY 1 

--Each continent's death count
SELECT continent, MAX(cast(total_cases as int)) AS total_death_count
FROM [Portfolio Project] .. CovidDeathsCSV
GROUP BY continent 

--Global cases and deaths per day
SELECT date, SUM(cast(new_cases as int)) AS cases_globally, SUM(cast(new_deaths as int)) AS death_globally
FROM [Portfolio Project]..CovidDeathsCSV
GROUP BY date
ORDER BY 3 desc

--Global death percentage per day
SELECT date, SUM(cast(new_cases as int)) AS cases_globally, SUM(cast(new_deaths as int)) AS death_globally,
(SUM(cast(new_deaths as float))/(SUM(cast(new_cases as float))))* 100 AS global_death_percent
FROM [Portfolio Project]..CovidDeathsCSV
GROUP BY date
ORDER BY 4 desc

--Joining both death and vaccintation data
SELECT *
FROM [Portfolio Project]..CovidDeathsCSV deaths
join [Portfolio Project]..CovidVaccinationsCSV vacs
on deaths.location = vacs.location
and deaths.date = vacs.date

--Daliy vaccination
SELECT deaths.location, deaths.date, population, vacs.new_vaccinations
FROM [Portfolio Project]..CovidDeathsCSV deaths
join [Portfolio Project]..CovidVaccinationsCSV vacs
on deaths.location = vacs.location
and deaths.date = vacs.date
ORDER BY 1

--Daily percent of vaccinated population 
SELECT vacs.date, vacs.location, population, cast(vacs.new_vaccinations AS int) AS daily_vaccinations,
cast(vacs.new_vaccinations AS float)/population*100 AS percent_of_vaccinated_population
FROM [Portfolio Project]..CovidDeathsCSV deaths
join [Portfolio Project]..CovidVaccinationsCSV vacs
on deaths.location = vacs.location
and deaths.date = vacs.date
ORDER BY 2

--Vaccination rolling count
SELECT deaths.location, deaths.date, deaths.population, vacs.new_vaccinations,
SUM(cast(vacs.new_vaccinations AS int)) OVER (partition by deaths.location ORDER BY deaths.location, deaths.date) AS rolling_count_vaccinations
FROM [Portfolio Project]..CovidDeathsCSV deaths
join [Portfolio Project]..CovidVaccinationsCSV vacs
on deaths.location = vacs.location
and deaths.date = vacs.date
ORDER BY 1

--Rolling count using CTE vaccination percent
WITH PopvsVac (location, date, population, new_vaccinations, rolling_count_vaccinations) AS
(SELECT deaths.location, deaths.date, deaths.population, vacs.new_vaccinations,
SUM(cast(vacs.new_vaccinations AS float)) OVER (partition by deaths.location ORDER BY deaths.location, deaths.date) AS rolling_count_vaccinations
FROM [Portfolio Project]..CovidDeathsCSV deaths
join [Portfolio Project]..CovidVaccinationsCSV vacs
on deaths.location = vacs.location
and deaths.date = vacs.date)
SELECT *, (rolling_count_vaccinations/population)* 100 AS rolling_vaccination_percentage
FROM PopvsVac

