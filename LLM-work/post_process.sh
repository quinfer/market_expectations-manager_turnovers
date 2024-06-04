#!/bin/bash

# Post-processing script
# This script takes the master_output.jsonl file as input
# and generates a cleaned master_output_cleaned.jsonl file
# containing only the JSON part of the responses.
# It also converts the cleaned JSON data to a CSV file.

# Check if the input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <master_output.jsonl>"
    exit 1
fi

input_file="$1"
cleaned_jsonl_file="master_output_cleaned.jsonl"
json_file="master_output.json"
csv_file="master_output.csv"

# Clear the output files
> "$cleaned_jsonl_file"
> "$json_file"
> "$csv_file"

# Process each line of the input file
while IFS= read -r line; do
    # Extract the JSON part from the line
    json_part=$(echo "$line" | sed -n '/^{/,/^}$/p' | jq -c '.')

    # Write the JSON part to the cleaned output file
    echo "$json_part" >> "$cleaned_jsonl_file"
done < "$input_file"

# Create a valid JSON array from the cleaned JSONL file
jq --slurp '.' "$cleaned_jsonl_file" > "$json_file"

# Convert JSON to CSV
jq -r '[["club_name", "end_of_spell", "spell_type", "country", "tier", "country_probability", "tier_probability"]] + (.[].response.variables[] | [.value, .value]) + (.[].response.results[] | [.value, .value, .value, .value, .value])' "$json_file" > "$csv_file"

echo "Post-processing completed."
echo "Cleaned output written to $cleaned_jsonl_file"
echo "JSON output written to $json_file"
echo "CSV output written to $csv_file"