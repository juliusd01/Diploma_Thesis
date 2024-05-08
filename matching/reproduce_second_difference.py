import statsmodels.formula.api as smf
import pandas as pd
from stargazer.stargazer import Stargazer

pd.set_option('display.max_rows', None)

# load cleaned data
df = pd.read_csv('data/preprocessed_data.csv')
treated = df[df['treat'] == 1]
controls = df[(df['treat'] == 0) & (df['year_3rd'].isin(['2008/09', '2009/10', '2010/11']))]
######################
# Summary statistics
######################
# Define the variables to summarize
variables = ['age', 'female', 'urban', 'academictrack', 'newspaper', 'art_at_home', 'kommheard', 'kommgotten', 'kommused', 'sportsclub', 'sport_hrs', 'oweight', 'tbula_3rd', 'treat']
# Generate summary statistics for the specified variables
summary = df[variables].describe().transpose()
# Format the summary statistics
summary = summary[['mean', 'std', 'min', 'max']].round(2)
print("Total summary statistics: ", summary)

# Generate summary statistics for the specified variables for the treated group
summary_treated = treated[variables].describe().transpose()
summary_treated = summary_treated[['mean', 'std', 'min', 'max']].round(2)
print("Treated summary statistics: ", summary_treated)
print(len(treated))

# Generate summary statistics for the specified variables for the control group
summary_controls = controls[variables].describe().transpose()
summary_controls = summary_controls[['mean', 'std', 'min', 'max']].round(2)
print(" \n Control summary statistics: ", summary_controls)
print(len(controls))

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