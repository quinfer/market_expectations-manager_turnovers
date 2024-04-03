#!/bin/bash

# use R to clean up csvs
Rscript csv_hack.r
# adjust the API responses
python adjust_text.py
# extract the LLM answers
python extract_answers.py