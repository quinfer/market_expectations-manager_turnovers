# LLM API Call and Data Processing Script

This bash script automates the process of making API calls to a local LLM (Language Model) and processes the responses to generate JSON and CSV output files. It reads input data from a file or stdin, replaces placeholders in a prompt template with the input values, and captures the JSON responses from the LLM.

## Prerequisites

- Make sure you have `jq` installed on your system. You can install it using a package manager like `apt-get` on Ubuntu or Debian, or `brew` on macOS.

## Setup

1. Create a file named `prompt_template.txt` in the same directory as the script. This file should contain the prompt template with placeholders for `{{club_name}}` and `{{end_of_spell}}`.

2. Prepare your input data file or ensure that the input data is provided via stdin. Each line of input should contain the `club_name` and `end_of_spell` values separated by a comma.

## Usage

1. Make the script executable by running the following command:
   ```
   chmod +x script_name.sh
   ```

2. Run the script by providing the input file as an argument or piping the input data via stdin:
   ```
   ./script_name.sh input_file.txt
   ```
   or
   ```
   cat input_file.txt | ./script_name.sh
   ```

## Script Functionality

1. The script reads the prompt template from `prompt_template.txt`.

2. It defines a function called `api_call` that performs the following steps:
   - Replaces the placeholders `{{club_name}}` and `{{end_of_spell}}` in the prompt template with the corresponding input values.
   - Calls the local LLM using the command `ollama run llama3` and saves the response to a temporary file.
   - Appends the JSON response to the `master_output.jsonl` file.
   - Increments a counter to keep track of the number of clubs processed.

3. The script reads input data from a file or stdin using a `while` loop with `read -r line`. It assumes that each line of input contains the `club_name` and `end_of_spell` values separated by a comma.

4. For each line of input, the script extracts the `club_name` and `end_of_spell` values using `cut` commands and passes them to the `api_call` function.

5. After processing all the input lines, the script creates a valid JSON array from the `master_output.jsonl` file. It adds an opening bracket `[` to `master_output.json`, appends the contents of `master_output.jsonl` with a trailing comma added to each line except the last one using `sed '$!s/$/,/'`, and adds a closing bracket `]` to complete the JSON array.

6. Finally, the script converts the JSON data to CSV using the `jq` command. It specifies the desired column headers and extracts the corresponding values from each JSON object in the array. The resulting CSV data is redirected to `master_output.csv`.

## Output Files

- `master_output.jsonl`: Contains the JSON responses from the LLM, with each response on a separate line.
- `master_output.json`: Contains a valid JSON array of the responses.
- `master_output.csv`: Contains the extracted data in CSV format, with columns for `club_name`, `end_of_spell`, `country`, `division`, `full_name`, and their corresponding confidence values.

## Customization

- If the structure of your JSON responses differs from the assumed structure, you may need to adjust the `jq` command in the script to extract the desired values correctly.

## Troubleshooting

- If the script encounters any issues, make sure that:
  - The `prompt_template.txt` file exists and contains the correct prompt template.
  - The input data is provided in the expected format (comma-separated `club_name` and `end_of_spell` values).
  - The `jq` command is installed on your system.
  - The script has the necessary permissions to read input files and write output files.

For any further assistance or questions, please contact the script maintainer.
