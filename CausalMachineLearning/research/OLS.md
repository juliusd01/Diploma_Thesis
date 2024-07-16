# Information for the Regression Models

## Fixed-Effects

- Can be used for categorical varibles; in this study applied to municipality (citino), grade(year_3rd) and district (bula_3rd)
- Control for any individual-specific attributes that do not vary across time

## Double-fixed Effects

-?

## Standard Errors

- The standard errors in the study are robust standard errors which are grouped by the municipality
- robust standard errors are used when assumption of homoscedasticity (constant variance of errors) is violated
- clustering the standard errors makes errors robust to within-cluster correlation. Used mostly in panel data setting when oberservations are correlated within groups (e.g. cities), but are assumed to be uncorrelated between groups
