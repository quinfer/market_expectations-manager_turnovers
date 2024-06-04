import json

# Open the input and output files
with open('master_output.jsonl', 'r') as infile, open('output.jsonl', 'w') as outfile:
    json_object = ''
    for line in infile:
        json_object += line.strip()
        if line.strip().endswith('}'):
            # Parse the JSON object and re-serialize it into a single-line format
            data = json.loads(json_object)
            json_singleline = json.dumps(data, separators=(',', ':'))
            # Write the single-line JSON object to the output file
            outfile.write(json_singleline + '\n')
            # Reset the JSON object
            json_object = ''