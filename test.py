import pandas as pd

df = pd.read_stata('data/MSZ_main-data.dta')
print(df.head())
df.to_csv('data/MSZ_main-data.csv', index=False)