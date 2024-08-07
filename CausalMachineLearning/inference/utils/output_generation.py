import pandas as pd

METHODS = ["logreg", "lasso", "cart", "random_forest", "boosted_trees"]

def generate_latex_table_for_NNM(csv_files: list):

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
    with open("CausalMachineLearning/output/latex/att_nnm_all.tex", "w") as f:
        f.write(latex_table)