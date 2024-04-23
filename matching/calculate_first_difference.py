import pandas as pd
import statsmodels.formula.api as smf
from statsmodels.compat import lzip
import statsmodels.stats.api as sms

# load data
df = pd.read_csv('data/preprocessed_data.csv')

# Filter the DataFrame to only include the years of treatment
df_treatment = df[df['year_3rd'].isin(['2008/09', '2009/10', '2010/11'])]
print(len(df_treatment))

# Define the variables and conditions
outcomes = ['kommheard', 'kommgotten', 'kommused', 'sportsclub', 'sport_hrs', 'oweight']

# Run the regressions and store the results
with open('first_difference_regression.txt', 'w') as f:
    for outcome in outcomes:
        model = smf.ols(f'{outcome} ~ treat', data=df_treatment).fit().get_robustcov_results(cov_type='cluster', groups=df_treatment['cityno'])
        f.write(model.summary().as_text())
        
        # Perform the Breusch-Pagan test
        names = ['Lagrange multiplier statistic', 'p-value', 'f-value', 'f p-value']
        test = sms.het_breuschpagan(model.resid, model.model.exog)
        f.write('\nBreusch-Pagan test:\n')
        f.write(lzip(names, test).__str__())
        
        f.write('\n\n')