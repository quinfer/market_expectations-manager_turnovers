import pandas as pd
import json

def preprocess_data(raw_data):
    data = []
    current_entry = ""

    for line in raw_data.splitlines():
        line = line.strip()
        if line:
            # Accumulate lines until we find a closing brace
            current_entry += line
            if line.endswith("}"):
                try:
                    entry = json.loads(current_entry)

                    # # Standardize date format (assuming DD/MM/YY)
                    # if "/" in entry['date']:
                    #     day, month, year = entry['date'].split("/")
                    #     entry['date'] = f"20{year}-{month}-{day}"

                    data.append(entry)
                except json.JSONDecodeError as e:
                    print(f"Warning: Skipping invalid JSON object: {current_entry} - Error: {e}")
                finally:
                    current_entry = ""  # Reset for the next entry

    df = pd.DataFrame(data)
    return df

# Raw data from the JSON file named master_output.jsonl
with open("master_output.jsonl") as f:
    raw_data = f.read()

# Preprocess the data
df = preprocess_data(raw_data)

# Reorder columns
df = df[['club', 'date', 'country', 'League', 'Tier']]

# Write to CSV
df.to_csv("cleaned_football_data.csv", index=False)

print(f"Processed {len(df)} entries and saved to cleaned_football_data.csv")
