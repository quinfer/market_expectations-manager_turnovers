from transformers import pipeline
import pandas as pd
generator = pipeline("text-generation")
# Load model directly
# from transformers import AutoTokenizer, AutoModelForCausalLM
# 
# tokenizer = AutoTokenizer.from_pretrained("mistralai/Mixtral-8x7B-Instruct-v0.1")
# model = AutoModelForCausalLM.from_pretrained("mistralai/Mixtral-8x7B-Instruct-v0.1")  
# Use a pipeline as a high-level helper
#from transformers import pipeline
#pipe = pipeline("text-generation", model="mistralai/Mixtral-8x7B-Instruct-v0.1")
# Example array of professional soccer club names
spells1 = pd.read_csv("raw_data/manager_spells_from_manager_urls_mgronly.csv")
club_names=spells1['club'].unique()
# Initialize an empty list to store the results
results = []

# Iterate over the array of club names
for club in club_names:
    # Prepare the prompt for the model
    prompt = f"Provide information about the soccer club {club}: its country of origin, division level, and whether it is a first team or a youth team."
    
    # Generate the response using the model
    responses=generator(prompt)
    
    # Assuming the first (or only) response is what we're interested in
    response_text = responses[0]
    
    # Store the response in our results list
    results.append({'ClubName': club, 'Information': response_text})

# Convert the results list to a DataFrame
import pandas as pd
results_df = pd.DataFrame(results)

# Display the DataFrame to verify the results
print(results_df)

# Specify the file path for the CSV file
csv_file_path = 'soccer_clubs_information_hf.csv'

# Save the DataFrame to a CSV file
results_df.to_csv(csv_file_path, index=False)

print(f"Results have been saved to {csv_file_path}")
