
import helpers
import warnings

warnings.filterwarnings('ignore')

data = helpers.estimate_propensity_scores(method="logreg", impute_ed_stats_p=False)
#helpers.check_common_support(data)
matched_data = helpers.match_on_propensity_score(data, verbose=False)

print(helpers.get_covariate_balance_for_ps_range(matched_data, ps_low=0.2, ps_high=0.4))