import pandas as pd
import re
file_path = 'LLM-work/output_adj.csv'
df = pd.read_csv(file_path)
df['API.Response'] = df['API.Response'].astype(str)
# Inspect the column types
print(df.dtypes)
print(df['API.Response'].head())
# Define a function to remove everything before the first instance of "Question"
def remove_before_question(text):
    index = text.find("Question 1")
    if index != -1:  # If "Question" is found
        return text[index:]
    else:
        return text  # If "Question" is not found, return the original text
# Apply the function to the 'text' column to remove everything before the first instance of "Question"
# convery API.Response to string
df['text'] = df['API.Response'].apply(remove_before_question)
df.drop(columns=['API.Response'], inplace=True)
print(df.head())
df.to_csv('LLM-work/output_adj.csv', index=False)


