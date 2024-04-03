## File descriptions
- paper.qmd contains a paper template with some visualisation of the group-level bayesian estimates.
- references.bib is a master file which can be called from paper.qmd to add literature.
- bayesian_estimation script run the baseline and group level models.  Depending on the number of parameters the group level estimates take between 9 to 12 hours.  The baseline estimates are much quicker.
- The data is split into two to avoid git large file issues.  To use simple load use either

```{python}
df1=pd.read_csv(df1)
df2=pd.read_csv(df2)
data=pd.concat(df1,df1)
```
OR

```{R}
read_csv(df1) |>
 bind_rows(read_csv(df2))-> dat
```

## LLM work
The LLM work uses llama2 populate the raw manager spells data with extra descriptive variables. Using ollama.ai
and the bash script `loop_w_counter.sh` to run the llama2 with the following prompt on each line in the input.csv file.

```{bash}
local prompt="""
  You are to search for information about ${club_name} on ${end_of_spell}. 
  Then answer the following questions filling in the blanks with the correct information.
  Only provide one word answers.
  Rate your confidence for each answer answer from 1 to 10.
  Question 1: In which country does ${club_name} play?
  Answer1: _________ confidence: _________
  Question 2: On ${end_of_spell}, what division was ${club_name} in? 
  Answer2: _________ confidence: _________
  Question 3: What is the full name of ${club_name}?
  Answer3: _________ confidence: _________
  """
```


## post processing
We combine post processing into three steps in the bash script `postprocessing_steps.sh`. The first steps tieds the csv files using an R script.  The second step uses `adjust_text.py` cleans up some of the API response text.  Finally, the third step uses the `extract_ansers.py` script to create a final csv file with the cleaned data which includes: 
- club_name
- end_of_spell
- country
- division
- full_name
- confidence_country
- confidence_division
- confidence_full_name
where the confidence variable is the LLM assignment of confidence in the answer.