# Install and load the stringr package if not already installed
# install.packages("stringr")
library(stringr)

# Read the contents of the txt file
file_contents <- readLines("./LLM-work/responses.txt")

# Collapse the file contents into a single string
text <- paste(file_contents, collapse = "\n")

# Extract content within curly brackets using regular expressions
extracted_content <- str_extract_all(text, "\\{[^{}]*\\}")

# Print the extracted content
extracted_content |> purrr::flatten() -> extracted_content

library(jsonlite)

# Create a sample list of JSON-like strings
data_list <- extracted_content

# Function to parse JSON-like strings and handle missing fields
parse_json_string <- function(json_string) {
  # Replace single quotes with double quotes
  json_string <- gsub("'", "\"", json_string)
  
  tryCatch(
    {
      parsed_data <- fromJSON(json_string)
      parsed_data$probability <- as.numeric(parsed_data$probability)
      parsed_data
    },
    error = function(e) {
      warning(paste("Error parsing JSON string:", e$message))
      return(NULL)
    }
  )
}

# Parse the JSON-like strings and create a data frame
parsed_data <- lapply(data_list, parse_json_string)
parsed_data <- do.call(rbind, parsed_data)

# Convert the parsed data to a data frame
df <- as.data.frame(parsed_data, stringsAsFactors = FALSE)

# Print the resulting data frame
print(df)
