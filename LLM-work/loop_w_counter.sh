#!/bin/bash

# Counter
counter=0

# Function to make a call to the local LLM and parse the response
api_call() {
  local club_name="$1"
  local end_of_spell="$2" # Assuming this variable is provided
  local temp_output="temp_response.txt" # Temporary file to store LLM response
  
  # Concatenate all questions into a single prompt
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
  
  # Call the local LLM model
  echo "$prompt" | ollama run llama3 > "$temp_output"
  local response=$(cat "$temp_output")
  
  # Increment counter
  ((counter++))
  
  echo "Processing club ${club_name} (${end_of_spell}}) - ${counter} of ${total_lines} processed"
  
  # Assuming the response can be directly appended. Adjust based on the actual output format
  echo "${counter},${club_name},${end_of_spell},\"${response}\"" >> "${output_file}"
  
  # Cleanup temporary file
  rm -f "$temp_output"
}

input_file="LLM-work/input2.csv"
output_file="LLM-work/output2.csv"
echo "Counter,club_name,end_of_spell,API Response" > "${output_file}"

# Calculate total lines in the input file
total_lines=$(wc -l < "${input_file}")

while IFS=',' read -r club_name end_of_spell; do
  if [[ -n "$club_name" && -n "$end_of_spell" ]]; then
    api_call "$club_name" "$end_of_spell"
  fi
done < "${input_file}"

echo "Done processing all clubs. Total responses processed: $(( $(wc -l < "${output_file}") - 1 ))"
