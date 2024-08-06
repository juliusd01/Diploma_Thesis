
import pandas as pd
import numpy as np
from tqdm import tqdm
from causalml.match import NearestNeighborMatch, create_table_one
from sklearn.utils import resample
import logging
import matplotlib.pyplot as plt

# Setup logger
logging.basicConfig(level=logging.INFO)

OUTCOME_VARS = ['oweight', 'sportsclub', 'sport_hrs', 'kommheard', 'kommgotten', 'kommused']

def estimate_att_nearest_neighbor(df: pd.DataFrame, method: str, caliper: float=0.2, verbose: bool=False) -> pd.DataFrame:
    """Uses 1:1 Nearest Neighbor Matching to match on the propensity score using a caliper, with replacement.
    CAUTION: Estimating ATT is done only when there is no trimming.
    """
    len_before_matching = len(df)
    # Perform caliper matching
    matcher = NearestNeighborMatch(replace=True, ratio=1, random_state=42, caliper=caliper)
    matched_data = matcher.match(data=df, treatment_col='treat', score_cols=['ps'])
    len_after_matching = len(matched_data)
    if len_after_matching < 10054: # 5027 is number of treated units (5027*2 = 10054)
        print(f"{int((10054 - len_after_matching)/2)} observations of the treated units were not matched for the {method}. The estimates do not represent the ATT anymore")
    elif len_after_matching == 10054:
        print(f"All observations were matched for the {method}. The estimates represent the ATT.")
    else:
        raise ValueError(f"More observations after matching {len_after_matching} than before {len_before_matching}. Carefully examine the data.")
    
    treated_outcome = matched_data[matched_data['treat'] == 1][['oweight', 'sportsclub', 'sport_hrs', 'kommheard', 'kommgotten', 'kommused']]
    control_outcome = matched_data[matched_data['treat'] == 0][['oweight', 'sportsclub', 'sport_hrs', 'kommheard', 'kommgotten', 'kommused']]
    assert len(treated_outcome) == len(control_outcome)
    att = treated_outcome.mean() - control_outcome.mean()
    att.to_csv(f"CausalMachineLearning/output/att/nearest_neighbor/att_{method}.csv")
    
    if verbose:
        # Print results
        print("\n -----------------------  Outcome  -----------------------\n")
        print(f"Mean outcome for treated: {treated_outcome.mean()}")
        print(f"Mean outcome for control: {control_outcome.mean()}")
        print(f"Average Treatment Effect on the Treated (ATT): {att}")

    return matched_data


def estimate_att_subclassification(df: pd.DataFrame, no_subclasses: int=5) -> float:
    """Calculate the ATT using the subclassification method. The number of subclasses can be specified.
    """

    df['subclass'] = pd.qcut(df['ps'], q=no_subclasses, labels=False)
    # List to store ATT estimates and weights
    att_subclass = []
    weights = []
    
    for subclass in range(5):
        subclass_data = df[df['subclass'] == subclass]
        treated = subclass_data[subclass_data['treat'] == 1]
        control = subclass_data[subclass_data['treat'] == 0]
        
        # Calculate ATT within the subclass
        att = treated["oweight"].mean() - control["oweight"].mean()
        att_subclass.append(att)
        
        # Weight by the number of treated units in the subclass
        weights.append(len(treated))
    
    # Combine the ATT estimates to get the overall ATT
    att_subclass = np.array(att_subclass)
    weights = np.array(weights)

    # Weighted average of subclass ATT
    overall_att = np.sum(att_subclass * weights) / np.sum(weights)

    print(f'Estimated ATT: {overall_att}')


def estimate_att_ipw(df: pd.DataFrame, outcome_var: str):
    # Calculate IPW weights
    df['weight'] = df['treat'] / df['ps'] + (1 - df['treat']) / (1 - df['ps'])
    # Separate treated and control groups
    treated = df[df['treat'] == 1]
    control = df[df['treat'] == 0]
    # Estimate ATT
    att_treated = (treated[outcome_var] * treated['weight']).sum() / treated['weight'].sum()
    att_control = (control[outcome_var] * control['weight']).sum() / control['weight'].sum()
    att = att_treated - att_control

    return att


def estimate_att_and_standard_errors_ipw(df: pd.DataFrame, n_bootstraps: int=1000):
    """Bootstrap the standard errors for the ATT estimate for the Inverse Propensity Weighting method.
    """
    np.random.seed(42)
    results = {}
    logging.info(f"Estimated the ATT, Bootstrap is about to start to get the standard error.")
    for outcome_var in OUTCOME_VARS:
        bootstrapped_atts = []
        for i in tqdm(range(n_bootstraps), desc=f"Bootstrap Progress for {outcome_var}"):
            bootstrap_sample = resample(df)
            bootstrapped_att = estimate_att_ipw(bootstrap_sample, outcome_var)
            bootstrapped_atts.append(bootstrapped_att)
    
        # Calculate the standard error
        standard_error = np.std(bootstrapped_atts)
        logging.info(f"Standard Error: {standard_error}")
        results[outcome_var] = round(standard_error, 4)
    
    # save att and standard errors in csv file
    att = [estimate_att_ipw(df, outcome_var) for outcome_var in OUTCOME_VARS]
    standard_errors = pd.DataFrame.from_dict(results, orient='index', columns=['Standard Error'])
    print(f"ATT: {att}")
    print(f"Standard Errors: {standard_errors}")


    return round(standard_error, 4)


def get_covariate_balance_for_ps_range(df: pd.DataFrame, ps_low: float, ps_high: float) -> pd.DataFrame:
    """Takes a dataframe and range for the propensity score and checks the covariate balance for the given range.
    Outputs the mean values of all individuals for the given range for treated and untreated individuals.
    """
    data = df
    features = df.columns.to_list()
    features.remove('treat')
    features = [feature for feature in features if feature not in OUTCOME_VARS]
    # Filter data for the given propensity score range
    ps_range_data = pd.DataFrame(data[(data['ps'] >= ps_low) & (data['ps'] <= ps_high)])
    if len(ps_range_data) == 0:
        print(f"No individuals in the given range {ps_low} - {ps_high}.")
        return None
    features.remove('ps')
    balance_df = create_table_one(
                data=ps_range_data,
                treatment_col='treat',
                features=features
                )
    # Reset index to convert the index into a column named 'Variable'
    balance_df.reset_index(inplace=True)
    balance_df.rename(columns={'index': 'Variable'}, inplace=True)
    # Get number of treated for the given range
    number_of_treated = balance_df[balance_df["Variable"] == "n"].iloc[0, 1]
    # delete the row with 'n' as it is not needed
    balance_df = balance_df[balance_df["Variable"] != "n"]
    __plot_smd(balance_df, number_of_treated, ps_low, ps_high)
    return balance_df

def __plot_smd(balance_df: pd.DataFrame, number_of_treated: int, ps_low: float, ps_high: float):
    if balance_df is None:
        return None
    
    # Ensure 'SMD' is numeric
    balance_df['SMD'] = pd.to_numeric(balance_df['SMD'], errors='coerce')
    
    # Separate data into valid SMDs and NaNs
    valid_smd = balance_df.dropna(subset=['SMD'])
    nan_smd = balance_df[balance_df['SMD'].isna()]
    
    # Plot
    plt.figure(figsize=(8, 8))
    
    # Scatter plot of valid SMD values within the range -1 to 1
    within_range = valid_smd[(valid_smd['SMD'] >= -1) & (valid_smd['SMD'] <= 1)]
    plt.scatter(within_range['SMD'], within_range['Variable'], color='blue', label='Valid SMD')
    
    # Scatter plot of NaN SMD values
    plt.scatter([0] * len(nan_smd), nan_smd['Variable'], color='red', marker='x', label='NaN SMD')
    
    # Annotate values outside the range -1 to 1
    outside_range = valid_smd[(valid_smd['SMD'] < -1) | (valid_smd['SMD'] > 1)]
    for _, row in outside_range.iterrows():
        if row['SMD'] < -1:
            x_pos = -0.95
            ha = 'left'
        else:
            x_pos = 0.95
            ha = 'right'
        plt.scatter(x_pos, row['Variable'], color='blue')
        plt.text(x_pos + (0.05 if row['SMD'] < -1 else -0.05), row['Variable'], f"{row['SMD']:.2f}", fontsize=8, ha=ha, va='center')

    
    # Vertical line at 0
    plt.axvline(x=0, color='gray', linestyle='dashed')
    plt.axvline(x=0.25, color='red', linestyle='dashed')
    plt.axvline(x=-0.25, color='red', linestyle='dashed')
    
    # Set x-axis range
    plt.xlim(-1, 1)
    
    # Labels and title
    plt.xlabel('SMD')
    plt.ylabel('Variables')
    plt.title(f'n={number_of_treated}, PS Range=[{round(ps_low, 1)},{round(ps_high, 1)}]')
    
    # Grid for better readability
    plt.grid(True, axis='x', linestyle='--', linewidth=0.7, alpha=0.7)
    
    # Legend
    plt.legend()
    
    # Tight layout for better spacing
    plt.tight_layout()
    
    # Show plot
    plt.show()
