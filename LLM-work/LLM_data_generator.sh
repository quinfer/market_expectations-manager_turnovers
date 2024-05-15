#!/bin/bash

# Counter
counter=0

# Read the prompt template from prompt_template.txt
prompt_template=$(cat prompt_template.txt)
   
# Function to make a call to the local LLM and parse the response
api_call() {
    local club_name="$1"
    local end_of_spell="$2"
    local temp_output="temp_response.txt"

    # Replace placeholders in the prompt template with local variables
    local prompt=$(echo "$prompt_template" | sed "s/<club_name>/${club_name}/g; s/<end_of_spell>/${end_of_spell}/g")

    # Call the local LLM model
    echo "$prompt" | ollama run llama3 > "$temp_output"
    local response=$(cat "$temp_output")

    # Increment counter
    ((counter++))
    echo "Processing club ${club_name} (${end_of_spell}) - ${counter} of ${total_lines} processed"

    # Append the JSON response to the master output file
    echo "$response" >> master_output.jsonl
}

# Read input from a file or stdin
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip the first line (header)
    [[ "$line" =~ ^club_name,end_of_spell$ ]] && continue

    # Parse the input line to extract club_name and end_of_spell
    club_name=$(echo "$line" | cut -d ',' -f 1)
    end_of_spell=$(echo "$line" | cut -d ',' -f 2)

    # Call the api_call function with the extracted variables
    api_call "$club_name" "$end_of_spell"
done < "${1:-/dev/stdin}"

# Create a valid JSON array from the JSONL file
echo "[" > master_output.json
sed "$!s/$/,/" master_output.jsonl >> master_output.json
echo "]" >> master_output.json

# Convert JSON to CSV using jq
jq -r '["club_name", "end_of_spell", "country", "division", "full_name", "country_confidence", "division_confidence", "full_name_confidence"], (.[] | [.club_name, .end_of_spell, .country, .division, .full_name, .country_confidence, .division_confidence, .full_name_confidence]) | @csv' master_output.json > master_output.csv
