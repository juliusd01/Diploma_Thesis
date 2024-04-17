


clear
set mem 400m
set more off
version 15.1

* Here you have to change the PATH
* I stored the files in the following path: G:\Dokumente\UNI\Semester8\Diplomarbeit\replication
global MY_PATH "Add your path here"

* Define relative paths 
global DATA_IN "$MY_PATH/Data/"
global DATA_OUT "$MY_PATH/out-data/"
global MY_TAB "$MY_PATH/results/"
global DO "$MY_PATH/Do/"

cap mkdir "$MY_PATH/out-data"
cap mkdir "$MY_PATH/log"
cap mkdir "$MY_PATH/results"


* disable all other paths for adofiles, ownly use those adofiles provided in this program
cap adopath - PERSONAL
cap adopath - PLUS
cap adopath - SITE
cap adopath - OLDPLACE
adopath ++ "$MY_PATH/Ado/"


* start the log file
cap 	log close
local 	datetime : di %tcCCYY.NN.DD!-HH.MM.SS `=clock("$S_DATE $S_TIME", "DMYhms")'
local 	logfile "$MY_PATH/log/v_`datetime'.log.txt"
log 	using "`logfile'", text

	
* Perform main analyses
do 	$DO/01_maketables.do
do 	$DO/02_makegraphs.do
do 	$DO/03_synthetic_control.do		
do 	$DO/04_power.do

*do $DO/05_soep_comparison.do
*do $DO/06_registrydata.do
*do $DO/07_schooldata.do

log close
exit
