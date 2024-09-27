--Install packages

install.packages("tidyverse")
library(tidyverse)
install.packages('dplyr')
library(dplyr)
install.packages("tidyr")
library(tidyr)

--Loading Dataset
survey_results <- read.csv("/kaggle/input/stackoverflow-survey/survey_results_public.csv")
head(survey_results)

--Creating dataframes
first_question <- select(survey_results, MainBranch, Employment, DevType, CompTotal, Industry)
second_question <- select(survey_results, RemoteWork, Employment, Age, OrgSize, Country, CodingActivities)
third_question <- select(survey_results, CompTotal, YearsCode, YearsCodePro)
forth_question <- select(survey_results, LearnCode)
fifth_question <- select(survey_results, Employment, MainBranch, EdLevel)

--What industries do developers get paid the most?
glimpse(first_question)


--First, specify data for only professionals as developers
developer_professionals <- first_question %>% filter(MainBranch == "I am a developer by profession")


--From the data, CompTotal covers several currencies. To get an accurate compensation average for each industry, we have to make the currency consistent
--For this question, we can convert only currencies used atleast 100 times. Let's see the most used currencies from highest to lowest

currencyy_count <- survey_results %>% group_by(Currency) %>% summarise(count = n()) %>% arrange(desc(count))
currencyy_count <- na.omit(currencyy_count)
View(currencyy_count)


--Create a list of USD exchange_rates for the top currencies
exchange_rates <- c(
  "EUR" = 1.1,  # Euro to USD
  "GBP" = 1.3,  # British Pound to USD
  "INR" = 0.012,  # Indian Rupee to USD
  "USD" = 1,  # USD stays the same
  "JPY" = 0.007, # Japanese Yen to USD
  "CAD" = 0.75,
  "PLN" = 0.26,
  "AUD" = 0.67,
  "BRL" = 0.18,
  "SEK" = 0.097,
  "CHF" = 1.19,
  "ILS" = 0.27,
  "DKK" = 0.15,
  "RUB" = 0.011,
  "CZK" = 0.044,
  "NOK" = 0.093,
  "NZD" = 0.62,
  "TRY" = 0.03,
  "RON" = 0.22,
  "ZAR" = 0.056,
  "UAH" = 0.024,
  "HUF" = 0.0028,
  "CNY" = 0.14,
  "MXN" = 0.05,
  "PKR" = 0.0036,
  "IRR" = 0.000024,
  "BGN" = 0.57,
  "BDT" = 0.0084,
  "COP" = 0.00024,
  "IDR" = 0.000065,
  "ARS" = 0.0010,
  "PHP" = 0.018,
  "SGD" = 0.77,
  "RSD" = 0.0095,
  "VND" = 0.000041,
  "KRW" = 0.00075,
  "MYR" = 0.230548,
  "AED" = 0.27,
  "TWD" = 0.031,
  "CLP" = 0.0011,
  "NGN" = 0.00062,
  "HKD" = 0.13,
  "LKR" = 0.0033,
  "THB" = 0.030,
  "EGP" = 0.021,
  "KES" = 0.0078,
  "NPR" = 0.0074
)


--Now, convert the currencies listed above to USD and save in a new column "compensation_USD" 
developer_professionals <- survey_results %>%
    mutate(currency_short = substr(Currency, 1, 3)) %>% 
    mutate(compensation_USD = CompTotal * exchange_rates[currency_short])


--Then, we calculate industry that pays the most.
industry_compensation <- developer_professionals %>% 
  group_by(Industry) %>% 
  summarise(avg_compensation = mean(compensation_USD, na.rm = TRUE)) %>%
  arrange(desc(avg_compensation))

View(industry_compensation)


--How much does remote working matter to employees?
glimpse(second_question)


--First, filter the dataframe to only include employees before carrying out analysis
remote_work <- second_question %>%
    filter(Employment %in% 
    c("Employed, full-time", "Employed, part-time", "Independent contractor, freelancer, or self-employed"))

remote_happiness <- remote_work %>%
  group_by(RemoteWork) %>%
  summarize(count = n()) %>%
  arrange(desc(count)) %>%
  mutate(percentage = round(count / sum(count) * 100, 2))

View(remote_happiness)


--How does coding experience affect level of pay
glimpse(third_question)

earning <- third_question %>%
  group_by(YearsCode) %>%
  summarize(
    count = n(),
    mean_compensation = mean(CompTotal, na.rm = TRUE)
  ) %>%
  arrange(desc(mean_compensation))


View(earning)


--What's the most popular method of learning to code
glimpse(forth_question)

--From the dataset, respondents were given the opportunity to select as many learning methods as possible from the 10 specified options. 
--As such, the the LearnCode column contains more than one entry, seperated with a semi-colon.
--To get the most popular learning method, We seperate each learning option into a different column

seperate_data <- forth_question %>% 
    separate(LearnCode, into = c("resource_1", "resource_2", "resource_3", "resource_4", "resource_5", "resource_6", "resource_7", "resource_8","resource_9", "resource_10"), sep = ";", fill = "right")

head(seperate_data)


--Convert the dataframe "seperated_data" from wide data to long data
seperate_data <- seperate_data %>% 
    pivot_longer(names_to = "Resource", values_to = "correct", resource_1:resource_10)

head(seperate_data)


--Determine the count for all learning method
top_learning_avenue <- seperate_data %>% 
  group_by(correct) %>% 
  summarize(count = n()) %>% 
  arrange(desc(count))

View(top_learning_avenue)


--Are you more likely to get a job as a developer if you have a master's degree?
glimpse(fifth_question)

--For this, we evaluate the total number of masters degree holders to the number of employed masters degree holders.
--First, filter data for only employed developers respondents and get number of employed for each educational level


masters_preference <- fifth_question %>% 
  filter(Employment %in% c("Employed, full-time", "Employed, part-time", "Independent contractor, freelancer, or self-employed"), MainBranch == "I am a developer by profession")

masters_preference <- masters_preference %>%
  group_by(EdLevel) %>%
  summarize(count_employed = n())

View(masters_preference)


--Now, find the total number of respondents for each educational level, regardless of employment status
general <- fifth_question %>%
  group_by(EdLevel) %>%
  summarize(count_general = n())

View(general)


--Join both tables together
likelihood <- merge(masters_preference, general, by='EdLevel')
View(likelihood)


--Calculate the percentage likelihood of getting employed for each educational level.
likelihood <- likelihood %>%
    mutate(percentage_likelihood = round(count_employed / count_general * 100, 2)) %>%
    arrange(desc(percentage_likelihood))

View(likelihood)
     
