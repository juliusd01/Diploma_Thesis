# I calculate the difference between treated (school years 2008/09, 2009/10, 2010/11) and untreated (2006/07, 2007/08) Saxons

import pandas as pd
import statsmodels.formula.api as smf
from statsmodels.compat import lzip
import statsmodels.stats.api as sms

# load data
df = pd.read_csv('data/preprocessed_data.csv')

# Filter the data to only include Saxons
df_saxons = df[df['bula_3rd'].isin(['13. Sachsen'])]
print(df_saxons['treat'].value_counts())

# Define the variables and conditions
outcomes = ['kommheard', 'kommgotten', 'kommused', 'sportsclub', 'sport_hrs', 'oweight']

# Run the regressions and store the results
with open('first_difference_regression_saxons.txt', 'w') as f:
    for outcome in outcomes:
        model = smf.ols(f'{outcome} ~ treat', data=df_saxons).fit().get_robustcov_results(cov_type='cluster', groups=df_saxons['cityno'])
        f.write(model.summary().as_text())
        
        # Perform the Breusch-Pagan test
        names = ['Lagrange multiplier statistic', 'p-value', 'f-value', 'f p-value']
        test = sms.het_breuschpagan(model.resid, model.model.exog)
        f.write('\nBreusch-Pagan test:\n')
        f.write(lzip(names, test).__str__())
        
        f.write('\n\n')