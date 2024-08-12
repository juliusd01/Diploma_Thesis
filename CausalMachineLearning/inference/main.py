
import utils.matching as matching
import utils.ps_estimation as ps_estimation
import utils.output_generation as output_gen
import warnings

warnings.filterwarnings('ignore')

# SETTINGS
methods = ["logreg", "lasso", "cart", "random_forest", "boosted_trees"]

###########################
# Nearest Neighbor Matching
###########################
for method in methods:
    data = ps_estimation.estimate_propensity_scores(method=method)
    ps_estimation.plot_roc_auc_score(data, method=method)
    ps_estimation.check_common_support(data, method=method)
    matched_data = matching.estimate_att_nearest_neighbor(data, method=method, verbose=False)
    matched_data.to_csv(f"data/matched_data/{method}_matched.csv", index=False)
    ps_estimation.check_common_support(matched_data, method=f"{method}_matched")
    cov_balances = [matching.get_covariate_balance_for_ps_range(matched_data, ps_low=i, ps_high=i+0.2, method=method) for i in [0, 0.2, 0.4, 0.6, 0.8]]
    # model robustness
    ps_estimation.check_model_robustness(method=method)


output_gen.generate_all_latex_tables()


###########################
# IPW
###########################
# for method in methods:
#     data = ps_estimation.estimate_propensity_scores(method=method)
#     print(f"\nMethod: {method.upper()} \n")
#     matching.estimate_att_and_standard_errors_ipw(data, 100)