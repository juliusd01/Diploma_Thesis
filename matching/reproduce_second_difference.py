import statsmodels.formula.api as smf
import pandas as pd
from stargazer.stargazer import Stargazer

pd.set_option('display.max_rows', None)

# load cleaned data
df = pd.read_csv('data/preprocessed_data.csv')

######################
# Summary statistics
######################
# Define the variables to summarize
variables = ['age', 'female', 'urban', 'academictrack', 'newspaper', 'art_at_home', 'kommheard', 'kommgotten', 'kommused', 'sportsclub', 'sport_hrs', 'oweight', 'tbula_3rd', 'treat']
# Generate summary statistics for the specified variables
summary = df[variables].describe().transpose()
# Format the summary statistics
summary = summary[['mean', 'std', 'min', 'max']].round(2)
print(summary)

######################
# DiD Models
######################
# Define the variables and conditions
outcomes = ['kommheard', 'kommgotten', 'kommused', 'sportsclub', 'sport_hrs', 'oweight']

# Run the regressions and store the results
latex_output = ''
for outcome in outcomes:
    results = []
    model1 = smf.ols(f'{outcome} ~ treat + tbula_3rd + tcoh', data=df).fit()
    model2 = smf.ols(f'{outcome} ~ treat + C(year_3rd) + C(bula_3rd)', data=df).fit()
    model3 = smf.ols(f'{outcome} ~ treat + C(year_3rd) + C(bula_3rd) + C(cityno)', data=df).fit()
    results.extend([model1, model2, model3])

    # Output the results to a LaTeX file
    stargazer = Stargazer(results)
    stargazer.title(f'Evaluation of Sports Club Voucher Program: Main DD Results for {outcome}')
    stargazer.custom_columns(['Model 1', 'Model 2', 'Model 3'], [1, 1, 1])
    stargazer.significant_digits(3)
    latex_output += stargazer.render_latex() + '\n\n'

# Write the LaTeX output to a file
with open('main.tex', 'w') as f:
    f.write(latex_output)