# Stata Code to replicate the results of original study by Jan Marcus et al.

## Steps for Replication

1. Download Stata with a License
2. Copy the 3 folders 'Ado', 'Data' and 'Do' and put them in the same folder.
3. Adjust the path in line 11 of 00_master.do to the path of the folder from 2.
4. Open the 00_master.do file in Stata and exceute the code.
5. The folders 'log', 'out-data' and 'results' will be automatically created and filled when executing the code.

NOTE: All code contained in the folders 'Ado', 'Data' and 'Do' is by the authors of "The Long-Run Effects of Sports Club Vouchers for Primary School Children".

## Match output to tables and figures from the paper
The authors provided a [README](replication/README.pdf) where the output is matched to the figures and tables from the paper.
There are some minor mistakes in the provided README:
- Table 4 is created from [robust_p1.tex](replication/results/robust_p1.tex) and [robust_p2.tex](replication/results/robust_p2.tex)
- Table 5 is creted from [main_parents.tex](replication/results/main_parents.tex)