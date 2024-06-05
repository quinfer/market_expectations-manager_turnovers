import json

with open("./LLM-work/responses.txt", 'r') as file:
  file_content = file.read()

# Find the first and last occurrences of '{' and '}'
start_index = file_content.find('{')
end_index = file_content.rfind('}')

# Extract the text between the first '{' and the last '}'
extracted_text = file_content[start_index:end_index + 1]

# Split the extracted text by newline character
json_strings = extracted_text.split('\n')

# Remove empty strings
json_strings = [js for js in json_strings if js.strip()]

# Load the JSON strings into a list of dictionaries
data = []
for js in json_strings:
  try:
    data.append(json.loads(js))
  except json.JSONDecodeError as e:
    print(f"Error decoding JSON string: {js}, Error: {e}")

import pandas as pd

# Create a dataframe from the list of dictionaries
df = pd.DataFrame(data)

# Display the first 5 rows
print(df.head().to_markdown(index=False, numalign="left", stralign="left"))

# Print the column names and their data types
print(df.info())
