# Propensity Score Matching (PSM)

## Disadvantages

- One has to make strong assumption that observable variables do not influence treatment assignment

### Nearest Neighbor with Caliper
- caliper width
- with replacement or not
- how many control units matched to one treated unit

### Radius Matching


### Kernel Matching


### Exact Matching
- Big advantage is, that bootstrap could be used to calculate standard errors
- But actually not feasible, because I have 13 binary and 1 categorical variable which means I do not have enough matches. 2^13 is already > 8000. 