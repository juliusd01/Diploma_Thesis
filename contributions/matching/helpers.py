
import pandas as pd
import numpy as np
import statsmodels.api as sm
import seaborn as sns
import matplotlib.pyplot as plt
from causalml.match import NearestNeighborMatch, create_table_one
from sklearn.preprocessing import PolynomialFeatures
from sklearn.tree import DecisionTreeClassifier, plot_tree
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler
import xgboost as xgb


INDEPENDENT_VARIABLES = ["female", "born_germany", "parent_nongermany", "sportsclub_4_7", "music_4_7", "urban", 'yob_1998.0', 'yob_1999.0', 'yob_2000.0', 'yob_2001.0',
       'yob_2002.0', 'yob_2003.0', 'abi_p', 'real_p', 'haupt_p', 'kindergarten_stats_unknown', 'parent_nongerman_unknown']

def __read_in_data(impute_ed_stats_p: bool) -> pd.DataFrame:
    if impute_ed_stats_p:
        data = pd.read_csv('data/preprocessed_data_imputed.csv')
    else:
        data = pd.read_csv('data/preprocessed_data.csv')
    # only select participants from the years 2008/09, 2009/10, and 2010/11
    data = data[(data['year_3rd'] == "2008/09") | (data['year_3rd'] == "2009/10") | (data['year_3rd'] == "2010/11")]
    important_variables = ["treat", "oweight", "sportsclub", "sport_hrs", "kommheard", "kommgotten", "kommused", "female", "born_germany", "parent_nongermany", "sportsclub_4_7", "music_4_7", "urban", "yob", "mob", "abi_p", "real_p", "haupt_p"]
    data = data[important_variables]

    return data


def __handle_missing_values(data: pd.DataFrame, impute_ed_stats_p: bool):
    if impute_ed_stats_p is False:
        data['education_unknown'] = np.where(data[['abi_p', 'real_p', 'haupt_p']].isna().all(axis=1), 1, 0)
        # Fill NAs in the individual education columns with -1 to indicate that the specific education level is not applicable/answered
        data[['abi_p', 'real_p', 'haupt_p']] = data[['abi_p', 'real_p', 'haupt_p']].fillna(-1)
    
    # create variable if stats for sportsclub and music at ages 4-7 are unknown
    data['kindergarten_stats_unknown'] = np.where(data[['sportsclub_4_7', 'music_4_7']].isna().all(axis=1), 1, 0)
    data[['sportsclub_4_7', 'music_4_7']] = data[['sportsclub_4_7', 'music_4_7']].fillna(-1)

    # create variable if no statement was made if parents are german
    data['parent_nongerman_unknown'] = np.where(data['parent_nongermany'].isna(), 1, 0)
    data['parent_nongermany'] = data['parent_nongermany'].fillna(-1)

    data.dropna(inplace=True)
    data.reset_index(drop=True, inplace=True)

    return data


def __create_yob_dummies(data: pd.DataFrame) -> pd.DataFrame:
    # create dummy variables for year of birth
    data['yob'] = data['yob'].astype(str)
    data = pd.get_dummies(data, columns=['yob'], drop_first=True, dtype=int)

    return data

def generate_interactions_and_quadratics(data, feature_columns):
    poly = PolynomialFeatures(degree=2, interaction_only=False, include_bias=False)
    interaction_quadratic_matrix = poly.fit_transform(data[feature_columns])
    feature_names = poly.get_feature_names_out(input_features=feature_columns)
    interaction_quadratic_df = pd.DataFrame(interaction_quadratic_matrix, columns=feature_names)
    return interaction_quadratic_df

def __estimate_ps_logistic_regression(df: pd.DataFrame, impute_ed_stats_p: bool) -> pd.DataFrame:
    if impute_ed_stats_p is False:
        INDEPENDENT_VARIABLES.append('education_unknown')
    data = df[INDEPENDENT_VARIABLES]
    interactions_terms = ["female", "parent_nongermany", "sportsclub_4_7", "music_4_7", "urban"]#, 'abi_p', 'real_p', 'haupt_p']
    # Generate interaction and quadratic terms on standardized data
    interaction_quadratic_df = generate_interactions_and_quadratics(data, interactions_terms)
    # Combine with the original standardized data
    data_expanded = pd.concat([data, interaction_quadratic_df], axis=1)
    # Remove duplicate columns if any
    data_expanded = data_expanded.loc[:, ~data_expanded.columns.duplicated()]
    # Drop columns with high vif
    data_expanded = data_expanded.drop(columns=['urban^2', 'music_4_7^2', 'sportsclub_4_7^2', 'female^2'])

    y = df['treat']
    # Fit the model
    logit_model = sm.Logit(y, data_expanded)
    result = logit_model.fit()
    # Get the propensity scores
    data_expanded['ps'] = result.predict(data_expanded)
    data_expanded['treat'] = y

    # add outcome variables to expanded data
    data_expanded['sportsclub'] = df['sportsclub']
    data_expanded['sport_hrs'] = df['sport_hrs']
    data_expanded['oweight'] = df['oweight']
    data_expanded['kommheard'] = df['kommheard']
    data_expanded['kommgotten'] = df['kommgotten']
    data_expanded['kommused'] = df['kommused']

    return data_expanded


def __estimate_ps_CART(df: pd.DataFrame, impute_ed_stats_p: bool) -> pd.DataFrame:
    if impute_ed_stats_p is False:
        INDEPENDENT_VARIABLES.append('education_unknown')
    data = df[INDEPENDENT_VARIABLES]

    y = df['treat']
    cart_model = DecisionTreeClassifier()
    cart_model.fit(data, y)
    data['ps'] = cart_model.predict_proba(data)[:, 1]
    data['treat'] = y

    # add outcome variables to expanded data
    data['sportsclub'] = df['sportsclub']
    data['sport_hrs'] = df['sport_hrs']
    data['oweight'] = df['oweight']
    data['kommheard'] = df['kommheard']
    data['kommgotten'] = df['kommgotten']
    data['kommused'] = df['kommused']

    # plot the decision tree
    # plt.figure(figsize=(40,20))
    # plot_tree(cart_model, filled=True, feature_names=INDEPENDENT_VARIABLES)
    # plt.show()

    return data


def __estimate_ps_XGBoost(df: pd.DataFrame, impute_ed_stats_p: bool) -> pd.DataFrame:
    if impute_ed_stats_p is False:
        INDEPENDENT_VARIABLES.append('education_unknown')
    data = df[INDEPENDENT_VARIABLES]

    y = df['treat']
    xgb_model = xgb.XGBClassifier(use_label_encoder=False, eval_metric='logloss')
    xgb_model.fit(data, y)
    data['ps'] = xgb_model.predict_proba(data)[:, 1]
    data['treat'] = y

    # add outcome variables to expanded data
    data['sportsclub'] = df['sportsclub']
    data['sport_hrs'] = df['sport_hrs']
    data['oweight'] = df['oweight']
    data['kommheard'] = df['kommheard']
    data['kommgotten'] = df['kommgotten']
    data['kommused'] = df['kommused']

    return data


def __estimate_ps_Random_Forest(df: pd.DataFrame, impute_ed_stats_p: bool) -> pd.DataFrame:
    if impute_ed_stats_p is False:
        INDEPENDENT_VARIABLES.append('education_unknown')
    data = df[INDEPENDENT_VARIABLES]

    y = df['treat']
    rf_model = RandomForestClassifier()
    rf_model.fit(data, y)
    data['ps'] = rf_model.predict_proba(data)[:, 1]
    data['treat'] = y

    # add outcome variables to expanded data
    data['sportsclub'] = df['sportsclub']
    data['sport_hrs'] = df['sport_hrs']
    data['oweight'] = df['oweight']
    data['kommheard'] = df['kommheard']
    data['kommgotten'] = df['kommgotten']
    data['kommused'] = df['kommused']

    return data

def __estimate_ps_LASSO(df: pd.DataFrame, impute_ed_stats_p: bool) -> pd.DataFrame:
    if impute_ed_stats_p is False:
        INDEPENDENT_VARIABLES.append('education_unknown')
    data = df[INDEPENDENT_VARIABLES]

    y = df['treat']
    
    # Standardize the features to the same scale
    scaler = StandardScaler()
    data_scaled = scaler.fit_transform(data)

    # Create and fit the LASSO model
    lasso_model = LogisticRegression(penalty='l1', solver='liblinear')
    lasso_model.fit(data_scaled, y)

    # Predict the propensity scores
    data['ps'] = lasso_model.predict_proba(data_scaled)[:, 1]
    data['treat'] = y

    # add outcome variables to expanded data
    data['sportsclub'] = df['sportsclub']
    data['sport_hrs'] = df['sport_hrs']
    data['oweight'] = df['oweight']
    data['kommheard'] = df['kommheard']
    data['kommgotten'] = df['kommgotten']
    data['kommused'] = df['kommused']

    return data


def estimate_propensity_scores(method: str, impute_ed_stats_p: bool) -> pd.DataFrame:
    """Estimates the propensity scores for YOLO survey data using the specified method. The returned dataframe contains
    the propensity scores as a new column 'ps'.
    """
    # Prepare the data
    data = __read_in_data(impute_ed_stats_p)
    data = __handle_missing_values(data, impute_ed_stats_p)
    data = __create_yob_dummies(data)
    # estimate the propensity scores by the specified method
    if method == "logreg":
        data = __estimate_ps_logistic_regression(df=data, impute_ed_stats_p=True)
    elif method == "cart":
        data = __estimate_ps_CART(df=data, impute_ed_stats_p)
    elif method == "boosted_trees":
        data = __estimate_ps_XGBoost(df=data, impute_ed_stats_p)
    elif method == "random_forest":
        data = __estimate_ps_Random_Forest(df=data, impute_ed_stats_p)
    elif method == "lasso":
        data = __estimate_ps_LASSO(df=data, impute_ed_stats_p)
    else:
        raise ValueError("Invalid method specified. Please choose one of the following: 'logreg', 'cart', 'boosted_trees', 'random_forest', 'lasso'.")

    return data



def check_common_support(data: pd.DataFrame):
    """Creates a plot to check for common support by comparing the distribution of propensity scores for the treated and
    untreated groups.
    """
    sns.histplot(data[data['treat'] == 0]['ps'], color="skyblue", label='Untreated', bins=20)
    sns.histplot(data[data['treat'] == 1]['ps'], color="red", label='Treated', bins=20)
    plt.legend(title='Group')
    plt.xlabel('Propensity Score')
    plt.title('Distribution of Propensity Scores for Treated and Untreated Groups')
    plt.show()


def match_on_propensity_score(df: pd.DataFrame, verbose: bool=False) -> pd.DataFrame:

    # Perform matching
    matcher = NearestNeighborMatch(replace=True, ratio=1, random_state=42)
    matched_data = matcher.match(data=df, treatment_col='treat', score_cols=['ps'])

    if verbose:
        treated_outcome = matched_data[matched_data['treat'] == 1][['oweight', 'sportsclub', 'sport_hrs', 'kommheard', 'kommgotten', 'kommused']]
        control_outcome = matched_data[matched_data['treat'] == 0][['oweight', 'sportsclub', 'sport_hrs', 'kommheard', 'kommgotten', 'kommused']]
        assert len(treated_outcome) == len(control_outcome)
        # Estimate ATT
        att = treated_outcome.mean() - control_outcome.mean()
        print(f"Mean outcome for treated: {treated_outcome.mean()}")
        print(f"Mean outcome for control: {control_outcome.mean()}")
        print(f"Average Treatment Effect on the Treated (ATT): {att}")

    return matched_data


def get_covariate_balance_for_ps_range(df: pd.DataFrame, ps_low: float, ps_high: float) -> pd.DataFrame:
    """Takes a dataframe and range for the propensity score and checks the covariate balance for the given range.
    Outputs the mean values of all individuals for the given range for treated and untreated individuals.
    """
    data = df
    features = df.columns.to_list()
    features.remove('treat')
    # print(features)
    ps_range_data = data[(data['ps'] >= ps_low) & (data['ps'] <= ps_high)]
    balance = create_table_one(
                data=ps_range_data,
                treatment_col='treat',
                features=features
                )
    
    return balance

