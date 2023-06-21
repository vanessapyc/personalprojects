/*
Covid 19 Data Exploration with SQL
Skills: Joins, CTEs, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Total cases vs. total deaths
-- Likelihood of dying if you contract Covid in Canada
Select Location, Date, Total_Cases, Total_Deaths, (cast(Total_Deaths as decimal))/(cast(Total_Cases as decimal))*100 as DeathPercentage
From Portfolio..CovidDeaths
Where location ='Canada'
and Continent is not NULL
Order by 1, 2

-- Total cases vs. population
-- Percentage of population that contracted Covid in Canada
Select Location, Date, Population, Total_Cases, (cast(Total_Cases as decimal))/(cast(Population as decimal))*100 as ContractedPercentage
From Portfolio..CovidDeaths
Where location ='Canada'
and Continent is not NULL
Order by 1, 2

-- Determining countries with highest infection rate at infection peak
Select Location, Population, MAX(Total_Cases) as HighestInfectionCount, MAX(cast(Total_Cases as decimal))/(cast(Population as decimal))*100 as ContractedPercentage
From Portfolio..CovidDeaths
Where Continent is not NULL
Group by Location, Population
Order by ContractedPercentage DESC

-- Showing total death count by country
Select Location, MAX(Total_Deaths) as TotalDeathCount
From Portfolio..CovidDeaths
Where Continent is not NULL
Group by Location
Order by TotalDeathCount DESC

-- Showing total death count by continent
Select Continent, MAX(Total_Deaths) as TotalDeathCount
From Portfolio..CovidDeaths
Where Continent is not NULL
Group by Continent
Order by TotalDeathCount DESC

-- Global stats
Select SUM(New_Cases) as TotalCases, SUM(cast(New_Deaths as decimal)) as TotalDeaths, (SUM(cast(New_Deaths as decimal))/SUM(New_Cases))*100 as DeathPercentage
From Portfolio..CovidDeaths
Where Continent is not NULL
Order by 1, 2

-- Total population vs. vaccinations
-- Showing percentage of poopulation that has recieved 1+ Covid vaccines
-- Version 1: Using CTE to perform calculation on Partition By
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinations)
as
(
Select dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations, 
SUM(cast(vac.New_Vaccinations as decimal)) OVER (Partition by dea.Location Order by dea.Date) as RollingVaccinations
From Portfolio..CovidDeaths dea
Join Portfolio..CovidVaccinations vac
    On dea.Location = vac.Location and dea.Date = vac.Date
Where dea.Continent is not NULL
)

Select *, (RollingVaccinations/Population)*100 as PercentRollingVacc
From PopvsVac

-- Total population vs. vaccinations
-- Showing percentage of poopulation that has recieved 1+ Covid vaccines
-- Version 2: Using Temp Table to perform calculation on Partition By
DROP Table if EXISTS #PercentVaccinated

Create Table #PercentVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingVaccinations NUMERIC
)

Insert into #PercentVaccinated
Select dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations, 
SUM(cast(vac.New_Vaccinations as decimal)) OVER (Partition by dea.Location Order by dea.Date) as RollingVaccinations
From Portfolio..CovidDeaths dea
Join Portfolio..CovidVaccinations vac
    On dea.Location = vac.Location and dea.Date = vac.Date
Where dea.Continent is not NULL

Select *, (RollingVaccinations/Population)*100 as PercentRollingVacc
From #PercentVaccinated

-- Creating view to store data for later visualizations
Create View PercentVaccinated as
Select dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations, 
SUM(cast(vac.New_Vaccinations as decimal)) OVER (Partition by dea.Location Order by dea.Date) as RollingVaccinations
From Portfolio..CovidDeaths dea
Join Portfolio..CovidVaccinations vac
    On dea.Location = vac.Location and dea.Date = vac.Date
Where dea.Continent is not NULL

Select *
From PercentVaccinated
