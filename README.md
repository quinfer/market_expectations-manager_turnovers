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
