#!/bin/bash

# Counter
counter=0

# Read the prompt template from prompt_template.txt
prompt_template=$(cat prompt_template.txt)

# Function to make a call to the local LLM and parse the response
api_call() {
    local club_name="$1"
    local end_of_spell="$2"
    local temp_output="temp_response.txt" # Temporary file to store LLM response

    # Replace placeholders in the prompt template with local variables
    local prompt=$(echo "$prompt_template" | sed "s/<club_name>/${club_name}/g; s/<end_of_spell>/${end_of_spell}/g")

    # Call the local LLM model
    echo "$prompt" | ollama run llama3:70b > "$temp_output"
    local response=$(cat "$temp_output")

    # Extract the JSON part from the response
    local json_response=$(echo "$response" | sed -n '/<|start_header_id|>assistant<|end_header_id|>/,/<|eot_id|>/p' | sed 's/<|start_header_id|>assistant<|end_header_id|>//' | sed 's/<|eot_id|>//')

    # Increment counter
    ((counter++))
    echo "Processing club ${club_name} (${end_of_spell}) - ${counter} of ${total_lines} processed"

    # Write the JSON response to the master output file
    echo "$json_response" >> master_output.jsonl
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
jq --slurp '.' master_output.jsonl > master_output.json

# Convert JSON to CSV
jq -r '[["club_name", "end_of_spell", "spell_type", "country", "tier", "country_probability", "tier_probability"]] + (.[].response.variables[] | [.value, .value]) + (.[].response.results[] | [.value, .value, .value, .value, .value])' master_output.json > master_output.csv