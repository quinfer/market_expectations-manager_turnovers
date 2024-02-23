import pandas as pd
df_anal=pd.read_csv("./data/df_anal.csv")
df_anal['event'] = df_anal['event'].astype('category')
df_anal['event'] = df_anal['event'].cat.reorder_categories(['Still in the job', 'A sacking', 'A poaching'])
df_anal['event_code'] = df_anal['event'].cat.codes  # Create a new column for the codes
df_anal=df_anal[df_anal['event_code']!=-1]
Duration=df_anal['Domestic Games in Charge']#predictors = ['Standardized_CumRS','Pct_of_Possible_Points_Won']
event=df_anal['event_code']
dummies = pd.get_dummies(df_anal['event'],prefix='event')
df_anal = pd.concat([df_anal,dummies] , axis=1)
# Extract and recategories the country codes to names
df_anal['Div_letter'] = df_anal['Div'].str.extract(r'([a-zA-Z]+)').apply(lambda x: ''.join(x), axis=1)
df_anal['Div_letter'] = df_anal['Div_letter'].astype('category')
df_anal['Div_letter'].value_counts()
dict = {'E': 'England', 'SP': 'Spain', 'SC':'Scotland','I': 'Italy', 'F': 'France', 'D': 'Germany', 'P': 'Portugal', 'N': 'Netherlands', 'T': 'Turkey', 'G': 'Greece', 'B': 'Belgium', 'G': 'Greece'}
df_anal['Country'] = df_anal['Div_letter'].map(dict)
df_anal['Country'] = df_anal['Country'].astype('category')
df_anal['Tier']=df_anal['Div'].str.extract(r'(\d+)')
df_anal=df_anal[(df_anal['Domestic Games in Charge']>5) & (df_anal['days_btw_spells']>=0)]
# Find the last game of each season
df_anal['Date'] = pd.to_datetime(df_anal['Date'])
Season_Ends = df_anal.drop_duplicates(['Div', 'Date'])
# Calculate how many days were between the last game of the season and the first game of the next season
Season_Ends['days_between_games'] = (Season_Ends['Date'] - Season_Ends.groupby(['Div'])['Date'].shift()).dt.days
# Keep only the last game of the season if it was at least 60 days away from the first game of the next season
Season_Ends = Season_Ends[Season_Ends['days_between_games'] > 60]
# Add the season start date to the matches table
Season_Ends['Year'] = Season_Ends['Date'].dt.year
Season_Ends = Season_Ends.drop_duplicates(['Div', 'Year'], keep='first')
# select only the columns we need and rename the date column
Season_Ends.rename(columns={'Date': 'Season_Start'}, inplace=True)
Season_Ends = Season_Ends[['Div', 'Year', 'Season_Start']]
df_anal['Year'] = df_anal['Date'].dt.year
df_anal = pd.merge(df_anal, Season_Ends, on=['Div', 'Year'], how='left')
# Create a season column in the matches table
df_anal['Season_Start'] = pd.to_datetime(df_anal['Season_Start_x'])
df_anal['Season'] = df_anal.apply(lambda row: f"{row['Year']-1}-{row['Year']}" if row['Date'] < row['Season_Start'] else f"{row['Year']}-{row['Year']+1}", axis=1)
# Fill in the missing season values for 2000 and 2022
df_anal['Season'].loc[(df_anal['Season'].isna()) & (df_anal['Year'] == 2000)] = "2000-2001"
df_anal['Season'].loc[(df_anal['Season'].isna()) & (df_anal['Year'] == 2022)] = "2022-2023"
df_anal['staff_dob'] = pd.to_datetime(df_anal['staff_dob'])
from datetime import timedelta
df_anal['age'] = (df_anal['Date'] - df_anal['staff_dob'])/ timedelta(days=365)
df_anal['Div'].value_counts()
df_anal=df_anal[(df_anal['Div']!="SC1")|(df_anal['Div']!="SC2")|(df_anal['Div']!="SC3")]
df_anal.to_csv("./data/df_anal_new.csv")
