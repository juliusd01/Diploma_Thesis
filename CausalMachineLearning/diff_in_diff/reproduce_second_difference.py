import statsmodels.formula.api as smf
import pandas as pd
from stargazer.stargazer import Stargazer


# load cleaned data
df = pd.read_csv('data/preprocessed_data.csv')
df_latex = df.copy()
df_latex = df_latex[df_latex['year_3rd'].isin(['2008/09', '2009/10', '2010/11'])]
df_latex = pd.get_dummies(df_latex, columns=['yob'], prefix='yob', dtype=int)
treated = df_latex[df_latex['treat'] == 1]
controls = df_latex[df_latex['treat'] == 0]

######################
# Table 2: Summary statistics
######################
# Define the variables to summarize
variables = ['born_germany', 'parent_nongermany', 'female', 'sportsclub_4_7', 'music_4_7', 'urban', 'yob_1998.0', 'yob_1999.0', 'yob_2000.0', 'yob_2001.0', 'yob_2002.0', 'yob_2003.0', 'abi_p', 'real_p', 'haupt_p', 'anz_osiblings']

# Generate summary statistics for the specified variables for the treated and control group
summary_treated = treated[variables].describe().transpose()
summary_treated = summary_treated[['mean', 'std']].round(2).rename(columns={'mean': 'Treatment state', 'std': 'Treatment std'})
summary_controls = controls[variables].describe().transpose()
summary_controls = summary_controls[['mean', 'std']].round(2).rename(columns={'mean': 'Control states', 'std': 'Control std'})

# Calculate standardized difference
standardized_diff = (summary_treated['Treatment state'] - summary_controls['Control states']) / \
                    ((summary_treated['Treatment std']**2 + summary_controls['Control std']**2) / 2).apply(lambda x: x**0.5)
standardized_diff = standardized_diff.round(2).rename('Standardized Difference')

# Concatenate the summary statistics for treated and control groups and standardized difference
table_df = pd.concat([summary_treated[['Treatment state']], summary_controls[['Control states']], standardized_diff], axis=1)
# Escape underscores in the index
table_df.index = table_df.index.str.replace('_', '\\_')
latex_table = table_df.to_latex(index=True, caption="Summary Statistics", label="tab:summary_statistics", float_format="%.2f")
print(latex_table)

exit()
######################
# DiD Models
######################
# Define the variables and conditions
outcomes = ['kommheard', 'kommgotten', 'kommused', 'sportsclub', 'sport_hrs', 'oweight']

# Run the regressions and store the results
with open('main.txt', 'w') as f:
    for outcome in outcomes:
        model1 = smf.ols(f'{outcome} ~ treat + tbula_3rd + tcoh', data=df).fit().get_robustcov_results(cov_type='cluster', groups=df['cityno'])
        f.write(model1.summary().as_text())
        f.write('\n\n')
        model2 = smf.ols(f'{outcome} ~ treat + C(year_3rd) + C(bula_3rd)', data=df).fit().get_robustcov_results(cov_type='cluster', groups=df['cityno'])
        f.write(model2.summary().as_text())
        f.write('\n\n')
        model3 = smf.ols(f'{outcome} ~ treat + C(year_3rd) + C(bula_3rd) + C(cityno)', data=df).fit().get_robustcov_results(cov_type='cluster', groups=df['cityno'])
        f.write(model3.summary().as_text())
        f.write('\n\n')