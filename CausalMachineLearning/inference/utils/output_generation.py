import pandas as pd

METHODS = ["logreg", "lasso", "cart", "random_forest", "boosted_trees"]


def generate_all_latex_tables():
    """Generates Latex tables for the NNM results and the robustness analysis for each method.
    """
    csv_files_main = ["CausalMachineLearning/output/att/nearest_neighbor/logreg.csv", "CausalMachineLearning/output/att/nearest_neighbor/lasso.csv", "CausalMachineLearning/output/att/nearest_neighbor/cart.csv", "CausalMachineLearning/output/att/nearest_neighbor/random_forest.csv", "CausalMachineLearning/output/att/nearest_neighbor/boosted_trees.csv"]
    __generate_latex_table_for_NNM(csv_files_main, "main_results")
    csv_files_boosting = ["CausalMachineLearning/output/att/nearest_neighbor/boosted_trees.csv", "CausalMachineLearning/output/att/nearest_neighbor/boosted_trees_deep.csv", "CausalMachineLearning/output/att/nearest_neighbor/boosted_trees_low_lr.csv", "CausalMachineLearning/output/att/nearest_neighbor/boosted_trees_restrictive.csv", "CausalMachineLearning/output/att/nearest_neighbor/boosted_trees_lambda.csv"]
    __generate_latex_table_for_NNM(csv_files_boosting, "boosting_robustness_results")
    csv_files_cart = ["CausalMachineLearning/output/att/nearest_neighbor/cart.csv", "CausalMachineLearning/output/att/nearest_neighbor/cart_shallow.csv", "CausalMachineLearning/output/att/nearest_neighbor/cart_restrictive.csv", "CausalMachineLearning/output/att/nearest_neighbor/cart_more_trees.csv", "CausalMachineLearning/output/att/nearest_neighbor/cart_impurity.csv"]
    __generate_latex_table_for_NNM(csv_files_cart, "cart_robustness_results")
    csv_files_rf = ["CausalMachineLearning/output/att/nearest_neighbor/random_forest.csv", "CausalMachineLearning/output/att/nearest_neighbor/random_forest_shallow.csv", "CausalMachineLearning/output/att/nearest_neighbor/random_forest_more_trees.csv", "CausalMachineLearning/output/att/nearest_neighbor/random_forest_restrictive.csv", "CausalMachineLearning/output/att/nearest_neighbor/random_forest_impurity.csv"]
    __generate_latex_table_for_NNM(csv_files_rf, "random_forest_robustness_results")
    csv_files_lasso = ["CausalMachineLearning/output/att/nearest_neighbor/lasso_decreased_reg.csv", "CausalMachineLearning/output/att/nearest_neighbor/lasso_increased_reg.csv", "CausalMachineLearning/output/att/nearest_neighbor/lasso_more_iter.csv", "CausalMachineLearning/output/att/nearest_neighbor/lasso_no_intercept.csv", "CausalMachineLearning/output/att/nearest_neighbor/lasso.csv"]
    __generate_latex_table_for_NNM(csv_files_lasso, "lasso_robustness_results")
    csv_files_logreg = ["CausalMachineLearning/output/att/nearest_neighbor/logreg_decreased_reg.csv", "CausalMachineLearning/output/att/nearest_neighbor/logreg_increased_reg.csv", "CausalMachineLearning/output/att/nearest_neighbor/logreg_more_iter.csv", "CausalMachineLearning/output/att/nearest_neighbor/logreg_no_intercept.csv", "CausalMachineLearning/output/att/nearest_neighbor/logreg.csv"]
    __generate_latex_table_for_NNM(csv_files_logreg, "logreg_robustness_results")

def __generate_latex_table_for_NNM(csv_files: list, filename: str):
    """Generates a latex table from the CSV files containing the ATE and AI Standard Error estimates for the Nearest Neighbor Matching method.
    """
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
            data[var].append((row['ATE'], row['AI Standard Error']))
    # Create the LaTeX table
    latex_table = "\\begin{table}[ht]\n\\centering\n\\begin{tabular}{l" + "c" * len(csv_files) + "}\n"
    latex_table += "\\hline\n"
    latex_table += "Outcome Variable & " + " & ".join([f"{method}" for method in METHODS]) + " \\\\\n"
    latex_table += "\\hline\n"

    for var in outcome_variables:
        latex_table += var
        for (ate, se) in data[var]:
            latex_table += f" & {ate:.4f}"
        latex_table += " \\\\\n"
        latex_table += " "  # Adds a new row for standard errors
        for (_, se) in data[var]:
            latex_table += f" & ({se:.4f})"
        latex_table += " \\\\\n"

    latex_table += "\\hline\n"
    latex_table += "\\end{tabular}\n\\caption{Your caption here}\n\\label{tab:your_label}\n\\end{table}"
    # Save the LaTeX table to a file
    with open(f"CausalMachineLearning/output/latex/{filename}.tex", "w") as f:
        f.write(latex_table)