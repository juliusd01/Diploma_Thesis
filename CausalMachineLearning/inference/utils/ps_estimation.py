
import pandas as pd
import numpy as np
import statsmodels.api as sm
import seaborn as sns
import matplotlib.pyplot as plt
from sklearn.preprocessing import PolynomialFeatures
from sklearn.tree import DecisionTreeClassifier, plot_tree
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import roc_curve, roc_auc_score
import xgboost as xgb
from statsmodels.stats.outliers_influence import variance_inflation_factor



INDEPENDENT_VARIABLES = ["female", "born_germany", "parent_nongermany", "sportsclub_4_7", "music_4_7", "urban", "anz_osiblings", 'yob_1998.0', 'yob_1999.0', 'yob_2000.0', 'yob_2001.0',
       'yob_2002.0', 'yob_2003.0', 'abi_p', 'real_p', 'haupt_p', 'kindergarten_stats_unknown', 'parent_nongerman_unknown', 'education_unknown', 'anz_osiblings_unknown']

OUTCOME_VARS = ['oweight', 'sportsclub', 'sport_hrs', 'kommheard', 'kommgotten', 'kommused']

def __read_in_data() -> pd.DataFrame:
    data = pd.read_csv('data/preprocessed_data.csv')
    # only select participants from the years 2008/09, 2009/10, and 2010/11
    data = data[(data['year_3rd'] == "2008/09") | (data['year_3rd'] == "2009/10") | (data['year_3rd'] == "2010/11")]
    important_variables = ["treat", "oweight", "sportsclub", "sport_hrs", "kommheard", "kommgotten", "kommused", "female", "born_germany", "parent_nongermany", "sportsclub_4_7", "music_4_7", "urban", "anz_osiblings", "yob", "mob", "abi_p", "real_p", "haupt_p"]
    data = data[important_variables]

    return data


def handle_missing_values(data: pd.DataFrame):
    data['education_unknown'] = np.where(data[['abi_p', 'real_p', 'haupt_p']].isna().all(axis=1), 1, 0)
    # Fill NAs in the individual education columns with -1 to indicate that the specific education level is not applicable/answered
    data[['abi_p', 'real_p', 'haupt_p']] = data[['abi_p', 'real_p', 'haupt_p']].fillna(0)
    
    # create variable if stats for sportsclub and music at ages 4-7 are unknown
    data['kindergarten_stats_unknown'] = np.where(data[['sportsclub_4_7', 'music_4_7']].isna().all(axis=1), 1, 0)
    data[['sportsclub_4_7', 'music_4_7']] = data[['sportsclub_4_7', 'music_4_7']].fillna(0)

    # create variable if no statement was made if parents are german
    data['parent_nongerman_unknown'] = np.where(data['parent_nongermany'].isna(), 1, 0)
    data['parent_nongermany'] = data['parent_nongermany'].fillna(0)

    # create variable if number of other siblings is unknown
    data['anz_osiblings_unknown'] = np.where(data['anz_osiblings'].isna(), 1, 0)
    data['anz_osiblings'] = data['anz_osiblings'].fillna(0)
    
    data.dropna(inplace=True)
    data.reset_index(drop=True, inplace=True)

    return data


def __create_yob_dummies(data: pd.DataFrame) -> pd.DataFrame:
    # create dummy variables for year of birth
    data['yob'] = data['yob'].astype(str)
    data = pd.get_dummies(data, columns=['yob'], drop_first=True, dtype=int)

    return data

def generate_interactions(data, feature_columns):
    poly = PolynomialFeatures(degree=2, interaction_only=True, include_bias=False)
    interaction_matrix = poly.fit_transform(data[feature_columns])
    feature_names = poly.get_feature_names_out(input_features=feature_columns)
    interaction_df = pd.DataFrame(interaction_matrix, columns=feature_names)
    # Filter out the original features, leaving only interaction terms
    interaction_columns = [col for col in interaction_df.columns if " " in col]
    interaction_df = interaction_df[interaction_columns]
    return interaction_df

def get_variance_inflation_factor(data):
    vif_data = pd.DataFrame()
    vif_data["feature"] = data.columns
    vif_data["VIF"] = [variance_inflation_factor(data.values, i) for i in range(data.shape[1])]
    return vif_data

def __estimate_ps_logistic_regression(df: pd.DataFrame) -> pd.DataFrame:
    data = df[INDEPENDENT_VARIABLES]
    interactions_terms = ["female", "parent_nongermany", "sportsclub_4_7", "music_4_7", "urban", "anz_osiblings"]
    # Generate interaction and quadratic terms on standardized data
    interaction_quadratic_df = generate_interactions(data, interactions_terms)
    # Combine with the original data
    data_expanded = pd.concat([data, interaction_quadratic_df], axis=1)
    # Remove duplicate columns if any
    data_expanded = data_expanded.loc[:, ~data_expanded.columns.duplicated()]

    # check variance inflation factor
    vif = get_variance_inflation_factor(data_expanded)
    print(vif)

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


def __estimate_ps_CART(df: pd.DataFrame) -> pd.DataFrame:
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


def __estimate_ps_XGBoost(df: pd.DataFrame) -> pd.DataFrame:
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


def __estimate_ps_Random_Forest(df: pd.DataFrame) -> pd.DataFrame:
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

def __estimate_ps_LASSO(df: pd.DataFrame) -> pd.DataFrame:
    data = df[INDEPENDENT_VARIABLES]
    interactions_terms = ["female", "parent_nongermany", "sportsclub_4_7", "music_4_7", "urban", "anz_osiblings"]
    # Generate interaction and quadratic terms on standardized data
    interaction_quadratic_df = generate_interactions(data, interactions_terms)
    # Combine with the original data
    data_expanded = pd.concat([data, interaction_quadratic_df], axis=1)
    # Remove duplicate columns if any
    data_expanded = data_expanded.loc[:, ~data_expanded.columns.duplicated()]

    y = df['treat']
    
    # Standardize the features to the same scale
    scaler = StandardScaler()
    data_scaled = scaler.fit_transform(data_expanded)

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


def estimate_propensity_scores(method: str) -> pd.DataFrame:
    """Estimates the propensity scores for YOLO survey data using the specified method. The returned dataframe contains
    the propensity scores as a new column 'ps'.
    param method: The method to use for estimating the propensity scores. Choose from 'logreg', 'cart', 'boosted_trees', 'random_forest', 'lasso'.
    """
    # Prepare the data
    data = __read_in_data()
    data = handle_missing_values(data)
    data = __create_yob_dummies(data)
    # estimate the propensity scores by the specified method
    if method == "logreg":
        data = __estimate_ps_logistic_regression(df=data)
    elif method == "cart":
        data = __estimate_ps_CART(df=data)
    elif method == "boosted_trees":
        data = __estimate_ps_XGBoost(df=data)
    elif method == "random_forest":
        data = __estimate_ps_Random_Forest(df=data)
    elif method == "lasso":
        data = __estimate_ps_LASSO(df=data)
    else:
        raise ValueError("Invalid method specified. Please choose one of the following: 'logreg', 'cart', 'boosted_trees', 'random_forest', 'lasso'.")

    return data



def check_common_support(data: pd.DataFrame, method: str):
    """Creates a plot to check for common support by comparing the distribution of propensity scores for the treated and
    untreated groups.
    """
    sns.histplot(data[data['treat'] == 1]['ps'], color="red", label='Treated', bins=20)
    sns.histplot(data[data['treat'] == 0]['ps'], color="skyblue", label='Untreated', bins=20)
    plt.legend(title='Group')
    plt.xlabel('Propensity Score')
    plt.savefig(f"/home/juliusdoebelt/documents/repos/Diploma_Thesis/contributions/output/common_support/{method}.png")
    plt.close()


def plot_roc_auc_score(data: pd.DataFrame, method: str):
    # Calculate the ROC curve and AUC
    fpr, tpr, thresholds = roc_curve(data['treat'], data['ps'])
    auc_score = roc_auc_score(data['treat'], data['ps'])

    # Plot the ROC curve
    plt.figure()
    plt.plot(fpr, tpr, color='darkorange', lw=2, label=f'ROC curve (area = {auc_score:.2f})')
    plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title(f'Receiver Operating Characteristic {method.upper()}')
    plt.legend(loc="lower right")
    plt.savefig(f"/home/juliusdoebelt/documents/repos/Diploma_Thesis/contributions/output/roc_auc/{method}.png")
    plt.close()