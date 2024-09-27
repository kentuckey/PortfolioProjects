--New codes for transforming form response dataset

--Load the code, change the column names for easy reference; 

--Snapshot of the data

SELECT TOP 1000 * FROM form_responses

--Since its a survey, there are a lot of nulls and inconsistent answers
--However, dropping all null rows would be bad because we will lose a lot of data
--Our task is to drop some nulls and standardize all the inconsistent answers.

    
--First column, Age is crucial in any analysis, so drop nulls
    
SELECT DISTINCT age FROM form_responses
SELECT * FROM form_responses WHERE age IS NULL
DELETE FROM form_responses WHERE age IS NULL

    
--Second column, Industry doesnt need to be standardized
    
SELECT DISTINCT industry FROM form_responses 

    
--Third column, Job title should not be standardized
    
SELECT DISTINCT hob_title FROM form_responses 

    
--4th, description of job title
--Too many nulls, we can concatenate with job title
    
UPDATE form_responses
SET job_title = COALESCE (job_title + ' (' + Description + ')', job_title)

--It's possible to have an error because some descriptions are too long and they exceed the max length for datatype in job_title
--Increase the max input for the data type "job_title" and try again

ALTER TABLE form_responses
ALTER COLUMN job_title NVARCHAR(400);

UPDATE form_responses
SET job_title = COALESCE(job_title + ' (' + Description + ')', job_title);

--Now, drop description column

ALTER TABLE form_responses
DROP COLUMN description


--5th, Annual salary, Datatype is in float
--We can change it to NVARCHAR and format it to have a comma and decimal place like compensation column.  

ALTER TABLE form_responses
ALTER COLUMN annual_salary NVARCHAR(255)

UPDATE form_responses
SET annual_salary = FORMAT(annual_salary, 'N2');


--6th, additional compensation: nothing to change

--7th, currency, looks good

SELECT DISTINCT currency FROM form_responses
ORDER BY currency


--8th, If other currencies, indicate. Since this column still holds currencies, We should include it into the currency column.

SELECT DISTINCT [If "Other," please indicate the currency here: ] FROM form_responses

--There are several inputs in this column, first we join the columns that are right abbreviations of currencies (3 LETTERS)
--First, concatenate under specific conditions

UPDATE form_responses
SET currency = [If "Other," please indicate the currency here: ]
WHERE currency = 'Other' AND LEN([If "Other," please indicate the currency here: ]) = 3

--Second, set all the inputs in the "If "Other," please indicate the currency here:" column with len(3) to NULL since we've added them to the "Currency" column

UPDATE form_responses
SET [If "Other," please indicate the currency here: ] = NULL
WHERE LEN([If "Other," please indicate the currency here: ]) = 3

--Now, we standardize each country's currency
--For israel
UPDATE form_responses
SET [If "Other," please indicate the currency here: ] = 'ILS' WHERE LEFT([If "Other," please indicate the currency here: ], 3) = 'ILS'
OR LEFT([If "Other," please indicate the currency here: ], 3) = 'NIS'
OR LEFT([If "Other," please indicate the currency here: ], 7) = 'Israeli'

--For Australia and New Zealand
UPDATE form_responses
SET [If "Other," please indicate the currency here: ] = 'AUD/NZD' WHERE LEFT([If "Other," please indicate the currency here: ], 3) = 'AUD'
OR LEFT([If "Other," please indicate the currency here: ], 10) = 'Australian'

--For USA
UPDATE form_responses
SET [If "Other," please indicate the currency here: ] = 'USD' WHERE [If "Other," please indicate the currency here: ] LIKE '%America%'
OR LEFT([If "Other," please indicate the currency here: ], 2) = 'US'
OR [If "Other," please indicate the currency here: ] LIKE '%USD%'
OR [If "Other," please indicate the currency here: ] LIKE '%$%'

--For Poland
UPDATE form_responses
SET [If "Other," please indicate the currency here: ] = 'PLN' WHERE [If "Other," please indicate the currency here: ] LIKE '%polish%'
OR LEFT([If "Other," please indicate the currency here: ], 3) = 'PLN'


--FOR OTHER COUNTRIES
UPDATE form_responses
SET [If "Other," please indicate the currency here: ] = CASE
    WHEN LEFT([If "Other," please indicate the currency here: ], 3) = 'RSU' THEN 'RSU'
    WHEN LEFT([If "Other," please indicate the currency here: ], 9) = 'Singapore' THEN 'SGD'
    WHEN LEFT([If "Other," please indicate the currency here: ], 3) = 'RM' THEN 'RMB'
    WHEN LEFT([If "Other," please indicate the currency here: ], 4) = 'Euro' THEN 'EUR'
    WHEN LEFT([If "Other," please indicate the currency here: ], 2) = 'Rs' THEN 'ZAR'
    WHEN [If "Other," please indicate the currency here: ] LIKE '%argenti%' THEN 'ARS'
    WHEN [If "Other," please indicate the currency here: ] LIKE '%philipp%' THEN 'PHP'
    WHEN [If "Other," please indicate the currency here: ] LIKE '%Rupee%' THEN 'INR'
    WHEN [If "Other," please indicate the currency here: ] LIKE '%KOREAN%' THEN 'KRW'
    WHEN [If "Other," please indicate the currency here: ] LIKE '%THAI%' THEN 'THB'
    WHEN [If "Other," please indicate the currency here: ] LIKE '%czech%' THEN 'CZK'
    WHEN [If "Other," please indicate the currency here: ] LIKE '%TAIWAN%' THEN 'TWD'
    WHEN [If "Other," please indicate the currency here: ] LIKE '%mexic%' THEN 'MXN'
    WHEN [If "Other," please indicate the currency here: ] LIKE '%CROATI%' THEN 'HRK'
    WHEN [If "Other," please indicate the currency here: ] LIKE '%norweg%' THEN 'NOK'
    WHEN [If "Other," please indicate the currency here: ] LIKE '%danish%' THEN 'DKK'
    ELSE [If "Other," please indicate the currency here: ] -- Retain the original value if no match is found
END;

--Next, add all the entries that have the correct abbreviations of currencies; i.e. length = 3

UPDATE form_responses
SET currency = [If "Other," please indicate the currency here: ]
WHERE currency = 'Other' AND LEN([If "Other," please indicate the currency here: ]) = 3

UPDATE form_responses
SET [If "Other," please indicate the currency here: ] = NULL
WHERE LEN([If "Other," please indicate the currency here: ]) = 3

--Then drop column [If "Other," please indicate the currency here: ]

ALTER TABLE form_responses
DROP COLUMN [If "Other," please indicate the currency here: ]

--Now, for the currency column, clean up and remove entries with 'Other' as currency

DELETE FROM form_responses
WHERE currency = 'Other'



--Depending on the analysis, we can do without the additional income context column

ALTER TABLE form_responses
DROP COLUMN additional_income_context

--For the 11th column "country_of_work"

SELECT DISTINCT country_of_work
FROM form_responses
    
--We need to standardize country_of_work
--First, we make detailed assumption that everyone earning USD is working in USA
--We can justify our assumption with the following code
    
SELECT * FROM form_responses
WHERE country_of_work = 'USA' AND currency NOT LIKE 'USD'

--People earning USD are predominantly from the USA, so we carry on with this assumption
    
UPDATE form_responses
SET country_of_work = 'USA' WHERE currency = 'USD'

--Do same for UK, You can also justify the assumption for UK too.

UPDATE form_responses
SET country_of_work = 'UK' WHERE currency = 'GBP'

--Same for Canada

UPDATE form_responses
SET country_of_work = 'Canada' 
WHERE currency = 'CAD'

--Perform individual updates on other countries

UPDATE form_responses
SET country_of_work = 
    CASE
        WHEN country_of_work LIKE '%Austral%' THEN 'Australia'
        WHEN country_of_work LIKE '%Zealan%' OR country_of_work LIKE '%NZ%' THEN 'New Zealand'
        WHEN country_of_work LIKE '%nether%' OR country_of_work LIKE '%NL%' OR country_of_work LIKE '%neder%' THEN 'Netherlands'
        WHEN country_of_work LIKE '%xico%' THEN 'Mexico'
        WHEN country_of_work LIKE '%BRA%' THEN 'Brazil'
        WHEN country_of_work LIKE '%Argentina%' THEN 'Argentina'
        WHEN country_of_work LIKE '%Czech%' THEN 'Czech Republic'
        WHEN country_of_work = 'India' THEN 'India'
        WHEN country_of_work LIKE '%ITALY%' THEN 'Italy'
        WHEN country_of_work LIKE '%LUXEM%' THEN 'Luxembourg'
        WHEN country_of_work LIKE '%US%' THEN 'USA'
        ELSE country_of_work
    END;



--For the 12th column, city_of_work, we also have so many inconsistent inputs
--We can view all the inputs in this column and how many times they were inputed
--The more a city was inputed, the less likely it was a mistake

SELECT city_of_work, COUNT(city_of_work) AS city_count
FROM form_responses
GROUP BY city_of_work
ORDER BY COUNT(city_of_work) DESC

--Theres a greater possibility of having very inconsistent and random inputs when city_count is 1
--So, change all city_of_work input that was entered by one person to N/A

UPDATE form_responses
SET city_of_work = 'N/A'
WHERE city_of_work IN (
    SELECT city_of_work
    FROM form_response2
    GROUP BY city_of_work
    HAVING COUNT(*) = 1
);



--Some entries contain more information seperated by a comma, we remove everything coming after the comma seperator

UPDATE form_responses
SET city_of_work = SUBSTRING(city_of_work, 1, CHARINDEX(',', city_of_work) - 1)
WHERE CHARINDEX(',', city_of_work) > 0;



--Now, standardize as many cities as possible

UPDATE form_responses
SET city_of_work = 
    CASE
        WHEN city_of_work = 'Bay Area' OR city_of_work LIKE '%Francisco%' THEN 'San Francisco'
        WHEN city_of_work LIKE '%new york%' OR city_of_work LIKE '%NYC%' THEN 'New York City'
        WHEN city_of_work LIKE '%los angeles%' THEN 'Los Angeles'
        WHEN city_of_work = 'DC' THEN 'Washington DC'
        ELSE city_of_work
    END;



--Alternatively, check and standardize the top 100 cities

WITH top_cities (city_of_work, city_count) AS
(
SELECT TOP 2000 city_of_work, COUNT(city_of_work) AS city_count FROM form_responses
GROUP BY city_of_work
ORDER BY 2 DESC
)

SELECT TOP 100 * FROM top_cities --Then standardize these cities


--NEXT, gender column; view all genders

SELECT DISTINCT gender FROM form_responses

--There are two similar columns, lets standardize them

UPDATE form_responses
SET gender = 'Other or prefer not to answer'
WHERE gender = 'Prefer not to answer' OR gender IS NULL
