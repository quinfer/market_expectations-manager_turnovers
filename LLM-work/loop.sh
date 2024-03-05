#!/bin/bash

# Function to make a call to the local LLM and parse the response
api_call() {
  local club_name="$1"
  local end_of_spell="$2" # Assuming this variable is provided
  local temp_output="temp_response.txt" # Temporary file to store LLM response
  
  # Concatenate all questions into a single prompt
  local prompt="""
  Question 1: Which league did ${club_name} play in on ${end_of_spell}? 
  Question 2: Categorise the team name ${club_name} into one of the following: 
  First Team 
  Youth Team 
  Reserve Team 
  Womens Team 
  International Team
  Other
  Question 3: Given this ${end_of_spell} date, what division was ${club_name} in?
  """
  
  # Call the local LLM model
  echo "$prompt" | ollama run llama2 > "$temp_output"
  local response=$(cat "$temp_output")
  
  echo "Processing club ${club_name} (${end_of_spell}})"
  
  # Assuming the response can be directly appended. Adjust based on the actual output format
  echo "${club_name},${end_of_spell},\"${response}\"" >> "${output_file}"
  
  # Cleanup temporary file
  rm -f "$temp_output"
}

input_file="input.csv"
output_file="output.csv"
echo "club_name,end_of_spell,API Response" > "${output_file}"

while IFS=',' read -r club_name end_of_spell; do
  if [[ -n "$club_name" && -n "$end_of_spell" ]]; then
    api_call "$club_name" "$end_of_spell"
  fi
done < "${input_file}"

echo "Done processing all clubs. Total responses processed: $(( $(wc -l < "${output_file}") - 1 ))"
