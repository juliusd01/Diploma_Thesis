import pandas as pd

pd.set_option('display.max_columns', None)

# Check if empty cells exist for yob and treatment
data = pd.read_csv("/home/juliusdoebelt/documents/repos/Diploma_Thesis/contributions/output/matched_data.csv")
data_years = data[["yob_1998.0","yob_1999.0","yob_2000.0","yob_2001.0","yob_2002.0","yob_2003.0", "treat"]]
data_years = data_years.groupby("treat").sum()
print(data_years)


# Check if empty cells exist for interaction terms and treatment
interaction_terms = ['female parent_nongermany',
       'female sportsclub_4_7', 'female music_4_7', 'female urban',
       'female anz_osiblings', 'parent_nongermany sportsclub_4_7',
       'parent_nongermany music_4_7', 'parent_nongermany urban',
       'parent_nongermany anz_osiblings', 'sportsclub_4_7 music_4_7',
       'sportsclub_4_7 urban', 'sportsclub_4_7 anz_osiblings',
       'music_4_7 urban', 'music_4_7 anz_osiblings', 'urban anz_osiblings', 'treat']
data_interactions = data[interaction_terms]
data_interactions_grouped = data_interactions.groupby("treat").sum()
print(data_interactions_grouped, "\n\n")

# Check if any interaction term is perfectly correlated with treatment
correlation_matrix = data_interactions.corr()
treatment_correlation = correlation_matrix["treat"].drop("treat")
print(treatment_correlation)