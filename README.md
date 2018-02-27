# data processing
### OrthoMCL pipeline using SnakeMake


Input files must be named after the organisms three letter code
e.g. 'cau.pep' and can be defined in the config.yaml file. Input should be in the folder data/fastas unless you alter the directories

All directories can be edited in the config.yaml file. keep in mind that these are paths relative to the location of the Snakefile.

To run the pipeline simple enter 'snakemake' into a terminal. Note that due to large files and all-v-all BLAST beign slow that running the pipeline can take hours or depending on the amount of input days.

Results will be stored in results/orthomcl

##### David van de Veerdonk
###### 316225
###### Bio-Informatics
