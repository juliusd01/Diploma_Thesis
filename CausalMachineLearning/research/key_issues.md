# Collection of key issues encountered during Coding

# Key Issue 1: NA's for education status of parents
- Including parents education for covariates would ake a lot of sense.
- However, 7800 from 9300 surveys contain NA's on this topic
- How to work around this huge chunk of missing values? 

### 1. Delete rows with NA's
Disadvantages:
- Waste of data
- Only ~1500 observations left --> not an option
- Deleting NA's might also introduce bias as individuals where parents did not indicate ther education status might sysematically differ from the ones that did provide this information

### 2. Use ML Techniques
- Tree based algorithms seem to work with NA's (e.g. Random Forest, Gradient Boosting)


# Key Issue 2: How to compare different methods using Benchmark from experimental results? The long-term effects are not significant...