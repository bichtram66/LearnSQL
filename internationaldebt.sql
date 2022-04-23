--1. Select all of column (limit the output to the top 100 row to keep the outout clean).

	SELECT TOP 100 *
	FROM Data$;

--2. Find the number of distinc countries

	SELECT COUNT(DISTINCT [Country Code]) AS total_distinct_countries
	FROM Data$;

--3. Find the distinct debt indicators

	SELECT DISTINCT [Indicator Code] AS distinct_indicators
	FROM Data$
	ORDER BY [Indicator Code];

--4. Total the amount of debt owed by the countries.

	SELECT ROUND(SUM(debt)/1000000,2) AS total_debt
	FROM Data$;

--5. Country with highest debt.

	SELECT TOP 1 [Country Name],
	SUM(debt) AS total_debt
	FROM Data$
	GROUP BY [Country Name]
	ORDER BY total_debt DESC;

--6. Average amount of debt across indicators.

	SELECT [Indicator Code],
	[Indicator Name],
	AVG(debt) AS average_debt
	FROM Data$
	GROUP BY [Indicator Code], [Indicator Name]
	ORDER BY average_debt;

--7. The highest amount of principal repayments (indicator code = DT.AMT.DLXF.CD)

	SELECT [Country Name],
	[Indicator Name]
	FROM Data$
	WHERE debt = (SELECT MAX(debt)
					FROM Data$
					WHERE  [Indicator Code] = 'DT.AMT.DLXF.CD');

--8. The most common debt indicators

	SELECT [Indicator Code],
	COUNT([Indicator Code]) AS count_indicator
	FROM Data$
	GROUP BY [Indicator Code]
	ORDER BY count_indicator DESC;


