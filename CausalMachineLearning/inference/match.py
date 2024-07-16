
import utils.matching as matching
import utils.ps_estimation as ps_estimation
import warnings

warnings.filterwarnings('ignore')

# SETTINGS
method="random_forest"

data = ps_estimation.estimate_propensity_scores(method=method)
#helpers.plot_roc_auc_score(data, method=method)
#helpers.check_common_support(data, method=method)
att = matching.calculate_att_ipw(data)
se = matching.bootstrap_standard_errors(data, 1000)

#matched_data = helpers.match_on_propensity_score(data, method=method, verbose=False)
#helpers.check_common_support(matched_data, method=f"{method}_matched")

# cov_balance = [helpers.get_covariate_balance_for_ps_range(matched_data, ps_low=i, ps_high=i+0.2) for i in [0, 0.2, 0.4, 0.6, 0.8]]

# for index, df in enumerate(cov_balance):
#     if df is not None:
#         df.reset_index(inplace=True)
#         df.rename(columns={'index': 'Variable'}, inplace=True)
#         # Replace '_' with '\_' in the index names
#         df['Variable'] = df['Variable'].astype(str).apply(lambda x: x.replace('_', '\_'))
#         with open(f"/home/juliusdoebelt/documents/repos/Diploma_Thesis/contributions/output/outcome/cov_balance_{method}_{index}.tex", "w") as tex_file:
#             tex_file.write(df.to_latex(index=False, escape=False))
