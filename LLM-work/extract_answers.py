import pandas as pd
import re
file_path = 'LLM-work/output_adj.csv'
df = pd.read_csv(file_path)
df['text'] = df['text'].astype(str)
# Define a function to extract the text after each instance of "Answer" but before each instance of "confidence" along with confidence score
def extract_answers(text):
    answers = re.findall(r'Answer(?:\s*\d+)?: (.*?) (?:confidence rating|confidence level|confidence)?:? (\d+)', text, re.IGNORECASE)
    return answers    

# Define a function to split the answers into separate columns
def split_answers(answers):
    answer_dict = {'Answer_' + str(i+1): answer[0] for i, answer in enumerate(answers)}
    answer_dict['LLM_assigned_confidence_1'] = answers[0][1] if answers else None
    answer_dict['LLM_assigned_confidence_2'] = answers[1][1] if len(answers) > 1 else None
    answer_dict['LLM_assigned_confidence_3'] = answers[2][1] if len(answers) > 2 else None
    return pd.Series(answer_dict)

# Apply the function to the 'text' column to extract the text after each instance of "Answer" but before each instance of "confidence"
# remove any brackets from the text before extracting answers
df['text'] = df['text'].apply(lambda x: x.replace('(', '').replace(')', '').replace('[', '').replace(']', ''))
df['answers'] = df['text'].apply(extract_answers)
#if df['answers'].empty:
#    df['answers'] = df['text'].apply(lambda x: re.findall(r'Answer:\s*(.*?)\s*\((?:Confidence(?:\s*level)?:)?\s*(\d+)\)',x) if x else None)
# Split the answers into separate columns
df[['Answer_1', 'Answer_2', 'Answer_3', 'LLM_assigned_confidence_1', 'LLM_assigned_confidence_2', 'LLM_assigned_confidence_3']] = df['answers'].apply(split_answers)

# Print the full text of these rows with empty 'Answer_1' column
print(df[df['Answer_1'].isnull()]['text'])
# Drop the 'answers', 'text', 'API.response' columns as they are no longer needed
#df.drop(columns=['text'], inplace=True)
df.drop(columns=['answers'], inplace=True)
df.to_csv('LLM-work/outputadj_parsed.csv', index=False)