
import pandas as pd
import numpy as np
from tqdm import tqdm
from causalml.match import NearestNeighborMatch, create_table_one
from sklearn.utils import resample
import logging

# Setup logger
logging.basicConfig(level=logging.INFO)

OUTCOME_VARS = ['oweight', 'sportsclub', 'sport_hrs', 'kommheard', 'kommgotten', 'kommused']

def match_on_propensity_score(df: pd.DataFrame, method: str, caliper: float=0.2, verbose: bool=False) -> pd.DataFrame:
    """Uses 1:1 Nearest Neighbor Matching to match on the propensity score using a caliper, with replacement.
    CAUTION: Estimating ATT is done only when there is no trimming.
    """
    len_before_matching = len(df)
    # Perform caliper matching
    matcher = NearestNeighborMatch(replace=True, ratio=1, random_state=42, caliper=caliper)
    matched_data = matcher.match(data=df, treatment_col='treat', score_cols=['ps'])
    len_after_matching = len(matched_data)
    if len_after_matching < 10054: # 5027 is number of treated units (5027*2 = 10054)
        print(f"Some observations were dropped during matching for the {method}. The estimates do not represent the ATT anymore")
    elif len_after_matching == 10054:
        print(f"All observations were matched for the {method}. The estimates represent the ATT.")
    else:
        raise ValueError(f"More observations after matching {len_after_matching} than before {len_before_matching}. Carefully examine the data.")
    
    treated_outcome = matched_data[matched_data['treat'] == 1][['oweight', 'sportsclub', 'sport_hrs', 'kommheard', 'kommgotten', 'kommused']]
    control_outcome = matched_data[matched_data['treat'] == 0][['oweight', 'sportsclub', 'sport_hrs', 'kommheard', 'kommgotten', 'kommused']]
    assert len(treated_outcome) == len(control_outcome)
    att = treated_outcome.mean() - control_outcome.mean()
    att.to_csv(f"CausalMachineLearning/output/outcome/att_{method}.csv")
    
    if verbose:
        # Print results
        print("\n -----------------------  Outcome  -----------------------\n")
        print(f"Mean outcome for treated: {treated_outcome.mean()}")
        print(f"Mean outcome for control: {control_outcome.mean()}")
        print(f"Average Treatment Effect on the Treated (ATT): {att}")

    return matched_data


def calculate_att_subclassification(df: pd.DataFrame, no_subclasses: int=5) -> float:
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


def calculate_att_ipw(df: pd.DataFrame, outcome_var: str):
    # Calculate IPW weights
    df['weight'] = df['treat'] / df['ps'] + (1 - df['treat']) / (1 - df['ps'])
    treated = df[df['treat'] == 1]
    control = df[df['treat'] == 0]
    # Calculate ATT
    att = (treated[outcome_var] / treated['weight']).mean() - (control[outcome_var] / control['weight']).mean()

    return att


def bootstrap_standard_errors(df: pd.DataFrame, n_bootstraps: int=1000):
    """Bootstrap the standard errors for the ATT estimate for the Inverse Propensity Weighting method.
    """
    np.random.seed(42)
    results = {}
    logging.info(f"Estimated the ATT, Bootstrap is about to start to get the standard error.")
    for outcome_var in OUTCOME_VARS:
        bootstrapped_atts = []
        for i in tqdm(range(n_bootstraps), desc=f"Bootstrap Progress for {outcome_var}"):
            bootstrap_sample = resample(df)
            bootstrapped_att = calculate_att_ipw(bootstrap_sample, outcome_var)
            bootstrapped_atts.append(bootstrapped_att)
    
        # Calculate the standard error
        standard_error = np.std(bootstrapped_atts)
        logging.info(f"Standard Error: {standard_error}")
        results[outcome_var] = round(standard_error, 4)

    return round(standard_error, 4)


def get_covariate_balance_for_ps_range(df: pd.DataFrame, ps_low: float, ps_high: float) -> pd.DataFrame:
    """Takes a dataframe and range for the propensity score and checks the covariate balance for the given range.
    Outputs the mean values of all individuals for the given range for treated and untreated individuals.
    """
    data = df
    features = df.columns.to_list()
    features.remove('treat')
    ps_range_data = pd.DataFrame(data[(data['ps'] >= ps_low) & (data['ps'] <= ps_high)])
    if len(ps_range_data) == 0:
        print(f"No individuals in the given range {ps_low} - {ps_high}.")
        return None
    balance = create_table_one(
                data=ps_range_data,
                treatment_col='treat',
                features=features
                )
    return balance

