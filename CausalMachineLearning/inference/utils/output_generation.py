import pandas as pd
import os
from scipy.stats import norm


var_to_table_name = {
    "kommheard": "Program known",
    "kommgotten": "Voucher received",
    "kommused": "Voucher redeemed",
    "sportsclub": "Member of sports club",
    "sport_hrs": "Weekly sport hours",
    "oweight": "Overweight"
}


def generate_all_latex_tables():
    """Generates Latex tables for the NNM results and the robustness analysis for each method.
    """
    csv_files_main = ["CausalMachineLearning/output/att/nearest_neighbor/logreg.csv", "CausalMachineLearning/output/att/nearest_neighbor/LASSO.csv", "CausalMachineLearning/output/att/nearest_neighbor/CART.csv", "CausalMachineLearning/output/att/nearest_neighbor/RF.csv", "CausalMachineLearning/output/att/nearest_neighbor/Boosting.csv"]
    __generate_latex_table_for_NNM(csv_files_main, "main_results")
    csv_files_boosting = ["CausalMachineLearning/output/att/nearest_neighbor/Boosting.csv", "CausalMachineLearning/output/att/nearest_neighbor/Boosting_deep.csv", "CausalMachineLearning/output/att/nearest_neighbor/Boosting_low_lr.csv", "CausalMachineLearning/output/att/nearest_neighbor/Boosting_restrictive.csv", "CausalMachineLearning/output/att/nearest_neighbor/Boosting_lambda.csv"]
    __generate_latex_table_for_NNM(csv_files_boosting, "boosting_robustness_results")
    csv_files_cart = ["CausalMachineLearning/output/att/nearest_neighbor/CART.csv", "CausalMachineLearning/output/att/nearest_neighbor/CART_shallow.csv", "CausalMachineLearning/output/att/nearest_neighbor/CART_restrictive.csv", "CausalMachineLearning/output/att/nearest_neighbor/CART_more_trees.csv", "CausalMachineLearning/output/att/nearest_neighbor/CART_impurity.csv"]
    __generate_latex_table_for_NNM(csv_files_cart, "cart_robustness_results")
    csv_files_rf = ["CausalMachineLearning/output/att/nearest_neighbor/RF.csv", "CausalMachineLearning/output/att/nearest_neighbor/RF_shallow.csv", "CausalMachineLearning/output/att/nearest_neighbor/RF_more_trees.csv", "CausalMachineLearning/output/att/nearest_neighbor/RF_restrictive.csv", "CausalMachineLearning/output/att/nearest_neighbor/RF_impurity.csv"]
    __generate_latex_table_for_NNM(csv_files_rf, "random_forest_robustness_results")
    csv_files_lasso = ["CausalMachineLearning/output/att/nearest_neighbor/LASSO.csv", "CausalMachineLearning/output/att/nearest_neighbor/LASSO_decreased_reg.csv", "CausalMachineLearning/output/att/nearest_neighbor/LASSO_increased_reg.csv", "CausalMachineLearning/output/att/nearest_neighbor/LASSO_more_iter.csv", "CausalMachineLearning/output/att/nearest_neighbor/LASSO_no_intercept.csv"]
    __generate_latex_table_for_NNM(csv_files_lasso, "lasso_robustness_results")
    csv_files_logreg = ["CausalMachineLearning/output/att/nearest_neighbor/logreg.csv", "CausalMachineLearning/output/att/nearest_neighbor/logreg_decreased_reg.csv", "CausalMachineLearning/output/att/nearest_neighbor/logreg_increased_reg.csv", "CausalMachineLearning/output/att/nearest_neighbor/logreg_more_iter.csv", "CausalMachineLearning/output/att/nearest_neighbor/logreg_no_intercept.csv"]
    __generate_latex_table_for_NNM(csv_files_logreg, "logreg_robustness_results")


def significance_stars(p_value):
    if p_value < 0.01:
        return "***"
    elif p_value < 0.05:
        return "**"
    elif p_value < 0.10:
        return "*"
    else:
        return ""


def __generate_latex_table_for_NNM(csv_files: list, filename: str):
    """Generates a LaTeX table from the CSV files containing the ATE and AI Standard Error estimates for the Nearest Neighbor Matching method.
    """
    # Order of outcome variables in the LaTeX table
    desired_order = ["kommheard", "kommgotten", "kommused", "sportsclub", "sport_hrs", "oweight"]
    # Headings for columns
    filenames = [os.path.splitext(os.path.basename(path))[0] for path in csv_files]

    # Fixed values for the two columns
    fixed_col1_estimates = ["0.272***", "0.200***", "0.122***", "0.004", "-0.069", "0.005"]
    fixed_col2_estimates = ["0.379***", "0.235***", "0.144***", "-0.009", "-0.087", "-0.016"]
    fixed_col1_errors = ["(0.014)", "(0.011)", "(0.006)", "(0.019)", "(0.161)", "(0.016)"]
    fixed_col2_errors = ["(0.018)", "(0.011)", "(0.006)", "(0.013)", "(0.115)", "(0.013)"]

    # Read the CSV files into DataFrames
    dfs = [pd.read_csv(file) for file in csv_files]
    # Extract the outcome variables (assuming they are the same across all files)
    outcome_variables = dfs[0]['Outcome Variable']
    # Initialize a dictionary to store the data
    data = {var: [] for var in outcome_variables}
    # Populate the dictionary with ATE and AI Standard Error from each file
    for df in dfs:
        for var in outcome_variables:
            row = df[df['Outcome Variable'] == var].iloc[0]
            data[var].append((row['ATE'], row['AI Standard Error'], row['test_statistics']))

    # Create the LaTeX table
    latex_table = "\\begin{sidewaystable*}\n\\centering\n\\begin{tabular}{ll" + "c" + "c" * len(csv_files) + "}\n"
    latex_table += "\\hline\n"
    latex_table += "Outcome Variable & Base DD & First Diff & " + " & ".join([f"{method}" for method in filenames]) + " \\\\\n"
    latex_table += "\\hline\n"

    for i, var in enumerate(desired_order):
        latex_table += f"{var_to_table_name[var]} & {fixed_col1_estimates[i]} & {fixed_col2_estimates[i]}"
        for (ate, se, test_statistics) in data[var]:
            p_value = 2 * (1 - norm.cdf(abs(test_statistics)))
            stars = significance_stars(p_value)
            latex_table += f" & {ate:.3f}{stars}"
        latex_table += " \\\\\n"
        latex_table += " "  # Adds a new row for standard errors
        latex_table += f" & {fixed_col1_errors[i]} & {fixed_col2_errors[i]}"  # Fixed columns for standard errors
        for (_, se, _) in data[var]:
            latex_table += f" & ({se:.3f})"
        latex_table += " \\\\\n"

    # Adding the row for N
    latex_table += "\\hline\n"
    latex_table += "N & 5027 & 5027 " + " & ".join([""] * len(csv_files)) + " \\\\\n"
    latex_table += "\\hline\n"

    latex_table += "\\end{tabular}\n\\caption{Your caption here}\n\\label{tab:your_label}\n\\end{sidewaystable*}"

    # Save the LaTeX table to a file
    with open(f"CausalMachineLearning/output/latex/{filename}.tex", "w") as f:
        f.write(latex_table)

if __name__ == "__main__":
    generate_all_latex_tables()